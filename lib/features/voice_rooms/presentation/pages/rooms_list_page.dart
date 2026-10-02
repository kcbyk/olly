import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/olly_avatar.dart';
import '../../../friends/presentation/social_relationships_store.dart';
import '../voice_rooms_store.dart';

// ─── Rooms List Page ─────────────────────────────────────────────────────────

class RoomsListPage extends ConsumerStatefulWidget {
  const RoomsListPage({super.key});

  @override
  ConsumerState<RoomsListPage> createState() => _RoomsListPageState();
}

class _RoomsListPageState extends ConsumerState<RoomsListPage> {
  String _selectedCategory = 'Tümü';

  static const _categories = ['Tümü', 'Arkadaşlar', 'Takip Edilen'];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final socialState = ref.watch(socialRelationshipsProvider);
    final friendNames = socialState.friends.map((f) => f.name).toSet();
    final followedUsers =
        ref.read(socialRelationshipsProvider.notifier).getFollowingUsers();
    final followedNames = followedUsers.map((u) => u.name).toSet();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            colors.isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: colors.background,
        body: Stack(
          children: [
            // ─── 1. Üst Bar Arkasında Sonsuz Dönen Video Arka Planı ───────────
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 290,
              child: _RoomsHeaderVideoBackground(),
            ),

            // ─── 2. Sayfa İçeriği ──────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: ValueListenableBuilder<VoiceRoomsSnapshot>(
            valueListenable: voiceRooms,
            builder: (context, snapshot, _) {
              final visibleRooms = snapshot.rooms.where((r) {
                if (!r.isActive) return false;
                if (_selectedCategory == 'Tümü') return true;
                if (_selectedCategory == 'Arkadaşlar') {
                  final isHostFriend = friendNames.contains(r.hostName);
                  final hasFriendInSeats = r.seats
                      .whereType<VoiceSeatOccupant>()
                      .any((s) => friendNames.contains(s.name));
                  return isHostFriend || hasFriendInSeats;
                }
                if (_selectedCategory == 'Takip Edilen') {
                  final isHostFollowed = followedNames.contains(r.hostName);
                  final hasFollowedInSeats = r.seats
                      .whereType<VoiceSeatOccupant>()
                      .any((s) => followedNames.contains(s.name));
                  return isHostFollowed || hasFollowedInSeats;
                }
                return r.category == _selectedCategory;
              }).toList();

              final people = snapshot.activePeople;
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: const _ListHeader(),
                    ),
                  ),
                  if (people.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                        child: _ActiveProfilesRow(
                          people: people,
                          onRoomTap: (p) =>
                              context.push('/rooms/${p.roomId}'),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _CategoryTabs(
                        categories: _categories,
                        selectedCategory: _selectedCategory,
                        onSelect: (cat) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategory = cat);
                        },
                      ),
                    ),
                  ),
                  if (visibleRooms.isEmpty)
                    SliverToBoxAdapter(
                        child: _EmptyState(category: _selectedCategory))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      sliver: SliverList.separated(
                        itemCount: visibleRooms.length,
                        separatorBuilder: (_, __) => const Gap(10),
                        itemBuilder: (context, index) => _RoomCard(
                          room: visibleRooms[index],
                          onJoin: () => context
                              .push('/rooms/${visibleRooms[index].id}'),
                        )
                            .animate(delay: Duration(milliseconds: index * 40))
                            .fadeIn()
                            .slideY(begin: 0.08),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  ),
);
}
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _ListHeader extends StatelessWidget {
  const _ListHeader();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {},
              child: Text(
                'Sesli Odalar',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: colors.textPrimary,
                ),
              ),
            ),
            const Gap(16),
            GestureDetector(
              onTap: () => context.push('/rooms/operations'),
              child: Text(
                'İşlem Merkezi',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: colors.textTertiary,
                ),
              ),
            ),
          ],
        ),
        const Gap(4),
        Text(
          'Canlı konuşmalara katıl veya kendi odanı aç.',
          style: TextStyle(
            fontSize: 12.5,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Aktif Profiller ─────────────────────────────────────────────────────────

class _ActiveProfilesRow extends StatelessWidget {
  const _ActiveProfilesRow({required this.people, required this.onRoomTap});
  final List<VoicePresence> people;
  final ValueChanged<VoicePresence> onRoomTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'ŞU AN AKTİF',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: colors.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Gap(10),
        if (people.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Şu an sahnede kimse yok.',
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
          )
        else
          SizedBox(
            height: 106,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: people.length,
              separatorBuilder: (_, __) => const Gap(10),
              itemBuilder: (context, i) => _ActiveProfileCard(
                profile: people[i],
                onTap: () => onRoomTap(people[i]),
              )
                  .animate(delay: Duration(milliseconds: i * 40))
                  .fadeIn()
                  .scale(begin: const Offset(0.85, 0.85)),
            ),
          ),
      ],
    );
  }
}

