import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/olly_avatar.dart';
import '../../../friends/presentation/social_relationships_store.dart';
import '../profile_identity_store.dart';
import '../../../voice_rooms/presentation/voice_rooms_store.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _actionsVisible = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── 1. Animasyon + Başlık + Kimlik Kartı (tek Stack içinde) ──
          SliverToBoxAdapter(
            child: ValueListenableBuilder<ProfileIdentity>(
              valueListenable: profileIdentity,
              builder: (context, identity, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Animasyonlu arka plan (300px, tam renkli)
                    const SizedBox(
                      height: 300,
                      child: _ProfileHeaderAnimatedBackground(),
                    ),
                    // Ayarlar butonu (çark ikonu)
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 16),
                      child: Row(
                        children: [
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.profileSettings),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBF4FC),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE2D4E6),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.settings_outlined,
                                size: 20,
                                color: Color(0xFF1E1E24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Kimlik kartı: animasyonun koyu kısmında başlar
                    Positioned(
                      top: 140,
                      left: 0,
                      right: 0,
                      child: _IdentityHeader(identity: identity),
                    ),
                  ],
                );
              },
            ),
          ),

          // ─── 3. Sesli Oda ve Bağlantılar ───────────────────────────────
          // Not: Kart Stack içinde 140px'ten başlayıp ~270px uzar.
          // SliverPadding top: etiketler kaldırıldı, kart daha kısa.
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 110),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _SectionTitle('Sesli oda'),
                const Gap(10),
                ValueListenableBuilder<VoiceRoomsSnapshot>(
                  valueListenable: voiceRooms,
                  builder: (context, snapshot, _) {
                    final currentIdentity = profileIdentity.value;
                    final joinedRoom = snapshot.joinedRoom;
                    final myRoom = snapshot.myRoom;

                    if (joinedRoom != null) {
                      return _CurrentRoom(
                        title: joinedRoom.title,
                        subtitle:
                            '${joinedRoom.participantsCount} kişi · sen de içindesin',
                        onTap: () =>
                            context.push('/rooms/${joinedRoom.id}'),
                      );
                    }

                    if (myRoom != null) {
                      final isLive = myRoom.participantsCount > 0;
                      return _CurrentRoom(
                        title: myRoom.title,
                        subtitle: isLive
                            ? '${myRoom.participantsCount} kişi odada · Odaya Gir'
                            : 'Kayıtlı odan · Başlatmak için dokun',
                        onTap: () {
                          joinVoiceRoom(myRoom.id);
                          context.push('/rooms/${myRoom.id}');
                        },
                      );
                    }

                    final defaultTitle =
                        '${currentIdentity.name} Sohbet Odası';
                    return _EmptyCurrentRoom(
                      title: defaultTitle,
                      subtitle: 'Sesli oda başlat ve katıl',
                      onBrowse: () {
                        final newId = createVoiceRoom(
                          title: defaultTitle,
                          category: 'Sohbet',
                        );
                        context.push('/rooms/$newId');
                      },
                    );
                  },
                ),
                const Gap(28),
                const _SectionTitle('Bağlantıların'),
                const Gap(10),
                const _ConnectionSummary(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({required this.identity});
  final ProfileIdentity identity;

  static const double _avatarSize = 76.0;
  static const double _avatarOverlap = 38.0; // yarısı kartın üstüne taşar

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ─── Arka kart ─────────────────────────────────────────────────
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: _avatarOverlap),
          decoration: BoxDecoration(
            color: colors.isDark ? colors.surface : const Color(0xFFFAF5FE),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: colors.isDark
                    ? colors.glassBorder
                    : const Color(0xFFEDE4F2),
                width: 1.0,
              ),
              left: BorderSide(
                color: colors.isDark
                    ? colors.glassBorder
                    : const Color(0xFFEDE4F2),
                width: 1.0,
              ),
              right: BorderSide(
                color: colors.isDark
                    ? colors.glassBorder
                    : const Color(0xFFEDE4F2),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            // üstten: avatarın kart içinde kalan yarısı + boşluk
            padding: const EdgeInsets.fromLTRB(18, _avatarOverlap + 12, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İsim + kalem ikonu (yan yana)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        identity.name,
                        style: TextStyle(
                          fontSize: 22,
                          letterSpacing: -0.7,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const Gap(6),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.editProfile),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(1),
                // ID badge — sola kaydırılmış
                Transform.translate(
                  offset: const Offset(-4, -4),
                  child: GestureDetector(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: identity.id));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Olly ID kopyalandı'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ID ${identity.id}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: colors.textSecondary,
                          ),
                        ),
                        const Gap(4),
                        Icon(
                          Icons.copy_rounded,
                          size: 13,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
                const Gap(14),
                Text(
                  identity.about,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ─── Avatar: kartın üstüne taşar ───────────────────────────────
        Positioned(
          top: 0,
          left: 18,
          child: GestureDetector(
            onTap: () => showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: 'Kapat',
              barrierColor: Colors.black.withValues(alpha: 0.75),
              transitionDuration: const Duration(milliseconds: 220),
              pageBuilder: (ctx, anim, _) => const SizedBox.shrink(),
              transitionBuilder: (ctx, anim, _, __) {
                final curved =
                    CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
                return GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: ScaleTransition(
                    scale: curved,
                    child: FadeTransition(
                      opacity: anim,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: OllyAvatar(size: 220, name: identity.name),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.isDark
                      ? colors.surface
                      : const Color(0xFFFAF5FE),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: OllyAvatar(size: _avatarSize, name: identity.name),
            ),
          ),
        ),
      ],
    );
  }
}

