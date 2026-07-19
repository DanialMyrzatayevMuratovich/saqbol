import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../sms/sms_models.dart';
import 'call_guard.dart';
import 'guard_background.dart';
import 'guard_notifications.dart';
import 'inbox_message.dart';

/// Backend caps a batch at 100 messages.
const _batchSize = 100;

enum GuardStatus { idle, needsPermission, scanning, ready, failed }

class GuardState {
  const GuardState({
    this.status = GuardStatus.idle,
    this.watching = false,
    this.scanned = 0,
    this.total = 0,
    this.findings = const [],
    this.callGuard = false,
    this.error,
  });

  final GuardStatus status;

  /// True once incoming messages are being checked automatically.
  final bool watching;
  final int scanned;
  final int total;

  /// Scam and suspicious verdicts only — safe messages are dropped, the point
  /// of the screen is what needs attention.
  final List<SmsCheckResult> findings;
  final String? error;

  /// True when the app holds the Android call-screening role.
  final bool callGuard;

  GuardState copyWith({
    GuardStatus? status,
    bool? watching,
    int? scanned,
    int? total,
    List<SmsCheckResult>? findings,
    bool? callGuard,
    String? error,
  }) {
    return GuardState(
      status: status ?? this.status,
      watching: watching ?? this.watching,
      scanned: scanned ?? this.scanned,
      total: total ?? this.total,
      findings: findings ?? this.findings,
      callGuard: callGuard ?? this.callGuard,
      error: error,
    );
  }
}

class GuardController extends Notifier<GuardState> {
  @override
  GuardState build() => const GuardState();

  Future<void> requestPermission() async {
    final reader = ref.read(smsReaderProvider);
    final granted = await reader.requestPermissions();
    state = state.copyWith(
      status: granted ? GuardStatus.idle : GuardStatus.needsPermission,
    );
  }

  Future<void> refreshPermission() async {
    final granted = await ref.read(smsReaderProvider).hasPermission();
    if (!granted) {
      state = state.copyWith(status: GuardStatus.needsPermission);
    }
  }

  /// Reads the inbox and classifies it in batches, publishing progress as it
  /// goes so a few hundred messages do not look like a frozen screen.
  Future<void> scanInbox({int limit = 200}) async {
    final reader = ref.read(smsReaderProvider);
    if (!await reader.hasPermission()) {
      state = state.copyWith(status: GuardStatus.needsPermission);
      return;
    }

    state = state.copyWith(
      status: GuardStatus.scanning,
      scanned: 0,
      total: 0,
      findings: const [],
    );

    try {
      final inbox = await reader.readInbox(limit: limit);
      state = state.copyWith(total: inbox.length);

      final repository = ref.read(smsRepositoryProvider);
      final findings = <SmsCheckResult>[];

      for (var start = 0; start < inbox.length; start += _batchSize) {
        final end =
            start + _batchSize < inbox.length ? start + _batchSize : inbox.length;
        final results = await repository.checkBatch(inbox.sublist(start, end));

        findings.addAll(results.where((item) => item.verdict != 'safe'));
        state = state.copyWith(scanned: end, findings: List.of(findings));
      }

      state = state.copyWith(status: GuardStatus.ready);
    } catch (error) {
      state = state.copyWith(status: GuardStatus.failed, error: error.toString());
    }
  }

  /// Starts watching for new messages. Foreground arrivals are checked here;
  /// background ones go through [handleBackgroundSms] in its own isolate.
  Future<void> startWatching() async {
    final reader = ref.read(smsReaderProvider);
    if (!await reader.hasPermission()) {
      state = state.copyWith(status: GuardStatus.needsPermission);
      return;
    }

    await GuardNotifications.init();
    reader.listen(
      onMessage: _checkIncoming,
      onBackgroundMessage: handleBackgroundSms,
    );
    state = state.copyWith(watching: true);
  }

  /// Hands the app the system call-screening role and mirrors the credentials
  /// the native service needs to query number reputation.
  Future<void> enableCallGuard() async {
    final token = await ref.read(tokenStorageProvider).readAccess();
    if (token == null) return;

    await CallGuard.syncCredentials(
      token: token,
      apiBaseUrl: ref.read(appConfigProvider).apiPrefix,
    );
    await CallGuard.requestRole();
    state = state.copyWith(callGuard: await CallGuard.isEnabled());
  }

  Future<void> refreshCallGuard() async {
    state = state.copyWith(callGuard: await CallGuard.isEnabled());
  }

  Future<void> _checkIncoming(InboxMessage message) async {
    try {
      final result = await ref.read(smsRepositoryProvider).check(
            text: message.body,
            sourceNumber: message.address,
          );
      if (result.verdict == 'safe') return;

      state = state.copyWith(findings: [result, ...state.findings]);
      if (result.verdict == 'scam') {
        await GuardNotifications.showScamAlert(result, message.address);
      }
    } catch (_) {
      // Ignore transient failures: the message stays in the inbox and the next
      // scan will pick it up.
    }
  }
}

final guardControllerProvider =
    NotifierProvider<GuardController, GuardState>(GuardController.new);
