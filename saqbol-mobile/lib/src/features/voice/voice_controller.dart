import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/providers.dart';
import 'call_socket.dart';
import 'voice_models.dart';

class VoiceState {
  const VoiceState({
    this.active = false,
    this.listening = false,
    this.probability = 0,
    this.verdict = 'safe',
    this.category = '',
    this.advice = '',
    this.triggers = const [],
    this.alerted = false,
    this.transcript = '',
    this.error,
  });

  final bool active;
  final bool listening;
  final double probability;
  final String verdict;
  final String category;
  final String advice;
  final List<String> triggers;
  final bool alerted;
  final String transcript;
  final String? error;

  VoiceState copyWith({
    bool? active,
    bool? listening,
    double? probability,
    String? verdict,
    String? category,
    String? advice,
    List<String>? triggers,
    bool? alerted,
    String? transcript,
    String? error,
  }) {
    return VoiceState(
      active: active ?? this.active,
      listening: listening ?? this.listening,
      probability: probability ?? this.probability,
      verdict: verdict ?? this.verdict,
      category: category ?? this.category,
      advice: advice ?? this.advice,
      triggers: triggers ?? this.triggers,
      alerted: alerted ?? this.alerted,
      transcript: transcript ?? this.transcript,
      error: error,
    );
  }
}

class VoiceController extends Notifier<VoiceState> {
  final SpeechToText _speech = SpeechToText();
  CallSocket? _socket;

  @override
  VoiceState build() {
    ref.onDispose(() => _socket?.close());
    return const VoiceState();
  }

  Future<void> start() async {
    final token = await ref.read(tokenStorageProvider).readAccess();
    if (token == null) {
      state = state.copyWith(error: 'Нет активной сессии');
      return;
    }

    final config = ref.read(appConfigProvider);
    final socket = CallSocket(config.wsBaseUrl);
    _socket = socket;

    socket.connect(
      token: token,
      onAlert: _handleAlert,
      onClosed: _handleClosed,
    );

    state = const VoiceState(active: true);
    await _startListening();
  }

  Future<void> stop() async {
    await _speech.stop();
    await _socket?.close();
    _socket = null;
    state = state.copyWith(active: false, listening: false);
  }

  void sendManualFragment(String text) {
    if (!state.active || text.trim().isEmpty) return;
    _socket?.sendFragment(text);
    state = state.copyWith(transcript: _appendTranscript(text));
  }

  Future<void> _startListening() async {
    final available = await _speech.initialize(onStatus: _onSpeechStatus);
    if (!available) {
      state = state.copyWith(listening: false);
      return;
    }

    await _speech.listen(
      listenOptions: SpeechListenOptions(partialResults: true, localeId: 'ru_RU'),
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          _socket?.sendFragment(result.recognizedWords);
          state = state.copyWith(transcript: _appendTranscript(result.recognizedWords));
        }
      },
    );
    state = state.copyWith(listening: true);
  }

  void _onSpeechStatus(String status) {
    if (status == 'done' && state.active) {
      _startListening();
    }
  }

  void _handleAlert(CallAlert alert) {
    final becameAlert = alert.alert && !state.alerted;
    if (becameAlert) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    }
    state = state.copyWith(
      probability: alert.probability,
      verdict: alert.verdict,
      category: alert.category,
      advice: alert.advice,
      triggers: alert.triggers,
      alerted: state.alerted || alert.alert,
    );
  }

  void _handleClosed() {
    state = state.copyWith(active: false, listening: false);
  }

  String _appendTranscript(String fragment) {
    final current = state.transcript;
    return current.isEmpty ? fragment : '$current $fragment';
  }
}

final voiceControllerProvider =
    NotifierProvider<VoiceController, VoiceState>(VoiceController.new);
