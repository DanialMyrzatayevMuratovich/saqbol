import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'history_models.dart';

/// The user's latest checks for the History tab. Invalidated after a new check
/// and when the tab is opened, so the list never goes stale.
final historyProvider = FutureProvider<List<HistoryItem>>((ref) {
  return ref.watch(historyRepositoryProvider).list(limit: 100);
});

/// Home's "Last 7 days" totals and recent threats. Invalidated together with
/// [historyProvider].
final historySummaryProvider = FutureProvider<HistorySummary>((ref) {
  return ref.watch(historyRepositoryProvider).summary(days: 7);
});

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
