import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../core/sync/cross_tab_sync.dart';
import '../../profile/presentation/profile_identity_store.dart';


/// Mevcut kullanıcının adını döner — profil kimliğinden alınır
String get kCurrentUserName => profileIdentity.value.name;

class VoiceSeatOccupant {
  const VoiceSeatOccupant({
    required this.name,
    this.isSpeaking = false,
    this.muted = false,
    this.isMe = false,
    this.isHost = false,
    this.handRaised = false,
  });

  final String name;
  final bool isSpeaking;
  final bool muted;
  final bool isMe;
  final bool isHost;
  final bool handRaised;

  VoiceSeatOccupant copyWith({
    String? name,
    bool? isSpeaking,
    bool? muted,
    bool? isMe,
    bool? isHost,
    bool? handRaised,
  }) =>
      VoiceSeatOccupant(
        name: name ?? this.name,
        isSpeaking: isSpeaking ?? this.isSpeaking,
        muted: muted ?? this.muted,
        isMe: isMe ?? this.isMe,
        isHost: isHost ?? this.isHost,
        handRaised: handRaised ?? this.handRaised,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'isSpeaking': isSpeaking,
        'muted': muted,
        'isMe': isMe,
        'isHost': isHost,
        'handRaised': handRaised,
      };

  factory VoiceSeatOccupant.fromJson(Map<String, dynamic> json) =>
      VoiceSeatOccupant(
        name: json['name'] as String? ?? 'Kullanıcı',
        isSpeaking: json['isSpeaking'] as bool? ?? false,
        muted: json['muted'] as bool? ?? false,
        isMe: json['isMe'] as bool? ?? false,
        isHost: json['isHost'] as bool? ?? false,
        handRaised: json['handRaised'] as bool? ?? false,
      );
}

class VoiceChatLine {
  const VoiceChatLine({
    required this.id,
    required this.name,
    required this.text,
    required this.time,
    this.isMine = false,
  });

  final String id;
  final String name;
  final String text;
  final String time;
  final bool isMine;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'text': text,
        'time': time,
        'isMine': isMine,
      };

  factory VoiceChatLine.fromJson(Map<String, dynamic> json) => VoiceChatLine(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        text: json['text'] as String? ?? '',
        time: json['time'] as String? ?? '',
        isMine: json['isMine'] as bool? ?? false,
      );
}

class VoiceRoom {
  const VoiceRoom({
    required this.id,
    required this.title,
    required this.hostName,
    this.hostId,
    required this.category,
    required this.displayId,
    required this.announcement,
    required this.seats,
    required this.messages,
    this.extraListeners = 0,
    this.lockedSeats = const [],
    this.mutedSeats = const [],
    this.lastNotice,
  });

  final String id;
  final String title;
  final String hostName;
  final String? hostId;
  final String category;
  final String displayId;
  final String announcement;
  final List<VoiceSeatOccupant?> seats;
  final List<VoiceChatLine> messages;
  final int extraListeners;
  final List<int> lockedSeats;
  final List<int> mutedSeats;
  final String? lastNotice;

  int get seatedCount => seats.whereType<VoiceSeatOccupant>().length;

  int get participantsCount => seatedCount + extraListeners;

  List<String> get speakerNames => seats
      .whereType<VoiceSeatOccupant>()
      .map((s) => s.name)
      .take(3)
      .toList();

  VoiceSeatOccupant? get me =>
      seats.whereType<VoiceSeatOccupant>().where((s) => s.isMe).firstOrNull;

  bool get iAmSeated => me != null;

