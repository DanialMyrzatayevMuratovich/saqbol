import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saqbol_mobile/src/app.dart';
import 'package:saqbol_mobile/src/core/providers.dart';
import 'package:saqbol_mobile/src/features/auth/auth_controller.dart';
import 'package:saqbol_mobile/src/features/auth/login_screen.dart';
import 'package:saqbol_mobile/src/features/guard/guard_controller.dart';
import 'package:saqbol_mobile/src/features/guard/inbox_message.dart';
import 'package:saqbol_mobile/src/features/guard/sms_reader.dart';
import 'package:saqbol_mobile/src/features/history/history_models.dart';
import 'package:saqbol_mobile/src/features/history/history_repository.dart';
import 'package:saqbol_mobile/src/features/home/home_screen.dart';
import 'package:saqbol_mobile/src/features/settings/inbox_scan_screen.dart';
import 'package:saqbol_mobile/src/features/sms/sms_models.dart';
import 'package:saqbol_mobile/src/features/sms/sms_repository.dart';
import 'package:saqbol_mobile/src/features/sms/widgets/verdict_card.dart';
import 'package:saqbol_mobile/src/features/voice/call_alert_screen.dart';

class _SignedIn extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

/// The real scan logic; only the Android-only calls are switched off.
class _TestGuard extends GuardController {
  @override
  Future<void> restore() async {}

  @override
  Future<void> refreshPermission() async {}

  @override
  Future<void> refreshCallGuard() async {}
}

/// An inbox of 150 messages, so the scan needs two batches.
class _Inbox extends SmsReader {
  _Inbox() : super(telephony: null);

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<List<InboxMessage>> readInbox({int limit = 200}) async => [
        for (var i = 0; i < 150; i++)
          InboxMessage(id: '$i', address: '+7700000$i', body: 'message $i', date: DateTime(2026, 10, 20)),
      ];
}

/// Each batch waits until the test answers it.
class _ManualBatches implements SmsRepository {
  final batches = <Completer<List<SmsCheckResult>>>[];

  @override
  Future<List<SmsCheckResult>> checkBatch(List<InboxMessage> messages) {
    final completer = Completer<List<SmsCheckResult>>();
    batches.add(completer);
    return completer.future;
  }

  @override
  Future<SmsCheckResult> check({required String text, String? sourceNumber}) => throw UnimplementedError();
}

class _NoHistory extends HistoryRepository {
  _NoHistory() : super(Dio());

  @override
  Future<List<HistoryItem>> list({String? channel, int limit = 50}) async => const [];
}

SmsCheckResult _scam(String text) => SmsCheckResult(
      messageId: 'id-$text',
      verdict: 'scam',
      probability: 0.95,
      category: 'fake_bank',
      triggers: const [],
      advice: '',
      modelVersion: 'test',
      originalText: text,
    );

void main() {
  late _ManualBatches batches;
  late ProviderContainer container;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'onboarding_done': '1'});
    batches = _ManualBatches();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_SignedIn.new),
        guardControllerProvider.overrideWith(_TestGuard.new),
        smsReaderProvider.overrideWithValue(_Inbox()),
        smsRepositoryProvider.overrideWithValue(batches),
        historyRepositoryProvider.overrideWithValue(_NoHistory()),
      ],
      child: const SaqBolApp(),
    ));
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
  }

  NavigatorState navigator(WidgetTester tester) => Navigator.of(tester.element(find.byType(HomeScreen)));

  testWidgets('an expired session closes the inbox scan and forgets its findings', (tester) async {
    await pumpApp(tester);

    navigator(tester).push(MaterialPageRoute<void>(builder: (_) => const InboxScanScreen()));
    await tester.pumpAndSettle();

    // The first batch finds a scam and shows it; the second is still running.
    batches.batches.first.complete([_scam('first batch scam')]);
    await tester.pump();
    await tester.pump();
    expect(find.byType(VerdictCard), findsOneWidget);
    expect(batches.batches, hasLength(2));

    container.read(authControllerProvider.notifier).sessionExpired();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(InboxScanScreen), findsNothing);
    expect(find.byType(HomeScreen), findsNothing);
    expect(container.read(guardControllerProvider).findings, isEmpty);

    // The batch that was in flight answers late: nothing comes back.
    batches.batches.last.complete([_scam('late scam')]);
    await tester.pumpAndSettle();
    final guard = container.read(guardControllerProvider);
    expect(guard.findings, isEmpty);
    expect(guard.status, GuardStatus.idle);
  });

  testWidgets('an expired session closes the call alert', (tester) async {
    await pumpApp(tester);

    navigator(tester).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => const CallAlertScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(CallAlertScreen), findsOneWidget);

    container.read(authControllerProvider.notifier).sessionExpired();
    await tester.pumpAndSettle();

    expect(find.byType(CallAlertScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
