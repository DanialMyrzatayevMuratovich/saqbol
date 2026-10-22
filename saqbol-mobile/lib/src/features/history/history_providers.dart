import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'history_models.dart';

/// The user's latest checks, shared by Home and History. Invalidated after a
/// new check and when either tab is opened, so the lists never go stale.
final historyProvider = FutureProvider<List<HistoryItem>>((ref) {
  return ref.watch(historyRepositoryProvider).list(limit: 100);
});

class WeeklyStats {
  const WeeklyStats({required this.checked, required this.scam, required this.suspicious});

  final int checked;
  final int scam;
  final int suspicious;
}

/// Counts only what really happened in the last seven days.
WeeklyStats weeklyStats(List<HistoryItem> items, DateTime now) {
  final since = now.subtract(const Duration(days: 7));
  final recent = items.where((item) => item.createdAt.isAfter(since));
  return WeeklyStats(
    checked: recent.length,
    scam: recent.where((item) => item.verdict == 'scam').length,
    suspicious: recent.where((item) => item.verdict == 'suspicious').length,
  );
}

/// The newest scam and suspicious items.
List<HistoryItem> recentThreats(List<HistoryItem> items, {int count = 3}) {
  final threats = items.where((item) => item.verdict != 'safe').toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return threats.take(count).toList();
}

/// [channel] and [verdict] are empty for “all”.
List<HistoryItem> filterHistory(List<HistoryItem> items, {String channel = '', String verdict = ''}) {
  return items
      .where((item) => channel.isEmpty || item.channel == channel)
      .where((item) => verdict.isEmpty || item.verdict == verdict)
      .toList();
}

class HistoryDay {
  const HistoryDay(this.day, this.items);

  /// Local midnight of the day.
  final DateTime day;
  final List<HistoryItem> items;
}

/// Groups items by local calendar day, newest day and newest item first.
List<HistoryDay> groupByDay(List<HistoryItem> items) {
  final sorted = List.of(items)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final days = <HistoryDay>[];
  for (final item in sorted) {
    final local = item.createdAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    if (days.isEmpty || days.last.day != day) {
      days.add(HistoryDay(day, [item]));
    } else {
      days.last.items.add(item);
    }
  }
  return days;
}