  VoiceRoom copyWith({
    String? id,
    String? title,
    String? hostName,
    String? hostId,
    String? category,
    String? displayId,
    String? announcement,
    List<VoiceSeatOccupant?>? seats,
    List<VoiceChatLine>? messages,
    int? extraListeners,
    List<int>? lockedSeats,
    List<int>? mutedSeats,
    String? lastNotice,
    bool clearNotice = false,
  }) =>
      VoiceRoom(
        id: id ?? this.id,
        title: title ?? this.title,
        hostName: hostName ?? this.hostName,
        hostId: hostId ?? this.hostId,
        category: category ?? this.category,
        displayId: displayId ?? this.displayId,
        announcement: announcement ?? this.announcement,
        seats: seats ?? this.seats,
        messages: messages ?? this.messages,
        extraListeners: extraListeners ?? this.extraListeners,
        lockedSeats: lockedSeats ?? this.lockedSeats,
        mutedSeats: mutedSeats ?? this.mutedSeats,
        lastNotice: clearNotice ? null : (lastNotice ?? this.lastNotice),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'hostName': hostName,
        'hostId': hostId,
        'category': category,
        'displayId': displayId,
        'announcement': announcement,
        'seats': seats.map((s) => s?.toJson()).toList(),
        'messages': messages.map((m) => m.toJson()).toList(),
        'extraListeners': extraListeners,
        'lockedSeats': lockedSeats,
        'mutedSeats': mutedSeats,
        'lastNotice': lastNotice,
      };

  factory VoiceRoom.fromJson(Map<String, dynamic> json) => VoiceRoom(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        // Supabase snake_case + local camelCase her ikisini destekle
        hostName: (json['host_name'] ?? json['hostName']) as String? ?? '',
        hostId: (json['host_id'] ?? json['hostId']) as String?,
        category: json['category'] as String? ?? 'Sohbet',
        displayId: (json['display_id'] ?? json['displayId']) as String? ?? '',
        announcement: json['announcement'] as String? ?? '',
        seats: (json['seats'] as List<dynamic>? ?? [])
            .map((s) => s != null
                ? VoiceSeatOccupant.fromJson(s as Map<String, dynamic>)
                : null)
            .toList(),
        messages: (json['messages'] as List<dynamic>? ?? [])
            .map((m) => VoiceChatLine.fromJson(m as Map<String, dynamic>))
            .toList(),
        extraListeners: ((json['extra_listeners'] ?? json['extraListeners']) as num?)?.toInt() ?? 0,
        lockedSeats: (json['lockedSeats'] as List<dynamic>? ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
        mutedSeats: (json['mutedSeats'] as List<dynamic>? ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
        lastNotice: (json['last_notice'] ?? json['lastNotice']) as String?,
      );
}

class VoicePresence {
  const VoicePresence({
    required this.id,
    required this.name,
    required this.roomId,
    required this.roomTitle,
    required this.roomMembers,
  });

  final String id;
  final String name;
  final String roomId;
  final String roomTitle;
  final int roomMembers;
}

class VoiceRoomsSnapshot {
  const VoiceRoomsSnapshot({
    required this.rooms,
    this.joinedRoomId,
    this.selfMuted = false,
    this.selfHandRaised = false,
  });

  final List<VoiceRoom> rooms;
  final String? joinedRoomId;
  final bool selfMuted;
  final bool selfHandRaised;

  VoiceRoom? byId(String id) {
    for (final room in rooms) {
      if (room.id == id) return room;
    }
    return null;
  }

  VoiceRoom? get joinedRoom =>
      joinedRoomId == null ? null : byId(joinedRoomId!);

  VoiceRoom? get myRoom => rooms
      .where((room) =>
          room.hostId == profileIdentity.value.id ||
          (room.hostId == null && room.hostName == kCurrentUserName))
      .firstOrNull;

  bool get iAmListening =>
      joinedRoom != null && joinedRoom?.iAmSeated != true;

  List<VoiceRoom> inCategory(
    String category, {
    Set<String> friendNames = const {},
    Set<String> followedNames = const {},
  }) {
    if (category == 'Tümü') return rooms;
    if (category == 'Arkadaşlar') {
      return rooms.where((r) {
        final isHostFriend = friendNames.contains(r.hostName);
        final hasFriendInSeats = r.seats
            .whereType<VoiceSeatOccupant>()
            .any((s) => friendNames.contains(s.name));
        return isHostFriend || hasFriendInSeats;
      }).toList();
    }
    if (category == 'Takip Edilen') {
      return rooms.where((r) {
        final isHostFollowed = followedNames.contains(r.hostName);
        final hasFollowedInSeats = r.seats
            .whereType<VoiceSeatOccupant>()
            .any((s) => followedNames.contains(s.name));
        return isHostFollowed || hasFollowedInSeats;
      }).toList();
    }
    return rooms.where((r) => r.category == category).toList();
  }

  List<VoicePresence> get activePeople {
    final seen = <String>{};
    final people = <VoicePresence>[];
    for (final room in rooms) {
      for (final seat in room.seats.whereType<VoiceSeatOccupant>()) {
        if (seat.isMe) continue;
        final key = seat.name;
        if (!seen.add(key)) continue;
        people.add(VoicePresence(
          id: key.toLowerCase().replaceAll(' ', '-'),
          name: seat.name.split(' ').first,
          roomId: room.id,
          roomTitle: room.title,
          roomMembers: room.participantsCount,
        ));
      }
    }
    return people;
  }
}

List<VoiceSeatOccupant?> _seats(List<VoiceSeatOccupant> filled) {
  return List<VoiceSeatOccupant?>.generate(
    8,
    (i) => i < filled.length ? filled[i] : null,
  );
}

const String _kPrefSavedMyRoomId = 'olly_my_voice_room_id';
const String _kPrefSavedMyRoomTitle = 'olly_my_voice_room_title';
const String _kPrefSavedMyRoomCategory = 'olly_my_voice_room_category';
const String _kPrefSavedMyRoomDisplayId = 'olly_my_voice_room_display_id';
const String _kPrefSavedMyRoomAnnouncement = 'olly_my_voice_room_announcement';

Future<void> _saveLocalMyRoom(VoiceRoom room) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefSavedMyRoomId, room.id);
    await prefs.setString(_kPrefSavedMyRoomTitle, room.title);
    await prefs.setString(_kPrefSavedMyRoomCategory, room.category);
    await prefs.setString(_kPrefSavedMyRoomDisplayId, room.displayId);
    await prefs.setString(_kPrefSavedMyRoomAnnouncement, room.announcement);
  } catch (e) {
    debugPrint('Local voice room save error: $e');
  }
}

