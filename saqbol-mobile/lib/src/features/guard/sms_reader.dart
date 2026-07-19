import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

import 'inbox_message.dart';

/// Device-side SMS access: permissions, reading the inbox, and listening for
/// new messages. Android only — iOS gives no app any access to SMS.
class SmsReader {
  SmsReader({Telephony? telephony}) : _telephony = telephony ?? Telephony.instance;

  final Telephony _telephony;

  /// Asks for SMS + notification permissions. Returns true only if SMS access
  /// was granted; notifications are requested too but are not fatal, the guard
  /// still works without them (results are visible in the app).
  Future<bool> requestPermissions() async {
    final statuses = await [Permission.sms, Permission.notification].request();
    return statuses[Permission.sms]?.isGranted ?? false;
  }

  Future<bool> hasPermission() => Permission.sms.isGranted;

  /// True when the user permanently denied SMS access, in which case only the
  /// system settings screen can restore it.
  Future<bool> isPermanentlyDenied() => Permission.sms.isPermanentlyDenied;

  Future<void> openSettings() => openAppSettings();

  /// Reads the inbox, newest first. [limit] caps how far back we go — a full
  /// inbox can hold thousands of messages and every one costs a classification.
  Future<List<InboxMessage>> readInbox({int limit = 200}) async {
    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.ID, SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    return messages
        .where((message) => (message.body ?? '').trim().isNotEmpty)
        .take(limit)
        .map(_toInboxMessage)
        .toList();
  }

  /// Starts delivering incoming messages. [onMessage] fires while the app is in
  /// the foreground; [onBackgroundMessage] must be a top-level or static
  /// function annotated with `@pragma('vm:entry-point')` — Android runs it in a
  /// separate isolate with no access to the UI's providers.
  void listen({
    required void Function(InboxMessage message) onMessage,
    required MessageHandler onBackgroundMessage,
  }) {
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) => onMessage(_toInboxMessage(message)),
      onBackgroundMessage: onBackgroundMessage,
      listenInBackground: true,
    );
  }

  static InboxMessage _toInboxMessage(SmsMessage message) {
    return InboxMessage(
      id: message.id?.toString() ?? '${message.date ?? 0}',
      address: message.address ?? '',
      body: message.body ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(
        message.date ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
