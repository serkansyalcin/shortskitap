import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../models/paragraph_model.dart';

class AutoVoiceoverService {
  final AudioPlayer _player1 = AudioPlayer();
  final AudioPlayer _player2 = AudioPlayer();
  bool _usePlayer1 = true;
  final StreamController<int> _paragraphCompletedController =
      StreamController<int>.broadcast();
  late final StreamSubscription<PlayerState> _player1StateSubscription;
  late final StreamSubscription<PlayerState> _player2StateSubscription;
  late final StreamSubscription<Duration> _player1PositionSubscription;
  late final StreamSubscription<Duration> _player2PositionSubscription;

  AudioPlayer get _currentPlayer => _usePlayer1 ? _player1 : _player2;
  AudioPlayer get _nextPlayer => _usePlayer1 ? _player2 : _player1;

  bool _enabled = false;
  bool _loading = false; // Is the _currentPlayer fetching its URL?

  int? _currentParagraphId;
  int? _nextPreloadedParagraphId;
  String? _nextPreloadedAudioSource;
  int _playRequestVersion = 0;
  int _preloadRequestVersion = 0;

  /// Which paragraph's audio is associated with each player (for completion events).
  /// Must not rely on [_currentParagraphId] alone: it is updated at the start of
  /// [playParagraph] before the previous player is stopped, so stale completions
  /// would otherwise report the wrong id.
  int? _player1ParagraphId;
  int? _player2ParagraphId;

  AutoVoiceoverService() {
    _player1StateSubscription = _player1.playerStateStream.listen(
      (state) => _handlePlayerStateChanged(_player1, state),
    );
    _player2StateSubscription = _player2.playerStateStream.listen(
      (state) => _handlePlayerStateChanged(_player2, state),
    );
    // Fallback: on some Android builds, natural end-of-track does not always emit
    // [ProcessingState.completed]. Advancing the reader then never runs.
    _player1PositionSubscription = _player1.positionStream.listen(
      (_) => _checkEndByPosition(_player1),
    );
    _player2PositionSubscription = _player2.positionStream.listen(
      (_) => _checkEndByPosition(_player2),
    );
  }

  bool get isEnabled => _enabled;
  bool get isLoading => _loading;
  bool get isPlaying => _player1.playing || _player2.playing;
  Stream<int> get paragraphCompletedStream =>
      _paragraphCompletedController.stream;

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
      await _stopPlayerForReuse(activePlayer);
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
      await _stopPlayerForReuse(activePlayer);
      await _stopPlayerForReuse(standbyPlayer);
      _clearPreloadedState();
      await _applyParagraphSource(activePlayer, paragraph);
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
      await _stopPlayerForReuse(preloadPlayer);
      if (_preloadRequestVersion != requestVersion) return;
      await _applyParagraphSource(preloadPlayer, paragraph);
      if (_preloadRequestVersion != requestVersion) return;
      if (_currentParagraphId == paragraph.id) return;
      _nextPreloadedParagraphId = paragraph.id;
      _nextPreloadedAudioSource = paragraph.preferredAudioSource;
    } catch (_) {}
  }

  Future<void> stop() async {
    _playRequestVersion++;
    _preloadRequestVersion++;
    await _stopPlayerForReuse(_player1);
    await _stopPlayerForReuse(_player2);
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
    unawaited(_player1StateSubscription.cancel());
    unawaited(_player2StateSubscription.cancel());
    unawaited(_player1PositionSubscription.cancel());
    unawaited(_player2PositionSubscription.cancel());
    unawaited(_paragraphCompletedController.close());
    unawaited(_player1.dispose());
    unawaited(_player2.dispose());
  }

  void _handlePlayerStateChanged(AudioPlayer player, PlayerState state) {
    if (state.processingState == ProcessingState.completed) {
      _emitParagraphCompleted(player);
    }
  }

  /// Detect end-of-track when [ProcessingState.completed] is missing (platform quirk).
  void _checkEndByPosition(AudioPlayer player) {
    if (_paragraphIdForPlayer(player) == null) return;
    final duration = player.duration;
    if (duration == null || duration.inMilliseconds <= 0) return;
    final position = player.position;
    // Normal path: playback stopped and we're at (or past) the end.
    if (!player.playing && position + _kEndOfTrackSlack >= duration) {
      _emitParagraphCompleted(player);
      return;
    }
    // Some Android/ExoPlayer builds report [playing] == true at the last frames and
    // never emit [ProcessingState.completed]; only advance when timeline is essentially done.
    if (player.playing && position + _kStuckPlayingEndSlack >= duration) {
      _emitParagraphCompleted(player);
    }
  }

  static const Duration _kEndOfTrackSlack = Duration(milliseconds: 80);
  static const Duration _kStuckPlayingEndSlack = Duration(milliseconds: 12);

  void _emitParagraphCompleted(AudioPlayer player) {
    final paragraphId = _paragraphIdForPlayer(player);
    if (paragraphId == null || _paragraphCompletedController.isClosed) return;
    _setParagraphIdForPlayer(player, null);
    _paragraphCompletedController.add(paragraphId);
  }

  int? _paragraphIdForPlayer(AudioPlayer player) {
    return identical(player, _player1) ? _player1ParagraphId : _player2ParagraphId;
  }

  void _setParagraphIdForPlayer(AudioPlayer player, int? id) {
    if (identical(player, _player1)) {
      _player1ParagraphId = id;
    } else {
      _player2ParagraphId = id;
    }
  }

  Future<void> _stopPlayerForReuse(AudioPlayer player) async {
    _setParagraphIdForPlayer(player, null);
    await player.stop();
  }

  Future<void> _applyParagraphSource(
    AudioPlayer player,
    ParagraphModel paragraph,
  ) async {
    await _setPlayerSource(player, paragraph);
    _setParagraphIdForPlayer(player, paragraph.id);
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
