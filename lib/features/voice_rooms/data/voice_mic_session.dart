import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';

import '../presentation/voice_rooms_store.dart';

// ─── State ───────────────────────────────────────────────────────────────────

Room? _room;
LocalAudioTrack? _track;
bool _bound = false;
bool _syncing = false;
String? _connectedRoomId;

// ─── Public API ──────────────────────────────────────────────────────────────

/// Call once from main() after initVoiceRoomsSync().
void bindVoiceMicToStore() {
  if (_bound) return;
  _bound = true;
  voiceRooms.addListener(_onStoreChanged);
  unawaited(_sync());
}

// ─── Internal ────────────────────────────────────────────────────────────────

void _onStoreChanged() => unawaited(_sync());

Future<void> _sync() async {
  if (_syncing) return;
  _syncing = true;
  try {
    final snapshot = voiceRooms.value;
    final targetRoomId = snapshot.joinedRoomId;

    // Left all rooms → disconnect
    if (targetRoomId == null) {
      await _disconnect();
      return;
    }

    // Switched rooms → disconnect first, then reconnect
    if (_connectedRoomId != null && _connectedRoomId != targetRoomId) {
      await _disconnect();
    }

    // Connect to new room if not already connected
    if (_connectedRoomId == null) {
      await _connect(snapshot, targetRoomId);
    } else {
      // Already in correct room — just sync mute state
      await _syncMute(snapshot.selfMuted);
    }
  } catch (e) {
    debugPrint('[VoiceMic] sync error: $e');
  } finally {
    _syncing = false;
  }
}

Future<void> _connect(VoiceRoomsSnapshot snapshot, String roomId) async {
  try {
    final room = snapshot.rooms.firstWhere((r) => r.id == roomId);
    final identity = kCurrentUserName.replaceAll(' ', '-').toLowerCase();

    // Fetch token from token server
    final token = await _fetchToken(
      roomName: roomId,
      identity: identity,
      name: kCurrentUserName,
    );
    if (token == null) return;

    final livekitUrl = dotenv.env['LIVEKIT_URL'] ?? '';
    if (livekitUrl.isEmpty) {
      debugPrint('[VoiceMic] LIVEKIT_URL not set in .env');
      return;
    }

    // Create and connect Room
    _room = Room();
    await _room!.connect(
      livekitUrl,
      token,
      roomOptions: const RoomOptions(
        defaultAudioPublishOptions: AudioPublishOptions(
          name: 'microphone',
          dtx: true,
        ),
      ),
    );

    _connectedRoomId = roomId;
    debugPrint('[VoiceMic] connected to room: ${room.title}');

    // Create and publish mic track
    _track = await LocalAudioTrack.create(
      const AudioCaptureOptions(
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true,
      ),
    );
    await _room!.localParticipant?.publishAudioTrack(_track!);

    // Apply initial mute state
    await _syncMute(snapshot.selfMuted);

    // Listen for remote participants speaking — update UI
    _room!.addListener(_onRoomEvent);
  } catch (e) {
    debugPrint('[VoiceMic] connect error: $e');
    await _disconnect();
  }
}

void _onRoomEvent() {
  // Reflect remote participants' speaking status in the store
  final room = _room;
  if (room == null) return;
  // Speaking detection is handled by LiveKit SDK's isSpeaking property
  // UI can poll voiceRooms notifier; no extra action needed here.
}

Future<void> _syncMute(bool muted) async {
  try {
    if (muted) {
      await _track?.mute();
    } else {
      await _track?.unmute();
    }
  } catch (e) {
    debugPrint('[VoiceMic] mute sync error: $e');
  }
}

Future<void> _disconnect() async {
  _connectedRoomId = null;

  try {
    await _track?.mute();
    await _track?.stop();
    await _track?.dispose();
  } catch (_) {}
  _track = null;

  try {
    _room?.removeListener(_onRoomEvent);
    await _room?.disconnect();
    await _room?.dispose();
  } catch (_) {}
  _room = null;

  debugPrint('[VoiceMic] disconnected');
}

// ─── Token fetcher ───────────────────────────────────────────────────────────

Future<String?> _fetchToken({
  required String roomName,
  required String identity,
  required String name,
}) async {
  final serverUrl = dotenv.env['VOICE_TOKEN_SERVER_URL'] ?? '';
  if (serverUrl.isEmpty) {
    debugPrint('[VoiceMic] VOICE_TOKEN_SERVER_URL not set in .env');
    return null;
  }

  try {
    final response = await http
        .post(
          Uri.parse('$serverUrl/token'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'roomName': roomName,
            'identity': identity,
            'name': name,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['token'] as String?;
    } else {
      debugPrint('[VoiceMic] token server error: ${response.statusCode} ${response.body}');
      return null;
    }
  } catch (e) {
    debugPrint('[VoiceMic] token fetch failed: $e');
    return null;
  }
}
