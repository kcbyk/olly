import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_entity.freezed.dart';

enum MessageType { text, image, audio, system }
enum MessageStatus { sending, sent, delivered, read }

@freezed
class MessageEntity with _$MessageEntity {
  const factory MessageEntity({
    required String id,
    required String conversationId,
    required String senderId,
    required String content,
    @Default(MessageType.text) MessageType type,
    @Default(MessageStatus.sending) MessageStatus status,
    DateTime? createdAt,
    DateTime? editedAt,
  }) = _MessageEntity;
}

@freezed
class ConversationEntity with _$ConversationEntity {
  const factory ConversationEntity({
    required String id,
    required List<String> participantIds,
    required List<String> participantNames,
    List<String>? participantPhotos,
    String? lastMessage,
    int? unreadCount,
    DateTime? lastMessageAt,
  }) = _ConversationEntity;
}