Future<void> _clearLocalMyRoom() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_kPrefSavedMyRoomId),
      prefs.remove(_kPrefSavedMyRoomTitle),
      prefs.remove(_kPrefSavedMyRoomCategory),
      prefs.remove(_kPrefSavedMyRoomDisplayId),
      prefs.remove(_kPrefSavedMyRoomAnnouncement),
    ]);
  } catch (e) {
    debugPrint('Local voice room clear error: $e');
  }
}

Future<void> _loadLocalRoomData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedTitle = prefs.getString(_kPrefSavedMyRoomTitle);
    if (savedTitle != null && savedTitle.trim().isNotEmpty) {
      final savedId = prefs.getString(_kPrefSavedMyRoomId) ?? 'r-senol-room';
      final savedCategory =
          prefs.getString(_kPrefSavedMyRoomCategory) ?? 'Sohbet';
      final savedDisplayId = prefs.getString(_kPrefSavedMyRoomDisplayId) ??
          (1000000 + DateTime.now().millisecondsSinceEpoch % 9000000).toString();
      final savedAnnouncement =
          prefs.getString(_kPrefSavedMyRoomAnnouncement) ??
              'Hoş geldin! Birlikte sohbet edelim.';

      final current = voiceRooms.value;
      final existingIndex = current.rooms.indexWhere((r) =>
          r.id == savedId ||
          r.hostId == profileIdentity.value.id ||
          (r.hostId == null && r.hostName == kCurrentUserName));
      if (existingIndex >= 0) {
        final existing = current.rooms[existingIndex];
        final updated = existing.copyWith(
          title: savedTitle,
          category: savedCategory,
          displayId: savedDisplayId,
          announcement: savedAnnouncement,
        );
        final newRooms = [...current.rooms];
        newRooms[existingIndex] = updated;
        _commit(
          VoiceRoomsSnapshot(
            rooms: newRooms,
            joinedRoomId: current.joinedRoomId,
            selfMuted: current.selfMuted,
            selfHandRaised: current.selfHandRaised,
          ),
          broadcast: false,
        );
      } else {
        final myRoom = VoiceRoom(
          id: savedId,
          title: savedTitle,
          hostName: kCurrentUserName,
          hostId: profileIdentity.value.id,
          category: savedCategory,
          displayId: savedDisplayId,
          announcement: savedAnnouncement,
          seats: _seats([]),
          messages: const [],
          extraListeners: 0,
        );
        _commit(
          VoiceRoomsSnapshot(
            rooms: [myRoom, ...current.rooms],
            joinedRoomId: current.joinedRoomId,
            selfMuted: current.selfMuted,
            selfHandRaised: current.selfHandRaised,
          ),
          broadcast: false,
        );
      }
    }
  } catch (e) {
    debugPrint('Local voice room load error: $e');
  }
}

