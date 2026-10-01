import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/sync/cross_tab_sync.dart';
import '../../profile/presentation/profile_identity_store.dart';

/// Gerçek kullanıcı modeli
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
        id: json['id'] as String? ?? 'OL-0000',
        username: json['username'] as String? ?? '@kullanici',
        name: json['name'] as String? ?? 'Olly Kullanıcısı',
        statusNote: json['statusNote'] as String? ?? 'Çevrimiçi',
        bio: json['bio'] as String?,
        location: json['location'] as String? ?? 'Türkiye',
        isOnline: json['isOnline'] as bool? ?? true,
        inVoiceRoom: json['inVoiceRoom'] as bool? ?? false,
        roomName: json['roomName'] as String?,
        roomId: json['roomId'] as String?,
        isVerified: json['isVerified'] as bool? ?? false,
        interests: (json['interests'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const ['Sohbet', 'Müzik'],
        mutualFriends: json['mutualFriends'] as int? ?? 0,
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

/// Tüm kayıtlı kullanıcılar rehberi
final List<OllyUser> allUsersRegistry = [];

/// Kullanıcı ID'si veya alternatif ID'leri eşleyen yardımcı fonksiyon
OllyUser findUserByIdOrAlias(String queryId) {
  final clean = queryId.trim().toLowerCase();
  for (final u in allUsersRegistry) {
    if (u.id.toLowerCase() == clean ||
        u.username.toLowerCase() == clean ||
        u.username.toLowerCase() == '@$clean' ||
        u.name.toLowerCase() == clean) {
      return u;
    }
  }

  // Bulunamadıysa dinamik kullanıcı profili oluştur ve rehbere kaydet
  final newUser = OllyUser(
    id: queryId.toUpperCase(),
    username: queryId.startsWith('@') ? queryId.toLowerCase() : '@${queryId.toLowerCase().replaceAll(' ', '')}',
    name: queryId,
    statusNote: 'Olly kullanıcısı',
    bio: 'Olly topluluğunda yeni bağlantılar kuruyor.',
    isOnline: true,
  );
  if (!allUsersRegistry.any((u) => u.id == newUser.id)) {
    allUsersRegistry.add(newUser);
  }
  return newUser;
}

/// Sosyal İlişkiler State Modeli
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

/// Sosyal İlişkiler Yönetim Notifier'ı (Riverpod)
class SocialRelationshipsNotifier extends StateNotifier<SocialState> {
  SocialRelationshipsNotifier()
      : super(const SocialState(
          friends: [],
          followingIds: {},
          followersIds: {},
          sentRequestIds: {},
        )) {
    _initCrossTabSync();
  }

  void _initCrossTabSync() {
    final self = profileIdentity.value;

    // Kendini yerel rehbere ekle ve diğer sekmelere anons et
    final selfUser = OllyUser(
      id: self.id,
      username: self.username,
      name: self.name,
      statusNote: 'Çevrimiçi',
      isOnline: true,
    );

    if (!allUsersRegistry.any((u) => u.id == self.id)) {
      allUsersRegistry.insert(0, selfUser);
    }

    CrossTabSyncService.instance.emit({
      'type': 'ANNOUNCE_USER',
      'user': selfUser.toJson(),
    });

    // Diğer sekmelerden gelen canlı olayları dinle
    CrossTabSyncService.instance.stream.listen((event) {
      final type = event['type'] as String?;
      if (type == 'ANNOUNCE_USER') {
        final userData = event['user'];
        if (userData is Map<String, dynamic>) {
          final peerUser = OllyUser.fromJson(userData);
          if (peerUser.id != self.id) {
            final exists = allUsersRegistry.any((u) => u.id == peerUser.id);
            if (!exists) {
              allUsersRegistry.insert(0, peerUser);
            }
            // Karşılık olarak kendi kimliğini bildir
            CrossTabSyncService.instance.emit({
              'type': 'ANNOUNCE_USER_REPLY',
              'user': selfUser.toJson(),
            });
          }
        }
      } else if (type == 'ANNOUNCE_USER_REPLY') {
        final userData = event['user'];
        if (userData is Map<String, dynamic>) {
          final peerUser = OllyUser.fromJson(userData);
          if (peerUser.id != self.id &&
              !allUsersRegistry.any((u) => u.id == peerUser.id)) {
            allUsersRegistry.insert(0, peerUser);
          }
        }
      } else if (type == 'FRIEND_ADDED') {
        final targetId = event['targetId'] as String?;
        final fromData = event['fromUser'];
        if (targetId != null &&
            (targetId.toLowerCase() == self.id.toLowerCase() ||
                targetId.toLowerCase() == self.username.toLowerCase())) {
          if (fromData is Map<String, dynamic>) {
            final senderUser = OllyUser.fromJson(fromData);
            if (!allUsersRegistry.any((u) => u.id == senderUser.id)) {
              allUsersRegistry.insert(0, senderUser);
            }
            final newFriends = List<OllyUser>.from(state.friends);
            if (!newFriends.any((u) => u.id == senderUser.id)) {
              newFriends.add(senderUser);
            }
            state = state.copyWith(
              friends: newFriends,
              followersIds: {...state.followersIds, senderUser.id},
            );
          }
        }
      } else if (type == 'FOLLOW_USER') {
        final targetId = event['targetId'] as String?;
        final fromId = event['fromId'] as String?;
        if (targetId != null &&
            targetId.toLowerCase() == self.id.toLowerCase() &&
            fromId != null) {
          state = state.copyWith(
            followersIds: {...state.followersIds, fromId},
          );
        }
      }
    });
  }

  /// ID, kullanıcı adı veya isim ile arama yapar
  List<OllyUser> searchUsers(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    final selfId = profileIdentity.value.id.toLowerCase();

    return allUsersRegistry.where((user) {
      if (user.id.toLowerCase() == selfId) return false;
      final matchId = user.id.toLowerCase().contains(clean);
      final matchUsername = user.username.toLowerCase().contains(clean) ||
          user.username.toLowerCase().replaceAll('@', '').contains(clean);
      final matchName = user.name.toLowerCase().contains(clean);
      return matchId || matchUsername || matchName;
    }).toList();
  }

  /// ID ile arkadaşlık isteği gönderir ve sekmeler arası canlı senkronize eder
  bool sendFriendRequest(String queryOrId) {
    final user = findUserByIdOrAlias(queryOrId);
    if (!allUsersRegistry.any((u) => u.id == user.id)) {
      allUsersRegistry.insert(0, user);
    }
    final self = profileIdentity.value;
    final selfUser = OllyUser(
      id: self.id,
      username: self.username,
      name: self.name,
      statusNote: 'Çevrimiçi',
      isOnline: true,
    );

    // İstek gönderildi olarak işaretle
    final newSent = Set<String>.from(state.sentRequestIds)..add(user.id);
    // Arkadaşlar listesine ekle ve takip et
    final newFriends = List<OllyUser>.from(state.friends);
    if (!newFriends.any((u) => u.id == user.id)) {
      newFriends.add(user);
    }
    final newFollowing = Set<String>.from(state.followingIds)..add(user.id);

    state = state.copyWith(
      friends: newFriends,
      followingIds: newFollowing,
      sentRequestIds: newSent,
    );

    // Diğer sekmelere canlı anons et
    CrossTabSyncService.instance.emit({
      'type': 'FRIEND_ADDED',
      'targetId': user.id,
      'targetUsername': user.username,
      'fromUser': selfUser.toJson(),
    });

    if (SupabaseService.instance.isInitialized) {
      try {
        SupabaseService.instance.client.from('friendships').upsert({
          'user_id': self.id,
          'friend_id': user.id,
          'status': 'accepted',
        });
        SupabaseService.instance.client.from('follows').upsert({
          'follower_id': self.id,
          'following_id': user.id,
        });
      } catch (_) {}
    }

    return true;
  }

  /// Arkadaşı listeden çıkarır
  void removeFriend(String userId) {
    final user = findUserByIdOrAlias(userId);
    final newFriends = state.friends.where((u) => u.id != user.id).toList();
    state = state.copyWith(friends: newFriends);

    if (SupabaseService.instance.isInitialized) {
      final selfId = profileIdentity.value.id;
      try {
        SupabaseService.instance.client
            .from('friendships')
            .delete()
            .match({'user_id': selfId, 'friend_id': user.id});
      } catch (_) {}
    }
  }

  /// Takip etme durumunu açıp kapatır
  void toggleFollow(String queryOrId) {
    final user = findUserByIdOrAlias(queryOrId);
    if (!allUsersRegistry.any((u) => u.id == user.id)) {
      allUsersRegistry.insert(0, user);
    }
    final newFollowing = Set<String>.from(state.followingIds);
    final isNowFollowing = !newFollowing.contains(user.id);
    if (isNowFollowing) {
      newFollowing.add(user.id);
    } else {
      newFollowing.remove(user.id);
    }
    state = state.copyWith(followingIds: newFollowing);

    final selfId = profileIdentity.value.id;
    if (isNowFollowing) {
      CrossTabSyncService.instance.emit({
        'type': 'FOLLOW_USER',
        'targetId': user.id,
        'fromId': selfId,
      });
      if (SupabaseService.instance.isInitialized) {
        try {
          SupabaseService.instance.client.from('follows').upsert({
            'follower_id': selfId,
            'following_id': user.id,
          });
        } catch (_) {}
      }
    } else {
      if (SupabaseService.instance.isInitialized) {
        try {
          SupabaseService.instance.client
              .from('follows')
              .delete()
              .match({'follower_id': selfId, 'following_id': user.id});
        } catch (_) {}
      }
    }
  }

  /// Kullanıcı arkadaş mı?
  bool isFriend(String queryOrId) {
    final user = findUserByIdOrAlias(queryOrId);
    return state.friends.any((u) => u.id == user.id);
  }

  /// Kullanıcı takip ediliyor mu?
  bool isFollowing(String queryOrId) {
    final user = findUserByIdOrAlias(queryOrId);
    return state.followingIds.contains(user.id);
  }

  /// Arkadaşlık isteği gönderildi mi?
  bool hasSentRequest(String queryOrId) {
    final user = findUserByIdOrAlias(queryOrId);
    return state.sentRequestIds.contains(user.id);
  }

  /// Takip edilen kullanıcıların listesini döner
  List<OllyUser> getFollowingUsers() {
    return allUsersRegistry
        .where((u) => state.followingIds.contains(u.id))
        .toList();
  }

  /// Takipçilerin listesini döner
  List<OllyUser> getFollowersUsers() {
    return allUsersRegistry
        .where((u) => state.followersIds.contains(u.id))
        .toList();
  }
}

/// Global Riverpod Provider
final socialRelationshipsProvider =
    StateNotifierProvider<SocialRelationshipsNotifier, SocialState>((ref) {
  return SocialRelationshipsNotifier();
});
