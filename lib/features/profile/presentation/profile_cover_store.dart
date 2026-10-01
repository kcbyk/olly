import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// Session-local state until profile media is persisted by the backend.
final profileCoverImage = ValueNotifier<Uint8List?>(null);
