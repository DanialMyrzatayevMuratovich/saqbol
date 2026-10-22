import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/strings.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/verdict_style.dart';
import '../sms_models.dart';
import 'highlighted_message.dart';

/// The verdict for one message: what it is, why, and what to do.
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
    HapticFeedback.selectionClick();
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
          SnackBar(content: Text(ref.read(stringsProvider).feedbackFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final strings = ref.watch(stringsProvider);
    final style = VerdictStyle.of(context, result.verdict);
    final c = context.saq;
    final text = Theme.of(context).textTheme;
    final advice = strings.advice(result.category, result.advice);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                VerdictAvatar(verdict: result.verdict, size: 56),
                const SizedBox(width: Gap.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(strings.verdictLabel(result.verdict), style: text.headlineSmall?.copyWith(color: style.color)),
                      const SizedBox(height: 2),
                      // Labelled as a risk, so 39% on a safe message is not read as “39% safe”.
                      Text(strings.riskLabel((result.probability * 100).round()), style: text.bodyMedium?.copyWith(color: c.muted)),
                    ],
                  ),
                ),
              ],
            ),
            if (result.category.isNotEmpty) ...[
              const SizedBox(height: Gap.m),
              VerdictBadge(verdict: result.verdict, label: strings.categoryLabel(result.category)),
            ],
            if (result.triggers.isNotEmpty) ...[
              const SizedBox(height: Gap.xl),
              Text(strings.whyTitle, style: text.titleSmall?.copyWith(color: c.muted)),
              const SizedBox(height: Gap.s),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(Radii.control)),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: c.text),
                  child: HighlightedMessage(text: result.originalText, triggers: result.triggers, highlightColor: style.color),
                ),
              ),
            ],
            if (advice.isNotEmpty) ...[
              const SizedBox(height: Gap.l),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: style.tint, borderRadius: BorderRadius.circular(Radii.control)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_rounded, color: style.color, size: 22),
                    const SizedBox(width: Gap.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.whatToDo, style: text.titleSmall?.copyWith(color: style.color)),
                          const SizedBox(height: Gap.xs),
                          Text(advice, style: text.bodyLarge),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: Gap.l),
            _feedbackSection(strings),
            if (result.modelVersion.isNotEmpty) ...[
              const SizedBox(height: Gap.m),
              Text(strings.modelVersion(result.modelVersion), style: text.bodySmall?.copyWith(fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _feedbackSection(AppStrings strings) {
    if (widget.result.messageId.isEmpty) return const SizedBox.shrink();
    final c = context.saq;
    if (_submittedFeedback != null) {
      return Row(
        children: [
          Icon(Icons.check_circle_rounded, color: c.safe, size: 20),
          const SizedBox(width: Gap.s),
          Text(strings.feedbackThanks, style: TextStyle(color: c.muted)),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _sending ? null : () => _submit('confirmed'),
            icon: Icon(Icons.report_rounded, size: 20, color: c.scam),
            label: Text(strings.feedbackScam, textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(width: Gap.s),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _sending ? null : () => _submit('false_positive'),
            icon: Icon(Icons.thumb_up_alt_rounded, size: 20, color: c.safe),
            label: Text(strings.feedbackFalse, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}
