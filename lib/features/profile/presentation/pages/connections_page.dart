import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/olly_avatar.dart';
import '../../../friends/presentation/social_relationships_store.dart';

class ConnectionsPage extends ConsumerStatefulWidget {
  const ConnectionsPage({required this.initialTab, super.key});
  final String initialTab;

  @override
  ConsumerState<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends ConsumerState<ConnectionsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: switch (widget.initialTab) {
        'following' => 1,
        'followers' => 2,
        _ => 0,
      },
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final socialState = ref.watch(socialRelationshipsProvider);
    final socialNotifier = ref.read(socialRelationshipsProvider.notifier);

    final friends = socialState.friends;
    final following = socialNotifier.getFollowingUsers();
    final followers = socialNotifier.getFollowersUsers();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 19, color: colors.textPrimary),
          tooltip: 'Geri',
        ),
        title: Text(
          'Bağlantıların',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textTertiary,
          indicatorColor: colors.primary,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: 'Arkadaşlar (${friends.length})'),
            Tab(text: 'Takip (${following.length})'),
            Tab(text: 'Takipçiler (${followers.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _UsersList(
            users: friends,
            emptyMessage: 'Henüz arkadaşın yok.',
            subtitleType: _SubtitleType.friends,
          ),
          _UsersList(
            users: following,
            emptyMessage: 'Henüz kimseyi takip etmiyorsun.',
            subtitleType: _SubtitleType.following,
          ),
          _UsersList(
            users: followers,
            emptyMessage: 'Henüz takipçin yok.',
            subtitleType: _SubtitleType.followers,
          ),
        ],
      ),
    );
  }
}

enum _SubtitleType { friends, following, followers }

class _UsersList extends StatelessWidget {
  const _UsersList({
    required this.users,
    required this.emptyMessage,
    required this.subtitleType,
  });

  final List<OllyUser> users;
  final String emptyMessage;
  final _SubtitleType subtitleType;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 48, color: colors.textTertiary),
            const Gap(12),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: users.length,
      separatorBuilder: (_, __) => Divider(
        indent: 64,
        height: 1,
        color: colors.glassBorder,
      ),
      itemBuilder: (context, index) {
        final person = users[index];
        final String subtitleText = switch (subtitleType) {
          _SubtitleType.friends => person.statusNote,
          _SubtitleType.following => 'Takip ediliyor · ${person.username}',
          _SubtitleType.followers => person.username,
        };

        return ListTile(
          onTap: () => context.push('${AppRoutes.profile}/${person.id}'),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          leading: OllyAvatar(
            size: 46,
            name: person.name,
            isOnline: person.isOnline,
          ),
          title: Text(
            person.name,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitleText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: colors.textTertiary,
          ),
        );
      },
    );
  }
}
