import 'package:another_telephony/telephony.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/app_config.dart';
import '../../core/auth_interceptor.dart';
import '../../core/token_storage.dart';
import '../sms/sms_repository.dart';
import 'guard_notifications.dart';

/// Entry point for SMS that arrive while the app is not in the foreground.
///
/// Android spawns a fresh isolate for this, so nothing from the running app is
/// available: no providers, no Dio instance, no widget tree. Everything the
/// check needs is rebuilt from scratch here, and the only output is a
/// notification.
@pragma('vm:entry-point')
Future<void> handleBackgroundSms(SmsMessage message) async {
  final body = message.body ?? '';
  if (body.trim().isEmpty) return;

  final config = AppConfig.fromEnvironment();
  final storage = TokenStorage(const FlutterSecureStorage());

  // No token means the user is logged out — nothing to check against.
  if (await storage.readAccess() == null) return;

  final options = BaseOptions(
    baseUrl: config.apiPrefix,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 10),
    contentType: Headers.jsonContentType,
  );
  final dio = Dio(options);
  dio.interceptors.add(AuthInterceptor(storage, Dio(options), config.apiPrefix));

  try {
    final result = await SmsRepository(dio).check(
      text: body,
      sourceNumber: message.address,
    );
    if (result.verdict == 'scam') {
      await GuardNotifications.showScamAlert(result, message.address ?? '');
    }
  } catch (_) {
    // Offline or server down: stay silent rather than alarming the user with a
    // failure they cannot act on. The message stays in the inbox and will be
    // picked up by the next manual scan.
  }
}
