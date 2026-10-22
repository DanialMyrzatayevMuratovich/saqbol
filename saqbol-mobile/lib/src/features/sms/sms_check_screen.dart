import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../shared/app_theme.dart';
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
  void initState() {
    super.initState();
    _textController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _textController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = data?.text?.trim() ?? '';
    if (pasted.isEmpty) return;
    HapticFeedback.selectionClick();
    _textController.text = pasted;
    _textController.selection = TextSelection.collapsed(offset: pasted.length);
  }

  void _clear() {
    _textController.clear();
    _senderController.clear();
    ref.read(smsControllerProvider.notifier).reset();
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    ref.read(smsControllerProvider.notifier).check(
          text: text,
          sourceNumber: _senderController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smsControllerProvider);
    final strings = ref.watch(stringsProvider);
    final c = context.saq;
    final text = Theme.of(context).textTheme;
    final hasText = _textController.text.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, Gap.xl),
      children: [
        Text(strings.checkIntro, style: text.bodyLarge?.copyWith(color: c.muted)),
        const SizedBox(height: Gap.l),
        TextField(
          controller: _textController,
          minLines: 5,
          maxLines: 10,
          style: text.bodyLarge,
          decoration: InputDecoration(hintText: strings.smsHint),
        ),
        const SizedBox(height: Gap.s),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _paste,
              icon: const Icon(Icons.content_paste_rounded, size: 20),
              label: Text(strings.paste),
            ),
            const Spacer(),
            if (hasText) TextButton(onPressed: _clear, child: Text(strings.clear)),
          ],
        ),
        const SizedBox(height: Gap.m),
        TextField(
          controller: _senderController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: strings.senderLabel,
            hintText: '+7...',
            prefixIcon: const Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: Gap.l),
        FilledButton.icon(
          onPressed: state.isLoading || !hasText ? null : _submit,
          icon: state.isLoading
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: c.onAccent))
              : const Icon(Icons.shield_rounded),
          label: Text(strings.checkButton),
        ),
        const SizedBox(height: Gap.xl),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: state.when(
            data: (result) => result == null
                ? const SizedBox.shrink()
                : VerdictCard(key: ValueKey(result.messageId + result.originalText), result: result),
            loading: () => const _ResultSkeleton(),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(Gap.l),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: c.scam),
                    const SizedBox(width: Gap.m),
                    Expanded(child: Text(error.toString(), style: text.bodyMedium)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultSkeleton extends StatelessWidget {
  const _ResultSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.saq;
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(8)),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(color: c.surfaceRaised, shape: BoxShape.circle)),
              const SizedBox(width: Gap.m),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [bar(140, 18), const SizedBox(height: Gap.s), bar(100, 12)]),
            ]),
            const SizedBox(height: Gap.xl),
            bar(double.infinity, 14),
            const SizedBox(height: Gap.s),
            bar(double.infinity, 14),
            const SizedBox(height: Gap.s),
            bar(180, 14),
          ],
        ),
      ),
    );
  }
}
