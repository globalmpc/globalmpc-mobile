import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Blocks screenshots and screen recording while a recovery phrase is on
/// screen (spec S2), via FLAG_SECURE on Android. iOS has no supported
/// equivalent for third-party apps; that gap is tracked in the compatibility
/// checklist, not silently ignored.
class SecureScreen {
  const SecureScreen._();

  static const _channel = MethodChannel('mpc/secure_screen');

  static Future<void> enable() => _set(true);

  static Future<void> disable() => _set(false);

  static Future<void> _set(bool secure) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>(secure ? 'enable' : 'disable');
    } on MissingPluginException {
      // Test embedder: nothing to secure.
    } on PlatformException {
      // Hardening must never break the flow itself.
    }
  }
}
