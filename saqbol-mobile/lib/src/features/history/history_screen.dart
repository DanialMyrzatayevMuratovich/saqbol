import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/strings.dart';
import '../../shared/app_theme.dart';
import 'history_providers.dart';
import 'history_tile.dart';

/// Every check, newest first, grouped by day, with a verdict filter.
///
/// There is no SMS/calls switch: the history API returns checked messages only,
/// live call sessions are stored separately and are not listed yet.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _verdict = '';

  String _dayLabel(DateTime day, AppStrings strings) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return strings.today;
    if (day == today.subtract(const Duration(days: 1))) return strings.yesterday;
    return DateFormat('dd.MM.yyyy').format(day);
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final strings = ref.watch(stringsProvider);
    final c = context.saq;
    final text = Theme.of(context).textTheme;

    final filters = <Widget>[
      // Wraps instead of scrolling sideways, so no filter hides off-screen.
      Wrap(
        spacing: Gap.s,
        runSpacing: Gap.s,
        children: [
          for (final verdict in const ['', 'scam', 'suspicious', 'safe'])
            ChoiceChip(
              label: Text(verdict.isEmpty ? strings.filterAll : strings.verdictLabel(verdict)),
              selected: _verdict == verdict,
              onSelected: (_) => setState(() => _verdict = verdict),
            ),
        ],
      ),
      const SizedBox(height: Gap.s),
    ];

    Widget message(IconData icon, String label) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            children: [
              Icon(icon, size: 48, color: c.muted),
              const SizedBox(height: Gap.m),
              Text(label, textAlign: TextAlign.center, style: text.bodyLarge?.copyWith(color: c.muted)),
            ],
          ),
        );

    final body = history.when(
      data: (items) {
        if (items.isEmpty) return [message(Icons.inbox_rounded, strings.historyEmpty)];
        final days = groupByDay(filterHistory(items, verdict: _verdict));
        if (days.isEmpty) return [message(Icons.filter_alt_off_rounded, strings.nothingMatches)];
        return [
          for (final day in days) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.xs, Gap.l, 0, Gap.s),
              child: Text(_dayLabel(day.day, strings), style: text.titleSmall?.copyWith(color: c.muted)),
            ),
            for (final item in day.items) ...[HistoryTile(item: item), const SizedBox(height: Gap.s)],
          ],
        ];
      },
      loading: () => [const Padding(padding: EdgeInsets.all(Gap.xxl), child: Center(child: CircularProgressIndicator()))],
      error: (_, _) => [message(Icons.wifi_off_rounded, strings.historyLoadFailed)],
    );

    return RefreshIndicator(
      onRefresh: () => ref.refresh(historyProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, Gap.xl),
        children: [...filters, ...body],
      ),
    );
  }
}
