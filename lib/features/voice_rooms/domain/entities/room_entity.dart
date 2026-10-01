import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_entity.freezed.dart';

enum RoomStatus { active, closed }

@freezed
class RoomEntity with _$RoomEntity {
  const factory RoomEntity({
    required String id,
    required String title,
    required String hostId,
    required String hostName,
    @Default([]) List<ParticipantEntity> participants,
    @Default(RoomStatus.active) RoomStatus status,
    String? description,
    String? topic,
    @Default(false) bool isPublic,
    int? maxParticipants,
    DateTime? createdAt,
  }) = _RoomEntity;
}

@freezed
class ParticipantEntity with _$ParticipantEntity {
  const factory ParticipantEntity({
    required String id,
    required String username,
    String? photoUrl,
    @Default(false) bool isMuted,
    @Default(false) bool isSpeaking,
    @Default(false) bool isHost,
  }) = _ParticipantEntity;
}
