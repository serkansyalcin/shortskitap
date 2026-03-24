import 'package:just_audio/just_audio.dart';

import '../api/api_client.dart';

class AutoVoiceoverService {
  final ApiClient _client = ApiClient.instance;
  final AudioPlayer _player1 = AudioPlayer();
  final AudioPlayer _player2 = AudioPlayer();
  bool _usePlayer1 = true;

  AudioPlayer get _currentPlayer => _usePlayer1 ? _player1 : _player2;
  AudioPlayer get _nextPlayer => _usePlayer1 ? _player2 : _player1;

  bool _enabled = false;
  bool _loading = false; // Is the _currentPlayer fetching its URL?

  int? _currentParagraphId;
  int? _nextPreloadedParagraphId;
  int? _fetchingParagraphId;

  bool get isEnabled => _enabled;
  bool get isLoading => _loading;
  bool get isPlaying => _player1.playing || _player2.playing;

  void toggle() => _enabled = !_enabled;

  void enable() => _enabled = true;

  void disable() {
    _enabled = false;
    stop();
  }

  /// Fetches (or returns cached) TTS audio URL and plays it.
  /// [paragraphId] is the DB id of the paragraph.
  Future<bool> playParagraph(int bookId, int paragraphId) async {
    if (!_enabled) return false;

    _currentParagraphId = paragraphId;

    // Is it already preloaded in the inactive player?
    if (_nextPreloadedParagraphId == paragraphId) {
      await _currentPlayer.stop();
      _usePlayer1 = !_usePlayer1; // Swap players
      _currentPlayer.play(); // Play instantly from the already buffered player
      _nextPreloadedParagraphId = null;
      return true;
    }

    // Standard cold fetch
    _loading = true;
    _fetchingParagraphId = paragraphId;
    try {
      await _currentPlayer.stop();
      await _nextPlayer.stop();

      final res = await _client.get(
        '/books/$bookId/paragraphs/$paragraphId/audio',
      );

      // Stop processing if user already swiped away
      if (_fetchingParagraphId != paragraphId) return false;

      final audioUrl = res.data['data']?['audio_url'] as String?;
      if (audioUrl == null || audioUrl.isEmpty) return false;

      await _currentPlayer.setUrl(audioUrl);
      
      // Stop processing if user swiped away while setUrl was buffering
      if (_fetchingParagraphId != paragraphId) return false;

      await _currentPlayer.play();
      return true;
    } catch (_) {
      return false;
    } finally {
      if (_fetchingParagraphId == paragraphId) {
        _loading = false;
        _fetchingParagraphId = null;
      }
    }
  }

  /// Preloads the audio for the next paragraph in the background.
  Future<void> preloadNextParagraph(int bookId, int paragraphId) async {
    if (!_enabled) return;
    if (_nextPreloadedParagraphId == paragraphId) return; // already buffering the right one
    if (_currentParagraphId == paragraphId || _fetchingParagraphId == paragraphId) return;

    _nextPreloadedParagraphId = paragraphId;
    try {
      final res = await _client.get('/books/$bookId/paragraphs/$paragraphId/audio');
      
      if (_nextPreloadedParagraphId != paragraphId) return;

      final audioUrl = res.data['data']?['audio_url'] as String?;
      if (audioUrl == null || audioUrl.isEmpty) return;
      
      // Buffer it into the inactive player
      await _nextPlayer.setUrl(audioUrl);
    } catch (_) {}
  }

  Future<void> stop() async {
    await _player1.stop();
    await _player2.stop();
    _currentParagraphId = null;
    _nextPreloadedParagraphId = null;
    _fetchingParagraphId = null;
    _loading = false;
  }

  void dispose() {
    _player1.dispose();
    _player2.dispose();
  }
}
