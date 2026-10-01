import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/olly_avatar.dart';
import '../blocked_users_store.dart';
import '../conversations_store.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  String _selectedFilter = 'Tümü';
  String _searchQuery = '';
  final _filters = ['Tümü', 'Okunmamış', 'Gruplar'];
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final convState = ref.watch(conversationsProvider);
    final convNotifier = ref.read(conversationsProvider.notifier);
    final conversations = convState.conversations;
    final pinned = convState.pinned;

    final query = _searchQuery;
    final isSearching = query.isNotEmpty;

    final visibleConversations = conversations.where((c) {
      if (_selectedFilter == 'Okunmamış' && c.unread == 0) return false;
      if (_selectedFilter == 'Gruplar' &&
          !c.name.toLowerCase().contains('grup') &&
          !c.name.toLowerCase().contains('group')) {
        return false;
      }
      if (isSearching) {
        final matchName = c.name.toLowerCase().contains(query);
        final matchId = c.id.toLowerCase().contains(query);
        final matchMsg = c.lastMessage.toLowerCase().contains(query);
        return matchName || matchId || matchMsg;
      }
      return true;
    }).toList();

    final visiblePinned = isSearching
        ? pinned
            .where((u) =>
                u.name.toLowerCase().contains(query) ||
                u.id.toLowerCase().contains(query))
            .toList()
        : pinned;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // ─── 1. Üst Bar Arkasında Sonsuz Dönen Video Arka Planı ───────────
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 310,
            child: _MessagesHeaderVideoBackground(),
          ),

          // ─── 2. Sayfa İçeriği ──────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
            // ─── Header ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mesajlar',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: colors.textPrimary,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            isSearching
                                ? '${visibleConversations.length} sonuç bulundu'
                                : (conversations.isEmpty
                                    ? 'Henüz mesajın yok'
                                    : '${conversations.where((c) => c.unread > 0).fold(0, (sum, c) => sum + c.unread)} okunmamış mesajın var'),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<_MessagesAction>(
                      tooltip: 'Mesaj seçenekleri',
                      onSelected: _handleMenuAction,
                      icon: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF4FC),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE2D4E6),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.more_horiz_rounded,
                          size: 20,
                          color: Color(0xFF1E1E24),
                        ),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: _MessagesAction.blockedUsers,
                          child: ListTile(
                            leading: Icon(Icons.block_outlined),
                            title: Text('Engellenen kişiler'),
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: _MessagesAction.clearAll,
                          child: ListTile(
                            leading: Icon(Icons.delete_outline,
                                color: colors.muted),
                            title: Text('Tüm mesajları sil',
                                style: TextStyle(color: colors.muted)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── Arama Çubuğu ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.glassBorder),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          color: colors.textTertiary, size: 20),
                      const Gap(10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(
                              () => _searchQuery = val.trim().toLowerCase()),
                          style: TextStyle(
                              color: colors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'İsim veya ID arayın...',
                            hintStyle: TextStyle(
                                color: colors.textTertiary, fontSize: 13.5),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Icon(Icons.close_rounded,
                              size: 18, color: colors.textTertiary),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Sabitlenen Hızlı Sohbetler (Pinned Carousel) ────────────
            SliverToBoxAdapter(
              child: visiblePinned.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          child: Text(
                            'SABİTLENENLER',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: colors.textTertiary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 88,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: visiblePinned.length,
                            separatorBuilder: (_, __) => const Gap(14),
                            itemBuilder: (context, index) {
                              final u = visiblePinned[index];
                              return GestureDetector(
                                onTap: () => context.push('/messages/${u.id}'),
                                onLongPress: () => _showConversationActions(
                                    _conversationFor(u, conversations)),
                                child: Column(
                                  children: [
                                    OllyAvatar(
                                      size: 52,
                                      name: u.name,
                                      isOnline: u.isOnline,
                                      hasActiveStory: u.hasUnread,
                                    ),
                                    const Gap(6),
                                    SizedBox(
                                      width: 56,
                                      child: Text(
                                        u.name.split(' ').first,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  .animate(
                                      delay: Duration(
                                          milliseconds: index * 40))
                                  .fadeIn()
                                  .scale(begin: const Offset(0.85, 0.85));
                            },
                          ),
                        ),
                      ],
                    ),
            ),

            // ─── Filtre Çipleri ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Row(
                  children: _filters.map((f) {
                    final isSel = _selectedFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel
                                ? const Color(0xFFFBF4FC)
                                : colors.surfaceElevated.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSel
                                  ? const Color(0xFFE2D4E6)
                                  : colors.glassBorder,
                              width: isSel ? 1.2 : 1.0,
                            ),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight:
                                  isSel ? FontWeight.w800 : FontWeight.w600,
                              color: isSel
                                  ? const Color(0xFF1E1E24)
                                  : colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ─── Konuşma Listesi ────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: visibleConversations.isEmpty
                  ? SliverToBoxAdapter(
                      child: _EmptyMessages(isSearching: isSearching))
                  : SliverList.separated(
                      itemCount: visibleConversations.length,
                      separatorBuilder: (_, __) => const Gap(2),
                      itemBuilder: (context, index) {
                        final conv = visibleConversations[index];
                        return _ConversationCard(
                          conversation: conv,
                          onTap: () => context.push('/messages/${conv.id}'),
                          onLongPress: () => _showConversationActions(conv),
                        )
                            .animate(delay: Duration(milliseconds: index * 40))
                            .fadeIn()
                            .slideY(begin: 0.08);
                      },
                    ),
            ),
          ],
        ),
      ),
    ],
  ),
);
}

  Future<void> _handleMenuAction(_MessagesAction action) async {
    final colors = AppColors.of(context);
    final convNotifier = ref.read(conversationsProvider.notifier);

    if (action == _MessagesAction.blockedUsers) {
      context.push(AppRoutes.blockedUsers);
      return;
    }

    final shouldClear = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: colors.surface,
            title: Text('Tüm mesajlar silinsin mi?',
                style: TextStyle(color: colors.textPrimary)),
            content: Text(
              'Konuşmaların ve sabitlenen mesajların bu cihazdaki listesi temizlenir.',
              style: TextStyle(color: colors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('Vazgeç',
                    style: TextStyle(color: colors.textSecondary)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: colors.muted),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Tümünü sil'),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldClear || !mounted) return;
    convNotifier.clearAll();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Tüm mesajlar silindi'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showConversationActions(ModernConversation conversation) {
    final colors = AppColors.of(context);
    final convNotifier = ref.read(conversationsProvider.notifier);
    final pinned = ref.read(conversationsProvider).pinned;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const Gap(20),
              OllyAvatar(
                  size: 48,
                  name: conversation.name,
                  isOnline: conversation.isOnline),
              const Gap(10),
              Text(conversation.name,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary)),
              const Gap(20),
              _ConversationAction(
                icon: Icons.person_outline_rounded,
                label: 'Profili görüntüle',
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/profile/${conversation.id}');
                },
              ),
              const Divider(height: 1),
              _ConversationAction(
                icon: Icons.push_pin_outlined,
                label: pinned.any((user) => user.id == conversation.id)
                    ? 'Sabitlemeyi kaldır'
                    : 'Sabitle',
                onTap: () {
                  convNotifier.togglePin(conversation);
                  Navigator.pop(sheetContext);
                },
              ),
              const Divider(height: 1),
              _ConversationAction(
                icon: Icons.delete_outline_rounded,
                label: 'Mesajı sil',
                isDestructive: true,
                onTap: () {
                  convNotifier.deleteConversation(conversation.id);
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${conversation.name} konuşması silindi'),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
              ),
              const Divider(height: 1),
              _ConversationAction(
                icon: Icons.block_outlined,
                label: 'Engelle',
                isDestructive: true,
                onTap: () {
                  blockUser(BlockedUser(conversation.id, conversation.name));
                  convNotifier.deleteConversation(conversation.id);
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${conversation.name} engellendi'),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }

  ModernConversation _conversationFor(
      PinnedUser user, List<ModernConversation> conversations) {
    for (final conversation in conversations) {
      if (conversation.id == user.id) return conversation;
    }
    return ModernConversation(
      id: user.id,
      name: user.name,
      lastMessage: '',
      time: '',
      unread: user.hasUnread ? 1 : 0,
      isOnline: user.isOnline,
    );
  }
}

enum _MessagesAction { blockedUsers, clearAll }

class _ConversationAction extends StatelessWidget {
  const _ConversationAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Icon(icon,
          color: isDestructive ? colors.muted : colors.primary),
      title: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDestructive ? colors.muted : colors.textPrimary)),
      trailing:
          Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
    );
  }
}

