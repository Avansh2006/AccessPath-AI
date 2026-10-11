import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Abstraction for voice search input.
abstract class VoiceSearchService {
  Future<bool> isAvailable();
  Future<void> startListening({
    required void Function(String text) onResult,
    required void Function() onDone,
    required void Function(String error) onError,
  });
  Future<void> stopListening();
  bool get isListening;
}

/// Real implementation using speech_to_text package.
class SpeechToTextService implements VoiceSearchService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _listening = false;

  @override
  Future<bool> isAvailable() async {
    if (!_initialized) {
      _initialized = await _speech.initialize(
        onError: (error) {},
        onStatus: (status) {},
      );
    }
    return _initialized;
  }

  @override
  Future<void> startListening({
    required void Function(String text) onResult,
    required void Function() onDone,
    required void Function(String error) onError,
  }) async {
    final available = await isAvailable();
    if (!available) {
      onError('Speech recognition is not available on this device.');
      return;
    }

    _listening = true;
    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
          _listening = false;
          onDone();
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      ),
    );
  }

  @override
  Future<void> stopListening() async {
    _listening = false;
    await _speech.stop();
  }

  @override
  bool get isListening => _listening;
}

/// Mock fallback for development/testing.
class MockVoiceSearchService implements VoiceSearchService {
  bool _listening = false;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> startListening({
    required void Function(String text) onResult,
    required void Function() onDone,
    required void Function(String error) onError,
  }) async {
    onError('Voice search is not available in demo mode.');
  }

  @override
  Future<void> stopListening() async {
    _listening = false;
  }

  @override
  bool get isListening => _listening;
}
