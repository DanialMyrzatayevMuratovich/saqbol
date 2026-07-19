import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/strings.dart';
import '../../../shared/verdict_style.dart';
import '../sms_models.dart';
import 'highlighted_message.dart';

class VerdictCard extends ConsumerStatefulWidget {
  const VerdictCard({super.key, required this.result});

  final SmsCheckResult result;

  @override
  ConsumerState<VerdictCard> createState() => _VerdictCardState();
}

class _VerdictCardState extends ConsumerState<VerdictCard> {
  String? _submittedFeedback;
  bool _sending = false;

  Future<void> _submit(String feedback) async {
    setState(() => _sending = true);
    try {
      await ref.read(reportsRepositoryProvider).submit(
            messageId: widget.result.messageId,
            feedback: feedback,
          );
      setState(() => _submittedFeedback = feedback);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось отправить отзыв')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final style = VerdictStyle.of(result.verdict);
    final percent = (result.probability * 100).round();

    return Card(
      elevation: 0,
      color: style.color.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: style.color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(style.icon, color: style.color, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    style.label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: style.color,
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: style.color,
                  ),
                ),
              ],
            ),
            if (result.category.isNotEmpty) ...[
              const SizedBox(height: 12),
              Chip(
                label: Text(categoryLabel(result.category)),
                backgroundColor: style.color.withValues(alpha: 0.12),
                side: BorderSide(color: style.color.withValues(alpha: 0.3)),
                labelStyle: TextStyle(color: style.color, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 16),
            HighlightedMessage(
              text: result.originalText,
              triggers: result.triggers,
              highlightColor: style.color,
            ),
            if (result.advice.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: style.color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(result.advice)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _feedbackSection(style),
            if (result.modelVersion.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Модель: ${result.modelVersion}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _feedbackSection(VerdictStyle style) {
    if (widget.result.messageId.isEmpty) {
      return const SizedBox.shrink();
    }
    final strings = ref.watch(stringsProvider);
    if (_submittedFeedback != null) {
      return Row(
        children: [
          Icon(Icons.check_circle, color: style.color, size: 18),
          const SizedBox(width: 6),
          Text(strings.feedbackThanks, style: const TextStyle(color: Colors.grey)),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _sending ? null : () => _submit('confirmed'),
            icon: const Icon(Icons.report, size: 18),
            label: Text(strings.feedbackScam),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _sending ? null : () => _submit('false_positive'),
            icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
            label: Text(strings.feedbackFalse),
          ),
        ),
      ],
    );
  }
}
