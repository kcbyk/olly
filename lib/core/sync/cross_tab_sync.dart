import 'cross_tab_sync_stub.dart'
    if (dart.library.html) 'cross_tab_sync_web.dart';

class CrossTabSyncService {
  CrossTabSyncService._() {
    _platform.init();
  }

  static final CrossTabSyncService instance = CrossTabSyncService._();

  final CrossTabSyncPlatform _platform = CrossTabSyncPlatform();

  Stream<Map<String, dynamic>> get stream => _platform.stream;

  void emit(Map<String, dynamic> data) {
    _platform.postMessage(data);
  }

  void dispose() {
    _platform.dispose();
  }
}
