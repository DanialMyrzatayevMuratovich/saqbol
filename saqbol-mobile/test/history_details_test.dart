import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:saqbol_mobile/src/core/strings.dart';
import 'package:saqbol_mobile/src/features/history/history_models.dart';
import 'package:saqbol_mobile/src/features/history/history_tile.dart';
import 'package:saqbol_mobile/src/shared/app_theme.dart';

void main() {
  testWidgets('a 4,000-character message scrolls in the details at double text size on a small phone', (tester) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2; // 360 x 640
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    // The longest text the backend accepts for one check.
    final longText = ('Служба безопасности банка: назовите код из смс. ' * 100).substring(0, 4000);
    final createdAt = DateTime(2026, 10, 20, 12, 30);
    final item = HistoryItem(
      id: '1',
      channel: 'sms',
      text: longText,
      sourceNumber: '+77000000000',
      probability: 0.94,
      verdict: 'scam',
      category: 'fake_bank',
      createdAt: createdAt,
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [stringsProvider.overrideWithValue(const AppStrings(AppLocale.ru))],
      child: MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(body: ListView(children: [HistoryTile(item: item)])),
      ),
    ));
    expect(MediaQuery.textScalerOf(tester.element(find.byType(HistoryTile))).scale(10), 20);

    await tester.tap(find.byType(HistoryTile));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final sheet = find.byType(BottomSheet);
    expect(find.descendant(of: sheet, matching: find.text(longText)), findsOneWidget);

    // The end of the sheet is reachable by scrolling, and nothing overflowed.
    final date = find.text(DateFormat('dd.MM.yyyy HH:mm').format(createdAt.toLocal()));
    await tester.scrollUntilVisible(
      date,
      300,
      scrollable: find.descendant(of: sheet, matching: find.byType(Scrollable)),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getBottomLeft(date).dy, lessThanOrEqualTo(640));
  });
}
