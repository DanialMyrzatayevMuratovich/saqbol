import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Remembers the chosen theme (`system`, `light` or `dark`) between launches.
class ThemeStorage {
  ThemeStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _key = 'app_theme';

  Future<String?> read() => _storage.read(key: _key);

  Future<void> save(String mode) => _storage.write(key: _key, value: mode);
}

/// Remembers that the user turned on automatic SMS checks, so the listener is
/// started again after the app restarts.
class GuardPrefs {
  GuardPrefs(this._storage);

  final FlutterSecureStorage _storage;

  static const _key = 'sms_guard_on';

  Future<bool> isSmsGuardOn() async => await _storage.read(key: _key) == '1';

  Future<void> setSmsGuardOn() => _storage.write(key: _key, value: '1');
}

/// Remembers that onboarding was finished, which includes the user's consent to
/// send message text to the server for checking.
class OnboardingStorage {
  OnboardingStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _key = 'onboarding_done';

  Future<bool> isDone() async => await _storage.read(key: _key) == '1';

  Future<void> markDone() => _storage.write(key: _key, value: '1');
}
