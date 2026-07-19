import 'package:dio/dio.dart';

import 'token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._refreshDio, this._apiPrefix);

  final TokenStorage _storage;
  final Dio _refreshDio;
  final String _apiPrefix;

  bool _isAuthPath(String path) => path.contains('/auth/');

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_isAuthPath(options.path)) {
      final token = await _storage.readAccess();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    if (status != 401 || _isAuthPath(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    final refreshed = await _refreshTokens();
    if (!refreshed) {
      handler.next(err);
      return;
    }

    final token = await _storage.readAccess();
    final options = err.requestOptions;
    options.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await _refreshDio.fetch(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _refreshTokens() async {
    final refreshToken = await _storage.readRefresh();
    if (refreshToken == null) {
      return false;
    }

    try {
      final response = await _refreshDio.post(
        '$_apiPrefix/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      await _storage.save(
        response.data['access_token'] as String,
        response.data['refresh_token'] as String,
      );
      return true;
    } on DioException {
      await _storage.clear();
      return false;
    }
  }
}
