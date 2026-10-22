import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Remembers the interface language between launches. Stored as a plain code
/// (`ru`, `kk`, `en`) because the background SMS isolate reads it too and has
/// no provider tree to ask.
class LocaleStorage {
  LocaleStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _key = 'app_locale';

  Future<String?> read() => _storage.read(key: _key);

  Future<void> save(String code) => _storage.write(key: _key, value: code);
}
