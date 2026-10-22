import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/strings.dart';
import '../history/history_providers.dart';
import 'sms_models.dart';

class SmsController extends Notifier<AsyncValue<SmsCheckResult?>> {
  @override
  AsyncValue<SmsCheckResult?> build() => const AsyncData(null);

  Future<void> check({required String text, String? sourceNumber}) async {
    state = const AsyncLoading();
    try {
      final result = await ref
          .read(smsRepositoryProvider)
          .check(text: text, sourceNumber: sourceNumber);
      state = AsyncData(result);
      // The new check belongs on Home and in History right away.
      ref.invalidate(historyProvider);
    } on DioException catch (error, stackTrace) {
      state = AsyncError(_messageFrom(error), stackTrace);
    }
  }

  void reset() {
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
