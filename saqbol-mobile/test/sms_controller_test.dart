import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saqbol_mobile/src/core/providers.dart';
import 'package:saqbol_mobile/src/core/strings.dart';
import 'package:saqbol_mobile/src/features/guard/inbox_message.dart';
import 'package:saqbol_mobile/src/features/sms/sms_controller.dart';
import 'package:saqbol_mobile/src/features/sms/sms_models.dart';
import 'package:saqbol_mobile/src/features/sms/sms_repository.dart';

/// Every check waits until the test answers it, so answers can come back in
/// any order.
class _ManualSms implements SmsRepository {
  final pending = <String, Completer<SmsCheckResult>>{};

  @override
  Future<SmsCheckResult> check({required String text, String? sourceNumber}) {
    final completer = Completer<SmsCheckResult>();
    pending[text] = completer;
    return completer.future;
  }

  void answer(String text, String verdict) {
    pending[text]!.complete(SmsCheckResult(
      messageId: 'id-$text',
      verdict: verdict,
      probability: verdict == 'scam' ? 0.9 : 0.1,
      category: '',
      triggers: const [],
      advice: '',
      modelVersion: 'test',
      originalText: text,
    ));
  }

  void fail(String text) {
    pending[text]!.completeError(DioException(requestOptions: RequestOptions(path: '/sms/check')));
  }

  @override
  Future<List<SmsCheckResult>> checkBatch(List<InboxMessage> messages) => throw UnimplementedError();
}

void main() {
  late _ManualSms sms;
  late ProviderContainer container;
  late SmsController controller;

  SmsCheckResult? shown() => container.read(smsControllerProvider).valueOrNull;

  setUp(() {
    sms = _ManualSms();
    container = ProviderContainer(overrides: [
      smsRepositoryProvider.overrideWithValue(sms),
      stringsProvider.overrideWithValue(const AppStrings(AppLocale.en)),
    ]);
    controller = container.read(smsControllerProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('after Clear, an older check that answers last does not replace the new verdict', () async {
    final first = controller.check(text: 'A');
    controller.reset();
    final second = controller.check(text: 'B');

    sms.answer('B', 'safe');
    await second;
    expect(shown()?.originalText, 'B');

    sms.answer('A', 'scam');
    await first;
    expect(shown()?.originalText, 'B');
    expect(shown()?.verdict, 'safe');
  });

  test('answers in the usual order still end on the newest check', () async {
    final first = controller.check(text: 'A');
    controller.reset();
    final second = controller.check(text: 'B');

    sms.answer('A', 'scam');
    await first;
    // A is not shown even for a moment: B is still being checked.
    expect(container.read(smsControllerProvider).isLoading, isTrue);

    sms.answer('B', 'safe');
    await second;
    expect(shown()?.originalText, 'B');
  });

  test('Clear while checking leaves the screen empty when the answer arrives', () async {
    final pending = controller.check(text: 'A');
    controller.reset();

    sms.answer('A', 'scam');
    await pending;

    final state = container.read(smsControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.hasError, isFalse);
    expect(state.valueOrNull, isNull);
  });

  test('a failure of a cleared check does not show an error', () async {
    final pending = controller.check(text: 'A');
    controller.reset();

    sms.fail('A');
    await pending;

    expect(container.read(smsControllerProvider).hasError, isFalse);
  });

  test('a failure of the current check is shown in the interface language', () async {
    final pending = controller.check(text: 'A');

    sms.fail('A');
    await pending;

    final state = container.read(smsControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, const AppStrings(AppLocale.en).checkFailed);
  });
}
