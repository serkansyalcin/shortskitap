import 'dart:async';

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
  String? _nextPreloadedAudioSource;
  int _playRequestVersion = 0;
  int _preloadRequestVersion = 0;

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

    final requestVersion = ++_playRequestVersion;
    _preloadRequestVersion++;
    _currentParagraphId = paragraph.id;
    final audioSource = paragraph.preferredAudioSource!;
    final activePlayer = _currentPlayer;
    final standbyPlayer = _nextPlayer;

    if (_nextPreloadedParagraphId == paragraph.id &&
        _nextPreloadedAudioSource == audioSource) {
      await activePlayer.stop();
      if (!_isLatestPlayRequest(requestVersion, paragraph.id)) return false;
      _usePlayer1 = !_usePlayer1;
      await standbyPlayer.seek(Duration.zero);
      if (!_isLatestPlayRequest(requestVersion, paragraph.id)) return false;
      unawaited(standbyPlayer.play());
      _clearPreloadedState();
      return true;
    }

    _loading = true;
    try {
      await activePlayer.stop();
      await standbyPlayer.stop();
      _clearPreloadedState();
      await _setPlayerSource(activePlayer, paragraph);
      if (!_isLatestPlayRequest(requestVersion, paragraph.id)) return false;

      await activePlayer.seek(Duration.zero);
      if (!_isLatestPlayRequest(requestVersion, paragraph.id)) return false;
      unawaited(activePlayer.play());
      return true;
    } catch (_) {
      return false;
    } finally {
      if (_playRequestVersion == requestVersion) {
        _loading = false;
      }
    }
  }

  Future<void> preloadNextParagraph(ParagraphModel paragraph) async {
    if (!_enabled) return;
    if (!paragraph.hasAudio) return;
    if (_nextPreloadedParagraphId == paragraph.id &&
        _nextPreloadedAudioSource == paragraph.preferredAudioSource) {
      return;
    }
    if (_currentParagraphId == paragraph.id) return;

    final requestVersion = ++_preloadRequestVersion;
    final preloadPlayer = _nextPlayer;
    _clearPreloadedState();
    try {
      await preloadPlayer.stop();
      if (_preloadRequestVersion != requestVersion) return;
      await _setPlayerSource(preloadPlayer, paragraph);
      if (_preloadRequestVersion != requestVersion) return;
      if (_currentParagraphId == paragraph.id) return;
      _nextPreloadedParagraphId = paragraph.id;
      _nextPreloadedAudioSource = paragraph.preferredAudioSource;
    } catch (_) {}
  }

  Future<void> stop() async {
    _playRequestVersion++;
    _preloadRequestVersion++;
    await _player1.stop();
    await _player2.stop();
    _currentParagraphId = null;
    _clearPreloadedState();
    _loading = false;
  }

  bool _isLatestPlayRequest(int requestVersion, int paragraphId) {
    return _playRequestVersion == requestVersion &&
        _currentParagraphId == paragraphId;
  }

  void _clearPreloadedState() {
    _nextPreloadedParagraphId = null;
    _nextPreloadedAudioSource = null;
  }

  void dispose() {
    _player1.dispose();
    _player2.dispose();
  }

  Future<void> _setPlayerSource(
    AudioPlayer player,
    ParagraphModel paragraph,
  ) async {
    if (paragraph.prefersLocalAudio) {
      await player.setFilePath(paragraph.localAudioPath!);
      return;
    }
    await player.setUrl(paragraph.audioUrl!);
  }
}
