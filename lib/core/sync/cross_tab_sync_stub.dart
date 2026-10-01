import 'dart:async';

/// Non-web / test stub for cross-tab sync
class CrossTabSyncPlatform {
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  void init() {}

  void postMessage(Map<String, dynamic> data) {
    // In-memory loopback or broadcast for tests/stub
  }

  void dispose() {
    _controller.close();
  }
}
