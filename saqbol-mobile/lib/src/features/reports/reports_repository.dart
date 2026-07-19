import 'package:dio/dio.dart';

class ReportsRepository {
  ReportsRepository(this._dio);

  final Dio _dio;

  Future<void> submit({required String messageId, required String feedback}) async {
    await _dio.post('/reports', data: {
      'message_id': messageId,
      'feedback': feedback,
    });
  }
}
