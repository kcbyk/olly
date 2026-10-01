import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

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
  StreamSubscription? _supabaseSub;

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

    // Supabase mesajlarını çek ve dinle
    if (SupabaseService.instance.isInitialized) {
      final selfId = profileIdentity.value.id;
      final peerId = _conversation.id;
      SupabaseService.instance.client
          .from('messages')
          .select()
          .or('and(sender_id.eq.$selfId,receiver_id.eq.$peerId),and(sender_id.eq.$peerId,receiver_id.eq.$selfId)')
          .order('created_at', ascending: true)
          .then((rows) {
        if (!mounted || rows.isEmpty) return;
        final history = rows.map((r) {
          final isMe = r['sender_id'] == selfId;
          final created = DateTime.tryParse(r['created_at']?.toString() ?? '') ?? DateTime.now();
          final timeStr = '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';
          return _ChatMessage(
            text: r['content']?.toString() ?? '',
            isMine: isMe,
            time: timeStr,
          );
        }).toList();
        setState(() {
          _messages = history;
        });
      }).catchError((_) {});

      _supabaseSub = SupabaseService.instance.client
          .from('messages')
          .stream(primaryKey: ['id'])
          .listen((rows) {
        if (!mounted) return;
        final relevant = rows.where((r) =>
            (r['sender_id'] == peerId && r['receiver_id'] == selfId) ||
            (r['sender_id'] == selfId && r['receiver_id'] == peerId)).toList();
        if (relevant.isNotEmpty) {
          final history = relevant.map((r) {
            final isMe = r['sender_id'] == selfId;
            final created = DateTime.tryParse(r['created_at']?.toString() ?? '') ?? DateTime.now();
            final timeStr = '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';
            return _ChatMessage(
              text: r['content']?.toString() ?? '',
              isMine: isMe,
              time: timeStr,
            );
          }).toList();
          setState(() {
            _messages = history;
          });
        }
      });
    }

    // Diğer tarayıcı sekmelerinden gelen anlık mesajları dinle
    _syncSub = CrossTabSyncService.instance.stream.listen((event) {
      if (event['type'] == 'CHAT_MESSAGE') {
        final self = profileIdentity.value;
        final toId = (event['toId'] as String?)?.toLowerCase();
        final fromId = (event['fromId'] as String?)?.toLowerCase();
        final currentConvId = _conversation.id.toLowerCase();
        final myId = self.id.toLowerCase();

        if (toId == myId &&
            (fromId == currentConvId ||
                event['fromName'] == _conversation.name)) {
          if (mounted) {
            setState(() {
              _messages.add(_ChatMessage(
                text: event['text'] as String? ?? '',
                isMine: false,
                time: event['time'] as String? ?? 'Şimdi',
              ));
            });
            ref.read(conversationsProvider.notifier).markAsRead(_conversation.id);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                );
              }
            });
          }
        }
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
    _syncSub?.cancel();
    _supabaseSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final self = profileIdentity.value;
    final timeStr = TimeOfDay.now().format(context);

    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isMine: true,
        time: timeStr,
      ));
      _controller.clear();
      _canSend = false;
    });

    ref.read(conversationsProvider.notifier).recordOutgoingMessage(
          peerId: _conversation.id,
          peerName: _conversation.name,
          text: text,
          time: timeStr,
        );

    // Supabase kaydı
    if (SupabaseService.instance.isInitialized) {
      try {
        SupabaseService.instance.client.from('messages').insert({
          'sender_id': self.id,
          'receiver_id': _conversation.id,
          'content': text,
        });
      } catch (_) {}
    }

    // Diğer sekmelere anlık yayınla
    CrossTabSyncService.instance.emit({
      'type': 'CHAT_MESSAGE',
      'fromId': self.id,
      'fromName': self.name,
      'toId': _conversation.id,
      'text': text,
      'time': timeStr,
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
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
    this.read = false,
    this.invite = false,
    this.audio = false,
  });

  final String text;
  final bool isMine;
  final String time;
  final bool read;
  final bool invite;
  final bool audio;
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