final voiceRooms = ValueNotifier<VoiceRoomsSnapshot>(
  VoiceRoomsSnapshot(rooms: _seedRooms),
);

VoiceRoom? voiceRoomById(String id) => voiceRooms.value.byId(id);

bool isVoiceRoomHost(VoiceRoom room) {
  final hostId = room.hostId;
  return hostId == profileIdentity.value.id ||
      ((hostId == null || hostId.isEmpty) &&
          room.hostName == kCurrentUserName);
}

bool _isSyncingFromRemote = false;
bool _crossTabInitialized = false;
Timer? _voiceRoomsRefreshTimer;
Future<void> _voiceRoomWriteQueue = Future<void>.value();
final Set<String> _pendingRoomPersistenceIds = <String>{};
StreamSubscription<Map<String, dynamic>>? _voiceCrossTabSubscription;

void initVoiceRoomsSync() {
  if (_crossTabInitialized) return;
  _crossTabInitialized = true;

  // Yerel depodan kaydedilen oda başlığı ve ayarlarını yükle.
  unawaited(_loadLocalRoomData());

  if (SupabaseService.instance.isInitialized) {
    unawaited(_refreshRemoteRooms());

    // Realtime hızlı yoldur; aşağıdaki timer publication/realtime ayarı eksik
    // bir projede bile odaların diğer cihazlara ulaşmasını sağlar.
    SupabaseService.instance.client
        .from('voice_rooms')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .listen(_applyRemoteRows, onError: (Object error) {
      debugPrint('[VoiceRooms] realtime error: $error');
    });
    _voiceRoomsRefreshTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => unawaited(_refreshRemoteRooms()),
    );
  }

  _voiceCrossTabSubscription = CrossTabSyncService.instance.stream.listen((data) {
    if (data['type'] != 'voice_rooms_sync') return;
    final rawRooms = data['rooms'] as List<dynamic>? ?? [];
    final roomsList = rawRooms
        .whereType<Map>()
        .map((raw) => VoiceRoom.fromJson(Map<String, dynamic>.from(raw)))
        .toList();
    _isSyncingFromRemote = true;
    try {
      final current = voiceRooms.value;
      _commit(
        VoiceRoomsSnapshot(
          rooms: roomsList,
          joinedRoomId: current.joinedRoomId,
          selfMuted: current.selfMuted,
          selfHandRaised: current.selfHandRaised,
        ),
        broadcast: false,
      );
    } finally {
      _isSyncingFromRemote = false;
    }
  });
}

