import 'package:just_audio/just_audio.dart';

import '../models/paragraph_model.dart';

class AutoVoiceoverService {
  final AudioPlayer _player1 = AudioPlayer();
  final AudioPlayer _player2 = AudioPlayer();
  bool _usePlayer1 = true;

  AudioPlayer get _currentPlayer => _usePlayer1 ? _player1 : _player2;
  AudioPlayer get _nextPlayer => _usePlayer1 ? _player2 : _player1;

  bool _enabled = false;
  bool _loading = false; // Is the _currentPlayer fetching its URL?

  int? _currentParagraphId;
  int? _nextPreloadedParagraphId;
  String? _nextPreloadedAudioUrl;

  bool get isEnabled => _enabled;
  bool get isLoading => _loading;
  bool get isPlaying => _player1.playing || _player2.playing;

  void toggle() => _enabled = !_enabled;

  void enable() => _enabled = true;

  void disable() {
    _enabled = false;
    stop();
  }

  Future<bool> playParagraph(ParagraphModel paragraph) async {
    if (!_enabled) return false;
    if (!paragraph.hasAudio) return false;

    _currentParagraphId = paragraph.id;
    final audioUrl = paragraph.audioUrl!;

    if (_nextPreloadedParagraphId == paragraph.id &&
        _nextPreloadedAudioUrl == audioUrl) {
      await _currentPlayer.stop();
      _usePlayer1 = !_usePlayer1;
      await _currentPlayer.play();
      _nextPreloadedParagraphId = null;
      _nextPreloadedAudioUrl = null;
      return true;
    }

    _loading = true;
    try {
      await _currentPlayer.stop();
      await _nextPlayer.stop();
      await _currentPlayer.setUrl(audioUrl);
      if (_currentParagraphId != paragraph.id) return false;

      await _currentPlayer.play();
      return true;
    } catch (_) {
      return false;
    } finally {
      _loading = false;
    }
  }

  Future<void> preloadNextParagraph(ParagraphModel paragraph) async {
    if (!_enabled) return;
    if (!paragraph.hasAudio) return;
    if (_nextPreloadedParagraphId == paragraph.id &&
        _nextPreloadedAudioUrl == paragraph.audioUrl) {
      return;
    }
    if (_currentParagraphId == paragraph.id) return;

    _nextPreloadedParagraphId = paragraph.id;
    _nextPreloadedAudioUrl = paragraph.audioUrl;
    try {
      await _nextPlayer.stop();
      await _nextPlayer.setUrl(paragraph.audioUrl!);
    } catch (_) {}
  }

  Future<void> stop() async {
    await _player1.stop();
    await _player2.stop();
    _currentParagraphId = null;
    _nextPreloadedParagraphId = null;
    _nextPreloadedAudioUrl = null;
    _loading = false;
  }

  void dispose() {
    _player1.dispose();
    _player2.dispose();
  }
}
