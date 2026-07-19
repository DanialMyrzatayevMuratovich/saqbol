import 'package:dio/dio.dart';

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
}
