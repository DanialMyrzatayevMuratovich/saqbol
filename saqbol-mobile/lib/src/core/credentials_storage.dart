import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SavedCredentials {
  const SavedCredentials(this.phone, this.password);

  final String phone;
  final String password;
}

/// Keeps the "remember me" login in the platform keystore, next to the tokens.
class CredentialsStorage {
  CredentialsStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _phoneKey = 'saved_phone';
  static const _passwordKey = 'saved_password';

  Future<void> save(String phone, String password) async {
    await _storage.write(key: _phoneKey, value: phone);
    await _storage.write(key: _passwordKey, value: password);
  }

  Future<SavedCredentials?> read() async {
    final phone = await _storage.read(key: _phoneKey);
    final password = await _storage.read(key: _passwordKey);
    if (phone == null || password == null) return null;
    return SavedCredentials(phone, password);
  }

  Future<void> clear() async {
    await _storage.delete(key: _phoneKey);
    await _storage.delete(key: _passwordKey);
  }
}
