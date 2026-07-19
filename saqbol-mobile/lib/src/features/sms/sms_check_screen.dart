import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import 'sms_controller.dart';
import 'widgets/verdict_card.dart';

class SmsCheckScreen extends ConsumerStatefulWidget {
  const SmsCheckScreen({super.key});

  @override
  ConsumerState<SmsCheckScreen> createState() => _SmsCheckScreenState();
}

class _SmsCheckScreenState extends ConsumerState<SmsCheckScreen> {
  final _textController = TextEditingController();
  final _senderController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    ref.read(smsControllerProvider.notifier).check(
          text: text,
          sourceNumber: _senderController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smsControllerProvider);
    final strings = ref.watch(stringsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _textController,
          minLines: 4,
          maxLines: 8,
          decoration: InputDecoration(
            labelText: strings.smsTextLabel,
            hintText: strings.smsHint,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _senderController,
          decoration: InputDecoration(
            labelText: strings.senderLabel,
            hintText: '+7...',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: state.isLoading ? null : _submit,
          icon: state.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.shield_outlined),
          label: Text(strings.checkButton),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 20),
        state.when(
          data: (result) =>
              result == null ? const SizedBox.shrink() : VerdictCard(result: result),
          loading: () => const SizedBox.shrink(),
          error: (error, _) => Text(
            error.toString(),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
