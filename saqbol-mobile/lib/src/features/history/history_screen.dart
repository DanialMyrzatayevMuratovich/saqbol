import 'package:flutter/material.dart';

import '../../shared/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../shared/verdict_style.dart';
import 'history_models.dart';

final historyProvider = FutureProvider.autoDispose<List<HistoryItem>>((ref) {
  return ref.watch(historyRepositoryProvider).list();
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(historyProvider.future),
      child: history.when(
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('История пуста')),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _HistoryTile(item: items[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Ошибка загрузки: $error')),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});

  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final style = VerdictStyle.of(item.verdict);
    final formatted = DateFormat('dd.MM HH:mm').format(item.createdAt.toLocal());

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: style.color.withValues(alpha: 0.15),
          child: Icon(style.icon, color: style.color, size: 20),
        ),
        title: Text(
          item.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            style.label,
            if (item.category.isNotEmpty) categoryLabel(item.category),
            formatted,
          ].join(' · '),
          style: TextStyle(color: style.color),
        ),
        trailing: Text('${(item.probability * 100).round()}%'),
      ),
    );
  }
}
