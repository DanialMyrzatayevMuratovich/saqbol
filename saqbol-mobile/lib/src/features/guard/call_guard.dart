import 'package:flutter/services.dart';

/// Bridge to the native Android call-screening service.
///
/// All methods are no-ops on platforms without the channel (iOS, web), so
/// callers do not need platform checks.
class CallGuard {
  static const MethodChannel _channel = MethodChannel('kz.saqbol/guard');

  /// Mirrors the access token and API address into native SharedPreferences.
  /// [CallGuardService] runs outside the Flutter engine and cannot read the
  /// secure storage the app normally uses.
  static Future<void> syncCredentials({
    required String token,
    required String apiBaseUrl,
  }) async {
    try {
      await _channel.invokeMethod<bool>('syncCredentials', {
        'token': token,
        'apiBaseUrl': apiBaseUrl,
      });
    } on MissingPluginException {
      // Not Android — nothing to sync.
    } on PlatformException {
      // Screening simply stays inactive.
    }
  }

  /// True when this app currently holds the system call-screening role.
  static Future<bool> isEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isCallScreeningEnabled') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the system dialog asking the user to hand this app the screening
  /// role. Returns false when the device cannot offer it (Android below 10).
  static Future<bool> requestRole() async {
    try {
      return await _channel.invokeMethod<bool>('requestCallScreeningRole') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
