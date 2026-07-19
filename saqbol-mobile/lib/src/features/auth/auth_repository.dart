import 'package:dio/dio.dart';

import '../../core/token_storage.dart';

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  Future<void> register({
    required String phone,
    required String password,
    String? name,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'phone': phone,
      'password': password,
      if (name != null && name.isNotEmpty) 'name': name,
    });
    await _persist(response.data);
  }

  Future<void> login({required String phone, required String password}) async {
    final response = await _dio.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    await _persist(response.data);
  }

  Future<void> logout() => _storage.clear();

  Future<bool> hasSession() async {
    final token = await _storage.readAccess();
    return token != null;
  }

  Future<void> _persist(dynamic data) async {
    await _storage.save(
      data['access_token'] as String,
      data['refresh_token'] as String,
    );
  }
}
