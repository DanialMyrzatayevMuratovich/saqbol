import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saqbol_mobile/src/features/sms/widgets/highlighted_message.dart';
import 'package:saqbol_mobile/src/shared/app_theme.dart';
import 'package:saqbol_mobile/src/shared/verdict_style.dart';

/// WCAG 2 contrast ratio of two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

/// What the eye gets: [color] painted over [under].
Color _over(Color color, Color under) => Color.alphaBlend(color, under);

const _verdicts = ['scam', 'suspicious', 'safe'];

void main() {
  test('the check reproduces the reported 4.195:1 of the old light scam badge', () {
    const oldScam = Color(0xFFC9372A);
    final oldTint = _over(oldScam.withValues(alpha: 0.14), Colors.white);
    expect(_contrast(oldScam, oldTint), closeTo(4.195, 0.005));
  });

  for (final brightness in Brightness.values) {
    final c = brightness == Brightness.dark ? SaqColors.dark : SaqColors.light;

    testWidgets('${brightness.name} theme: verdict badges keep 4.5:1 on a card and on the page', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(brightness),
        home: Scaffold(
          body: Column(children: [
            for (final verdict in _verdicts) VerdictBadge(verdict: verdict, label: verdict),
          ]),
        ),
      ));

      for (final verdict in _verdicts) {
        final badge = find.widgetWithText(VerdictBadge, verdict);
        final background = (tester.widget<Container>(find.descendant(of: badge, matching: find.byType(Container))).decoration! as BoxDecoration).color!;
        final foreground = tester.widget<Text>(find.descendant(of: badge, matching: find.byType(Text))).style!.color!;

        for (final under in [c.surface, c.background]) {
          final ratio = _contrast(_over(foreground, under), _over(background, under));
          expect(ratio, greaterThanOrEqualTo(4.5), reason: '$verdict badge on ${under.toARGB32().toRadixString(16)}: ${ratio.toStringAsFixed(2)}:1');
        }
      }
    });

    testWidgets('${brightness.name} theme: verdict colour on its tint keeps 4.5:1 (advice title)', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(brightness),
        home: Builder(builder: (ctx) {
          context = ctx;
          return const SizedBox();
        }),
      ));

      for (final verdict in _verdicts) {
        final style = VerdictStyle.of(context, verdict);
        expect(style.tint.a, 1.0, reason: 'the tint is opaque, so the page under it does not matter');
        final ratio = _contrast(style.color, style.tint);
        expect(ratio, greaterThanOrEqualTo(4.5), reason: '$verdict: ${ratio.toStringAsFixed(2)}:1');
      }
    });

    testWidgets('${brightness.name} theme: highlighted trigger words keep 4.5:1', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(brightness),
        home: Scaffold(
          body: Column(children: [
            for (final verdict in _verdicts)
              Builder(
                builder: (context) => DefaultTextStyle.merge(
                  // As in VerdictCard: normal text colour on surfaceRaised.
                  style: TextStyle(color: c.text),
                  child: HighlightedMessage(
                    text: 'назовите код из смс',
                    triggers: const ['код из смс'],
                    highlightColor: VerdictStyle.of(context, verdict).color,
                  ),
                ),
              ),
          ]),
        ),
      ));

      var checked = 0;
      for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
        final root = richText.text as TextSpan;
        root.visitChildren((span) {
          final style = (span as TextSpan).style;
          if (style?.backgroundColor == null) return true;
          final text = style!.color ?? root.style!.color!;
          final ratio = _contrast(_over(text, c.surfaceRaised), _over(style.backgroundColor!, c.surfaceRaised));
          expect(ratio, greaterThanOrEqualTo(4.5), reason: '${ratio.toStringAsFixed(2)}:1');
          checked++;
          return true;
        });
      }
      expect(checked, _verdicts.length);
    });
  }
}
