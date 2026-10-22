import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../shared/app_theme.dart';
import '../../shared/brand.dart';
import '../guard/guard_controller.dart';
import '../history/history_models.dart';
import '../history/history_providers.dart';
import '../history/history_tile.dart';
import '../home/shell_tab.dart';

/// Home: is protection on, what happened this week, and the shortest way to
/// check a message. Every number here is counted by the server over the
/// user's whole history, not over the last page of it.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final guard = ref.watch(guardControllerProvider);
    final summary = ref.watch(historySummaryProvider);
    final text = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(historySummaryProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, Gap.xl),
        children: [
          _StatusHero(
            smsOn: guard.watching,
            callsOn: guard.callGuard,
            strings: strings,
            onTurnOn: () => ref.read(shellTabProvider.notifier).go(ShellTab.settings),
          ),
          const SizedBox(height: Gap.l),
          Text(strings.statsTitle, style: text.titleSmall?.copyWith(color: context.saq.muted)),
          const SizedBox(height: Gap.s),
          summary.when(
            data: (summary) => _StatsRow(stats: summary, strings: strings),
            loading: () => const _StatsRow(stats: null, strings: null),
            error: (_, _) => const _StatsRow(stats: null, strings: null),
          ),
          const SizedBox(height: Gap.l),
          _CheckCta(strings: strings, onTap: () => ref.read(shellTabProvider.notifier).go(ShellTab.check)),
          const SizedBox(height: Gap.xl),
          Row(
            children: [
              Expanded(child: Text(strings.recentThreats, style: text.titleLarge)),
              TextButton(
                onPressed: () => ref.read(shellTabProvider.notifier).go(ShellTab.history),
                child: Text(strings.seeAll),
              ),
            ],
          ),
          const SizedBox(height: Gap.s),
          ...summary.when(
            data: (summary) => _threats(context, summary.threats, strings),
            loading: () => const [Center(child: Padding(padding: EdgeInsets.all(Gap.xl), child: CircularProgressIndicator()))],
            error: (_, _) => [Text(strings.historyLoadFailed, style: text.bodyMedium?.copyWith(color: context.saq.muted))],
          ),
        ],
      ),
    );
  }

  List<Widget> _threats(BuildContext context, List<HistoryItem> threats, AppStrings strings) {
    if (threats.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Gap.xl),
            child: Row(
              children: [
                Icon(Icons.verified_user_rounded, color: context.saq.safe),
                const SizedBox(width: Gap.m),
                Expanded(child: Text(strings.noThreats, style: Theme.of(context).textTheme.bodyLarge)),
              ],
            ),
          ),
        ),
      ];
    }
    return [
      for (final item in threats) ...[HistoryTile(item: item), const SizedBox(height: Gap.s)],
    ];
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.smsOn, required this.callsOn, required this.strings, required this.onTurnOn});

  final bool smsOn;
  final bool callsOn;
  final AppStrings strings;
  final VoidCallback onTurnOn;

  @override
  Widget build(BuildContext context) {
    final c = context.saq;
    final text = Theme.of(context).textTheme;
    final full = smsOn && callsOn;
    final none = !smsOn && !callsOn;
    final title = full ? strings.protectedTitle : (none ? strings.offTitle : strings.partialTitle);
    final body = full ? strings.protectedBody : (none ? strings.offBody : strings.partialBody);
    final statusColor = full ? c.safe : c.suspicious;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.xl, Gap.xl, Gap.xl),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: (full ? c.accent : c.suspicious).withValues(alpha: 0.30), blurRadius: 60, spreadRadius: 2)],
              ),
              child: const SaqHeroShield(size: 150),
            ),
            const SizedBox(height: Gap.l),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(full ? Icons.check_circle_rounded : Icons.error_rounded, color: statusColor, size: 22),
                const SizedBox(width: Gap.s),
                Flexible(child: Text(title, textAlign: TextAlign.center, style: text.headlineSmall)),
              ],
            ),
            const SizedBox(height: Gap.xs),
            Text(body, textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: c.muted)),
            if (!full) ...[
              const SizedBox(height: Gap.l),
              FilledButton.icon(onPressed: onTurnOn, icon: const Icon(Icons.shield_rounded), label: Text(strings.turnOn)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats, required this.strings});

  final HistorySummary? stats;
  final AppStrings? strings;

  @override
  Widget build(BuildContext context) {
    final c = context.saq;
    final s = stats;
    final labels = strings;
    return Row(
      children: [
        _StatTile(value: s?.checked, label: labels?.statChecked, color: c.accent),
        const SizedBox(width: Gap.s),
        _StatTile(value: s?.scam, label: labels?.verdictLabel('scam'), color: c.scam),
        const SizedBox(width: Gap.s),
        _StatTile(value: s?.suspicious, label: labels?.verdictLabel('suspicious'), color: c.suspicious),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, required this.color});

  final int? value;
  final String? label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.saq;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.l),
          child: value == null
              // Skeleton while the history loads.
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 36, height: 28, decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(8))),
                    const SizedBox(height: Gap.s),
                    Container(width: 64, height: 12, decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(6))),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$value', style: text.headlineSmall?.copyWith(color: color, fontSize: 28)),
                    const SizedBox(height: Gap.xs),
                    // Shrinks rather than cuts long words like “Мошенничество”.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(label ?? '', maxLines: 1, style: text.bodySmall),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CheckCta extends StatelessWidget {
  const _CheckCta({required this.strings, required this.onTap});

  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.saq;
    final text = Theme.of(context).textTheme;
    return Material(
      color: c.accent,
      borderRadius: BorderRadius.circular(Radii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Gap.l),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: c.onAccent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.content_paste_search_rounded, color: c.onAccent),
              ),
              const SizedBox(width: Gap.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.checkMessageCta, style: text.titleMedium?.copyWith(color: c.onAccent)),
                    const SizedBox(height: 2),
                    Text(strings.checkMessageCtaBody, style: text.bodyMedium?.copyWith(color: c.onAccent.withValues(alpha: 0.85))),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: c.onAccent),
            ],
          ),
        ),
      ),
    );
  }
}
