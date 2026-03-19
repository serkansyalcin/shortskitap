import 'package:just_audio/just_audio.dart';

import '../api/api_client.dart';

class AutoVoiceoverService {
  final ApiClient _client = ApiClient.instance;
  final AudioPlayer _player = AudioPlayer();
  bool _enabled = false;
  bool _loading = false;

  bool get isEnabled => _enabled;
  bool get isLoading => _loading;
  bool get isPlaying => _player.playing;

  void toggle() => _enabled = !_enabled;

  void enable() => _enabled = true;

  void disable() {
    _enabled = false;
    _player.stop();
  }

  /// Fetches (or returns cached) TTS audio URL and plays it.
  /// [paragraphId] is the DB id of the paragraph.
  Future<bool> playParagraph(int bookId, int paragraphId) async {
    if (!_enabled) return false;

    _loading = true;
    try {
      await _player.stop();

      final res = await _client.get(
        '/books/$bookId/paragraphs/$paragraphId/audio',
      );

      final audioUrl = res.data['data']?['audio_url'] as String?;
      if (audioUrl == null || audioUrl.isEmpty) return false;

      await _player.setUrl(audioUrl);
      await _player.play();
      return true;
    } catch (_) {
      return false;
    } finally {
      _loading = false;
    }
  }

  Future<void> stop() async => _player.stop();

  void dispose() => _player.dispose();
}
