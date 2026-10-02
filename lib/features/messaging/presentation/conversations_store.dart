import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../core/sync/cross_tab_sync.dart';
import '../../friends/presentation/social_relationships_store.dart';
import '../../profile/presentation/profile_identity_store.dart';

/// Konuşma modeli.
class ModernConversation {
  const ModernConversation({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.isOnline,
    this.isVoiceMessage = false,
    this.lastMessageId,
  });

  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isOnline;
  final bool isVoiceMessage;
  final String? lastMessageId;

  ModernConversation copyWith({
    String? id,
    String? name,
    String? lastMessage,
    String? time,
    int? unread,
    bool? isOnline,
    bool? isVoiceMessage,
    String? lastMessageId,
  }) {
    return ModernConversation(
      id: id ?? this.id,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      unread: unread ?? this.unread,
      isOnline: isOnline ?? this.isOnline,
      isVoiceMessage: isVoiceMessage ?? this.isVoiceMessage,
      lastMessageId: lastMessageId ?? this.lastMessageId,
    );
  }
}

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

/// Mesaj özetlerini yerel state + Supabase Realtime/polling ile güncel tutar.
class ConversationsNotifier extends StateNotifier<ConversationsState> {
  ConversationsNotifier()
      : super(const ConversationsState(
          conversations: [],
          pinned: [],
        )) {
    _initCrossTabSync();
    _initSupabaseSync();
    unawaited(_loadRemoteConversations());
  }

  RealtimeChannel? _supabaseChannel;
  StreamSubscription<Map<String, dynamic>>? _crossTabSubscription;
  Timer? _pollTimer;
  bool _remoteLoadInFlight = false;
  bool _disposed = false;

  String _formatTime(dynamic raw) {
    final created = DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now();
    return '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';
  }

  void _initCrossTabSync() {
    _crossTabSubscription = CrossTabSyncService.instance.stream.listen((event) {
      if (event['type'] != 'CHAT_MESSAGE') return;

      final self = profileIdentity.value;
      final toId = (event['toId'] as String?)?.toLowerCase();
      final fromId = event['fromId'] as String? ?? '';
      if (toId == null ||
          (toId != self.id.toLowerCase() &&
              toId != self.username.toLowerCase())) {
        return;
      }

      final fromName = event['fromName'] as String? ?? 'Kullanıcı $fromId';
      final text = event['text'] as String? ?? '';
      final time = event['time'] as String? ?? 'Şimdi';
      recordIncomingMessage(
        peerId: fromId,
        peerName: fromName,
        text: text,
        time: time,
        messageId: event['messageId'] as String?,
      );
    });
  }

  void _initSupabaseSync() {
    if (!SupabaseService.instance.isInitialized) return;

    final selfId = profileIdentity.value.id;
    _supabaseChannel = SupabaseService.instance.client
        .channel('messages_incoming_$selfId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: selfId,
          ),
          callback: (payload) => unawaited(_handleIncomingRow(payload.newRecord)),
        )
      ..subscribe();

