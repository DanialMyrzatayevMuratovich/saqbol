import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.submitting = false,
    this.error,
  });

  final AuthStatus status;
  final bool submitting;
  final String? error;

  AuthState copyWith({AuthStatus? status, bool? submitting, String? error}) {
    return AuthState(
      status: status ?? this.status,
      submitting: submitting ?? this.submitting,
      error: error,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restore();
    return const AuthState();
  }

  Future<void> _restore() async {
    final hasSession = await ref.read(authRepositoryProvider).hasSession();
    state = state.copyWith(
      status: hasSession ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  Future<void> login(String phone, String password) async {
    await _run(() => ref.read(authRepositoryProvider).login(phone: phone, password: password));
  }

  Future<void> register(String phone, String password, String name) async {
    await _run(() => ref.read(authRepositoryProvider).register(phone: phone, password: password, name: name));
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }

  Future<void> _run(Future<void> Function() action) async {
    state = state.copyWith(submitting: true, error: null);
    try {
      await action();
      state = state.copyWith(status: AuthStatus.authenticated, submitting: false);
    } on DioException catch (error) {
      state = state.copyWith(submitting: false, error: _messageFrom(error));
    }
  }

  String _messageFrom(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    return 'Не удалось выполнить запрос. Проверьте подключение.';
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
