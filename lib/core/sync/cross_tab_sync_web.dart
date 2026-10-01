// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Web implementation using BroadcastChannel and localStorage storage events
class CrossTabSyncPlatform {
  web.BroadcastChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  void init() {
    try {
      _channel = web.BroadcastChannel('olly_cross_tab_sync');
      _channel?.addEventListener(
        'message',
        (web.MessageEvent event) {
          final data = event.data;
          if (data != null) {
            try {
              final decoded = jsonDecode(data.toString());
              if (decoded is Map<String, dynamic>) {
                _controller.add(decoded);
              }
            } catch (_) {}
          }
        }.toJS,
      );
    } catch (_) {}

    try {
      web.window.addEventListener(
        'storage',
        (web.StorageEvent event) {
          if (event.key == 'olly_cross_tab_event' &&
              event.newValue != null) {
            try {
              final decoded = jsonDecode(event.newValue!);
              if (decoded is Map<String, dynamic>) {
                _controller.add(decoded);
              }
            } catch (_) {}
          }
        }.toJS,
      );
    } catch (_) {}
  }

  void postMessage(Map<String, dynamic> data) {
    try {
      final jsonStr = jsonEncode(data);
      _channel?.postMessage(jsonStr.toJS);
      web.window.localStorage.setItem('olly_cross_tab_event', jsonStr);
    } catch (_) {}
  }

  void dispose() {
    try {
      _channel?.close();
    } catch (_) {}
    _controller.close();
  }
}
