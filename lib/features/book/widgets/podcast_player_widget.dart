import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/podcast_model.dart';

class PodcastSectionWidget extends StatefulWidget {
  final List<PodcastModel> podcasts;

  const PodcastSectionWidget({super.key, required this.podcasts});

  @override
  State<PodcastSectionWidget> createState() => _PodcastSectionWidgetState();
}

class _PodcastSectionWidgetState extends State<PodcastSectionWidget> {
  final AudioPlayer _player = AudioPlayer();
  int? _activeIndex;
  bool _isLoading = false;
  double _volume = 1;
  double _lastAudibleVolume = 1;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _initSession();
    _player.setVolume(_volume);
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() => _activeIndex = null);
      }
    });
  }

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _playPause(int index) async {
    final podcast = widget.podcasts[index];

    if (_activeIndex == index) {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
      return;
    }

    setState(() {
      _activeIndex = index;
      _isLoading = true;
    });

    try {
      await _player.stop();
      await _player.setUrl(podcast.audioUrl);
      await _player.play();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ses dosyası yüklenemedi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _stop() {
    _player.stop();
    setState(() => _activeIndex = null);
  }

  Future<void> _setVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    await _player.setVolume(clamped);
    if (!mounted) return;

    setState(() {
      _volume = clamped;
      if (clamped > 0) {
        _lastAudibleVolume = clamped;
      }
    });
  }

  Future<void> _toggleMute() async {
    if (_volume == 0) {
      await _setVolume(_lastAudibleVolume <= 0 ? 0.6 : _lastAudibleVolume);
      return;
    }

    _lastAudibleVolume = _volume;
    await _setVolume(0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.podcasts.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.podcasts_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Podcast',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '${widget.podcasts.length} bölüm',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Podcast list
        ...List.generate(widget.podcasts.length, (i) {
          final p = widget.podcasts[i];
          final isActive = _activeIndex == i;

          return _PodcastTile(
            podcast: p,
            isActive: isActive,
            isLoading: isActive && _isLoading,
            player: _player,
            volume: _volume,
            onTap: () => _playPause(i),
            onStop: _stop,
            onVolumeChanged: _setVolume,
            onMuteToggle: _toggleMute,
          );
        }),
      ],
    );
  }
}

class _PodcastTile extends StatefulWidget {
  final PodcastModel podcast;
  final bool isActive;
  final bool isLoading;
  final AudioPlayer player;
  final double volume;
  final VoidCallback onTap;
  final VoidCallback onStop;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onMuteToggle;

  const _PodcastTile({
    required this.podcast,
    required this.isActive,
    required this.isLoading,
    required this.player,
    required this.volume,
    required this.onTap,
    required this.onStop,
    required this.onVolumeChanged,
    required this.onMuteToggle,
  });

  @override
  State<_PodcastTile> createState() => _PodcastTileState();
}

class _PodcastTileState extends State<_PodcastTile> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.isActive
            ? (isDark
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.primary.withOpacity(0.06))
            : colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isActive
              ? AppColors.primary.withOpacity(0.35)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Play button
                  _PlayButton(
                    isActive: widget.isActive,
                    isLoading: widget.isLoading,
                    player: widget.player,
                    onTap: widget.onTap,
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.podcast.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.isActive
                                ? AppColors.primary
                                : colorScheme.onSurface,
                            height: 1.3,
                          ),
                        ),
                        if (widget.podcast.description != null &&
                            widget.podcast.description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.podcast.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (widget.podcast.durationSeconds != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 11,
                                color: colorScheme.onSurfaceVariant.withOpacity(
                                  0.7,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                widget.podcast.durationFormatted,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.7),
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Stop button if active
                  if (widget.isActive)
                    IconButton(
                      icon: Icon(
                        Icons.stop_rounded,
                        color: AppColors.primary.withOpacity(0.7),
                        size: 20,
                      ),
                      onPressed: widget.onStop,
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Progress bar (only when active)
          if (widget.isActive)
            StreamBuilder<Duration>(
              stream: widget.player.positionStream,
              builder: (context, snapshot) {
                return StreamBuilder<Duration?>(
                  stream: widget.player.durationStream,
                  builder: (context, durationSnap) {
                    final position = snapshot.data ?? Duration.zero;
                    final total = durationSnap.data ?? Duration.zero;

                    return _ProgressBar(
                      position: position,
                      total: total,
                      player: widget.player,
                      volume: widget.volume,
                      onVolumeChanged: widget.onVolumeChanged,
                      onMuteToggle: widget.onMuteToggle,
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool isActive;
  final bool isLoading;
  final AudioPlayer player;
  final VoidCallback onTap;

  const _PlayButton({
    required this.isActive,
    required this.isLoading,
    required this.player,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : AppColors.primary.withOpacity(0.12),
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: isLoading
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isActive ? Colors.white : AppColors.primary,
                ),
              )
            : StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  return Icon(
                    (isActive && playing)
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: isActive ? Colors.white : AppColors.primary,
                    size: 24,
                  );
                },
              ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final Duration position;
  final Duration total;
  final AudioPlayer player;
  final double volume;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onMuteToggle;

  const _ProgressBar({
    required this.position,
    required this.total,
    required this.player,
    required this.volume,
    required this.onVolumeChanged,
    required this.onMuteToggle,
  });

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = (total.inMilliseconds > 0)
        ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final volumeIcon = volume == 0
        ? Icons.volume_off_rounded
        : volume < 0.5
        ? Icons.volume_down_rounded
        : Icons.volume_up_rounded;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withOpacity(0.18),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.12),
            ),
            child: Slider(
              value: progress,
              onChanged: (v) {
                if (total.inMilliseconds > 0) {
                  player.seek(
                    Duration(milliseconds: (v * total.inMilliseconds).round()),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fmt(position),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  _fmt(total),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onMuteToggle,
                  icon: Icon(volumeIcon, size: 20),
                  color: volume == 0
                      ? colorScheme.onSurfaceVariant
                      : AppColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(
                      volume == 0 ? 0.08 : 0.14,
                    ),
                    minimumSize: const Size(38, 38),
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.volume_down_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.primary.withOpacity(0.18),
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withOpacity(0.12),
                    ),
                    child: Slider(value: volume, onChanged: onVolumeChanged),
                  ),
                ),
                Icon(
                  Icons.volume_up_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
