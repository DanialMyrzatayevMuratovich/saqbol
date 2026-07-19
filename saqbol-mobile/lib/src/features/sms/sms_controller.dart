import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
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
    } on DioException catch (error, stackTrace) {
      state = AsyncError(_messageFrom(error), stackTrace);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }

  String _messageFrom(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    return 'Проверка не удалась. Попробуйте ещё раз.';
  }
}

final smsControllerProvider =
    NotifierProvider<SmsController, AsyncValue<SmsCheckResult?>>(SmsController.new);
