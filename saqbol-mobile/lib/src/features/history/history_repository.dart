import 'package:dio/dio.dart';

import 'history_models.dart';

class HistoryRepository {
  HistoryRepository(this._dio);

  final Dio _dio;

  Future<List<HistoryItem>> list({String? channel, int limit = 50}) async {
    final response = await _dio.get('/history', queryParameters: {
      'limit': limit,
      if (channel != null && channel.isNotEmpty) 'channel': channel,
    });
    final items = (response.data['items'] as List<dynamic>? ?? []);
    return items
        .map((item) => HistoryItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
