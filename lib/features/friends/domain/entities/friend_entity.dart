import 'package:freezed_annotation/freezed_annotation.dart';

part 'friend_entity.freezed.dart';

enum FriendStatus { pending, accepted, blocked }

@freezed
class FriendEntity with _$FriendEntity {
  const factory FriendEntity({
    required String id,
    required String userId,
    required String friendId,
    required String friendUsername,
    String? friendPhotoUrl,
    @Default(FriendStatus.pending) FriendStatus status,
    @Default(false) bool isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) = _FriendEntity;
}
