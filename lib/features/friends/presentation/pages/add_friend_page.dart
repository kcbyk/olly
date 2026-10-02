import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/olly_avatar.dart';
import '../../../profile/presentation/profile_identity_store.dart';
import '../social_relationships_store.dart';

class AddFriendPage extends ConsumerStatefulWidget {
  const AddFriendPage({super.key});

  @override
  ConsumerState<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends ConsumerState<AddFriendPage> {
  final _ctrl = TextEditingController();
  String _searchQuery = '';
  List<OllyUser> _remoteResults = [];
  bool _isSearching = false;
  int _searchGeneration = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String val) async {
    final q = val.trim();
    final generation = ++_searchGeneration;
    setState(() {
      _searchQuery = q;
      _isSearching = q.isNotEmpty;
    });
    if (q.isEmpty) {
      setState(() => _remoteResults = []);
      return;
    }
    final notifier = ref.read(socialRelationshipsProvider.notifier);
    final results = await notifier.searchUsersRemote(q);
    if (mounted && generation == _searchGeneration) {
      setState(() {
        _remoteResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final socialState = ref.watch(socialRelationshipsProvider);
    final socialNotifier = ref.read(socialRelationshipsProvider.notifier);

    final hasQuery = _searchQuery.isNotEmpty;
    final selfId = profileIdentity.value.id.toLowerCase();

    final displayList = hasQuery
        ? _remoteResults
        : allUsersRegistry.where((u) => u.id.toLowerCase() != selfId).toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: colors.textPrimary),
          tooltip: 'Geri',
        ),
        title: Text(
          'Arkadaş Ekle',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // ─── Kendi ID Kartı ──────────────────────────────────────────
          ValueListenableBuilder<ProfileIdentity>(
            valueListenable: profileIdentity,
            builder: (context, identity, _) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.badge_outlined,
                            color: colors.primary, size: 20),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Senin Olly ID\'n',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colors.textTertiary,
                              ),
                            ),
                            Text(
                              identity.id,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: identity.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Olly ID\'n panoya kopyalandı!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.glassBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded,
                                  size: 13, color: colors.primary),
                              const Gap(4),
                              Text(
                                'Kopyala',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ─── Arama Çubuğu ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.glassBorder),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  if (_isSearching)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    )
                  else
                    Icon(Icons.search_rounded,
                        color: colors.textTertiary, size: 21),
                  const Gap(10),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      onChanged: _onSearch,
                      style: TextStyle(
                          color: colors.textPrimary, fontSize: 14.5),
                      decoration: InputDecoration(
                        hintText: 'İsim, @kullanıcı veya Olly ID...',
                        hintStyle: TextStyle(
                            color: colors.textTertiary, fontSize: 13),
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
                        _ctrl.clear();
                        setState(() {
                          _searchQuery = '';
                          _remoteResults = [];
                        });
                      },
                      child: Icon(Icons.close_rounded,
                          size: 18, color: colors.textTertiary),
                    ),
                ],
              ),
            ),
          ),

          // ─── Kullanıcı Sonuçları Listesi ────────────────────────────
          Expanded(
            child: displayList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasQuery
                                ? Icons.search_off_rounded
                                : Icons.person_search_rounded,
                            size: 54,
                            color: colors.textTertiary,
                          ),
                          const Gap(14),
                          Text(
                            hasQuery
                                ? 'Kullanıcı bulunamadı'
                                : 'Arkadaşlarını Keşfet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const Gap(6),
                          Text(
                            hasQuery
                                ? 'ID veya kullanıcı adını kontrol edip tekrar deneyin.'
                                : 'Yukarıdaki arama çubuğuna arkadaşının adını, kullanıcı adını veya Olly ID\'sini yazarak anında ekleyebilirsin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    itemCount: displayList.length,
                    separatorBuilder: (_, __) => const Gap(10),
                    itemBuilder: (context, index) {
                      final user = displayList[index];
                      final isFriend =
                          socialState.friends.any((f) => f.id == user.id);
                      final isFollowing =
                          socialState.followingIds.contains(user.id);
                      final hasSent =
                          socialState.sentRequestIds.contains(user.id);

                      return GestureDetector(
                        onTap: () => context.push('/profile/${user.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.glassBorder),
                          ),
                          child: Row(
                            children: [
                              OllyAvatar(
                                size: 48,
                                name: user.name,
                                isOnline: user.isOnline,
                              ),
                              const Gap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            user.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (user.isVerified) ...[
                                          const Gap(4),
                                          Icon(Icons.verified_rounded,
                                              size: 14,
                                              color: colors.primaryLight),
                                        ],
                                      ],
                                    ),
                                    const Gap(2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: colors.surfaceElevated,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            user.id,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: colors.primary,
                                            ),
                                          ),
                                        ),
                                        const Gap(6),
                                        Text(
                                          user.username,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Gap(10),
                              if (isFollowing || isFriend)
                                GestureDetector(
                                  onTap: () async {
                                    final ok = await socialNotifier.toggleFollow(user.id);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(ok
                                            ? '${user.name} takipten çıkarıldı'
                                            : 'Takip işlemi tamamlanamadı'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceElevated,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                          color: colors.glassBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_rounded,
                                            size: 14,
                                            color: colors.primaryLight),
                                        const Gap(4),
                                        Text(
                                          'Takip ediliyor',
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else if (hasSent)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: colors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: colors.glassBorder),
                                  ),
                                  child: Text(
                                    'İstek Gönderildi',
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: () async {
                                    final ok = await socialNotifier
                                        .sendFriendRequest(user.id);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(ok
                                            ? '${user.name} arkadaşlara eklendi!'
                                            : 'Arkadaş ekleme başarısız oldu'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 7.5),
                                    decoration: BoxDecoration(
                                      gradient: colors.primaryGradient,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors.primary
                                              .withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.person_add_rounded,
                                            size: 14, color: Colors.white),
                                        Gap(4),
                                        Text(
                                          'Ekle',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                          .animate(
                              delay: Duration(milliseconds: index * 40))
                          .fadeIn()
                          .slideY(begin: 0.08);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
