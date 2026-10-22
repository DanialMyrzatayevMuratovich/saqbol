import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saqbol_mobile/src/core/locale_storage.dart';
import 'package:saqbol_mobile/src/core/providers.dart';
import 'package:saqbol_mobile/src/core/strings.dart';
import 'package:saqbol_mobile/src/shared/locale_switcher.dart';

class _MemoryLocaleStorage implements LocaleStorage {
  _MemoryLocaleStorage([this.code]);

  String? code;

  @override
  Future<String?> read() async => code;

  @override
  Future<void> save(String value) async => code = value;
}

Widget _app(_MemoryLocaleStorage storage) {
  return ProviderScope(
    overrides: [localeStorageProvider.overrideWithValue(storage)],
    child: MaterialApp(
      home: Scaffold(
        appBar: AppBar(actions: const [LocaleSwitcher()]),
        body: Consumer(
          builder: (context, ref, _) => Text(ref.watch(stringsProvider).login),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('offers three languages and switches the interface', (tester) async {
    final storage = _MemoryLocaleStorage();
    await tester.pumpWidget(_app(storage));
    await tester.pumpAndSettle();

    expect(find.text('Войти'), findsOneWidget);
    expect(find.text('РУС'), findsOneWidget);

    await tester.tap(find.byType(LocaleSwitcher));
    await tester.pumpAndSettle();

    expect(find.text('Русский'), findsOneWidget);
    expect(find.text('Қазақша'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('ENG'), findsOneWidget);
    expect(storage.code, 'en');

    await tester.tap(find.byType(LocaleSwitcher));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Қазақша'));
    await tester.pumpAndSettle();

    expect(find.text('Кіру'), findsOneWidget);
    expect(storage.code, 'kk');
  });

  testWidgets('starts in the language chosen last time', (tester) async {
    await tester.pumpWidget(_app(_MemoryLocaleStorage('en')));
    await tester.pumpAndSettle();

    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('ENG'), findsOneWidget);
  });
}
