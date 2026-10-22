import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/locale_storage.dart';
import '../../core/strings.dart';
import '../sms/sms_models.dart';

/// Local alerts raised when the guard classifies a message as dangerous.
///
/// Static because the background isolate has no access to the provider tree and
/// still needs to raise notifications.
class GuardNotifications {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialised = false;

  static Future<void> init() async {
    if (_initialised) return;
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialised = true;
  }

  /// Shows an alert for a scam verdict. Safe verdicts are deliberately silent —
  /// a notification per harmless SMS would train the user to ignore all of them.
  static Future<void> showScamAlert(SmsCheckResult result, String sender) async {
    await init();

    // Read from storage rather than a provider: this also runs in the
    // background isolate, where the saved language is all there is.
    final code = await LocaleStorage(const FlutterSecureStorage()).read();
    final strings = AppStrings(localeFromCode(code));
    final percent = (result.probability * 100).round();

    await _plugin.show(
      result.messageId.hashCode,
      strings.scamSmsAlert(sender),
      '$percent% — ${strings.advice(result.category, result.advice)}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'saqbol_guard',
          'SaqBol',
          channelDescription: strings.guardChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
