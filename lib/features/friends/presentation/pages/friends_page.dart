import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/olly_avatar.dart';
import '../social_relationships_store.dart';

class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage> {
  String _selectedFilter = 'Tümü';
  final _filters = ['Tümü', 'Canlı Odadakiler', 'Çevrimiçi'];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final socialState = ref.watch(socialRelationshipsProvider);
    final allFriends = socialState.friends;

    // Filtrelenmiş liste
    final filteredFriends = allFriends.where((friend) {
      if (_selectedFilter == 'Canlı Odadakiler') {
        return friend.inVoiceRoom;
      }
      if (_selectedFilter == 'Çevrimiçi') {
        return friend.isOnline;
      }
      return true;
    }).toList();

    // Canlı presence listesi (çevrimiçi veya odada olan arkadaşlar)
    final presenceFriends = allFriends.where((f) => f.isOnline).toList();

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // ─── 1. Üst Bar Arkasında Sonsuz Dönen Video Arka Planı ───────────
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: _HeaderVideoBackground(),
          ),

          // ─── 2. Sayfa İçeriği ──────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ─── Lüks Header ─────────────────────────────────────────────
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
                                'Keşfet',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: colors.textPrimary,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const Gap(2),
                              Text(
                                '${allFriends.length} arkadaşın var · Canlı topluluk',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ID ile Arama / Arkadaş Ekle Butonu
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.addFriend),
                          child: Container(
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
                              Icons.person_add_rounded,
                              size: 20,
                              color: Color(0xFF1E1E24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

            // ─── Canlı / Aktif Hikayeler & Hızlı Odalar ─────────────────
            if (presenceFriends.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                      child: Text(
                        'CANLI PRESENCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: colors.textTertiary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 104,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: presenceFriends.length,
                        separatorBuilder: (_, __) => const Gap(14),
                        itemBuilder: (context, index) {
                          final item = presenceFriends[index];
                          return _PresenceBubble(
                            user: item,
                            onTap: () {
                              if (item.inVoiceRoom && item.roomId != null) {
                                context.push('/rooms/${item.roomId}');
                              } else {
                                context.push('/profile/${item.id}');
                              }
                            },
                          )
                              .animate(delay: Duration(milliseconds: index * 40))
                              .fadeIn()
                              .scale(begin: const Offset(0.85, 0.85));
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // ─── Filtre Çipleri (Kategori Sekmeleri) ──────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: _buildCategoryTabs(
                  colors,
                  _selectedFilter,
                  (filter) => setState(() => _selectedFilter = filter),
                ),
              ),
            ),

            // ─── Modern Arkadaş Kartları Listesi ─────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: filteredFriends.isEmpty
                  ? SliverToBoxAdapter(
                      child: _EmptyFriendsState(
                        filter: _selectedFilter,
                        onAddTap: () => context.push(AppRoutes.addFriend),
                      ),
                    )
                  : SliverList.separated(
                      itemCount: filteredFriends.length,
                      separatorBuilder: (_, __) => const Gap(10),
                      itemBuilder: (context, index) {
                        final friend = filteredFriends[index];
                        return _ModernFriendCard(friend: friend)
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

  Widget _buildCategoryTabs(
      OllyPalette colors, String activeTab, Function(String) onTabSelect) {
    final tabs = ['Tümü', 'Canlı Odadakiler', 'Çevrimiçi'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isActive = activeTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => onTabSelect(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFFBF4FC)
                      : (colors.isDark
                          ? const Color(0xFF262626)
                          : colors.surfaceElevated.withValues(alpha: 0.9)),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFE2D4E6)
                        : (colors.isDark
                            ? const Color(0xFF262626)
                            : colors.glassBorder),
                    width: isActive ? 1.2 : 1.0,
                  ),
                  boxShadow: isActive
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
                  tab,
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFF1E1E24)
                        : (colors.isDark
                            ? const Color(0xFFA8A8A8)
                            : colors.textSecondary),
                    fontSize: 12.5,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Canlı Presence Balonu (Story / Aktivite) ────────────────────────────────

class _PresenceBubble extends StatelessWidget {
  const _PresenceBubble({required this.user, required this.onTap});
  final OllyUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              OllyAvatar(
                size: 52,
                name: user.name,
                isSpeaking: user.inVoiceRoom,
                hasActiveStory: user.inVoiceRoom,
                isOnline: user.isOnline,
              ),
              if (user.inVoiceRoom)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.spatial_audio_rounded,
                        size: 10, color: Colors.white),
                  ),
                ),
            ],
          ),
          const Gap(6),
          SizedBox(
            width: 64,
            child: Text(
              user.name.split(' ').first,
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
          Text(
            user.inVoiceRoom ? (user.roomName ?? 'Ses Odasında') : 'Çevrimiçi',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              color: user.inVoiceRoom ? colors.online : colors.textTertiary,
              fontWeight:
                  user.inVoiceRoom ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lüks Modern Arkadaş Kartı ───────────────────────────────────────────────

class _ModernFriendCard extends StatelessWidget {
  const _ModernFriendCard({required this.friend});
  final OllyUser friend;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: () => context.push('/profile/${friend.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: friend.inVoiceRoom
                ? colors.primary.withValues(alpha: 0.4)
                : colors.glassBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            if (friend.inVoiceRoom)
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.08),
                blurRadius: 16,
              ),
          ],
        ),
        child: Row(
          children: [
            OllyAvatar(
              size: 46,
              name: friend.name,
              isOnline: friend.isOnline,
              isSpeaking: friend.inVoiceRoom,
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          friend.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (friend.isVerified) ...[
                        const Gap(4),
                        Icon(Icons.verified_rounded,
                            size: 14, color: colors.primaryLight),
                      ],
                    ],
                  ),
                  const Gap(2),
                  Row(
                    children: [
                      if (friend.inVoiceRoom) ...[
                        Icon(Icons.volume_up_rounded,
                            size: 12, color: colors.online),
                        const Gap(4),
                        Expanded(
                          child: Text(
                            friend.roomName ?? 'Ses Odasında',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: colors.online,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            friend.id,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            friend.statusNote,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Gap(10),
            // Aksiyon Tuşları
            if (friend.inVoiceRoom)
              GestureDetector(
                onTap: () => context.push('/rooms/${friend.roomId ?? 'r1'}'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: colors.online.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.spatial_audio_rounded,
                          size: 14, color: Colors.white),
                      Gap(5),
                      Text(
                        'Katıl',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              _IconAction(
                icon: Icons.chat_bubble_outline_rounded,
                onTap: () => context.push('/messages/${friend.id}'),
                tooltip: 'Mesaj',
              ),
              const Gap(6),
              _IconAction(
                icon: Icons.waving_hand_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${friend.name} kullanıcısına selam yollandı'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: colors.surfaceElevated,
                    ),
                  );
                },
                tooltip: 'Selam Ver',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.glassBorder),
          ),
          child: Icon(icon, size: 16, color: colors.textSecondary),
        ),
      ),
    );
  }
}