class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages({this.isSearching = false});
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 42),
      child: Column(children: [
        Icon(
          isSearching ? Icons.search_off_rounded : Icons.forum_outlined,
          size: 36,
          color: colors.textTertiary,
        ),
        const Gap(12),
        Text(
          isSearching ? 'Sonuç bulunamadı' : 'Mesaj kutun boş',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const Gap(4),
        Text(
          isSearching
              ? 'Aradığın isim veya ID ile eşleşen konuşma bulunamadı.'
              : 'Yeni bir sohbete başladığında burada görünür.',
          style: TextStyle(color: colors.textSecondary),
        ),
      ]),
    );
  }
}

// ─── Konuşma Satırı ──────────────────────────────────────────────────────────

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.conversation,
    required this.onTap,
    required this.onLongPress,
  });
  final ModernConversation conversation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final hasUnread = conversation.unread > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              OllyAvatar(
                size: 50,
                name: conversation.name,
                isOnline: conversation.isOnline,
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.name,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: hasUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          conversation.time,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: hasUnread
                                ? colors.primaryLight
                                : colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        if (conversation.isVoiceMessage) ...[
                          Icon(Icons.mic_rounded,
                              size: 14, color: colors.accent),
                          const Gap(4),
                        ] else if (!hasUnread) ...[
                          Icon(Icons.done_all_rounded,
                              size: 14, color: colors.accent),
                          const Gap(4),
                        ],
                        Expanded(
                          child: Text(
                            conversation.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: hasUnread
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: colors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      colors.primary.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Text(
                              '${conversation.unread}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
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
      ),
    );
  }
}

