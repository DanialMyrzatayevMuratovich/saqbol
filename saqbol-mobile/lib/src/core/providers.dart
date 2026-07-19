import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../features/auth/auth_repository.dart';
import '../features/history/history_repository.dart';
import '../features/reports/reports_repository.dart';
import '../features/sms/sms_repository.dart';
import 'app_config.dart';
import 'auth_interceptor.dart';
import 'token_storage.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final storage = ref.watch(tokenStorageProvider);

  final options = BaseOptions(
    baseUrl: config.apiPrefix,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 10),
    contentType: Headers.jsonContentType,
  );

  final dio = Dio(options);
  final refreshDio = Dio(options);
  dio.interceptors.add(AuthInterceptor(storage, refreshDio, config.apiPrefix));
  return dio;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider));
});

final smsRepositoryProvider = Provider<SmsRepository>((ref) {
  return SmsRepository(ref.watch(dioProvider));
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(dioProvider));
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(dioProvider));
});
