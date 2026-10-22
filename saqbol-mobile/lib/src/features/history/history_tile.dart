import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/strings.dart';
import '../../shared/app_theme.dart';
import '../../shared/verdict_style.dart';
import 'history_models.dart';

/// One check in a list, laid out like a bank transaction: who, what, when and
/// a verdict badge. Tapping opens the full text.
class HistoryTile extends ConsumerWidget {
  const HistoryTile({super.key, required this.item});

  final HistoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final c = context.saq;
    final text = Theme.of(context).textTheme;
    final who = item.sourceNumber.isNotEmpty
        ? item.sourceNumber
        : (item.channel == 'call' ? strings.callTitle : strings.unknownSender);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context, strings),
        child: Padding(
          padding: const EdgeInsets.all(Gap.l),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VerdictAvatar(verdict: item.verdict),
              const SizedBox(width: Gap.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item.channel == 'call') ...[
                          Icon(Icons.call_rounded, size: 16, color: c.muted),
                          const SizedBox(width: Gap.xs),
                        ],
                        Expanded(
                          child: Text(who, style: text.titleMedium?.copyWith(fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Text(DateFormat('HH:mm').format(item.createdAt.toLocal()), style: text.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: Gap.s,
                      runSpacing: Gap.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        VerdictBadge(verdict: item.verdict, label: strings.verdictLabel(item.verdict)),
                        if (item.category.isNotEmpty)
                          Text(strings.categoryLabel(item.category), style: text.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, AppStrings strings) {
    final style = VerdictStyle.of(context, item.verdict);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      // Stays below the status bar; a long message scrolls inside the sheet.
      useSafeArea: true,
      builder: (context) {
        final text = Theme.of(context).textTheme;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Gap.xl, 0, Gap.xl, Gap.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    VerdictAvatar(verdict: item.verdict, size: 52),
                    const SizedBox(width: Gap.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.verdictLabel(item.verdict), style: text.titleLarge?.copyWith(color: style.color)),
                          Text(strings.riskLabel((item.probability * 100).round()), style: text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.l),
                Text(item.text, style: text.bodyLarge),
                const SizedBox(height: Gap.m),
                Text(DateFormat('dd.MM.yyyy HH:mm').format(item.createdAt.toLocal()), style: text.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }
}
