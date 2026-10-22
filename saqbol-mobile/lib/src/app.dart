import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/history/history_providers.dart';
import 'features/home/home_screen.dart';
import 'features/home/shell_tab.dart';
import 'features/onboarding/onboarding_controller.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/sms/sms_controller.dart';
import 'features/voice/voice_controller.dart';
import 'shared/app_theme.dart';
import 'shared/brand.dart';
import 'shared/theme_controller.dart';

class SaqBolApp extends ConsumerWidget {
  const SaqBolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'SaqBol',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ref.watch(themeControllerProvider),
      home: const _Gate(),
    );
  }
}

/// Onboarding (with the consent to send text for checking) comes first, then
/// login, then the app.
class _Gate extends ConsumerWidget {
  const _Gate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final wasIn = previous?.status == AuthStatus.authenticated;
      final isIn = next.status == AuthStatus.authenticated;
      // Stop listening to a call the moment the session ends.
      if (wasIn && !isIn) ref.invalidate(voiceControllerProvider);
      // Every login starts clean: nothing from the previous account. Doing it
      // on logout instead would refetch the history without a token while
      // Home is still on screen, and keep that error.
      if (!wasIn && isIn) {
        ref.invalidate(historyProvider);
        ref.invalidate(smsControllerProvider);
        ref.invalidate(shellTabProvider);
      }
    });

    final onboarded = ref.watch(onboardingControllerProvider);
    if (!onboarded.hasValue) return const _Splash();
    if (onboarded.value != true) return const OnboardingScreen();

    switch (ref.watch(authControllerProvider).status) {
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.unknown:
        return const _Splash();
    }
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.saq.background,
      body: const Center(child: SaqLogo(size: 72)),
    );
  }
}
