import 'dart:async';

/// Non-web stub — in-process loopback so same-device scenarios work on mobile/desktop
class CrossTabSyncPlatform {
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  void init() {}

  void postMessage(Map<String, dynamic> data) {
    // Loopback: emit back to own stream so listeners on the same device receive it
    if (!_controller.isClosed) {
      _controller.add(data);
    }
  }

  void dispose() {
    _controller.close();
  }
}
