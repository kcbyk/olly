import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/olly_avatar.dart';
import '../blocked_users_store.dart';

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
            tooltip: 'Geri',
          ),
          title: const Text('Engellenen kişiler'),
          bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
        ),
        body: ValueListenableBuilder<List<BlockedUser>>(
          valueListenable: blockedUsers,
          builder: (context, users, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
            children: [
              const Text('Engeli kaldırdığında yeniden mesajlaşabilirsiniz.',
                  style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.textSecondary)),
              const Gap(20),
              if (users.isEmpty)
                const _EmptyBlockedUsers()
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Column(
                    children: List.generate(users.length, (index) {
                      final user = users[index];
                      return Column(children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          leading: OllyAvatar(size: 42, name: user.name),
                          title: Text(user.name,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                          subtitle: const Text('Engellendi'),
                          trailing: TextButton(
                            onPressed: () {
                              unblockUser(user);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('${user.name} engeli kaldırıldı'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: const Text('Engeli kaldır'),
                          ),
                        ),
                        if (index != users.length - 1)
                          const Divider(height: 1, indent: 74),
                      ]);
                    }),
                  ),
                ),
            ],
          ),
        ),
      );
}

class _EmptyBlockedUsers extends StatelessWidget {
  const _EmptyBlockedUsers();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 42),
        child: Column(children: [
          Icon(Icons.person_off_outlined,
              size: 38, color: AppColors.textTertiary),
          Gap(12),
          Text('Engellenen kişi yok',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
      );
}
