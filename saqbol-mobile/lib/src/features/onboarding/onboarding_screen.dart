import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../shared/app_theme.dart';
import '../../shared/brand.dart';
import '../../shared/locale_switcher.dart';
import 'onboarding_controller.dart';

/// Three steps: what SaqBol is, what it does, and consent to send message text
/// to the server. The last step cannot be skipped.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  bool _consent = false;

  static const _last = 2;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pages.animateToPage(page, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    await ref.read(onboardingControllerProvider.notifier).finish();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final c = context.saq;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.s, 0),
              child: Row(
                children: [
                  const SaqLogo(size: 28),
                  const SizedBox(width: Gap.s),
                  Text('SaqBol', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  const LocaleSwitcher(),
                  if (_page < _last)
                    TextButton(onPressed: () => _goTo(_last), child: Text(strings.onbSkip)),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _HeroPage(title: strings.onbTitle1, body: strings.onbBody1),
                  _FeaturesPage(strings: strings),
                  _ConsentPage(
                    strings: strings,
                    consent: _consent,
                    onChanged: (value) => setState(() => _consent = value),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.xl, 0, Gap.xl, Gap.xl),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i <= _last; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page ? c.accent : c.border,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Gap.xl),
                  FilledButton(
                    onPressed: _page < _last
                        ? () => _goTo(_page + 1)
                        : (_consent ? _finish : null),
                    child: Text(_page < _last ? strings.onbNext : strings.onbStart),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPage extends StatelessWidget {
  const _HeroPage({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.saq;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
      children: [
        const SizedBox(height: Gap.xl),
        Center(
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: c.accent.withValues(alpha: 0.28), blurRadius: 80, spreadRadius: 4)],
            ),
            child: const SaqHeroShield(size: 230),
          ),
        ),
        const SizedBox(height: Gap.xl),
        Text(title, textAlign: TextAlign.center, style: text.displaySmall),
        const SizedBox(height: Gap.m),
        Text(body, textAlign: TextAlign.center, style: text.bodyLarge?.copyWith(color: c.muted)),
      ],
    );
  }
}

class _FeaturesPage extends StatelessWidget {
  const _FeaturesPage({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final features = [
      (Icons.sms_rounded, strings.onbFeature1Title, strings.onbFeature1Body),
      (Icons.shield_rounded, strings.onbFeature2Title, strings.onbFeature2Body),
      (Icons.record_voice_over_rounded, strings.onbFeature3Title, strings.onbFeature3Body),
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
      children: [
        const SizedBox(height: Gap.xl),
        Text(strings.onbTitle2, style: text.displaySmall),
        const SizedBox(height: Gap.xl),
        for (final (icon, title, body) in features) ...[
          _FeatureRow(icon: icon, title: title, body: body),
          const SizedBox(height: Gap.l),
        ],
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.saq;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.l),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: c.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: c.accent),
            ),
            const SizedBox(width: Gap.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium),
                  const SizedBox(height: Gap.xs),
                  Text(body, style: text.bodyMedium?.copyWith(color: c.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentPage extends StatelessWidget {
  const _ConsentPage({required this.strings, required this.consent, required this.onChanged});

  final AppStrings strings;
  final bool consent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.saq;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
      children: [
        const SizedBox(height: Gap.xl),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: c.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
          child: Icon(Icons.lock_rounded, color: c.accent, size: 32),
        ),
        const SizedBox(height: Gap.xl),
        Text(strings.onbTitle3, style: text.displaySmall),
        const SizedBox(height: Gap.m),
        Text(strings.onbBody3, style: text.bodyLarge?.copyWith(color: c.muted)),
        const SizedBox(height: Gap.xl),
        Card(
          child: CheckboxListTile(
            value: consent,
            onChanged: (value) => onChanged(value ?? false),
            title: Text(strings.onbConsent, style: text.bodyLarge),
            controlAffinity: ListTileControlAffinity.leading,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card)),
            contentPadding: const EdgeInsets.symmetric(horizontal: Gap.s, vertical: Gap.xs),
          ),
        ),
      ],
    );
  }
}
