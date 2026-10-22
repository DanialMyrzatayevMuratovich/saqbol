import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saqbol_mobile/src/core/credentials_storage.dart';
import 'package:saqbol_mobile/src/core/locale_storage.dart';
import 'package:saqbol_mobile/src/core/providers.dart';
import 'package:saqbol_mobile/src/features/auth/auth_controller.dart';
import 'package:saqbol_mobile/src/features/auth/login_screen.dart';

class _MemoryCredentials implements CredentialsStorage {
  SavedCredentials? saved;

  @override
  Future<SavedCredentials?> read() async => saved;

  @override
  Future<void> save(String phone, String password) async => saved = SavedCredentials(phone, password);

  @override
  Future<void> clear() async => saved = null;
}

class _MemoryLocale implements LocaleStorage {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> save(String code) async {}
}

/// Accepts only "secret123", like a backend with one user.
class _FakeAuth extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);

  @override
  Future<void> login(String phone, String password) async {
    state = password == 'secret123'
        ? const AuthState(status: AuthStatus.authenticated)
        : const AuthState(status: AuthStatus.unauthenticated, error: 'invalid phone or password');
  }
}

Widget _app(_MemoryCredentials credentials) {
  return ProviderScope(
    overrides: [
      credentialsStorageProvider.overrideWithValue(credentials),
      localeStorageProvider.overrideWithValue(_MemoryLocale()),
      authControllerProvider.overrideWith(_FakeAuth.new),
    ],
    child: const MaterialApp(home: LoginScreen()),
  );
}

Future<void> _fillAndSubmit(WidgetTester tester, {required String password, required bool remember}) async {
  await tester.enterText(find.widgetWithText(TextField, 'Телефон'), '+77000000001');
  await tester.enterText(find.widgetWithText(TextField, 'Пароль'), password);
  if (remember) await tester.tap(find.byType(CheckboxListTile));
  await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
  await tester.pumpAndSettle();
}

bool _ticked(WidgetTester tester) => tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value ?? false;

void main() {
  testWidgets('opting in saves the login after it succeeds', (tester) async {
    final credentials = _MemoryCredentials();
    await tester.pumpWidget(_app(credentials));
    await tester.pumpAndSettle();

    await _fillAndSubmit(tester, password: 'secret123', remember: true);

    expect(credentials.saved?.phone, '+77000000001');
    expect(credentials.saved?.password, 'secret123');
  });

  testWidgets('a failed login saves nothing', (tester) async {
    final credentials = _MemoryCredentials();
    await tester.pumpWidget(_app(credentials));
    await tester.pumpAndSettle();

    await _fillAndSubmit(tester, password: 'wrong-pass', remember: true);

    expect(credentials.saved, isNull);
  });

  testWidgets('unticking deletes the saved login at once, and reopening starts empty', (tester) async {
    final credentials = _MemoryCredentials()..saved = const SavedCredentials('+77000000001', 'secret123');
    await tester.pumpWidget(_app(credentials));
    await tester.pumpAndSettle();
    expect(_ticked(tester), isTrue);
    expect(find.text('+77000000001'), findsOneWidget);

    // No login after unticking: the app could be closed right here.
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(credentials.saved, isNull);

    // Reopen the screen from scratch.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app(credentials));
    await tester.pumpAndSettle();
    expect(_ticked(tester), isFalse);
    expect(find.text('+77000000001'), findsNothing);
  });
}