class _EmptyFriendsState extends StatelessWidget {
  const _EmptyFriendsState({required this.filter, required this.onAddTap});
  final String filter;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.people_outline_rounded,
              size: 48, color: colors.textTertiary),
          const Gap(12),
          Text(
            filter == 'Tümü'
                ? 'Henüz arkadaşın yok'
                : '$filter filtresine uygun arkadaş bulunamadı',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const Gap(6),
          Text(
            'Arkadaşının Olly ID\'sini girerek hemen ekleyebilirsin.',
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
          const Gap(16),
          GestureDetector(
            onTap: onAddTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF4FC),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFFE2D4E6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_add_rounded,
                    size: 17,
                    color: Color(0xFF1E1E24),
                  ),
                  Gap(8),
                  Text(
                    'Arkadaş Ekle',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1E24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderVideoBackground extends StatefulWidget {
  const _HeaderVideoBackground();

  @override
  State<_HeaderVideoBackground> createState() => _HeaderVideoBackgroundState();
}

class _HeaderVideoBackgroundState extends State<_HeaderVideoBackground> {
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
          VideoPlayerController.asset('assets/videos/discover_header_bg.mp4');
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      await controller.play();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Video 1 load error: $e');
      try {
        final fallback =
            VideoPlayerController.asset('assets/videos/whatsapp_video.mp4');
        _controller = fallback;
        await fallback.initialize();
        await fallback.setLooping(true);
        await fallback.setVolume(0.0);
        await fallback.play();
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      } catch (err) {
        debugPrint('Fallback video error: $err');
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
    final isReady = _isInitialized && controller != null && controller.value.isInitialized;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isReady)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                alignment: const Alignment(0.0, -0.1),
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
                  colors.background.withValues(alpha: 0.45),
                  colors.background,
                ],
                stops: const [0.0, 0.35, 0.70, 0.88, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