Future<void> _refreshRemoteRooms() async {
  if (!SupabaseService.instance.isInitialized) return;
  try {
    final rows = await SupabaseService.instance.client
        .from('voice_rooms')
        .select()
        .eq('is_active', true);
    final loaded = (rows as List<dynamic>)
        .map((raw) => VoiceRoom.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList();
    _applyRemoteRows(loaded.map((room) => room.toJson()).toList());
  } catch (e) {
    debugPrint('[VoiceRooms] remote refresh error: $e');
  }
}

void _applyRemoteRows(List<dynamic> rows) {
  final loaded = rows
      .whereType<Map>()
      .map((raw) => VoiceRoom.fromJson(Map<String, dynamic>.from(raw)))
      .where((room) => room.id.isNotEmpty)
      .map((room) => room.copyWith(
            // isMe is intentionally omitted from the shared JSON. Restore it
            // on each device from the current profile name.
            seats: room.seats
                .map((seat) => seat == null
                    ? null
                    : seat.copyWith(isMe: seat.name == kCurrentUserName))
                .toList(),
          ))
      .toList();
  final current = voiceRooms.value;
  final remoteIds = loaded.map((room) => room.id).toSet();

  // A room restored from SharedPreferences may not have reached Supabase yet.
  // Do not let an empty realtime snapshot erase it; persist it and merge it.
  final localOnly = current.rooms
      .where((room) =>
          (room.hostId == profileIdentity.value.id ||
              (room.hostId == null && room.hostName == kCurrentUserName)) &&
          !remoteIds.contains(room.id) &&
          _pendingRoomPersistenceIds.contains(room.id))
      .toList();
  if (localOnly.isNotEmpty) {
    _queueRoomPersistence(localOnly);
  }

  final merged = [...localOnly, ...loaded];
  final joinedId = merged.any((room) => room.id == current.joinedRoomId)
      ? current.joinedRoomId
      : null;
  _isSyncingFromRemote = true;
  try {
    _commit(
      VoiceRoomsSnapshot(
        rooms: merged,
        joinedRoomId: joinedId,
        selfMuted: current.selfMuted,
        selfHandRaised: current.selfHandRaised,
      ),
      broadcast: false,
    );
  } finally {
    _isSyncingFromRemote = false;
  }
}

Map<String, dynamic> _roomPayload(VoiceRoom room) {
  // isMe is device-local state and must never be copied into the shared row.
  final seatsForDb = room.seats
      .map((seat) => seat == null
          ? null
          : seat.copyWith(isMe: false).toJson())
      .toList();
  return {
    'id': room.id,
    'title': room.title,
    'host_name': room.hostName,
    'host_id': room.hostId ??
        (room.hostName == kCurrentUserName ? profileIdentity.value.id : ''),
    'category': room.category,
    'display_id': room.displayId,
    'announcement': room.announcement,
    'seats': seatsForDb,
    'extra_listeners': room.extraListeners,
    'is_active': true,
    'last_notice': room.lastNotice,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };
}

void _queueRoomPersistence(Iterable<VoiceRoom> rooms) {
  if (!SupabaseService.instance.isInitialized) return;
  final snapshot = rooms.toList(growable: false);
  if (snapshot.isEmpty) return;
  _pendingRoomPersistenceIds.addAll(snapshot.map((room) => room.id));

  _voiceRoomWriteQueue = _voiceRoomWriteQueue.then((_) async {
    for (final room in snapshot) {
      try {
        final payload = _roomPayload(room);
        if (isVoiceRoomHost(room)) {
          // Only the owner creates/reactivates a room. This also keeps the
          // initial local room write reliable.
          await SupabaseService.instance.client
              .from('voice_rooms')
              .upsert(payload, onConflict: 'id');
        } else {
          // Participants may update seats and counters, but must never be
          // able to resurrect a room after its owner closed it.
          payload
            ..remove('id')
            ..remove('is_active');
          await SupabaseService.instance.client
              .from('voice_rooms')
              .update(payload)
              .eq('id', room.id)
              .eq('is_active', true);
        }
        _pendingRoomPersistenceIds.remove(room.id);
      } catch (e) {
        // Stale local data must not revive an explicitly closed room after a
        // later refresh. A future local change can enqueue it again.
        _pendingRoomPersistenceIds.remove(room.id);
        debugPrint('[VoiceRooms] room write error: $e');
      }
    }
  });
}

void _queueRoomDeactivation(VoiceRoom room) {
  if (!SupabaseService.instance.isInitialized) return;

  _voiceRoomWriteQueue = _voiceRoomWriteQueue.then((_) async {
    try {
      await SupabaseService.instance.client
          .from('voice_rooms')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
            'last_notice': 'Oda kapatıldı',
          })
          .eq('id', room.id);
    } catch (e) {
      debugPrint('[VoiceRooms] room close error: $e');
    }
  });
}

void _commit(VoiceRoomsSnapshot next, {bool broadcast = true}) {
  voiceRooms.value = next;
  final myRoom = next.myRoom;
  if (myRoom != null) {
    unawaited(_saveLocalMyRoom(myRoom));
  }

  if (broadcast && !_isSyncingFromRemote) {
    try {
      CrossTabSyncService.instance.emit({
        'type': 'voice_rooms_sync',
        'rooms': next.rooms.map((room) => room.toJson()).toList(),
      });
    } catch (_) {}
    _queueRoomPersistence(next.rooms);
  }
}

