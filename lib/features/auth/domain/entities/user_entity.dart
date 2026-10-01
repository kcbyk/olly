import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';

@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String username,
    required String email,
    String? displayName,
    String? photoUrl,
    String? bio,
    @Default(false) bool isOnline,
    @Default([]) List<String> friendIds,
    DateTime? createdAt,
  }) = _UserEntity;
}
