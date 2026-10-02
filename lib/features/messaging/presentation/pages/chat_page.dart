import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/sync/cross_tab_sync.dart';
import '../../../../core/widgets/olly_avatar.dart';
import '../../../friends/presentation/social_relationships_store.dart';
import '../../../profile/presentation/profile_identity_store.dart';
import '../conversations_store.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({required this.conversationId, super.key});
  final String conversationId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _canSend = false;
  late _ConversationDetail _conversation;
  late List<_ChatMessage> _messages;
  StreamSubscription? _syncSub;
  RealtimeChannel? _supabaseChannel;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _conversation = _resolveConversation(widget.conversationId);
    _messages = List<_ChatMessage>.from(_conversation.messages);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(conversationsProvider.notifier).markAsRead(_conversation.id);
      }
    });

    // Supabase mesajlarını çek, Realtime ile dinle ve publication ayarı
    // eksikse polling ile yine de diğer cihazdaki mesajı yakala.
    if (SupabaseService.instance.isInitialized) {
      final selfId = profileIdentity.value.id;
      final peerId = _conversation.id;
      unawaited(_loadHistory());

      _supabaseChannel = SupabaseService.instance.client
          .channel('chat_${selfId}_$peerId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            callback: (payload) =>
                _handleDatabaseMessage(payload.newRecord, selfId, peerId),
          )
        ..subscribe();
      _pollTimer = Timer.periodic(
        const Duration(seconds: 6),
        (_) => unawaited(_loadHistory()),
      );
    }

    // Diğer tarayıcı sekmelerinden gelen anlık mesajları dinle
    _syncSub = CrossTabSyncService.instance.stream.listen((event) {
      if (event['type'] != 'CHAT_MESSAGE') return;
      final self = profileIdentity.value;
      final toId = (event['toId'] as String?)?.toLowerCase();
      final fromId = (event['fromId'] as String?)?.toLowerCase();
      final currentConvId = _conversation.id.toLowerCase();
      final myId = self.id.toLowerCase();

      if (toId != myId ||
          (fromId != currentConvId && event['fromName'] != _conversation.name)) {
        return;
      }

      final messageId = event['messageId'] as String?;
      if (messageId != null &&
          _messages.any((message) => message.id == messageId)) {
        return;
      }
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            id: messageId,
            text: event['text'] as String? ?? '',
            isMine: false,
            time: event['time'] as String? ?? 'Şimdi',
          ));
        });
        ref.read(conversationsProvider.notifier).markAsRead(_conversation.id);
        _scrollToBottom();
      }
    });
  }

  Future<void> _loadHistory() async {
    if (!mounted || !SupabaseService.instance.isInitialized) return;
    final selfId = profileIdentity.value.id;
    final peerId = _conversation.id;
    try {
      final rawRows = await SupabaseService.instance.client
          .from('messages')
          .select('id, sender_id, receiver_id, content, created_at')
          .or('and(sender_id.eq.$selfId,receiver_id.eq.$peerId),and(sender_id.eq.$peerId,receiver_id.eq.$selfId)')
          .order('created_at', ascending: true);
      final history = (rawRows as List<dynamic>).map((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        final created = DateTime.tryParse(row['created_at']?.toString() ?? '') ??
            DateTime.now();
        final isMe = row['sender_id']?.toString() == selfId;
        return _ChatMessage(
          id: row['id']?.toString(),
          text: row['content']?.toString() ?? '',
          isMine: isMe,
          time:
              '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}',
        );
      }).toList();
      if (!mounted || history.isEmpty) return;

      // A send can happen while the initial query is in flight. Preserve any
      // optimistic bubbles that are not in the query response yet.
      final next = <_ChatMessage>[...history];
      for (final optimistic in _messages.where((message) => message.isOptimistic)) {
        final exists = next.any((message) =>
            (optimistic.id != null && message.id == optimistic.id) ||
            (message.text == optimistic.text && message.isMine == optimistic.isMine));
        if (!exists) next.add(optimistic);
      }
      setState(() => _messages = next);
      _scrollToBottom(animated: false);
    } catch (_) {
      // Local/cross-tab messaging remains available when the API is offline.
    }
  }

  void _handleDatabaseMessage(
    Map<String, dynamic> row,
    String selfId,
    String peerId,
  ) {
    if (!mounted) return;
    final senderId = row['sender_id']?.toString() ?? '';
    final receiverId = row['receiver_id']?.toString() ?? '';
    if (!((senderId == peerId && receiverId == selfId) ||
        (senderId == selfId && receiverId == peerId))) {
      return;
    }

    final id = row['id']?.toString();
    final text = row['content']?.toString() ?? '';
    final isMine = senderId == selfId;
    final created = DateTime.tryParse(row['created_at']?.toString() ?? '') ??
        DateTime.now();
    final time =
        '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';

    final exactIndex = id == null
        ? -1
        : _messages.indexWhere((message) => message.id == id);
    if (exactIndex >= 0 && !_messages[exactIndex].isOptimistic) return;

    final optimisticIndex = _messages.lastIndexWhere((message) =>
        message.isOptimistic && message.isMine == isMine && message.text == text);
    setState(() {
      if (optimisticIndex >= 0) {
        _messages[optimisticIndex] = _ChatMessage(
          id: id,
          text: text,
          isMine: isMine,
          time: time,
        );
      } else if (exactIndex < 0) {
        _messages.add(_ChatMessage(
          id: id,
          text: text,
          isMine: isMine,
          time: time,
        ));
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (!animated) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      setState(() {
        _conversation = _resolveConversation(widget.conversationId);
        _messages = List<_ChatMessage>.from(_conversation.messages);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(conversationsProvider.notifier).markAsRead(_conversation.id);
        }
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _syncSub?.cancel();
    if (_supabaseChannel != null && SupabaseService.instance.isInitialized) {
      SupabaseService.instance.client.removeChannel(_supabaseChannel!);
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() => unawaited(_sendMessage());

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final self = profileIdentity.value;
    final timeStr = TimeOfDay.now().format(context);
    final hasBackend = SupabaseService.instance.isInitialized;

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isMine: true,
        time: timeStr,
        // With a backend this bubble is replaced by the row returned from
        // Supabase. Without one it is already the durable local message.
        isOptimistic: hasBackend,
      ));
      _canSend = false;
    });
    _controller.clear();

    ref.read(conversationsProvider.notifier).recordOutgoingMessage(
          peerId: _conversation.id,
          peerName: _conversation.name,
          text: text,
          time: timeStr,
        );
    _scrollToBottom();

    String? messageId;
    if (hasBackend) {
      try {
        final inserted = await SupabaseService.instance.client
            .from('messages')
            .insert({
              'sender_id': self.id,
              'receiver_id': _conversation.id,
              'content': text,
            })
            .select('id, sender_id, receiver_id, content, created_at')
            .single();
        final row = Map<String, dynamic>.from(inserted as Map);
        messageId = row['id']?.toString();
        if (mounted) _handleDatabaseMessage(row, self.id, _conversation.id);
        ref.read(conversationsProvider.notifier).recordOutgoingMessage(
              peerId: _conversation.id,
              peerName: _conversation.name,
              text: text,
              time: timeStr,
              messageId: messageId,
            );
      } catch (e) {
        if (mounted) {
          final index = _messages.lastIndexWhere(
            (message) =>
                message.isOptimistic &&
                message.isMine &&
                message.text == text,
          );
          if (index >= 0) {
            setState(() => _messages.removeAt(index));
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mesaj gönderilemedi. İnternet bağlantını kontrol et.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    // Aynı origin'deki diğer sekmeler için hızlı yol. Farklı cihazlar mesajı
    // Supabase insert + Realtime/polling üzerinden alır.
    CrossTabSyncService.instance.emit({
      'type': 'CHAT_MESSAGE',
      'messageId': messageId,
      'fromId': self.id,
      'fromName': self.name,
      'toId': _conversation.id,
      'text': text,
      'time': timeStr,
    });
  }

  void _showChatOptions(BuildContext context) {
    final colors = AppColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.surfaceHighlight,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const Gap(16),
            ListTile(
              leading: Icon(Icons.person_outline_rounded, color: colors.primary),
              title: Text('Profili Görüntüle',
                  style: TextStyle(
                      color: colors.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/profile/${_conversation.id}');
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications_off_outlined,
                  color: colors.textSecondary),
              title: Text('Bildirimleri Sessize Al',
                  style: TextStyle(
                      color: colors.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bildirimler sessize alındı'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.delete_outline_rounded, color: colors.muted),
              title: Text('Sohbeti Temizle',
                  style: TextStyle(
                      color: colors.muted, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(sheetContext);
                setState(() => _messages.clear());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sohbet temizlendi'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leadingWidth: 50,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: colors.textPrimary,
            ),
            splashRadius: 22,
            tooltip: 'Geri',
          ),
        ),
        titleSpacing: 4,
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.push('/profile/${_conversation.id}'),
          child: Row(
            children: [
              OllyAvatar(
                size: 40,
                name: _conversation.name,
                isOnline: _conversation.isOnline,
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _conversation.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Gap(2),
                    Row(
                      children: [
                        if (_conversation.isOnline)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              color: colors.online,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            _conversation.status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: _conversation.isOnline
                                  ? colors.online
                                  : colors.textTertiary,
                              fontWeight: _conversation.isOnline
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_conversation.name} ile sesli arama yakında'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: Icon(Icons.phone_outlined,
                color: colors.textPrimary, size: 21),
            tooltip: 'Ara',
          ),
          IconButton(
            onPressed: () => _showChatOptions(context),
            icon: Icon(Icons.more_horiz_rounded,
                color: colors.textPrimary, size: 22),
            tooltip: 'Diğer seçenekler',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ─── Topluluk Uyarı Banneri ───────────────────────────────────────
          _CommunityBanner(name: _conversation.name),
          Expanded(
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.04, 0.96, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                itemCount: _messages.length + 1,
                itemBuilder: (context, index) => index == 0
                    ? const _ConversationDate()
                    : _MessageBubble(
                        message: _messages[index - 1],
                        activeRoomId: _conversation.activeRoomId,
                      ),
              ),
            ),
          ),
          _Composer(
            controller: _controller,
            canSend: _canSend,
            onChanged: (value) =>
                setState(() => _canSend = value.trim().isNotEmpty),
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _ConversationDate extends StatelessWidget {
  const _ConversationDate();
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Center(
        child: Text(
          'BUGÜN',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
            color: colors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.canSend,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool canSend;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
              tooltip: 'Ekle',
              color: colors.textSecondary,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: (_) => canSend ? onSend() : null,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                style: TextStyle(
                  fontSize: 14.5,
                  color: colors.textPrimary,
                  height: 1.35,
                ),
                decoration: InputDecoration(
                  hintText: 'Mesaj yaz',
                  hintStyle: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 14.5,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  suffixIcon: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.sentiment_satisfied_alt_outlined, size: 22),
                    tooltip: 'Emoji',
                    color: colors.textTertiary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: canSend ? 'Mesajı gönder' : 'Sesli mesaj kaydet',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: canSend ? colors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: canSend ? onSend : () {},
                  tooltip: canSend ? 'Gönder' : 'Sesli mesaj',
                  icon: Icon(
                    canSend
                        ? Icons.arrow_upward_rounded
                        : Icons.mic_none_rounded,
                    size: 22,
                    color: canSend ? Colors.white : colors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.activeRoomId});
  final _ChatMessage message;
  final String? activeRoomId;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    if (message.invite) {
      return _RoomInvite(
        title: message.text,
        roomId: activeRoomId ?? 'r1',
      );
    }
    if (message.audio) return _AudioMessage(duration: message.text);
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(message.isMine ? 16 : 4),
      bottomRight: Radius.circular(message.isMine ? 4 : 16),
    );
    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .72),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: message.isMine ? colors.primary : colors.surface,
          borderRadius: radius,
          border: message.isMine ? null : Border.all(color: colors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment:
              message.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.38,
                color: message.isMine ? Colors.white : colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.time,
                  style: TextStyle(
                    fontSize: 10,
                    color: message.isMine ? Colors.white70 : colors.textTertiary,
                  ),
                ),
                if (message.isMine) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all_rounded,
                    size: 13,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomInvite extends StatelessWidget {
  const _RoomInvite({required this.title, required this.roomId});
  final String title;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .76),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.graphic_eq_rounded,
                    color: colors.secondary, size: 18),
                const Gap(8),
                Text(
                  'Ses odası daveti',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            const Gap(10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const Gap(12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: colors.primary),
                onPressed: () => context.push('/rooms/$roomId'),
                icon: const Icon(Icons.headset_mic_outlined, size: 17),
                label: const Text('Odaya katıl'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioMessage extends StatelessWidget {
  const _AudioMessage({required this.duration});
  final String duration;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.primary,
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
            const Gap(10),
            ...[5, 12, 18, 9, 15, 20, 11, 7].map((height) => Container(
                  width: 3,
                  height: height.toDouble(),
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: colors.primaryLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
            const Gap(9),
            Text(
              duration,
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isMine,
    required this.time,
    this.id,
    this.read = false,
    this.invite = false,
    this.audio = false,
    this.isOptimistic = false,
  });

  final String text;
  final String? id;
  final bool isMine;
  final String time;
  final bool read;
  final bool invite;
  final bool audio;
  final bool isOptimistic;
}

class _ConversationDetail {
  const _ConversationDetail({
    required this.id,
    required this.name,
    required this.status,
    required this.isOnline,
    this.activeRoomId,
    required this.messages,
  });

  final String id;
  final String name;
  final String status;
  final bool isOnline;
  final String? activeRoomId;
  final List<_ChatMessage> messages;
}

class _CommunityBanner extends StatelessWidget {
  const _CommunityBanner({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.glassBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 12, color: colors.textTertiary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$name ile mesajların uçtan uca şifrelidir.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: colors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

_ConversationDetail _resolveConversation(String id) {
  final user = findUserByIdOrAlias(id);

  return _ConversationDetail(
    id: user.id,
    name: user.name,
    status: user.isOnline
        ? (user.inVoiceRoom && user.roomName != null
            ? 'Çevrimiçi · ${user.roomName} Odası’nda'
            : user.statusNote)
        : user.statusNote,
    isOnline: user.isOnline,
    activeRoomId: user.roomId,
    messages: const [
      _ChatMessage(
        text: 'Sohbet başlatıldı. Mesajınızı buraya yazabilirsiniz.',
        isMine: false,
        time: 'Şimdi',
      ),
    ],
  );
}
