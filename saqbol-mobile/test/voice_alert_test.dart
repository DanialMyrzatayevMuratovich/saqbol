import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saqbol_mobile/src/features/voice/voice_controller.dart';
import 'package:saqbol_mobile/src/features/voice/voice_models.dart';

CallAlert _alert({required bool alert, double probability = 0.9}) => CallAlert(
      verdict: alert ? 'scam' : 'safe',
      probability: probability,
      category: alert ? 'fake_bank' : '',
      triggers: alert ? const ['код из смс'] : const [],
      advice: '',
      alert: alert,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late VoiceController controller;

  setUp(() {
    container = ProviderContainer();
    controller = container.read(voiceControllerProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('a scam fragment raises the alert and it stays raised', () {
    controller.handleAlert(_alert(alert: true));
    expect(container.read(voiceControllerProvider).alerted, isTrue);

    controller.handleAlert(_alert(alert: false, probability: 0.2));
    final state = container.read(voiceControllerProvider);
    expect(state.alerted, isTrue);
    expect(state.probability, 0.2);
  });

  test('after “not a scammer” the same call does not alert again', () {
    controller.handleAlert(_alert(alert: true));
    controller.dismissAlert();
    expect(container.read(voiceControllerProvider).alerted, isFalse);

    controller.handleAlert(_alert(alert: true, probability: 0.95));
    final state = container.read(voiceControllerProvider);
    expect(state.alerted, isFalse);
    // The risk is still shown, only the full-screen alert is silenced.
    expect(state.probability, 0.95);
    expect(state.verdict, 'scam');
  });
}