VoiceRoomsSnapshot _mapRoom(
  String id,
  VoiceRoom Function(VoiceRoom room) update, {
  String? joinedRoomId,
  bool keepJoined = true,
  bool? selfMuted,
  bool? selfHandRaised,
}) {
  final current = voiceRooms.value;
  return VoiceRoomsSnapshot(
    rooms: [
      for (final room in current.rooms)
        if (room.id == id) update(room) else room,
    ],
    joinedRoomId: keepJoined
        ? (joinedRoomId ?? current.joinedRoomId)
        : joinedRoomId,
    selfMuted: selfMuted ?? current.selfMuted,
    selfHandRaised: selfHandRaised ?? current.selfHandRaised,
  );
}

@visibleForTesting
void resetVoiceRoomsForTest() {
  _commit(VoiceRoomsSnapshot(rooms: List<VoiceRoom>.from(_seedRooms)), broadcast: false);
}

/// Oda sahibi odayı kapattığında oda hem yerel listeden hem de Supabase'den
/// kaldırılır. Dinleyiciler odadan ayrıldığında oda açık kalmaya devam eder.
void closeVoiceRoom(String id) {
  final room = voiceRoomById(id);
  if (room == null || !isVoiceRoomHost(room)) return;

  final current = voiceRooms.value;
  final nextJoined = current.joinedRoomId == id
      ? null
      : current.joinedRoomId;
  _pendingRoomPersistenceIds.remove(id);
  _commit(
    VoiceRoomsSnapshot(
      rooms: current.rooms.where((item) => item.id != id).toList(),
      joinedRoomId: nextJoined,
      selfMuted: nextJoined == null ? false : current.selfMuted,
      selfHandRaised: false,
    ),
  );
  _queueRoomDeactivation(room);
  unawaited(_clearLocalMyRoom());
}

String createVoiceRoom({
  required String title,
  required String category,
}) {
  final current = voiceRooms.value;
  final existingMyRoom = current.rooms
      .where((r) =>
          r.hostId == profileIdentity.value.id ||
          (r.hostId == null && r.hostName == kCurrentUserName))
      .firstOrNull;

  final id = existingMyRoom?.id ?? 'r-${const Uuid().v4().substring(0, 8)}';
  final effectiveTitle = title.trim().isNotEmpty
      ? title.trim()
      : (existingMyRoom != null && existingMyRoom.title.isNotEmpty
          ? existingMyRoom.title
          : 'Yeni sohbet');
  final effectiveCategory = category.trim().isNotEmpty
      ? category
      : (existingMyRoom?.category ?? 'Sohbet');
  final displayId = existingMyRoom?.displayId ??
      (1000000 + DateTime.now().millisecondsSinceEpoch % 9000000).toString();
  final announcement = existingMyRoom?.announcement ??
      'Hoş geldin! Birlikte sohbet edelim.';

  final room = VoiceRoom(
    id: id,
    title: effectiveTitle,
    hostName: kCurrentUserName,
    hostId: profileIdentity.value.id,
    category: effectiveCategory,
    displayId: displayId,
    announcement: announcement,
    extraListeners: 1, // Odaya dinleyici olarak başlar
    lastNotice: 'Odayı sen açtın',
    seats: _seats([]), // Başlangıçta koltuklar boştur
    messages: existingMyRoom != null && existingMyRoom.messages.isNotEmpty
        ? existingMyRoom.messages
        : const [
            VoiceChatLine(
              id: 'welcome',
              name: 'Olly',
              text:
                  'Odan hazır. Sahneye çıkmak için Otur butonuna dokunabilirsin.',
              time: 'Şimdi',
            ),
          ],
  );

  _saveLocalMyRoom(room);

  final otherRooms = current.rooms
      .where((r) =>
          r.id != id &&
          r.hostId != profileIdentity.value.id &&
          !(r.hostId == null && r.hostName == kCurrentUserName))
      .toList();
  _commit(VoiceRoomsSnapshot(
    rooms: [room, ...otherRooms],
    joinedRoomId: id,
    selfMuted: true,
    selfHandRaised: false,
  ));
  return id;
}

