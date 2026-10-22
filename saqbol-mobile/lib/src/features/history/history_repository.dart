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

  /// Totals of the last [days] days, counted on the server: a page of
  /// [list] holds at most 200 checks, and one inbox scan alone can add 200.
  Future<HistorySummary> summary({int days = 7}) async {
    final response = await _dio.get('/history/summary', queryParameters: {'days': days});
    return HistorySummary.fromJson(response.data as Map<String, dynamic>);
  }
}
