import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../core/sync/cross_tab_sync.dart';
import '../../profile/presentation/profile_identity_store.dart';

/// Gerçek kullanıcı modeli.
class OllyUser {
  const OllyUser({
    required this.id,
    required this.username,
    required this.name,
    required this.statusNote,
    this.bio,
    this.location = 'Türkiye',
    this.isOnline = false,
    this.inVoiceRoom = false,
    this.roomName,
    this.roomId,
    this.isVerified = false,
    this.interests = const ['Sohbet', 'Müzik'],
    this.mutualFriends = 0,
  });

  final String id;
  final String username;
  final String name;
  final String statusNote;
  final String? bio;
  final String location;
  final bool isOnline;
  final bool inVoiceRoom;
  final String? roomName;
  final String? roomId;
  final bool isVerified;
  final List<String> interests;
  final int mutualFriends;

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'name': name,
        'statusNote': statusNote,
        'bio': bio,
        'location': location,
        'isOnline': isOnline,
        'inVoiceRoom': inVoiceRoom,
        'roomName': roomName,
        'roomId': roomId,
        'isVerified': isVerified,
        'interests': interests,
        'mutualFriends': mutualFriends,
      };

  factory OllyUser.fromJson(Map<String, dynamic> json) => OllyUser(
        id: (json['id'] ?? json['olly_id'])?.toString() ?? 'OL-0000',
        username: json['username']?.toString() ?? '@kullanici',
        name: json['name']?.toString() ?? 'Olly Kullanıcısı',
        statusNote: (json['status_note'] ?? json['statusNote'])?.toString() ??
            'Çevrimiçi',
        bio: json['bio']?.toString(),
        location: json['location']?.toString() ?? 'Türkiye',
        isOnline: (json['is_online'] ?? json['isOnline']) as bool? ?? true,
        inVoiceRoom: (json['inVoiceRoom'] ?? json['in_voice_room']) as bool? ??
            false,
        roomName: (json['roomName'] ?? json['room_name'])?.toString(),
        roomId: (json['roomId'] ?? json['room_id'])?.toString(),
        isVerified: (json['is_verified'] ?? json['isVerified']) as bool? ??
            false,
        interests: (json['interests'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const ['Sohbet', 'Müzik'],
        mutualFriends: (json['mutualFriends'] ?? json['mutual_friends']) is num
            ? ((json['mutualFriends'] ?? json['mutual_friends']) as num).toInt()
            : 0,
      );

  OllyUser copyWith({
    String? id,
    String? username,
    String? name,
    String? statusNote,
    String? bio,
    String? location,
    bool? isOnline,
    bool? inVoiceRoom,
    String? roomName,
    String? roomId,
    bool? isVerified,
    List<String>? interests,
    int? mutualFriends,
  }) {
    return OllyUser(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      statusNote: statusNote ?? this.statusNote,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      isOnline: isOnline ?? this.isOnline,
      inVoiceRoom: inVoiceRoom ?? this.inVoiceRoom,
      roomName: roomName ?? this.roomName,
      roomId: roomId ?? this.roomId,
      isVerified: isVerified ?? this.isVerified,
      interests: interests ?? this.interests,
      mutualFriends: mutualFriends ?? this.mutualFriends,
    );
  }
}

/// Bu liste yalnızca hızlı yerel önbellektir. Kalıcı kaynak Supabase'dir.
final List<OllyUser> allUsersRegistry = [];

String _normalise(String value) => value.trim().toLowerCase();

/// Kullanıcı ID'si, kullanıcı adı veya isim ile eşleşen kullanıcıyı döner.
OllyUser findUserByIdOrAlias(String queryId) {
  final clean = _normalise(queryId);
  final withoutAt = clean.startsWith('@') ? clean.substring(1) : clean;

  for (final user in allUsersRegistry) {
    final username = _normalise(user.username);
    if (_normalise(user.id) == clean ||
        username == clean ||
        username == '@$withoutAt' ||
        _normalise(user.name) == clean) {
      return user;
    }
  }

  // Arama Supabase'e ulaşamasa bile mesaj/istek ekranı çökmesin. Bu geçici
  // kayıt, gerçek profil geldiğinde remote hydration sırasında güncellenir.
  final newUser = OllyUser(
    id: queryId.trim().isEmpty ? 'OL-0000' : queryId.trim().toUpperCase(),
    username: '@${withoutAt.replaceAll(' ', '')}',
    name: queryId.trim().isEmpty ? 'Olly Kullanıcısı' : queryId.trim(),
    statusNote: 'Olly kullanıcısı',
    bio: 'Olly topluluğunda yeni bağlantılar kuruyor.',
    isOnline: true,
  );
  if (!allUsersRegistry.any((u) => _normalise(u.id) == _normalise(newUser.id))) {
    allUsersRegistry.add(newUser);
  }
  return newUser;
}

class SocialState {
  const SocialState({
    required this.friends,
    required this.followingIds,
    required this.followersIds,
    required this.sentRequestIds,
  });

  final List<OllyUser> friends;
  final Set<String> followingIds;
  final Set<String> followersIds;
  final Set<String> sentRequestIds;

  SocialState copyWith({
    List<OllyUser>? friends,
    Set<String>? followingIds,
    Set<String>? followersIds,
    Set<String>? sentRequestIds,
  }) {
    return SocialState(
      friends: friends ?? this.friends,
      followingIds: followingIds ?? this.followingIds,
      followersIds: followersIds ?? this.followersIds,
      sentRequestIds: sentRequestIds ?? this.sentRequestIds,
    );
  }
}

/// Sosyal ilişkilerin kalıcı kaynağını Supabase'e bağlayan notifier.
class SocialRelationshipsNotifier extends StateNotifier<SocialState> {
  SocialRelationshipsNotifier()
      : super(const SocialState(
          friends: [],
          followingIds: {},
          followersIds: {},
          sentRequestIds: {},
        )) {
    _initCrossTabSync();
    _subscribeRemoteChanges();
    _hydration = _loadRemoteRelationships();
  }

  late final Future<void> _hydration;
  RealtimeChannel? _remoteChannel;
  StreamSubscription<Map<String, dynamic>>? _crossTabSubscription;
  Timer? _remotePollTimer;
  bool _disposed = false;

  void _registerUser(OllyUser user) {
    final index = allUsersRegistry.indexWhere(
      (item) => _normalise(item.id) == _normalise(user.id),
    );
    if (index >= 0) {
      allUsersRegistry[index] = user;
    } else {
      allUsersRegistry.insert(0, user);
    }
  }

  OllyUser _localUserForId(String id) {
    for (final user in allUsersRegistry) {
      if (_normalise(user.id) == _normalise(id)) return user;
    }
    return findUserByIdOrAlias(id);
  }

  bool _isCurrentUser(String? value) {
    if (value == null) return false;
    final clean = _normalise(value);
    final self = profileIdentity.value;
    return clean == _normalise(self.id) ||
        clean == _normalise(self.username) ||
        clean == _normalise(self.username.replaceFirst('@', ''));
  }

  void _initCrossTabSync() {
    final self = profileIdentity.value;
    final selfUser = OllyUser(
      id: self.id,
      username: self.username,
      name: self.name,
      statusNote: 'Çevrimiçi',
      isOnline: true,
    );
    _registerUser(selfUser);

    CrossTabSyncService.instance.emit({
      'type': 'ANNOUNCE_USER',
      'user': selfUser.toJson(),
    });

    _crossTabSubscription = CrossTabSyncService.instance.stream.listen((event) {
      final type = event['type'] as String?;
      final userData = event['user'];

      if (type == 'ANNOUNCE_USER' || type == 'ANNOUNCE_USER_REPLY') {
        if (userData is Map) {
          final peerUser = OllyUser.fromJson(
            Map<String, dynamic>.from(userData),
          );
          if (!_isCurrentUser(peerUser.id)) {
            _registerUser(peerUser);
            if (type == 'ANNOUNCE_USER') {
              CrossTabSyncService.instance.emit({
                'type': 'ANNOUNCE_USER_REPLY',
                'user': selfUser.toJson(),
              });
            }
          }
        }
        return;
      }

      final targetId = event['targetId'] as String?;
      if (type == 'FRIEND_ADDED' && _isCurrentUser(targetId)) {
        if (userData is Map) {
          final sender = OllyUser.fromJson(Map<String, dynamic>.from(userData));
          _registerUser(sender);
          if (!state.friends.any((user) => user.id == sender.id)) {
            state = state.copyWith(
              friends: [...state.friends, sender],
              followersIds: {...state.followersIds, sender.id},
            );
          }
        }
      } else if (type == 'FRIEND_REMOVED' && _isCurrentUser(targetId)) {
        final fromId = event['fromId'] as String?;
        if (fromId != null) {
          state = state.copyWith(
            friends: state.friends
                .where((user) => _normalise(user.id) != _normalise(fromId))
                .toList(),
          );
        }
      } else if (type == 'FOLLOW_USER' && _isCurrentUser(targetId)) {
        final fromId = event['fromId'] as String?;
        if (fromId != null) {
          state = state.copyWith(
            followersIds: {...state.followersIds, fromId},
          );
        }
      } else if (type == 'UNFOLLOW_USER' && _isCurrentUser(targetId)) {
        final fromId = event['fromId'] as String?;
        if (fromId != null) {
          state = state.copyWith(
            followersIds: state.followersIds
                .where((id) => _normalise(id) != _normalise(fromId))
                .toSet(),
          );
        }
      }
    });
  }

  void _subscribeRemoteChanges() {
    if (!SupabaseService.instance.isInitialized) return;

    final selfId = profileIdentity.value.id;
    final channel = SupabaseService.instance.client
        .channel('social_relationships_$selfId');

    for (final event in [
      PostgresChangeEvent.insert,
      PostgresChangeEvent.update,
      PostgresChangeEvent.delete,
    ]) {
      channel.onPostgresChanges(
        event: event,
        schema: 'public',
        table: 'friendships',
        callback: (_) => unawaited(_loadRemoteRelationships()),
      );
      channel.onPostgresChanges(
        event: event,
        schema: 'public',
        table: 'follows',
        callback: (_) => unawaited(_loadRemoteRelationships()),
      );
    }

    _remoteChannel = channel..subscribe();
    _remotePollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(_loadRemoteRelationships()),
    );
  }

  Future<List<Map<String, dynamic>>?> _loadFriendshipRows(String selfId) async {
    try {
      final outgoing = await SupabaseService.instance.client
          .from('friendships')
          .select('user_id, friend_id, status')
          .eq('user_id', selfId);
      final incoming = await SupabaseService.instance.client
          .from('friendships')
          .select('user_id, friend_id, status')
          .eq('friend_id', selfId);
      return [
        ...(outgoing as List<dynamic>).map(
          (row) => Map<String, dynamic>.from(row as Map),
        ),
        ...(incoming as List<dynamic>).map(
          (row) => Map<String, dynamic>.from(row as Map),
        ),
      ];
    } catch (e) {
      debugPrint('[Social] friendship sync error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> _loadFollowRows(
    String selfId, {
    required bool following,
  }) async {
    try {
      final query = SupabaseService.instance.client
          .from('follows')
          .select('follower_id, following_id');
      final rows = following
          ? await query.eq('follower_id', selfId)
          : await query.eq('following_id', selfId);
      return (rows as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (e) {
      debugPrint('[Social] follow sync error: $e');
      return null;
    }
  }

  Future<Map<String, OllyUser>> _loadProfiles(Set<String> ids) async {
    if (ids.isEmpty || !SupabaseService.instance.isInitialized) return {};

    final result = <String, OllyUser>{};
    try {
      final rows = await SupabaseService.instance.client
          .from('profiles')
          .select(
              'id, olly_id, username, name, bio, status_note, location, is_online, is_verified, interests')
          .inFilter('id', ids.toList());
      for (final raw in rows as List<dynamic>) {
        final user = OllyUser.fromJson(Map<String, dynamic>.from(raw as Map));
        result[_normalise(user.id)] = user;
        _registerUser(user);
      }
    } catch (e) {
      debugPrint('[Social] profile hydration error: $e');
    }
    return result;
  }

  Future<void> _loadRemoteRelationships() async {
    if (_disposed || !SupabaseService.instance.isInitialized) return;

    final selfId = profileIdentity.value.id;
    final rows = await _loadFriendshipRows(selfId);
    if (rows == null || _disposed) return;

    final friendIds = <String>{};
    final sentRequestIds = <String>{};
    for (final row in rows) {
      final userId = row['user_id']?.toString() ?? '';
      final friendId = row['friend_id']?.toString() ?? '';
      final status = row['status']?.toString() ?? 'accepted';
      final peerId = _normalise(userId) == _normalise(selfId) ? friendId : userId;
      if (peerId.isEmpty || _normalise(peerId) == _normalise(selfId)) continue;

      if (status == 'pending' && _normalise(userId) == _normalise(selfId)) {
        sentRequestIds.add(peerId);
      } else if (status == 'accepted') {
        friendIds.add(peerId);
      }
    }

    final followingRows = await _loadFollowRows(selfId, following: true);
    final followerRows = await _loadFollowRows(selfId, following: false);
    final followingIds = followingRows == null
        ? state.followingIds
        : followingRows
            .map((row) => row['following_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
    final followersIds = followerRows == null
        ? state.followersIds
        : followerRows
            .map((row) => row['follower_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();

    final allIds = <String>{
      ...friendIds,
      ...sentRequestIds,
      ...followingIds,
      ...followersIds,
    }..remove(selfId);
    final profiles = await _loadProfiles(allIds);

    OllyUser resolve(String id) =>
        profiles[_normalise(id)] ?? _localUserForId(id);

    final friends = friendIds.map(resolve).toList();
    for (final user in friends) {
      _registerUser(user);
    }

    if (!_disposed) {
      state = state.copyWith(
        friends: friends,
        followingIds: followingIds,
        followersIds: followersIds,
        sentRequestIds: sentRequestIds,
      );
    }
  }

  /// ID, kullanıcı adı veya isim ile arama yapar — önce local registry.
  List<OllyUser> searchUsers(String query) {
    final clean = _normalise(query);
    if (clean.isEmpty) return [];

    final selfId = _normalise(profileIdentity.value.id);
    return allUsersRegistry.where((user) {
      if (_normalise(user.id) == selfId) return false;
      final matchId = _normalise(user.id).contains(clean);
      final matchUsername = _normalise(user.username).contains(clean) ||
          _normalise(user.username).replaceAll('@', '').contains(
                clean.replaceAll('@', ''),
              );
      final matchName = _normalise(user.name).contains(clean);
      return matchId || matchUsername || matchName;
    }).toList();
  }

  /// Supabase profiles tablosundan kullanıcı arar ve local registry'e ekler.
  Future<List<OllyUser>> searchUsersRemote(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    if (!SupabaseService.instance.isInitialized) return searchUsers(clean);

    try {
      final selfId = profileIdentity.value.id;
      final q = (clean.startsWith('@') ? clean.substring(1) : clean)
          .replaceAll(RegExp(r'[%(),]'), '');
      if (q.isEmpty) return [];

      final rows = await SupabaseService.instance.client
          .from('profiles')
          .select(
              'id, olly_id, username, name, bio, status_note, location, is_online, is_verified, interests')
          .or('username.ilike.%$q%,name.ilike.%$q%,olly_id.ilike.%$q%')
          .neq('id', selfId)
          .limit(20);

      final remoteUsers = (rows as List<dynamic>)
          .map((raw) => OllyUser.fromJson(Map<String, dynamic>.from(raw as Map)))
          .where((user) => user.id.isNotEmpty)
          .toList();
      for (final user in remoteUsers) {
        _registerUser(user);
      }

      return remoteUsers.isNotEmpty ? remoteUsers : searchUsers(clean);
    } catch (e) {
      debugPrint('[Social] remote search error: $e');
      return searchUsers(clean);
    }
  }

  /// Karşılıklı arkadaşlık kaydı oluşturur. Böylece iki cihazda da arkadaş
  /// listesi, uygulama yeniden açıldığında Supabase'den yeniden kurulabilir.
  Future<bool> sendFriendRequest(String queryOrId) async {
    await _hydration;
    final user = findUserByIdOrAlias(queryOrId);
    final self = profileIdentity.value;
    if (_normalise(user.id) == _normalise(self.id)) return false;

    if (SupabaseService.instance.isInitialized) {
      try {
        await SupabaseService.instance.client.from('friendships').upsert([
          {
            'user_id': self.id,
            'friend_id': user.id,
            'status': 'accepted',
          },
          {
            'user_id': user.id,
            'friend_id': self.id,
            'status': 'accepted',
          },
        ], onConflict: 'user_id,friend_id');

        await SupabaseService.instance.client.from('follows').upsert({
          'follower_id': self.id,
          'following_id': user.id,
        }, onConflict: 'follower_id,following_id');
      } catch (e) {
        debugPrint('[Social] friend request write error: $e');
        return false;
      }
    }

    _registerUser(user);
    final friends = List<OllyUser>.from(state.friends);
    if (!friends.any((item) => _normalise(item.id) == _normalise(user.id))) {
      friends.add(user);
    }
    state = state.copyWith(
      friends: friends,
      followingIds: {...state.followingIds, user.id},
      sentRequestIds: state.sentRequestIds
          .where((id) => _normalise(id) != _normalise(user.id))
          .toSet(),
    );

    final selfUser = OllyUser(
      id: self.id,
      username: self.username,
      name: self.name,
      statusNote: 'Çevrimiçi',
      isOnline: true,
    );
    CrossTabSyncService.instance.emit({
      'type': 'FRIEND_ADDED',
      'targetId': user.id,
      'targetUsername': user.username,
      'fromUser': selfUser.toJson(),
    });
    return true;
  }

  /// Arkadaşlığı iki yönde de kaldırır.
  Future<bool> removeFriend(String userId) async {
    await _hydration;
    final user = findUserByIdOrAlias(userId);
    final selfId = profileIdentity.value.id;

    if (SupabaseService.instance.isInitialized) {
      try {
        await SupabaseService.instance.client
            .from('friendships')
            .delete()
            .or('and(user_id.eq.$selfId,friend_id.eq.${user.id}),and(user_id.eq.${user.id},friend_id.eq.$selfId)');
      } catch (e) {
        debugPrint('[Social] friend removal error: $e');
        return false;
      }
    }

    state = state.copyWith(
      friends: state.friends
          .where((item) => _normalise(item.id) != _normalise(user.id))
          .toList(),
    );
    CrossTabSyncService.instance.emit({
      'type': 'FRIEND_REMOVED',
      'targetId': user.id,
      'fromId': selfId,
    });
    return true;
  }

  /// Takip etme durumunu açıp kapatır.
  Future<bool> toggleFollow(String queryOrId) async {
    await _hydration;
    final user = findUserByIdOrAlias(queryOrId);
    final selfId = profileIdentity.value.id;
    if (_normalise(user.id) == _normalise(selfId)) return false;

    final following = Set<String>.from(state.followingIds);
    final isNowFollowing = !following.contains(user.id);

    if (SupabaseService.instance.isInitialized) {
      try {
        if (isNowFollowing) {
          await SupabaseService.instance.client.from('follows').upsert({
            'follower_id': selfId,
            'following_id': user.id,
          }, onConflict: 'follower_id,following_id');
        } else {
          await SupabaseService.instance.client
              .from('follows')
              .delete()
              .match({'follower_id': selfId, 'following_id': user.id});
        }
      } catch (e) {
        debugPrint('[Social] follow write error: $e');
        return false;
      }
    }

    if (isNowFollowing) {
      following.add(user.id);
      CrossTabSyncService.instance.emit({
        'type': 'FOLLOW_USER',
        'targetId': user.id,
        'fromId': selfId,
      });
    } else {
      following.remove(user.id);
      CrossTabSyncService.instance.emit({
        'type': 'UNFOLLOW_USER',
        'targetId': user.id,
        'fromId': selfId,
      });
    }
    state = state.copyWith(followingIds: following);
    _registerUser(user);
    return true;
  }

  bool isFriend(String queryOrId) {
    final user = findUserByIdOrAlias(queryOrId);
    return state.friends.any((item) => _normalise(item.id) == _normalise(user.id));
  }

  bool isFollowing(String queryOrId) {
    final user = findUserByIdOrAlias(queryOrId);
    return state.followingIds
        .any((id) => _normalise(id) == _normalise(user.id));
  }

  bool hasSentRequest(String queryOrId) {
    final user = findUserByIdOrAlias(queryOrId);
    return state.sentRequestIds
        .any((id) => _normalise(id) == _normalise(user.id));
  }

  List<OllyUser> getFollowingUsers() {
    return allUsersRegistry
        .where((user) => isFollowing(user.id))
        .toList();
  }

  List<OllyUser> getFollowersUsers() {
    return allUsersRegistry
        .where((user) => state.followersIds
            .any((id) => _normalise(id) == _normalise(user.id)))
        .toList();
  }

  @override
  void dispose() {
    _disposed = true;
    _remotePollTimer?.cancel();
    _crossTabSubscription?.cancel();
    if (_remoteChannel != null && SupabaseService.instance.isInitialized) {
      SupabaseService.instance.client.removeChannel(_remoteChannel!);
    }
    super.dispose();
  }
}

final socialRelationshipsProvider =
    StateNotifierProvider<SocialRelationshipsNotifier, SocialState>((ref) {
  return SocialRelationshipsNotifier();
});