void joinVoiceRoom(String id) {
  final previousId = voiceRooms.value.joinedRoomId;
  if (previousId != null && previousId != id) {
    leaveVoiceRoom(previousId);
  }
  final room = voiceRoomById(id);
  if (room == null) return;
  final current = voiceRooms.value;
  if (current.joinedRoomId == id) {
    return;
  }
  _commit(_mapRoom(
    id,
    (r) => r.copyWith(
      extraListeners: r.extraListeners + 1,
      lastNotice: '$kCurrentUserName odaya katıldı',
    ),
    joinedRoomId: id,
    selfMuted: true,
    selfHandRaised: false,
  ));
}

void leaveVoiceRoom(String id) {
  final room = voiceRoomById(id);
  if (room == null) return;
  final current = voiceRooms.value;
  final leavingThisJoin = current.joinedRoomId == id;
  if (!leavingThisJoin && !room.iAmSeated) return;

  final seats = [
    for (final seat in room.seats)
      if (seat?.isMe == true) null else seat,
  ];
  var extra = room.extraListeners;
  if (!room.iAmSeated && extra > 0) extra -= 1;

  var hostName = room.hostName;
  if (room.me?.isHost == true) {
    if (room.hostName != kCurrentUserName) {
      final nextHost = seats.indexWhere((s) => s != null);
      if (nextHost >= 0) {
        seats[nextHost] = seats[nextHost]!.copyWith(isHost: true);
        hostName = seats[nextHost]!.name;
      }
    }
  }

  final nextJoined = leavingThisJoin ? null : current.joinedRoomId;

  _commit(_mapRoom(
    id,
    (r) => r.copyWith(
      seats: seats,
      extraListeners: extra,
      hostName: hostName,
      clearNotice: true,
    ),
    joinedRoomId: nextJoined,
    keepJoined: false,
    selfMuted: nextJoined == null ? false : current.selfMuted,
    selfHandRaised: false,
  ));
}

bool takeVoiceSeat(String id, [int? targetIndex]) {
  final room = voiceRoomById(id);
  if (room == null) return false;
  final isHost = room.hostId == profileIdentity.value.id ||
      (room.hostId == null && room.hostName == kCurrentUserName) ||
      room.me?.isHost == true;
  final seats = [...room.seats];

  int index;
  if (targetIndex != null) {
    index = targetIndex;
  } else {
    index = seats.indexWhere((s) => s == null);
  }

  if (index < 0 || index >= seats.length) return false;
  if (seats[index] != null) return false;
  if (room.lockedSeats.contains(index) && !isHost) return false;

  final current = voiceRooms.value;
  final meIndex = seats.indexWhere((s) => s?.isMe == true);
  var extra = room.extraListeners;
  if (meIndex >= 0) {
    seats[index] = seats[meIndex];
    seats[meIndex] = null;
  } else {
    if (current.joinedRoomId == id && extra > 0) extra -= 1;
    seats[index] = VoiceSeatOccupant(
      name: kCurrentUserName,
      isMe: true,
      isHost: isHost,
      isSpeaking: true,
      muted: false,
      handRaised: current.selfHandRaised,
    );
  }
  _commit(_mapRoom(
    id,
    (r) => r.copyWith(
      seats: seats,
      extraListeners: extra,
      lastNotice: '$kCurrentUserName sahneye çıktı',
    ),
    joinedRoomId: id,
    selfMuted: false,
  ));
  return true;
}

void leaveVoiceSeat(String id) {
  final room = voiceRoomById(id);
  if (room == null || !room.iAmSeated) return;
  final seats = [
    for (final seat in room.seats)
      if (seat?.isMe == true) null else seat,
  ];
  _commit(_mapRoom(
    id,
    (r) => r.copyWith(
      seats: seats,
      extraListeners: r.extraListeners + 1,
      lastNotice: '$kCurrentUserName dinleyicilere geçti',
    ),
    joinedRoomId: id,
    selfMuted: true,
  ));
}

