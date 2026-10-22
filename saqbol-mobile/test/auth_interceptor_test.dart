import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saqbol_mobile/src/core/auth_interceptor.dart';
import 'package:saqbol_mobile/src/core/token_storage.dart';

class _MemoryTokenStorage implements TokenStorage {
  _MemoryTokenStorage(this.access, this.refresh);

  String? access;
  String? refresh;

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> save(String accessToken, String refreshToken) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clear() async => access = refresh = null;
}

/// Answers every request with [status]; refresh requests with [refreshStatus].
class _Adapter implements HttpClientAdapter {
  _Adapter({required this.status, required this.refreshStatus});

  final int status;
  final int refreshStatus;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final refresh = options.path.endsWith('/auth/refresh');
    final code = refresh ? refreshStatus : status;
    final body = refresh && code == 200 ? {'access_token': 'new-access', 'refresh_token': 'new-refresh'} : {'items': []};
    return ResponseBody.fromString(jsonEncode(body), code, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_MemoryTokenStorage storage, _Adapter adapter, void Function() onExpired) {
  final options = BaseOptions(baseUrl: 'http://test/api/v1');
  final dio = Dio(options)..httpClientAdapter = adapter;
  final refreshDio = Dio(options)..httpClientAdapter = adapter;
  dio.interceptors.add(AuthInterceptor(storage, refreshDio, 'http://test/api/v1', onSessionExpired: onExpired));
  return dio;
}

void main() {
  test('a rejected refresh token clears the session and reports it', () async {
    final storage = _MemoryTokenStorage('old-access', 'old-refresh');
    var expired = 0;
    final dio = _dio(storage, _Adapter(status: 401, refreshStatus: 401), () => expired++);

    await expectLater(dio.get('/history'), throwsA(isA<DioException>()));

    expect(expired, 1);
    expect(storage.access, isNull);
    expect(storage.refresh, isNull);
  });

  test('a working refresh token keeps the session', () async {
    final storage = _MemoryTokenStorage('old-access', 'old-refresh');
    var expired = 0;
    final dio = _dio(storage, _Adapter(status: 401, refreshStatus: 200), () => expired++);

    // The retried request also gets 401 from this adapter; what matters is
    // that the tokens were renewed and the session was not dropped.
    await expectLater(dio.get('/history'), throwsA(isA<DioException>()));

    expect(expired, 0);
    expect(storage.access, 'new-access');
    expect(storage.refresh, 'new-refresh');
  });
}