class _ActiveProfileCard extends StatelessWidget {
  const _ActiveProfileCard({required this.profile, required this.onTap});
  final VoicePresence profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 82,
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                OllyAvatar(size: 46, name: profile.name),
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors.online,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(7),
            Text(
              profile.name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const Gap(3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline_rounded,
                    size: 11, color: colors.textTertiary),
                const Gap(3),
                Text(
                  '${profile.roomMembers}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Kategori Tabları ─────────────────────────────────────────────────────────

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.categories,
    required this.selectedCategory,
    required this.onSelect,
  });
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isActive = cat == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => onSelect(cat),
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
                  cat,
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

// ─── Oda Kartı ────────────────────────────────────────────────────────────────

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.onJoin});
  final VoiceRoom room;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onJoin,
      child: Container(
        decoration: BoxDecoration(
          gradient: colors.isDark
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFCEEF8), Color(0xFFEFEAF8)],
                ),
          color: colors.isDark ? colors.surface : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.isDark
                ? colors.glassBorder
                : const Color(0xFFE2D0ED),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A154B).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Diagonal çizgi dokusu
            if (!colors.isDark)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: CustomPaint(painter: _DiagonalLinesPainter()),
                ),
              ),
            // İçerik
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil Avatarı
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      OllyAvatar(
                        size: 46,
                        name: room.hostName,
                        isOnline: true,
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: colors.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.isDark
                                  ? colors.surface
                                  : const Color(0xFFFCEEF8),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            size: 9,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),

                  // Oda Bilgisi
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.hostName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const Gap(2),
                        Text(
                          room.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.3,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(10),

                  // Katıl Butonu ve Katılımcı Sayısı
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _JoinButton(onTap: onJoin),
                      const Gap(8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (room.speakerNames.isNotEmpty)
                            SizedBox(
                              width: (room.speakerNames.take(3).length - 1) *
                                      12.0 +
                                  18.0,
                              height: 20,
                              child: Stack(
                                children: [
                                  for (int i = 0;
                                      i < room.speakerNames.length && i < 3;
                                      i++)
                                    Positioned(
                                      left: i * 11.0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: colors.surface,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: OllyAvatar(
                                          size: 18,
                                          name: room.speakerNames[i],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          if (room.speakerNames.isNotEmpty) const Gap(4),
                          Text(
                            '${room.participantsCount}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const Gap(2.5),
                          Icon(
                            Icons.people_outline_rounded,
                            size: 13,
                            color: colors.textTertiary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Diagonal çizgi dokusu boyaması
class _DiagonalLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDDB8D8).withValues(alpha: 0.28)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    const spacing = 16.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DiagonalLinesPainter old) => false;
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFFDCC4E8),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'Katıl',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E1E24),
          ),
        ),
      ),
    );
  }
}

// ─── Boş Durum ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.category = 'Tümü'});
  final String category;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final String title;
    final String subtitle;
    final IconData icon;

    if (category == 'Arkadaşlar') {
      icon = Icons.group_outlined;
      title = 'Arkadaşlarının açık odası yok';
      subtitle = 'Arkadaşların yeni bir oda açtığında burada görünecek.';
    } else if (category == 'Takip Edilen') {
      icon = Icons.bookmark_border_rounded;
      title = 'Takip edilen oda yok';
      subtitle = 'Henüz takip ettiğin bir oda veya yayıncı bulunmuyor.';
    } else {
      icon = Icons.graphic_eq_outlined;
      title = 'Açık oda yok';
      subtitle = 'Şu anda yayında aktif oda bulunmuyor.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          Icon(icon, size: 40, color: colors.textTertiary),
          const Gap(14),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const Gap(6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Oda Oluşturma Sayfası ────────────────────────────────────────────────────

class _CreateRoomSheet extends StatefulWidget {
  const _CreateRoomSheet();

  @override
  State<_CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends State<_CreateRoomSheet> {
  final _titleCtrl = TextEditingController();
  String _selectedCategory = 'Sohbet';

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const Gap(20),
            Text(
              'Yeni oda aç',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: colors.textPrimary,
              ),
            ),
            const Gap(4),
            Text(
              'Arkadaşların katılmak için bildirim alır.',
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
            const Gap(20),
            // İsim alanı
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.glassBorder),
              ),
              child: TextField(
                controller: _titleCtrl,
                autofocus: true,
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Oda adı',
                  labelStyle: TextStyle(color: colors.textSecondary),
                  hintText: 'Örn. Akşam sohbeti',
                  hintStyle: TextStyle(color: colors.textTertiary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                ),
              ),
            ),
            const Gap(16),
            // Kategoriler
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Sohbet', 'Oyun', 'Müzik', 'Teknoloji']
                  .map(
                    (cat) => GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedCategory == cat
                              ? colors.primary
                              : colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedCategory == cat
                                ? Colors.transparent
                                : colors.glassBorder,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: _selectedCategory == cat
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _selectedCategory == cat
                                ? Colors.white
                                : colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const Gap(24),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  final title = _titleCtrl.text.trim();
                  if (title.isEmpty) return;
                  final id = createVoiceRoom(
                    title: title,
                    category: _selectedCategory,
                  );
                  Navigator.pop(context);
                  context.push('/rooms/$id');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: colors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic_rounded,
                          size: 18, color: Colors.white),
                      Gap(8),
                      Text(
                        'Odayı başlat',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
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

class _RoomsHeaderVideoBackground extends StatefulWidget {
  const _RoomsHeaderVideoBackground();

  @override
  State<_RoomsHeaderVideoBackground> createState() =>
      _RoomsHeaderVideoBackgroundState();
}

class _RoomsHeaderVideoBackgroundState
    extends State<_RoomsHeaderVideoBackground> {
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
          VideoPlayerController.asset('assets/videos/rooms_header_bg.mp4');
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      await controller.play();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Rooms video 1 load error: $e');
      try {
        final fallback =
            VideoPlayerController.asset('assets/videos/whatsapp_video_rooms.mp4');
        _controller = fallback;
        await fallback.initialize();
        await fallback.setLooping(true);
        await fallback.setVolume(0.0);
        await fallback.play();
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      } catch (err) {
        debugPrint('Fallback rooms video error: $err');
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
                alignment: const Alignment(0.0, 0.0),
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

          // Lüks karartma ve yumuşak sayfa geçiş gradyanı
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