    // Realtime is the fast path. Polling is a small safety net for projects
    // where the table was created before realtime publication was enabled.
    _pollTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => unawaited(_loadRemoteConversations()),
    );
  }

  Future<OllyUser> _resolveUser(String id) async {
    for (final user in allUsersRegistry) {
      if (user.id.toLowerCase() == id.toLowerCase()) return user;
    }

    if (SupabaseService.instance.isInitialized) {
      try {
        final rows = await SupabaseService.instance.client
            .from('profiles')
            .select(
                'id, olly_id, username, name, bio, status_note, location, is_online, is_verified, interests')
            .eq('id', id)
            .limit(1);
        if ((rows as List<dynamic>).isNotEmpty) {
          final user = OllyUser.fromJson(
            Map<String, dynamic>.from(rows.first as Map),
          );
          final oldIndex = allUsersRegistry.indexWhere(
            (item) => item.id.toLowerCase() == user.id.toLowerCase(),
          );
          if (oldIndex >= 0) {
            allUsersRegistry[oldIndex] = user;
          } else {
            allUsersRegistry.insert(0, user);
          }
          return user;
        }
      } catch (_) {
        // The fallback below still lets the message render.
      }
    }
    return findUserByIdOrAlias(id);
  }

  Future<Map<String, OllyUser>> _resolveUsers(Set<String> ids) async {
    final resolved = <String, OllyUser>{};
    final unresolved = <String>{};
    for (final id in ids) {
      final local = allUsersRegistry.where(
        (user) => user.id.toLowerCase() == id.toLowerCase(),
      );
      if (local.isNotEmpty) {
        resolved[id.toLowerCase()] = local.first;
      } else {
        unresolved.add(id);
      }
    }

    if (unresolved.isNotEmpty && SupabaseService.instance.isInitialized) {
      try {
        final rows = await SupabaseService.instance.client
            .from('profiles')
            .select(
                'id, olly_id, username, name, bio, status_note, location, is_online, is_verified, interests')
            .inFilter('id', unresolved.toList());
        for (final raw in rows as List<dynamic>) {
          final user = OllyUser.fromJson(Map<String, dynamic>.from(raw as Map));
          resolved[user.id.toLowerCase()] = user;
          final oldIndex = allUsersRegistry.indexWhere(
            (item) => item.id.toLowerCase() == user.id.toLowerCase(),
          );
          if (oldIndex >= 0) {
            allUsersRegistry[oldIndex] = user;
          } else {
            allUsersRegistry.insert(0, user);
          }
        }
      } catch (_) {
        // Resolve missing IDs one by one through the local fallback below.
      }
    }

    for (final id in ids) {
      resolved.putIfAbsent(id.toLowerCase(), () => findUserByIdOrAlias(id));
    }
    return resolved;
  }

  Future<void> _loadRemoteConversations() async {
    if (_disposed ||
        !SupabaseService.instance.isInitialized ||
        _remoteLoadInFlight) {
      return;
    }
    _remoteLoadInFlight = true;
    try {
      final selfId = profileIdentity.value.id;
      final rawRows = await SupabaseService.instance.client
          .from('messages')
          .select('id, sender_id, receiver_id, content, is_read, created_at')
          .or('sender_id.eq.$selfId,receiver_id.eq.$selfId')
          .order('created_at', ascending: false);
      final rows = (rawRows as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      if (rows.isEmpty || _disposed) return;

      final latestByPeer = <String, Map<String, dynamic>>{};
      final unreadByPeer = <String, int>{};
      final peerIds = <String>{};
      for (final row in rows) {
        final senderId = row['sender_id']?.toString() ?? '';
        final receiverId = row['receiver_id']?.toString() ?? '';
        final peerId = senderId.toLowerCase() == selfId.toLowerCase()
            ? receiverId
            : senderId;
        if (peerId.isEmpty) continue;
        peerIds.add(peerId);
        latestByPeer.putIfAbsent(peerId.toLowerCase(), () => row);
        if (receiverId.toLowerCase() == selfId.toLowerCase() &&
            row['is_read'] != true) {
          unreadByPeer[peerId.toLowerCase()] =
              (unreadByPeer[peerId.toLowerCase()] ?? 0) + 1;
        }
      }

      final users = await _resolveUsers(peerIds);
      final loaded = <ModernConversation>[];
      for (final peerId in peerIds) {
        final row = latestByPeer[peerId.toLowerCase()];
        if (row == null) continue;
        final user = users[peerId.toLowerCase()] ?? findUserByIdOrAlias(peerId);
        loaded.add(ModernConversation(
          id: peerId,
          name: user.name.isNotEmpty ? user.name : peerId,
          lastMessage: row['content']?.toString() ?? '',
          time: _formatTime(row['created_at']),
          unread: unreadByPeer[peerId.toLowerCase()] ?? 0,
          isOnline: user.isOnline,
          lastMessageId: row['id']?.toString(),
        ));
      }

      // Keep an optimistic conversation until its insert becomes queryable.
      final loadedIds = loaded.map((item) => item.id.toLowerCase()).toSet();
      final optimistic = state.conversations.where(
        (item) => !loadedIds.contains(item.id.toLowerCase()),
      );
      if (!_disposed) {
        state = state.copyWith(conversations: [...loaded, ...optimistic]);
      }
    } catch (e) {
      // The UI remains usable in local/cross-tab mode.
      // Do not surface a transient polling error to the user.
    } finally {
      _remoteLoadInFlight = false;
    }
  }

  Future<void> _handleIncomingRow(Map<String, dynamic> row) async {
    if (_disposed) return;
    final selfId = profileIdentity.value.id;
    final senderId = row['sender_id']?.toString() ?? '';
    if (senderId.isEmpty || senderId.toLowerCase() == selfId.toLowerCase()) {
      return;
    }
    final user = await _resolveUser(senderId);
    if (_disposed) return;
    recordIncomingMessage(
      peerId: senderId,
      peerName: user.name.isNotEmpty ? user.name : senderId,
      text: row['content']?.toString() ?? '',
      time: _formatTime(row['created_at']),
      messageId: row['id']?.toString(),
    );
  }

  void recordIncomingMessage({
    required String peerId,
    required String peerName,
    required String text,
    required String time,
    String? messageId,
  }) {
    final list = List<ModernConversation>.from(state.conversations);
    final idx = list.indexWhere((conversation) =>
        conversation.id.toLowerCase() == peerId.toLowerCase() ||
        conversation.name.toLowerCase() == peerName.toLowerCase());

    if (idx >= 0) {
      final old = list[idx];
      if (messageId != null && old.lastMessageId == messageId) return;
      list.removeAt(idx);
      list.insert(
        0,
        old.copyWith(
          lastMessage: text,
          time: time,
          unread: old.unread + 1,
          isOnline: true,
          lastMessageId: messageId,
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
          lastMessageId: messageId,
        ),
      );
    }
    state = state.copyWith(conversations: list);
  }

  void recordOutgoingMessage({
    required String peerId,
    required String peerName,
    required String text,
    required String time,
    String? messageId,
  }) {
    final list = List<ModernConversation>.from(state.conversations);
    final idx = list.indexWhere((conversation) =>
        conversation.id.toLowerCase() == peerId.toLowerCase() ||
        conversation.name.toLowerCase() == peerName.toLowerCase());

    if (idx >= 0) {
      final old = list.removeAt(idx);
      list.insert(
        0,
        old.copyWith(
          lastMessage: text,
          time: time,
          unread: 0,
          lastMessageId: messageId,
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
          lastMessageId: messageId,
        ),
      );
    }
    state = state.copyWith(conversations: list);
  }

  void markAsRead(String peerId) {
    final list = List<ModernConversation>.from(state.conversations);
    final idx = list.indexWhere((conversation) =>
        conversation.id.toLowerCase() == peerId.toLowerCase() ||
        conversation.name.toLowerCase() == peerId.toLowerCase());
    if (idx >= 0) {
      list[idx] = list[idx].copyWith(unread: 0);
      state = state.copyWith(conversations: list);
    }

    if (SupabaseService.instance.isInitialized) {
      unawaited(_markRemoteMessagesRead(peerId));
    }
  }

  Future<void> _markRemoteMessagesRead(String peerId) async {
    try {
      await SupabaseService.instance.client
          .from('messages')
          .update({'is_read': true})
          .eq('receiver_id', profileIdentity.value.id)
          .eq('sender_id', peerId)
          .eq('is_read', false);
    } catch (_) {}
  }

  void togglePin(ModernConversation conv) {
    final list = List<PinnedUser>.from(state.pinned);
    final idx = list.indexWhere((pinned) => pinned.id == conv.id);
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

  void deleteConversation(String convId) {
    final convs = state.conversations.where((c) => c.id != convId).toList();
    final pins = state.pinned.where((p) => p.id != convId).toList();
    state = state.copyWith(conversations: convs, pinned: pins);
  }

  void clearAll() {
    state = const ConversationsState(conversations: [], pinned: []);
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    _crossTabSubscription?.cancel();
    if (_supabaseChannel != null && SupabaseService.instance.isInitialized) {
      SupabaseService.instance.client.removeChannel(_supabaseChannel!);
    }
    super.dispose();
  }
}

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, ConversationsState>((ref) {
  return ConversationsNotifier();
});
