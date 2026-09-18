import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../security/web_navigation_policy.dart';

/// Hands a destination to the system browser instead of the in-app browser.
///
/// The in-app browser is pinned to one host, which is right for reading an
/// explorer page but wrong for a site the user has to interact with through
/// their own browser session and extensions. Only https destinations are
/// ever passed on; anything else is refused before it reaches the platform.
class ExternalLink {
  const ExternalLink._();

  static const _channel = MethodChannel('mpc/external_link');

  /// Returns true when the platform accepted the URL. A false result means
  /// nothing was opened, so the caller can fall back to the in-app browser.
  static Future<bool> open(String url) async {
    if (kIsWeb || !WebNavigationPolicy.isSafeUrl(url)) return false;
    try {
      return await _channel.invokeMethod<bool>('open', {'url': url}) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
