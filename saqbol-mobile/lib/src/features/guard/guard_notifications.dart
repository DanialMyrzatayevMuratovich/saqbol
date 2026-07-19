import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../sms/sms_models.dart';

/// Local alerts raised when the guard classifies a message as dangerous.
///
/// Static because the background isolate has no access to the provider tree and
/// still needs to raise notifications.
class GuardNotifications {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'saqbol_guard',
    'SaqBol',
    channelDescription: 'Оповещения о мошеннических сообщениях',
    importance: Importance.max,
    priority: Priority.high,
  );

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

    final percent = (result.probability * 100).round();
    final from = sender.isEmpty ? '' : ' от $sender';

    await _plugin.show(
      result.messageId.hashCode,
      '⚠️ Мошенническое SMS$from',
      '$percent% — ${result.advice}',
      const NotificationDetails(android: _androidDetails),
    );
  }
}
