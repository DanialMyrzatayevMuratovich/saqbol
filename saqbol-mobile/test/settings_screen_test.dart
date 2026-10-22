import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saqbol_mobile/src/core/locale_storage.dart';
import 'package:saqbol_mobile/src/core/preferences_storage.dart';
import 'package:saqbol_mobile/src/core/providers.dart';
import 'package:saqbol_mobile/src/features/guard/guard_controller.dart';
import 'package:saqbol_mobile/src/features/settings/settings_screen.dart';
import 'package:saqbol_mobile/src/shared/app_theme.dart';
import 'package:saqbol_mobile/src/shared/theme_controller.dart';

class _FakeGuard extends GuardController {
  int callGuardRequests = 0;

  @override
  GuardState build() => const GuardState(watching: true);

  @override
  Future<void> refreshPermission() async {}

  @override
  Future<void> refreshCallGuard() async {}

  @override
  Future<void> enableCallGuard() async => callGuardRequests++;
}

class _MemoryThemeStorage implements ThemeStorage {
  String? name;

  @override
  Future<String?> read() async => name;

  @override
  Future<void> save(String mode) async => name = mode;
}

class _MemoryLocaleStorage implements LocaleStorage {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> save(String code) async {}
}

void main() {
  testWidgets('protection that is on shows a badge, protection that is off a button', (tester) async {
    final guard = _FakeGuard();
    final themeStorage = _MemoryThemeStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          guardControllerProvider.overrideWith(() => guard),
          themeStorageProvider.overrideWithValue(themeStorage),
          localeStorageProvider.overrideWithValue(_MemoryLocaleStorage()),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            themeMode: ref.watch(themeControllerProvider),
            home: const Scaffold(body: SettingsScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // SMS checks are on: a badge, and no switch that looks locked.
    expect(find.byType(Switch), findsNothing);
    expect(find.text('Включено'), findsOneWidget);

    // Call screening is off: one button turns it on.
    await tester.tap(find.widgetWithText(FilledButton, 'Включить'));
    expect(guard.callGuardRequests, 1);

    // The theme can be chosen right here, and the choice is kept.
    await tester.tap(find.text('Светлая'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(SettingsScreen))).brightness, Brightness.light);
    expect(themeStorage.name, 'light');
  });
}
