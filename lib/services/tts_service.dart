import 'package:flutter_tts/flutter_tts.dart';
import '../core/platform.dart';

/// flutter_tts 기반 — Android 시스템 en-US 목소리 사용.
///
/// 화자별 음성: 기기에 남/여 en-US 보이스가 있으면 voice 전환,
/// 없으면 피치(남 0.75 / 여 1.12)로 구분한다.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  String? _speaking;

  Map<String, String>? _maleVoice;
  Map<String, String>? _femaleVoice;
  bool _voicesScanned = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    if (isIOS) {
      // 무음 스위치가 켜져 있어도 재생되게, 다른 앱 소리는 잠시 줄이게
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.duckOthers,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        ],
        IosTextToSpeechAudioMode.spokenAudio,
      );
    }
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true); // 재생 패널이 턴을 순서대로 읽을 수 있게 speak 가 끝날 때까지 기다린다
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() => _speaking = null);
    _tts.setCancelHandler(() => _speaking = null);
    _tts.setErrorHandler((msg) => _speaking = null);
    _initialized = true;
  }

  Future<void> _scanVoices() async {
    if (_voicesScanned) return;
    _voicesScanned = true;
    try {
      final voices = await _tts.getVoices;
      if (voices is! List) return;
      for (final v in voices) {
        if (v is! Map) continue;
        final name = (v['name'] ?? '').toString();
        final locale = (v['locale'] ?? '').toString();
        if (!locale.toLowerCase().replaceAll('_', '-').startsWith('en-us')) continue;
        final lower = name.toLowerCase();
        final voice = {'name': name, 'locale': locale};
        if (_maleVoice == null && lower.contains('male') && !lower.contains('female')) {
          _maleVoice = voice;
        }
        if (_femaleVoice == null && lower.contains('female')) {
          _femaleVoice = voice;
        }
      }
    } catch (_) {}
  }

  bool isSpeaking(String text) => _speaking == text;

  Future<void> speak(String text) => _speakWith(text, null, 1.0);

  /// 화자 성별에 맞춰 읽기. gender: 'male' | 'female'
  Future<void> speakAs(String text, {required String gender, double? rate}) async {
    await _scanVoices();
    final male = gender == 'male';
    final voice = male ? _maleVoice : _femaleVoice;
    final pitch = voice != null ? 1.0 : (male ? 0.75 : 1.12);
    await _speakWith(text, voice, pitch, rate: rate);
  }

  Future<void> _speakWith(String text, Map<String, String>? voice, double pitch, {double? rate}) async {
    await _ensureInit();
    await _tts.stop();
    await _tts.setSpeechRate(rate ?? 0.45);
    if (voice != null) {
      await _tts.setVoice(voice);
    } else {
      await _tts.setLanguage('en-US');
    }
    await _tts.setPitch(pitch);
    _speaking = text;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _speaking = null;
  }
}
