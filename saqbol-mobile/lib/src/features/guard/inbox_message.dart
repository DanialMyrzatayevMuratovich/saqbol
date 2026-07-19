/// A single SMS as read from the device inbox.
///
/// Kept separate from [SmsCheckResult] so the reading layer (telephony) and the
/// checking layer (backend) can evolve independently.
class InboxMessage {
  const InboxMessage({
    required this.id,
    required this.address,
    required this.body,
    required this.date,
  });

  final String id;

  /// Sender: a phone number or an alphanumeric sender id such as "KaspiBank".
  final String address;
  final String body;
  final DateTime date;
}