void toggleSeatLock(String id, [int seatIndex = 0]) {
  final room = voiceRoomById(id);
  if (room == null) return;
  final currentLocked = List<int>.from(room.lockedSeats);
  if (currentLocked.contains(seatIndex)) {
    currentLocked.remove(seatIndex);
  } else {
    currentLocked.add(seatIndex);
  }
  _commit(_mapRoom(
    id,
    (r) => r.copyWith(lockedSeats: currentLocked),
  ));
}

void toggleSeatMute(String id, int seatIndex) {
  final room = voiceRoomById(id);
  if (room == null || seatIndex < 0 || seatIndex >= room.seats.length) return;

  final currentMutedSeats = List<int>.from(room.mutedSeats);
  final isSeatCurrentlyMuted = currentMutedSeats.contains(seatIndex) ||
      (room.seats[seatIndex]?.muted == true);
  final nextMuted = !isSeatCurrentlyMuted;

  if (nextMuted) {
    if (!currentMutedSeats.contains(seatIndex)) {
      currentMutedSeats.add(seatIndex);
    }
  } else {
    currentMutedSeats.remove(seatIndex);
  }

  final occupant = room.seats[seatIndex];
  final isMe = occupant?.isMe == true;

  final updatedSeats = [
    for (int i = 0; i < room.seats.length; i++)
      if (i == seatIndex)
        room.seats[i]?.copyWith(
          muted: nextMuted,
          isSpeaking: nextMuted ? false : room.seats[i]!.isSpeaking,
        )
      else
        room.seats[i],
  ];

  _commit(_mapRoom(
    id,
    (r) => r.copyWith(
      seats: updatedSeats,
      mutedSeats: currentMutedSeats,
    ),
    selfMuted: isMe ? nextMuted : voiceRooms.value.selfMuted,
  ));
}

void toggleRoomMute(String id) {
  final room = voiceRoomById(id);
  if (room == null || voiceRooms.value.joinedRoomId != id) return;
  final muted = !voiceRooms.value.selfMuted;
  _commit(_mapRoom(
    id,
    (r) => r.copyWith(
      seats: [
        for (final seat in r.seats)
          seat?.isMe == true
              ? seat!.copyWith(muted: muted, isSpeaking: muted ? false : true)
              : seat,
      ],
    ),
    selfMuted: muted,
  ));
}

void toggleRoomHand(String id) {
  final room = voiceRoomById(id);
  if (room == null || voiceRooms.value.joinedRoomId != id) return;
  final raised = !voiceRooms.value.selfHandRaised;
  _commit(_mapRoom(
    id,
    (r) => r.copyWith(
      seats: [
        for (final seat in r.seats)
          seat?.isMe == true
              ? seat!.copyWith(handRaised: raised)
              : seat,
      ],
    ),
    selfHandRaised: raised,
  ));
}

void sendRoomChat(String id, String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return;
  _commit(_mapRoom(
    id,
    (r) => r.copyWith(
      messages: [
        ...r.messages,
        VoiceChatLine(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: kCurrentUserName,
          text: trimmed,
          time: 'Şimdi',
          isMine: true,
        ),
      ],
    ),
  ));
}

void updateRoomAnnouncement(String id, String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return;
  final room = voiceRoomById(id);
  _commit(_mapRoom(id, (r) => r.copyWith(announcement: trimmed)));
  if (room != null &&
      (room.hostId == profileIdentity.value.id ||
          (room.hostId == null && room.hostName == kCurrentUserName) ||
          room.me?.isHost == true)) {
    unawaited(_saveLocalMyRoom(room.copyWith(announcement: trimmed)));
  }
}

void updateRoomTitle(String id, String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) return;
  final room = voiceRoomById(id);
  _commit(_mapRoom(id, (r) => r.copyWith(title: trimmed)));
  if (room != null &&
      (room.hostId == profileIdentity.value.id ||
          (room.hostId == null && room.hostName == kCurrentUserName) ||
          room.me?.isHost == true)) {
    unawaited(_saveLocalMyRoom(room.copyWith(title: trimmed)));
  }
}

final _seedRooms = <VoiceRoom>[];
