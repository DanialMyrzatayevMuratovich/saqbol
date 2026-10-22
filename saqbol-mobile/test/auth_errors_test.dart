import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saqbol_mobile/src/core/locale_storage.dart';
import 'package:saqbol_mobile/src/core/providers.dart';
import 'package:saqbol_mobile/src/core/strings.dart';
import 'package:saqbol_mobile/src/features/auth/auth_controller.dart';
import 'package:saqbol_mobile/src/features/auth/auth_repository.dart';

class _MemoryLocale implements LocaleStorage {
  _MemoryLocale(this.code);

  final String code;

  @override
  Future<String?> read() async => code;

  @override
  Future<void> save(String code) async {}
}

/// Fails every call with [status] and an English server message.
class _FailingRepository implements AuthRepository {
  _FailingRepository(this.status);

  final int status;

  DioException get _error {
    final options = RequestOptions(path: '/auth');
    return DioException(
      requestOptions: options,
      response: Response(requestOptions: options, statusCode: status, data: {'error': 'invalid phone or password'}),
    );
  }

  @override
  Future<void> login({required String phone, required String password}) async => throw _error;

  @override
  Future<void> register({required String phone, required String password, String? name}) async => throw _error;

  @override
  Future<void> logout() async {}

  @override
  Future<bool> hasSession() async => false;
}

Future<String?> _errorFor(int status, String locale) async {
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(_FailingRepository(status)),
    localeStorageProvider.overrideWithValue(_MemoryLocale(locale)),
  ]);
  addTearDown(container.dispose);
  container.read(localeControllerProvider);
  container.read(authControllerProvider);
  await pumpEventQueue();
  await container.read(authControllerProvider.notifier).login('+77000000001', 'whatever');
  return container.read(authControllerProvider).error;
}

void main() {
  test('server errors are shown in the interface language, never as the English server text', () async {
    expect(await _errorFor(401, 'ru'), 'Неверный телефон или пароль');
    expect(await _errorFor(401, 'kk'), 'Телефон немесе құпия сөз қате');
    expect(await _errorFor(409, 'en'), 'This number is already registered');
    expect(await _errorFor(429, 'ru'), 'Слишком много запросов. Подождите минуту.');
    expect(await _errorFor(500, 'en'), 'Request failed. Check your connection.');
  });
}
