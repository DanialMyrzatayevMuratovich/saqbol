import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/strings.dart';
import '../history/history_providers.dart';
import 'sms_models.dart';

class SmsController extends Notifier<AsyncValue<SmsCheckResult?>> {
  /// Number of the check whose answer may still be shown. Every new check,
  /// Clear and a rebuild (a new login) move it on, so an answer that arrives
  /// late for an older check is dropped instead of replacing the current one.
  int _current = 0;

  @override
  AsyncValue<SmsCheckResult?> build() {
    _current++;
    return const AsyncData(null);
  }

  Future<void> check({required String text, String? sourceNumber}) async {
    final request = ++_current;
    state = const AsyncLoading();
    try {
      final result = await ref
          .read(smsRepositoryProvider)
          .check(text: text, sourceNumber: sourceNumber);
      // The server has saved the check either way, so History refreshes even
      // when the verdict itself is no longer wanted on screen.
      ref.invalidate(historyProvider);
      if (request != _current) return;
      state = AsyncData(result);
    } on DioException catch (error, stackTrace) {
      if (request != _current) return;
      state = AsyncError(_messageFrom(error), stackTrace);
    }
  }

  /// Clears the screen and forgets the check still in flight, if any.
  void reset() {
    _current++;
    state = const AsyncData(null);
  }

  /// Never shows the server's English text.
  String _messageFrom(DioException error) {
    final strings = ref.read(stringsProvider);
    return error.response?.statusCode == 429 ? strings.tooManyRequests : strings.checkFailed;
  }
}

final smsControllerProvider =
    NotifierProvider<SmsController, AsyncValue<SmsCheckResult?>>(SmsController.new);
