import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/olly_avatar.dart';
import '../../../friends/presentation/social_relationships_store.dart';

class PublicProfilePage extends ConsumerWidget {
  const PublicProfilePage({required this.profileId, super.key});
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final user = findUserByIdOrAlias(profileId);
    final socialState = ref.watch(socialRelationshipsProvider);
    final socialNotifier = ref.read(socialRelationshipsProvider.notifier);

    final isFriend = socialState.friends.any((f) => f.id == user.id);
    final isFollowing = socialState.followingIds.contains(user.id);
    final hasSentRequest = socialState.sentRequestIds.contains(user.id);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ─── Header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: colors.primary,
                padding: const EdgeInsets.fromLTRB(12, 16, 20, 14),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 19, color: Colors.white),
                    ),
                    const Gap(6),
                    const Expanded(
                      child: Text(
                        'Profil',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Icon(Icons.more_horiz_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),

            // ─── Kimlik Alanı ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20)),
                  border: Border(
                      bottom: BorderSide(color: colors.glassBorder)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 74, color: colors.primary),
                    Transform.translate(
                      offset: const Offset(20, -38),
                      child: OllyAvatar(
                        size: 76,
                        name: user.name,
                        isOnline: user.isOnline,
                        borderWidth: 3,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            user.name,
                                            style: TextStyle(
                                              fontSize: 22,
                                              letterSpacing: -0.7,
                                              fontWeight: FontWeight.w800,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (user.isVerified) ...[
                                          const Gap(4),
                                          Icon(Icons.verified_rounded,
                                              size: 16,
                                              color: colors.primaryLight),
                                        ],
                                      ],
                                    ),
                                    const Gap(3),
                                    Text(
                                      '${user.username} · ${user.location}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Gap(14),

                          // ─── Olly ID Rozeti & Kopyalama ────────────────
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: user.id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${user.name} ID\'si (${user.id}) panoya kopyalandı'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: colors.surfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: colors.glassBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.badge_outlined,
                                      size: 14, color: colors.primary),
                                  const Gap(6),
                                  Text(
                                    'Olly ID: ${user.id}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const Gap(6),
                                  Icon(Icons.copy_rounded,
                                      size: 12, color: colors.textTertiary),
                                ],
                              ),
                            ),
                          ),
                          const Gap(14),

                          // ─── Aksiyon Butonları (Takip Et / Arkadaş Ekle / Mesaj) ───
                          Row(
                            children: [
                              // Takip Et / Takipten Çık Butonu
                              Expanded(
                                child: FilledButton.icon(
                                  style: isFollowing
                                      ? FilledButton.styleFrom(
                                          backgroundColor:
                                              colors.surfaceElevated,
                                          foregroundColor: colors.primary,
                                        )
                                      : FilledButton.styleFrom(
                                          backgroundColor: colors.primary,
                                          foregroundColor: Colors.white,
                                        ),
                                  onPressed: () {
                                    socialNotifier.toggleFollow(user.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isFollowing
                                            ? '${user.name} takipten çıkarıldı'
                                            : '${user.name} takip edildi'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    isFollowing
                                        ? Icons.check_rounded
                                        : Icons.person_add_alt_1_outlined,
                                    size: 16,
                                  ),
                                  label: Text(
                                      isFollowing ? 'Takip ediliyor' : 'Takip Et'),
                                ),
                              ),
                              const Gap(8),

                              // Arkadaş Ekle / Arkadaşsınız Butonu
                              if (!isFriend)
                                OutlinedButton.icon(
                                  onPressed: () {
                                    socialNotifier.sendFriendRequest(user.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${user.name} arkadaş olarak eklendi!'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    hasSentRequest
                                        ? Icons.hourglass_top_rounded
                                        : Icons.person_add_rounded,
                                    size: 16,
                                  ),
                                  label: Text(hasSentRequest
                                      ? 'İstek Gönderildi'
                                      : 'Arkadaş Ekle'),
                                ),

                              const Gap(8),
                              // Mesaj Gönder
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: colors.surfaceElevated,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: colors.glassBorder),
                                  ),
                                ),
                                onPressed: () =>
                                    context.push('/messages/${user.id}'),
                                icon: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 18,
                                  color: colors.textPrimary,
                                ),
                                tooltip: 'Mesaj Gönder',
                              ),
                            ],
                          ),
                          const Gap(16),

                          // ─── Bio & Durum ─────────────────────────────
                          Text(
                            user.bio ?? user.statusNote,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Ortak Noktalar & İlgi Alanları ─────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Ortak noktalar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Gap(10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people_outline_rounded,
                            color: colors.primary),
                        const Gap(12),
                        Expanded(
                          child: Text(
                            '${user.mutualFriends} ortak arkadaşınız var',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: colors.textTertiary),
                      ],
                    ),
                  ),
                  const Gap(24),
                  Text(
                    'İlgi alanları',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Gap(10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: user.interests
                        .map((item) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: colors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
