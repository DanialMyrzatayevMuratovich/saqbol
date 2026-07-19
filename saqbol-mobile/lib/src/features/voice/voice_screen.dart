import 'package:flutter/material.dart';

import '../../shared/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../shared/verdict_style.dart';
import 'voice_controller.dart';

class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen> {
  final _fragmentController = TextEditingController();

  @override
  void dispose() {
    _fragmentController.dispose();
    super.dispose();
  }

  void _sendFragment() {
    final text = _fragmentController.text.trim();
    if (text.isEmpty) return;
    ref.read(voiceControllerProvider.notifier).sendManualFragment(text);
    _fragmentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceControllerProvider);
    final controller = ref.read(voiceControllerProvider.notifier);
    final strings = ref.watch(stringsProvider);
    final style = VerdictStyle.of(state.verdict);
    final percent = (state.probability * 100).round();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.alerted)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.scam,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.gpp_bad, color: AppColors.foreground),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Возможно мошенник! Не диктуйте коды и не переводите деньги.',
                    style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        Center(
          child: Column(
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: style.color.withValues(alpha: 0.12),
                  border: Border.all(color: style.color, width: 3),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(style.icon, color: style.color, size: 44),
                    const SizedBox(height: 8),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: style.color,
                      ),
                    ),
                    Text(style.label, style: TextStyle(color: style.color)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                state.active
                    ? (state.listening ? strings.listening : strings.sessionActive)
                    : strings.sessionInactive,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => state.active ? controller.stop() : controller.start(),
          icon: Icon(state.active ? Icons.stop : Icons.mic),
          label: Text(state.active ? strings.stopListening : strings.startListening),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: state.active ? AppColors.scam : null,
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 10),
          Text(state.error!, style: const TextStyle(color: AppColors.scam)),
        ],
        if (state.triggers.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Триггеры', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.triggers
                .map((trigger) => Chip(
                      label: Text(trigger),
                      backgroundColor: style.color.withValues(alpha: 0.12),
                    ))
                .toList(),
          ),
        ],
        if (state.transcript.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Транскрипт', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(state.transcript),
          ),
        ],
        if (state.active) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fragmentController,
                  decoration: const InputDecoration(
                    labelText: 'Фрагмент вручную (демо)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _sendFragment(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sendFragment,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
