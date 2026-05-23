import 'dart:io';

import 'package:boorusphere/utils/logger.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

class DeviceWorkarounds {
  const DeviceWorkarounds._();

  // ignore: avoid_void_async
  static void apply() async {
    if (!Platform.isAndroid) return;
    try {
      mainLog.i('Forcing highest display refresh rate natively');
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (e, s) {
      mainLog.e('Failed to set native high refresh rate', e, s);
    }
  }
}