class _InterestTag extends StatelessWidget {
  const _InterestTag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -.3,
        color: colors.textPrimary,
      ),
    );
  }
}

class _CurrentRoom extends StatelessWidget {
  const _CurrentRoom({
    required this.onTap,
    required this.title,
    required this.subtitle,
  });
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.isDark ? colors.surface : const Color(0xFFFBF4FC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.isDark ? colors.glassBorder : const Color(0xFFE2D4E6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: colors.isDark
                  ? const Color(0xFF262626)
                  : const Color(0xFFF0E2F5),
              child: Icon(
                Icons.graphic_eq_rounded,
                color: colors.isDark ? Colors.white : const Color(0xFF1E1E24),
              ),
            ),
            const Gap(13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.isDark
                          ? Colors.white
                          : const Color(0xFF1E1E24),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Gap(3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.isDark
                          ? const Color(0xFFA8A8A8)
                          : const Color(0xFF6B6572),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: colors.isDark ? Colors.white : const Color(0xFF1E1E24),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCurrentRoom extends StatelessWidget {
  const _EmptyCurrentRoom({
    required this.onBrowse,
    this.title = 'Sesli Odalar',
    this.subtitle = 'Canlı odalara göz at',
  });
  final VoidCallback onBrowse;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onBrowse,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.isDark ? colors.surface : const Color(0xFFFBF4FC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.isDark ? colors.glassBorder : const Color(0xFFE2D4E6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: colors.isDark
                  ? const Color(0xFF262626)
                  : const Color(0xFFF0E2F5),
              child: Icon(
                Icons.graphic_eq_outlined,
                color: colors.isDark ? Colors.white : const Color(0xFF1E1E24),
              ),
            ),
            const Gap(13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.isDark
                          ? Colors.white
                          : const Color(0xFF1E1E24),
                    ),
                  ),
                  const Gap(3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.isDark
                          ? const Color(0xFFA8A8A8)
                          : const Color(0xFF6B6572),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: colors.isDark ? Colors.white : const Color(0xFF1E1E24),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionSummary extends ConsumerWidget {
  const _ConnectionSummary();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final socialState = ref.watch(socialRelationshipsProvider);
    final friendsCount = socialState.friends.length.toString();
    final followingCount = socialState.followingIds.length.toString();
    final followersCount = socialState.followersIds.length.toString();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.glassBorder),
      ),
      child: Row(
        children: [
          _ConnectionLink(
              label: 'Arkadaşlar', count: friendsCount, tab: 'friends'),
          const SizedBox(height: 36, child: VerticalDivider(width: 1)),
          _ConnectionLink(
              label: 'Takip edilen', count: followingCount, tab: 'following'),
          const SizedBox(height: 36, child: VerticalDivider(width: 1)),
          _ConnectionLink(
              label: 'Takipçiler', count: followersCount, tab: 'followers'),
        ],
      ),
    );
  }
}

class _ConnectionLink extends StatelessWidget {
  const _ConnectionLink(
      {required this.label, required this.count, required this.tab});
  final String label;
  final String count;
  final String tab;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Expanded(
      child: InkWell(
        onTap: () => context.push('${AppRoutes.profile}/connections/$tab'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Column(
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileActionPanel extends StatelessWidget {
  const _ProfileActionPanel({required this.onEdit, required this.onSettings});
  final VoidCallback onEdit;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.isDark ? colors.surface : const Color(0xFFFAF5FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.isDark ? colors.glassBorder : const Color(0xFFEDE4F2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: onEdit,
            leading: Icon(
              Icons.edit_outlined,
              color: colors.isDark ? Colors.white : const Color(0xFF1E1E24),
              size: 20,
            ),
            title: Text(
              'Profili düzenle',
              style: TextStyle(
                color: colors.isDark ? Colors.white : const Color(0xFF1E1E24),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: colors.isDark ? Colors.white70 : const Color(0xFF8E8895),
            ),
          ),
          Divider(
            color: colors.isDark ? colors.glassBorder : const Color(0xFFEDE4F2),
            height: 1,
          ),
          ListTile(
            onTap: onSettings,
            leading: Icon(
              Icons.settings_outlined,
              color: colors.isDark ? Colors.white : const Color(0xFF1E1E24),
              size: 20,
            ),
            title: Text(
              'Ayarlar',
              style: TextStyle(
                color: colors.isDark ? Colors.white : const Color(0xFF1E1E24),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: colors.isDark ? Colors.white70 : const Color(0xFF8E8895),
            ),
          ),
        ],
      ),
    );
  }
}


class _ProfileHeaderAnimatedBackground extends StatefulWidget {
  const _ProfileHeaderAnimatedBackground();

  @override
  State<_ProfileHeaderAnimatedBackground> createState() =>
      _ProfileHeaderAnimatedBackgroundState();
}

class _ProfileHeaderAnimatedBackgroundState
    extends State<_ProfileHeaderAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        final t2 = (t + 0.4) % 1.0;
        final t3 = (t + 0.7) % 1.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Arka animasyonlu gradyan
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(_lerp(-0.6, 0.6, t), -1.0),
                  end: Alignment(_lerp(0.4, -0.4, t2), 1.0),
                  colors: [
                    Color.lerp(
                      const Color(0xFFD8B4FE),
                      const Color(0xFFC4B5FD),
                      t,
                    )!,
                    Color.lerp(
                      const Color(0xFFF0ABFC),
                      const Color(0xFFE9D5FF),
                      t2,
                    )!,
                    Color.lerp(
                      const Color(0xFFE0C3FC),
                      const Color(0xFFB8C6FB),
                      t3,
                    )!,
                  ],
                ),
              ),
            ),

            // Bulut blob 1 (sol ust)
            Positioned(
              top: _lerp(-50, 10, t),
              left: _lerp(-70, -20, t2),
              child: _AtmosphereBlob(
                size: 230,
                color: Color.lerp(
                  const Color(0x60FFFFFF),
                  const Color(0x40E9D5FF),
                  t,
                )!,
              ),
            ),

            // Bulut blob 2 (sag ust)
            Positioned(
              top: _lerp(30, -10, t2),
              right: _lerp(-50, 10, t),
              child: _AtmosphereBlob(
                size: 190,
                color: Color.lerp(
                  const Color(0x50F0ABFC),
                  const Color(0x60FFFFFF),
                  t2,
                )!,
              ),
            ),

            // Bulut blob 3 (orta)
            Positioned(
              top: _lerp(60, 30, t3),
              left: _lerp(60, 130, t),
              child: _AtmosphereBlob(
                size: 160,
                color: Color.lerp(
                  const Color(0x35FFFFFF),
                  const Color(0x45DDD6FE),
                  t3,
                )!,
              ),
            ),

            // Bulut blob 4 (alt, ekstra derinlik)
            Positioned(
              top: _lerp(100, 70, t2),
              right: _lerp(40, 100, t3),
              child: _AtmosphereBlob(
                size: 120,
                color: Color.lerp(
                  const Color(0x30E9D5FF),
                  const Color(0x45FFFFFF),
                  t,
                )!,
              ),
            ),

            // Sayfa rengiyle alt geçiş (kısa fade)
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 70,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        colors.background.withValues(alpha: 0.55),
                        colors.background,
                      ],
                      stops: const [0.0, 0.65, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AtmosphereBlob extends StatelessWidget {
  const _AtmosphereBlob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
