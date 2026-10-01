import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/cross_tab_sync.dart';
import '../../friends/presentation/social_relationships_store.dart';
import '../../profile/presentation/profile_identity_store.dart';

/// Konuşma modeli
class ModernConversation {
  const ModernConversation({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.isOnline,
    this.isVoiceMessage = false,
  });

  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isOnline;
  final bool isVoiceMessage;

  ModernConversation copyWith({
    String? id,
    String? name,
    String? lastMessage,
    String? time,
    int? unread,
    bool? isOnline,
    bool? isVoiceMessage,
  }) {
    return ModernConversation(
      id: id ?? this.id,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      unread: unread ?? this.unread,
      isOnline: isOnline ?? this.isOnline,
      isVoiceMessage: isVoiceMessage ?? this.isVoiceMessage,
    );
  }
}

/// Sabitlenmiş kullanıcı modeli
class PinnedUser {
  const PinnedUser({
    required this.id,
    required this.name,
    this.isOnline = true,
    this.hasUnread = false,
  });

  final String id;
  final String name;
  final bool isOnline;
  final bool hasUnread;
}

/// Konuşmalar State Modeli
class ConversationsState {
  const ConversationsState({
    required this.conversations,
    required this.pinned,
  });

  final List<ModernConversation> conversations;
  final List<PinnedUser> pinned;

  ConversationsState copyWith({
    List<ModernConversation>? conversations,
    List<PinnedUser>? pinned,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      pinned: pinned ?? this.pinned,
    );
  }
}

/// Konuşmalar Riverpod StateNotifier
class ConversationsNotifier extends StateNotifier<ConversationsState> {
  ConversationsNotifier()
      : super(const ConversationsState(
          conversations: [
            ModernConversation(
              id: 'user_ayse',
              name: 'Ayşe Kaya',
              lastMessage: 'Bugün odaya katılıyor musun? 🎙️',
              time: '14:32',
              unread: 3,
              isOnline: true,
            ),
            ModernConversation(
              id: 'user_mert',
              name: 'Mert Demir',
              lastMessage: 'Harika bir konuşmaydı, teşekkürler!',
              time: '12:05',
              unread: 0,
              isOnline: false,
            ),
            ModernConversation(
              id: 'user_zeynep',
              name: 'Zeynep Arslan',
              lastMessage: 'Sesli mesaj bıraktım 🎤',
              time: 'Dün',
              unread: 1,
              isOnline: true,
              isVoiceMessage: true,
            ),
            ModernConversation(
              id: 'user_can',
              name: 'Can Yıldız',
              lastMessage: 'Tamam görüşürüz 👋',
              time: 'Dün',
              unread: 0,
              isOnline: false,
            ),
            ModernConversation(
              id: 'user_elif',
              name: 'Elif Şahin',
              lastMessage: 'Olly çok güzel bir uygulama olmuş!',
              time: 'Pzt',
              unread: 0,
              isOnline: true,
            ),
          ],
          pinned: [
            PinnedUser(id: 'user_ayse', name: 'Ayşe Kaya', isOnline: true, hasUnread: true),
            PinnedUser(id: 'user_mert', name: 'Mert Demir', isOnline: false),
            PinnedUser(id: 'user_zeynep', name: 'Zeynep Arslan', isOnline: true, hasUnread: true),
          ],
        )) {
    _initCrossTabSync();
  }

  void _initCrossTabSync() {
    CrossTabSyncService.instance.stream.listen((event) {
      final type = event['type'] as String?;
      if (type == 'CHAT_MESSAGE') {
        final self = profileIdentity.value;
        final toId = (event['toId'] as String?)?.toLowerCase();
        final fromId = event['fromId'] as String? ?? '';
        final fromName = event['fromName'] as String? ?? 'Kullanıcı $fromId';
        final text = event['text'] as String? ?? '';
        final time = event['time'] as String? ?? 'Şimdi';

        // Gelen mesaj bana mı ait?
        if (toId != null &&
            (toId == self.id.toLowerCase() ||
                toId == self.username.toLowerCase())) {
          final user = findUserByIdOrAlias(fromId);
          recordIncomingMessage(
            peerId: user.id,
            peerName: user.name.isNotEmpty && user.name != user.id
                ? user.name
                : fromName,
            text: text,
            time: time,
          );
        }
      }
    });
  }

  /// Gelen mesajı listenin en başına ekler/günceller ve okunmamış sayısını artırır
  void recordIncomingMessage({
    required String peerId,
    required String peerName,
    required String text,
    required String time,
  }) {
    final list = List<ModernConversation>.from(state.conversations);
    final idx = list.indexWhere((c) =>
        c.id.toLowerCase() == peerId.toLowerCase() ||
        c.name.toLowerCase() == peerName.toLowerCase());

    if (idx >= 0) {
      final old = list.removeAt(idx);
      list.insert(
        0,
        old.copyWith(
          lastMessage: text,
          time: time,
          unread: old.unread + 1,
          isOnline: true,
        ),
      );
    } else {
      list.insert(
        0,
        ModernConversation(
          id: peerId,
          name: peerName,
          lastMessage: text,
          time: time,
          unread: 1,
          isOnline: true,
        ),
      );
    }
    state = state.copyWith(conversations: list);
  }

  /// Gönderilen mesajı listenin en başına günceller
  void recordOutgoingMessage({
    required String peerId,
    required String peerName,
    required String text,
    required String time,
  }) {
    final list = List<ModernConversation>.from(state.conversations);
    final idx = list.indexWhere((c) =>
        c.id.toLowerCase() == peerId.toLowerCase() ||
        c.name.toLowerCase() == peerName.toLowerCase());

    if (idx >= 0) {
      final old = list.removeAt(idx);
      list.insert(
        0,
        old.copyWith(
          lastMessage: text,
          time: time,
          unread: 0,
        ),
      );
    } else {
      list.insert(
        0,
        ModernConversation(
          id: peerId,
          name: peerName,
          lastMessage: text,
          time: time,
          unread: 0,
          isOnline: true,
        ),
      );
    }
    state = state.copyWith(conversations: list);
  }

  /// Mesajları okundu olarak işaretle
  void markAsRead(String peerId) {
    final list = List<ModernConversation>.from(state.conversations);
    final idx = list.indexWhere((c) =>
        c.id.toLowerCase() == peerId.toLowerCase() ||
        c.name.toLowerCase() == peerId.toLowerCase());
    if (idx >= 0) {
      list[idx] = list[idx].copyWith(unread: 0);
      state = state.copyWith(conversations: list);
    }
  }

  /// Sabitleme durumunu değiştir
  void togglePin(ModernConversation conv) {
    final list = List<PinnedUser>.from(state.pinned);
    final idx = list.indexWhere((p) => p.id == conv.id);
    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.insert(
        0,
        PinnedUser(
          id: conv.id,
          name: conv.name,
          isOnline: conv.isOnline,
          hasUnread: conv.unread > 0,
        ),
      );
    }
    state = state.copyWith(pinned: list);
  }

  /// Konuşmayı sil
  void deleteConversation(String convId) {
    final convs = state.conversations.where((c) => c.id != convId).toList();
    final pins = state.pinned.where((p) => p.id != convId).toList();
    state = state.copyWith(conversations: convs, pinned: pins);
  }

  /// Tüm mesajları temizle
  void clearAll() {
    state = const ConversationsState(conversations: [], pinned: []);
  }
}

/// Global Conversations Riverpod Provider
final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, ConversationsState>((ref) {
  return ConversationsNotifier();
});
