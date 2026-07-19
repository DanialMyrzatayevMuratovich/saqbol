import 'package:dio/dio.dart';

import '../guard/inbox_message.dart';
import 'sms_models.dart';

class SmsRepository {
  SmsRepository(this._dio);

  final Dio _dio;

  Future<SmsCheckResult> check({required String text, String? sourceNumber}) async {
    final response = await _dio.post('/sms/check', data: {
      'text': text,
      if (sourceNumber != null && sourceNumber.isNotEmpty) 'source_number': sourceNumber,
    });
    return SmsCheckResult.fromJson(response.data as Map<String, dynamic>, text);
  }

  /// Checks a whole slice of the inbox in one request. The backend caps a batch
  /// at 100 messages, so callers must chunk longer inboxes themselves.
  Future<List<SmsCheckResult>> checkBatch(List<InboxMessage> messages) async {
    final response = await _dio.post('/sms/check/batch', data: {
      'messages': [
        for (final message in messages)
          {
            'external_id': message.id,
            'text': message.body,
            if (message.address.isNotEmpty) 'source_number': message.address,
          },
      ],
    });

    final payload = response.data as Map<String, dynamic>;
    final results = payload['results'] as List<dynamic>? ?? const [];
    final bodyById = {for (final message in messages) message.id: message.body};

    return results
        .cast<Map<String, dynamic>>()
        // Items the backend could not classify carry an `error` and no verdict.
        .where((item) => item['error'] == null)
        .map((item) => SmsCheckResult.fromJson(
              item,
              bodyById[item['external_id']] ?? '',
            ))
        .toList();
  }
}
