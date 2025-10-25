import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _stt = stt.SpeechToText();

  Future<bool> init() async => await _stt.initialize();

  Future<void> start(void Function(String) onResult,
      {String fallback = 'es-ES'}) async {
    String? localeId = fallback;
    try {
      final locales = await _stt.locales();
      final es = locales.firstWhere(
        (l) => l.localeId.toLowerCase().startsWith('es'),
        orElse: () => locales.isNotEmpty
            ? locales.first
            : stt.LocaleName(fallback, 'Spanish'),
      );
      localeId = es.localeId;
    } catch (_) {
      // usa fallback
    }
    await _stt.listen(
      onResult: (r) => onResult(r.recognizedWords),
      localeId: localeId,
    );
  }

  Future<void> stop() async => _stt.stop();
}
