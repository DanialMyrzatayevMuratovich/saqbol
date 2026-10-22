import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../shared/app_theme.dart';
import 'voice_controller.dart';

/// The trigger phrases worth showing in the alert: longest first, without
/// words already inside a shown phrase ("bank" next to "bank security"), at
/// most [max], so the advice below stays on screen.
List<String> topAlertReasons(List<String> triggers, {int max = 4}) {
  final sorted = triggers.toSet().toList()..sort((a, b) => b.length.compareTo(a.length));
  final picked = <String>[];
  for (final trigger in sorted) {
    final lower = trigger.toLowerCase();
    if (picked.any((shown) => shown.toLowerCase().contains(lower))) continue;
    picked.add(trigger);
    if (picked.length == max) break;
  }
  return picked;
}

/// Full-screen warning shown the moment a live call crosses the scam threshold.
/// Always dark red, whatever the theme: it has to stop the user mid-call.
class CallAlertScreen extends ConsumerWidget {
  const CallAlertScreen({super.key});

  static const _background = Color(0xFF2A0B0E);
  static const _danger = Color(0xFFFF6B5E);
  static const _ink = Color(0xFFFFF1EF);
  static const _muted = Color(0xFFF2C4BE);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceControllerProvider);
    final strings = ref.watch(stringsProvider);
    final text = Theme.of(context).textTheme;
    final advice = strings.advice(state.category, state.advice);
    final percent = (state.probability * 100).round();
    final reasons = topAlertReasons(state.triggers);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Gap.xl),
              Center(
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _danger.withValues(alpha: 0.16),
                    boxShadow: [BoxShadow(color: _danger.withValues(alpha: 0.35), blurRadius: 60)],
                  ),
                  child: const Icon(Icons.gpp_bad_rounded, color: _danger, size: 76),
                ),
              ),
              const SizedBox(height: Gap.xl),
              Text(strings.alertTitle, textAlign: TextAlign.center, style: text.displaySmall?.copyWith(color: _ink)),
              const SizedBox(height: Gap.s),
              Text(
                [
                  strings.riskLabel(percent),
                  if (state.category.isNotEmpty) strings.categoryLabel(state.category),
                ].join(' · '),
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(color: _muted),
              ),
              const SizedBox(height: Gap.xl),
              Expanded(
                child: ListView(
                  children: [
                    if (reasons.isNotEmpty) ...[
                      Text(strings.alertReasons, style: text.titleMedium?.copyWith(color: _ink)),
                      const SizedBox(height: Gap.s),
                      for (final trigger in reasons)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Gap.s),
                          child: Row(
                            children: [
                              const Icon(Icons.error_rounded, color: _danger, size: 20),
                              const SizedBox(width: Gap.s),
                              Expanded(child: Text('«$trigger»', style: text.bodyLarge?.copyWith(color: _ink))),
                            ],
                          ),
                        ),
                      const SizedBox(height: Gap.l),
                    ],
                    Container(
                      padding: const EdgeInsets.all(Gap.l),
                      decoration: BoxDecoration(color: _danger.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(Radii.control)),
                      child: Text(
                        advice.isNotEmpty ? advice : strings.callScamWarning,
                        style: text.bodyLarge?.copyWith(color: _ink, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.l),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _danger, foregroundColor: _background),
                onPressed: () {
                  ref.read(voiceControllerProvider.notifier).stop();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.call_end_rounded),
                label: Text(strings.endAnalysis),
              ),
              const SizedBox(height: Gap.s),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  side: const BorderSide(color: _muted),
                  minimumSize: const Size.fromHeight(kButtonHeight),
                ),
                onPressed: () {
                  ref.read(voiceControllerProvider.notifier).dismissAlert();
                  Navigator.of(context).pop();
                },
                child: Text(strings.notScammer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