class _MessagesHeaderVideoBackground extends StatefulWidget {
  const _MessagesHeaderVideoBackground();

  @override
  State<_MessagesHeaderVideoBackground> createState() =>
      _MessagesHeaderVideoBackgroundState();
}

class _MessagesHeaderVideoBackgroundState
    extends State<_MessagesHeaderVideoBackground> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final controller =
          VideoPlayerController.asset('assets/videos/messages_header_bg.mp4');
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      await controller.play();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Messages video 1 load error: $e');
      try {
        final fallback = VideoPlayerController.asset(
            'assets/videos/whatsapp_video_messages.mp4');
        _controller = fallback;
        await fallback.initialize();
        await fallback.setLooping(true);
        await fallback.setVolume(0.0);
        await fallback.play();
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      } catch (err) {
        debugPrint('Fallback messages video error: $err');
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final controller = _controller;
    final isReady =
        _isInitialized && controller != null && controller.value.isInitialized;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isReady)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                alignment: const Alignment(0.0, 0.30),
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: controller.value.size.width > 0
                      ? controller.value.size.width
                      : 16,
                  height: controller.value.size.height > 0
                      ? controller.value.size.height
                      : 9,
                  child: VideoPlayer(controller),
                ),
              ),
            )
          else
            Container(color: colors.surfaceElevated),

          // Lüks karartma ve yumuşak sayfa geçiş gradyanı (yüzü kapatmayacak şekilde)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.20),
                  Colors.transparent,
                  Colors.transparent,
                  colors.background.withValues(alpha: 0.40),
                  colors.background,
                ],
                stops: const [0.0, 0.30, 0.70, 0.90, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

