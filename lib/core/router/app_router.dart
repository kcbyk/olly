import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/friends/presentation/pages/friends_page.dart';
import '../../features/friends/presentation/pages/add_friend_page.dart';
import '../../features/messaging/presentation/pages/conversations_page.dart';
import '../../features/messaging/presentation/pages/chat_page.dart';
import '../../features/messaging/presentation/pages/blocked_users_page.dart';
import '../../features/voice_rooms/presentation/pages/rooms_list_page.dart';
import '../../features/voice_rooms/presentation/pages/room_page.dart';
import '../../features/voice_rooms/presentation/pages/operations_center_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/connections_page.dart';
import '../../features/profile/presentation/pages/profile_settings_page.dart';
import '../../features/profile/presentation/pages/public_profile_page.dart';
import '../widgets/shell/main_shell.dart';

/// Route isimleri — magic string'lerden kaçınmak için.
abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const friends = '/friends';
  static const addFriend = '/friends/add';
  static const messages = '/messages';
  static const blockedUsers = '/messages/blocked';
  static const rooms = '/rooms';
  static const operationsCenter = '/rooms/operations';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const profileSettings = '/profile/settings';
}

/// Riverpod provider — GoRouter instance'ını sağlar.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.friends,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // TODO: Auth guard — Firebase auth state'e göre redirect
      // final isLoggedIn = ref.read(authStateProvider).value != null;
      // if (!isLoggedIn && state.matchedLocation != AppRoutes.login) return AppRoutes.login;
      return null;
    },
    routes: [
      // ─── Auth Routes ────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (_, __) => const RegisterPage(),
      ),

      // ─── Main Shell (Floating Pill Bar) ─────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          // Tab 0: Friends / Discover
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.friends,
                name: 'friends',
                builder: (_, __) => const FriendsPage(),
                routes: [
                  GoRoute(
                    path: 'add',
                    name: 'addFriend',
                    builder: (_, __) => const AddFriendPage(),
                  ),
                ],
              ),
            ],
          ),

          // Tab 1: Messages
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.messages,
                name: 'messages',
                builder: (_, __) => const ConversationsPage(),
                routes: [
                  GoRoute(
                    path: 'blocked',
                    name: 'blockedUsers',
                    builder: (_, __) => const BlockedUsersPage(),
                  ),
                  GoRoute(
                    path: ':conversationId',
                    name: 'chat',
                    builder: (context, state) => ChatPage(
                      conversationId:
                          state.pathParameters['conversationId'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Tab 2: Voice Rooms
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.rooms,
                name: 'rooms',
                builder: (_, __) => const RoomsListPage(),
                routes: [
                  GoRoute(
                    path: 'operations',
                    name: 'operationsCenter',
                    builder: (_, __) => const OperationsCenterPage(),
                  ),
                  GoRoute(
                    path: ':roomId',
                    name: 'room',
                    builder: (context, state) => RoomPage(
                      roomId: state.pathParameters['roomId'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Tab 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (_, __) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'editProfile',
                    builder: (_, __) => const EditProfilePage(),
                  ),
                  GoRoute(
                    path: 'settings',
                    name: 'profileSettings',
                    builder: (_, __) => const ProfileSettingsPage(),
                  ),
                  GoRoute(
                    path: 'connections/:tab',
                    name: 'connections',
                    builder: (context, state) => ConnectionsPage(
                        initialTab: state.pathParameters['tab'] ?? 'friends'),
                  ),
                  GoRoute(
                    path: ':profileId',
                    name: 'publicProfile',
                    builder: (context, state) => PublicProfilePage(
                        profileId: state.pathParameters['profileId'] ?? ''),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
