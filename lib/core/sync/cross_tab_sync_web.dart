// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

/// Web implementation using BroadcastChannel and window.localStorage events
class CrossTabSyncPlatform {
  html.BroadcastChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  void init() {
    try {
      _channel = html.BroadcastChannel('olly_cross_tab_sync');
      _channel?.onMessage.listen((event) {
        if (event.data != null) {
          try {
            final dynamic decoded = jsonDecode(event.data.toString());
            if (decoded is Map<String, dynamic>) {
              _controller.add(decoded);
            }
          } catch (_) {}
        }
      });
    } catch (_) {}

    try {
      html.window.onStorage.listen((event) {
        if (event.key == 'olly_cross_tab_event' && event.newValue != null) {
          try {
            final dynamic decoded = jsonDecode(event.newValue!);
            if (decoded is Map<String, dynamic>) {
              _controller.add(decoded);
            }
          } catch (_) {}
        }
      });
    } catch (_) {}
  }

  void postMessage(Map<String, dynamic> data) {
    try {
      final jsonStr = jsonEncode(data);
      _channel?.postMessage(jsonStr);
      html.window.localStorage['olly_cross_tab_event'] = jsonStr;
    } catch (_) {}
  }

  void dispose() {
    try {
      _channel?.close();
    } catch (_) {}
    _controller.close();
  }
}
