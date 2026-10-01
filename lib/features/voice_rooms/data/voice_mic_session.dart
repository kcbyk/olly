import 'dart:async';

import 'package:livekit_client/livekit_client.dart';

import '../presentation/voice_rooms_store.dart';

LocalAudioTrack? _track;
bool _bound = false;
bool _syncing = false;

void bindVoiceMicToStore() {
  if (_bound) return;
  _bound = true;
  voiceRooms.addListener(_onStoreChanged);
  unawaited(_sync());
}

void _onStoreChanged() => unawaited(_sync());

bool get _shouldCapture {
  final snapshot = voiceRooms.value;
  if (snapshot.joinedRoomId == null) return false;
  return !snapshot.selfMuted;
}

Future<void> _sync() async {
  if (_syncing) return;
  _syncing = true;
  try {
    final snapshot = voiceRooms.value;
    if (snapshot.joinedRoomId == null) {
      await _release();
      return;
    }
    try {
      _track ??= await LocalAudioTrack.create(
        const AudioCaptureOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        ),
      );
      if (snapshot.selfMuted) {
        await _track?.mute();
      } else if (_shouldCapture) {
        await _track?.unmute();
      }
    } catch (_) {
      // Mic permission or platform capture can fail; seat/mute UI still works.
    }
  } finally {
    _syncing = false;
  }
}

Future<void> _release() async {
  final track = _track;
  _track = null;
  if (track == null) return;
  try {
    await track.mute();
    await track.stop();
    await track.dispose();
  } catch (_) {}
}
