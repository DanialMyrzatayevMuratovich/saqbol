import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../shared/app_theme.dart';
import '../../shared/verdict_style.dart';
import 'call_alert_screen.dart';
import 'voice_controller.dart';

/// Live call analysis: one big button, a risk ring with the real probability,
/// and a full-screen alert when the conversation looks like a scam.
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

  void _toggle(VoiceState state) {
    HapticFeedback.mediumImpact();
    final controller = ref.read(voiceControllerProvider.notifier);
    state.active ? controller.stop() : controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceControllerProvider);
    final strings = ref.watch(stringsProvider);
    final c = context.saq;
    final text = Theme.of(context).textTheme;

    ref.listen<VoiceState>(voiceControllerProvider, (previous, next) {
      if (next.alerted && !(previous?.alerted ?? false)) {
        Navigator.of(context).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => const CallAlertScreen()));
      }
    });

    final status = state.active ? (state.listening ? strings.listening : strings.sessionActive) : strings.sessionInactive;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, Gap.xl),
      children: [
        if (!state.active)
          Text(strings.callIntro, textAlign: TextAlign.center, style: text.bodyLarge?.copyWith(color: c.muted)),
        const SizedBox(height: Gap.xl),
        Center(child: _ListenButton(state: state, strings: strings, onTap: () => _toggle(state))),
        const SizedBox(height: Gap.l),
        Text(status, textAlign: TextAlign.center, style: text.titleMedium?.copyWith(color: state.active ? c.text : c.muted)),
        if (state.error != null) ...[
          const SizedBox(height: Gap.s),
          Text(state.error!, textAlign: TextAlign.center, style: TextStyle(color: c.scam)),
        ],
        if (state.triggers.isNotEmpty) ...[
          const SizedBox(height: Gap.xl),
          Text(strings.triggers, style: text.titleSmall?.copyWith(color: c.muted)),
          const SizedBox(height: Gap.s),
          Wrap(
            spacing: Gap.s,
            runSpacing: Gap.s,
            children: [
              for (final trigger in state.triggers)
                VerdictBadge(verdict: state.verdict, label: trigger),
            ],
          ),
        ],
        if (state.transcript.isNotEmpty) ...[
          const SizedBox(height: Gap.xl),
          Text(strings.transcript, style: text.titleSmall?.copyWith(color: c.muted)),
          const SizedBox(height: Gap.s),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Gap.l),
              child: Text(state.transcript, style: text.bodyLarge),
            ),
          ),
        ],
        if (state.active) ...[
          const SizedBox(height: Gap.xl),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              shape: const Border(),
              leading: Icon(Icons.keyboard_rounded, color: c.muted),
              title: Text(strings.manualFragment, style: text.bodyMedium),
              childrenPadding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.l),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _fragmentController,
                        onSubmitted: (_) => _sendFragment(),
                        decoration: const InputDecoration(isDense: true),
                      ),
                    ),
                    const SizedBox(width: Gap.s),
                    IconButton.filled(onPressed: _sendFragment, icon: const Icon(Icons.send_rounded)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A large round button. While a session runs, a ring around it shows the
/// current scam probability in the verdict colour, and it pulses gently.
class _ListenButton extends StatefulWidget {
  const _ListenButton({required this.state, required this.strings, required this.onTap});

  final VoiceState state;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  State<_ListenButton> createState() => _ListenButtonState();
}

class _ListenButtonState extends State<_ListenButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didUpdateWidget(_ListenButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.listening && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.state.listening && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final c = context.saq;
    final style = VerdictStyle.of(context, state.verdict);
    final active = state.active;
    final ringColor = active ? style.color : c.accent;
    final percent = (state.probability * 100).round();

    return Semantics(
      button: true,
      label: active ? widget.strings.stopListening : widget.strings.startListening,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) => Container(
            width: 232,
            height: 232,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.18 + 0.22 * _pulse.value),
                  blurRadius: 40 + 30 * _pulse.value,
                  spreadRadius: 2 + 6 * _pulse.value,
                ),
              ],
            ),
            child: child,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The percentage is read out by the label inside; the ring would
              // only add a bare number to the button's description.
              ExcludeSemantics(
                child: SizedBox(
                  width: 232,
                  height: 232,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: active ? state.probability : 0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: active ? value : 1,
                      strokeWidth: 12,
                      strokeCap: StrokeCap.round,
                      color: ringColor,
                      backgroundColor: c.surfaceRaised,
                    ),
                  ),
                ),
              ),
              Container(
                width: 184,
                height: 184,
                decoration: BoxDecoration(shape: BoxShape.circle, color: active ? c.surface : c.accent),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: active
                      ? [
                          Icon(style.icon, color: style.color, size: 34),
                          const SizedBox(height: Gap.xs),
                          Text('$percent%', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: style.color)),
                          Text(widget.strings.stopListening, style: TextStyle(color: c.muted, fontWeight: FontWeight.w600)),
                        ]
                      : [
                          Icon(Icons.mic_rounded, color: c.onAccent, size: 56),
                          const SizedBox(height: Gap.s),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: Gap.l),
                            child: Text(
                              widget.strings.startListening,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: c.onAccent, fontWeight: FontWeight.w700, fontSize: 16),
                            ),
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
}
