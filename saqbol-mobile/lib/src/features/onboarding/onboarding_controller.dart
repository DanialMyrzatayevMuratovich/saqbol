import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// True once the user has seen the onboarding and agreed that message text is
/// sent to the server for checking.
class OnboardingController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.read(onboardingStorageProvider).isDone();

  Future<void> finish() async {
    await ref.read(onboardingStorageProvider).markDone();
    state = const AsyncData(true);
  }
}

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, bool>(OnboardingController.new);
