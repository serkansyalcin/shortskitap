import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers/books_provider.dart';
import '../../../app/providers/progress_provider.dart';
import '../../../app/providers/settings_provider.dart';
import '../../../app/providers/subscription_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/platform/platform_support.dart';
import '../../../features/subscription/widgets/ad_banner.dart';
import '../widgets/paragraph_card.dart';

const _adEveryN = 5;

class ReaderScreen extends ConsumerStatefulWidget {
  final int bookId;
  final bool bookIsPremium;

  const ReaderScreen({
    super.key,
    required this.bookId,
    this.bookIsPremium = false,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _debounce;
  Timer? _sessionTimer;
  int _sessionSeconds = 0;
  bool _showControls = true;
  Timer? _controlsTimer;
  String? _readerThemeOverride;
  double? _readerFontSizeOverride;


  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    if (PlatformSupport.supportsImmersiveUi) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sessionSeconds++;
    });

    _startControlsTimer();
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _debounce?.cancel();
    _sessionTimer?.cancel();
    _controlsTimer?.cancel();
    if (PlatformSupport.supportsImmersiveUi) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _showControlsTemporarily();

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref
          .read(progressSyncProvider.notifier)
          .sync(widget.bookId, index + 1, _sessionSeconds);
      _sessionSeconds = 0;
    });
  }

  void _showControlsTemporarily() {
    setState(() => _showControls = true);
    _startControlsTimer();
  }

  void _goNext(int total) {
    if (_currentIndex < total - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paragraphsAsync = ref.watch(paragraphsProvider(widget.bookId));
    final settings = ref.watch(settingsProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final readerTheme = _readerThemeOverride ?? settings.theme;
    final readerFontSize =
        _readerFontSizeOverride ?? settings.fontSize.toDouble();
    final palette = _paletteForTheme(readerTheme);

    if (widget.bookIsPremium && !isPremium) {
      return _PremiumGateScreen(
        onUpgrade: () => context.push('/premium'),
        onBack: () => context.pop(),
      );
    }

    return GestureDetector(
      onTap: _showControlsTemporarily,
      child: Scaffold(
        backgroundColor: palette.background,
        body: paragraphsAsync.when(
          data: (paragraphs) {
            if (paragraphs.isEmpty) {
              return Center(
                child: Text(
                  'Bu kitapta henüz içerik yok.',
                  style: TextStyle(color: palette.text),
                ),
              );
            }

            final items = _buildItemList(paragraphs, isPremium);

            return Stack(
              children: [
                // ── PageView ─────────────────────────────────────────────
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  physics: const PageScrollPhysics(),
                  itemCount: items.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (ctx, index) {
                    final item = items[index];
                    if (item is _AdItem) return _AdPage(palette: palette);
                    return ParagraphCard(
                      paragraph: (item as _ParagraphItem).paragraph,
                      isCurrent: index == _currentIndex,
                      total: paragraphs.length,
                      fontSize: readerFontSize,
                      textColor: palette.text,
                      dividerColor: palette.divider,
                      accentColor: palette.accent,
                      mutedColor: palette.muted,
                    );
                  },
                ),

                // ── Top bar (Positioned must be direct child of Stack) ──
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: _ReaderTopBar(
                      readerTheme: readerTheme,
                      onBack: () => context.pop(),
                      onSettings: () =>
                          _showReaderSettings(context, readerTheme),
                    ),
                  ),
                ),

                // ── Bottom bar ─────────────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: _ReaderBottomBar(
                      readerTheme: readerTheme,
                      current: _currentIndex + 1,
                      total: items.length,
                      onPrev: _currentIndex > 0 ? _goPrev : null,
                      onNext: _currentIndex < items.length - 1
                          ? () => _goNext(items.length)
                          : null,
                    ),
                  ),
                ),

              ],
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Yüklenemedi: $e',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.refresh(paragraphsProvider(widget.bookId)),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<dynamic> _buildItemList(List paragraphs, bool isPremium) {
    if (isPremium) {
      return paragraphs.map((p) => _ParagraphItem(p)).toList();
    }
    final items = <dynamic>[];
    for (var i = 0; i < paragraphs.length; i++) {
      items.add(_ParagraphItem(paragraphs[i]));
      if ((i + 1) % _adEveryN == 0 && i < paragraphs.length - 1) {
        items.add(_AdItem());
      }
    }
    return items;
  }

  void _showReaderSettings(BuildContext context, String readerTheme) {
    final settings = ref.read(settingsProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Okuma Ayarları',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tema',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: ['light', 'dark', 'sepia'].map((t) {
                  final labels = {
                    'light': '☀️ Açık',
                    'dark': '🌙 Koyu',
                    'sepia': '🍂 Sepya',
                  };
                  final isSelected = (_readerThemeOverride ?? readerTheme) == t;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _readerThemeOverride = t;
                        setModalState(() {});
                        if (mounted) setState(() {});
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          labels[t]!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Font Boyutu',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    'A',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(ctx).copyWith(
                        activeTrackColor: AppColors.primary,
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withOpacity(0.12),
                        inactiveTrackColor: Colors.white24,
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 7),
                      ),
                      child: Slider(
                        value: _readerFontSizeOverride ??
                            settings.fontSize.toDouble(),
                        min: 12,
                        max: 22,
                        divisions: 5,
                        onChanged: (v) {
                          _readerFontSizeOverride = v;
                          setModalState(() {});
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  ),
                  const Text(
                    'A',
                    style: TextStyle(fontSize: 22, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _ReaderPalette _paletteForTheme(String theme) {
    return switch (theme) {
      'light' => const _ReaderPalette(
        background: Color(0xFFF8F5EE),
        text: Color(0xFF1A1A1A),
        muted: Color(0xFF7A746B),
        divider: Color(0xFFD9D3C8),
        accent: AppColors.primary,
      ),
      'sepia' => const _ReaderPalette(
        background: Color(0xFFF1E4C8),
        text: Color(0xFF4A3928),
        muted: Color(0xFF8E745C),
        divider: Color(0xFFD7C3A1),
        accent: Color(0xFF9A6B33),
      ),
      _ => const _ReaderPalette(
        background: Color(0xFF050505),
        text: Color(0xFFE8E5DF),
        muted: Color(0xFF8D8880),
        divider: Color(0xFF2B2B2B),
        accent: AppColors.primary,
      ),
    };
  }
}

// ── Page item types ───────────────────────────────────────────────────────────

class _ParagraphItem {
  final dynamic paragraph;
  const _ParagraphItem(this.paragraph);
}

class _AdItem {}

// ── Ad page ───────────────────────────────────────────────────────────────────
//
// Replaces the broken Spacer-in-Column-in-Center pattern.

class _AdPage extends StatelessWidget {
  final _ReaderPalette palette;
  const _AdPage({super.key, required this.palette});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: palette.background,
        child: const Center(
          child: AdBannerWidget(position: 'reader_banner'),
        ),
      ),
    );
  }
}

// ── Premium gate ──────────────────────────────────────────────────────────────

class _PremiumGateScreen extends StatelessWidget {
  final VoidCallback onUpgrade;
  final VoidCallback onBack;

  const _PremiumGateScreen({required this.onUpgrade, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👑', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 24),
              const Text(
                'Bu kitap Premium',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Bu kitabı okumak için KitapLig Premium üyeliği gerekiyor.\nAylık ₺14,99 ile sınırsız erişim sağlayın.',
                style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Premium\'a Geç',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onBack,
                child: const Text(
                  'Geri Dön',
                  style: TextStyle(color: AppColors.primaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
//
// NOTE: This widget must NOT return Positioned — the caller places it inside
// a Positioned widget at the Stack level.

class _ReaderTopBar extends StatelessWidget {
  final String readerTheme;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  const _ReaderTopBar({
    required this.readerTheme,
    required this.onBack,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = readerTheme == 'dark';
    final iconColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 8,
        8,
        12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconColor, size: 20),
          ),
          const Spacer(),
          IconButton(
            onPressed: onSettings,
            icon: Icon(Icons.tune_rounded, color: iconColor, size: 20),
          ),
        ],
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _ReaderBottomBar extends StatelessWidget {
  final String readerTheme;
  final int current;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _ReaderBottomBar({
    required this.readerTheme,
    required this.current,
    required this.total,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;
    final isDark = readerTheme == 'dark';
    final textColor = isDark ? Colors.white70 : Colors.black54;
    final arrowColor = isDark ? Colors.white54 : Colors.black38;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 2.5,
            ),
          ),
          const SizedBox(height: 8),
          // Counter + nav arrows
          Row(
            children: [
              // Prev button
              _NavArrow(
                icon: Icons.keyboard_arrow_up_rounded,
                color: arrowColor,
                enabled: onPrev != null,
                onTap: onPrev,
              ),
              const SizedBox(width: 4),
              // Next button
              _NavArrow(
                icon: Icons.keyboard_arrow_down_rounded,
                color: arrowColor,
                enabled: onNext != null,
                onTap: onNext,
              ),
              const Spacer(),
              Text(
                '$current / $total',
                style: TextStyle(color: textColor, fontSize: 12),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _NavArrow({
    required this.icon,
    required this.color,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.25,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

// ── Palette & data ────────────────────────────────────────────────────────────

class _ReaderPalette {
  final Color background;
  final Color text;
  final Color muted;
  final Color divider;
  final Color accent;

  const _ReaderPalette({
    required this.background,
    required this.text,
    required this.muted,
    required this.divider,
    required this.accent,
  });
}
