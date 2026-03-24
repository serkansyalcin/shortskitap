import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers/books_provider.dart';
import '../../../app/providers/library_provider.dart';
import '../../../app/providers/progress_provider.dart';
import '../../../app/providers/settings_provider.dart';
import '../../../app/providers/subscription_provider.dart';
import '../../../app/providers/voiceover_provider.dart';
import '../../../core/services/auto_voiceover_service.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/paragraph_model.dart';
import '../../../core/platform/platform_support.dart';
import '../../../features/subscription/widgets/ad_banner.dart';
import '../widgets/paragraph_card.dart';
import '../widgets/review_modal.dart';
import '../widgets/highlight_modal.dart';

const _adEveryN = 5;

class ReaderScreen extends ConsumerStatefulWidget {
  final int bookId;
  final bool bookIsPremium;
  final String? bookTitle;
  final String? authorName;

  const ReaderScreen({
    super.key,
    required this.bookId,
    this.bookIsPremium = false,
    this.bookTitle,
    this.authorName,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  int _currentParagraphOrder = 1;
  Timer? _debounce;
  Timer? _sessionTimer;
  int _sessionSeconds = 0;
  bool _showControls = true;
  Timer? _controlsTimer;
  String? _readerThemeOverride;
  double? _readerFontSizeOverride;
  String? _readerFontFamilyOverride;
  double? _readerLineHeightOverride;
  bool _restoredInitialPage = false;
  bool _voiceoverLoading = false;
  int? _currentParagraphId;
  late final AutoVoiceoverService _voiceoverService;
  final Map<int, String> _localHighlights = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _voiceoverService = ref.read(autoVoiceoverServiceProvider);

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
    _voiceoverService.stop();
    if (PlatformSupport.supportsImmersiveUi) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  void _onPageChanged(int index) {
    final items = _lastBuiltItems;
    final paragraphOrder = _paragraphOrderForIndex(items, index);
    final item = index < items.length ? items[index] : null;
    final paragraphId = item is _ParagraphItem ? item.paragraph.id : null;

    setState(() {
      _currentIndex = index;
      _currentParagraphOrder = paragraphOrder;
      _currentParagraphId = paragraphId;
    });
    _showControlsTemporarily();

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final readAt = DateTime.now();
      ref
          .read(progressSyncProvider.notifier)
          .sync(widget.bookId, paragraphOrder, _sessionSeconds, readAt: readAt);
      _sessionSeconds = 0;
    });

    final voiceEnabled = ref.read(voiceoverEnabledProvider);
    if (voiceEnabled && paragraphId != null) {
      _triggerVoiceover(paragraphId, index);

      // Trigger preload for the next page
      if (index + 1 < items.length) {
        final nextItem = items[index + 1];
        if (nextItem is _ParagraphItem) {
          _voiceoverService.preloadNextParagraph(
            widget.bookId,
            nextItem.paragraph.id,
          );
        }
      }
    }
  }

  Future<void> _triggerVoiceover(int paragraphId, int index) async {
    if (!mounted) return;
    setState(() => _voiceoverLoading = true);
    try {
      await _voiceoverService.playParagraph(widget.bookId, paragraphId);
    } finally {
      if (mounted && _currentIndex == index) {
        setState(() => _voiceoverLoading = false);
      }
    }
  }

  void _toggleVoiceover() {
    final voiceEnabled = ref.read(voiceoverEnabledProvider);
    if (voiceEnabled) {
      ref.read(voiceoverEnabledProvider.notifier).state = false;
      _voiceoverService.disable();
    } else {
      ref.read(voiceoverEnabledProvider.notifier).state = true;
      _voiceoverService.enable();
      if (_currentParagraphId != null) {
        _triggerVoiceover(_currentParagraphId!, _currentIndex);
      }
    }
  }

  void _showControlsTemporarily() {
    setState(() => _showControls = true);
    _startControlsTimer();
  }

  void _showPremiumRequiredForDownloadModal() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF171A17) : theme.cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 64,
                height: 64,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              Text(
                'Premium Özellik',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kitapları cihazınıza indirip çevrimdışı okumak için Kitaplig Premium abonesi olmalısınız. İstediğiniz zaman, internete ihtiyaç duymadan okuma keyfini çıkarın!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/premium');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Premium\'u İncele',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Vazgeç',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadBook() async {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      _showPremiumRequiredForDownloadModal();
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    try {
      final count = await ref
          .read(bookDownloadControllerProvider.notifier)
          .downloadBook(widget.bookId);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? 'Kitap cihaza indirildi. Artık çevrimdışı da okunabilir.'
                : 'Bu kitap zaten indiriliyor.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'İndirme tamamlanamadı. Lütfen daha sonra tekrar deneyin.',
          ),
        ),
      );
    }
  }

  void _goNext(int total) {
    if (_currentIndex < total - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      // Reached the end. Let's show the review modal!
      ReviewModal.show(context, widget.bookId);
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

  List<dynamic> _lastBuiltItems = const [];

  void _restoreInitialPageIfNeeded(int initialIndex) {
    if (_restoredInitialPage) return;
    _restoredInitialPage = true;
    _currentIndex = initialIndex;
    _currentParagraphOrder = _paragraphOrderForIndex(
      _lastBuiltItems,
      initialIndex,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(initialIndex);
      setState(() {});
    });
  }

  int _resolveInitialIndex(List<dynamic> items, int? lastParagraphOrder) {
    if (lastParagraphOrder == null || lastParagraphOrder <= 1) return 0;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is _ParagraphItem && item.paragraphOrder == lastParagraphOrder) {
        return i;
      }
    }
    return 0;
  }

  int _paragraphOrderForIndex(List<dynamic> items, int index) {
    if (items.isEmpty) return 1;
    final safeIndex = index.clamp(0, items.length - 1);
    final item = items[safeIndex];
    if (item is _ParagraphItem) return item.paragraphOrder;

    for (var i = safeIndex - 1; i >= 0; i--) {
      final previous = items[i];
      if (previous is _ParagraphItem) return previous.paragraphOrder;
    }

    for (var i = safeIndex + 1; i < items.length; i++) {
      final next = items[i];
      if (next is _ParagraphItem) return next.paragraphOrder;
    }

    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final paragraphsAsync = ref.watch(paragraphsProvider(widget.bookId));
    final progressAsync = ref.watch(bookProgressProvider(widget.bookId));
    final settings = ref.watch(settingsProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final isDownloading = ref.watch(
      bookDownloadControllerProvider.select(
        (downloading) => downloading.contains(widget.bookId),
      ),
    );
    final cacheStatusAsync = ref.watch(bookCacheStatusProvider(widget.bookId));
    final isDownloaded = cacheStatusAsync.valueOrNull == true;
    final readerTheme = _readerThemeOverride ?? settings.theme;
    final readerFontSize =
        _readerFontSizeOverride ?? settings.fontSize.toDouble();
    final readerFontFamily = _readerFontFamilyOverride ?? 'classic';
    final readerLineHeight = _readerLineHeightOverride ?? 1.8;
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

            if (progressAsync.isLoading && !progressAsync.hasValue) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final items = _buildItemList(paragraphs, isPremium);
            _lastBuiltItems = items;
            final lastParagraphOrder =
                progressAsync.valueOrNull?.lastParagraphOrder;
            final initialIndex = _resolveInitialIndex(
              items,
              lastParagraphOrder,
            );

            _restoreInitialPageIfNeeded(initialIndex);

            return Stack(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        palette.background,
                        palette.background.withValues(alpha: 0.98),
                      ],
                    ),
                  ),
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    physics: const PageScrollPhysics(),
                    itemCount: items.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (ctx, index) {
                      final item = items[index];
                      if (item is _AdItem) return _AdPage(palette: palette);
                      final paragraph = (item as _ParagraphItem).paragraph;
                      final highlightHex =
                          _localHighlights[paragraph.id] ??
                          paragraph.highlightColor;
                      Color? highlightColor;
                      if (highlightHex != null) {
                        try {
                          highlightColor = Color(
                            int.parse(highlightHex.replaceFirst('#', '0xFF')),
                          );
                        } catch (_) {}
                      }

                      return ParagraphCard(
                        paragraph: paragraph,
                        isCurrent: index == _currentIndex,
                        total: paragraphs.length,
                        fontSize: readerFontSize,
                        fontFamily: readerFontFamily,
                        lineHeight: readerLineHeight,
                        textColor: palette.text,
                        dividerColor: palette.divider,
                        accentColor: palette.accent,
                        mutedColor: palette.muted,
                        highlightColor: highlightColor,
                        bookTitle: widget.bookTitle,
                        authorName: widget.authorName,
                        onHighlight: () {
                          HighlightModal.show(
                            context,
                            widget.bookId,
                            paragraph,
                            onSaved: (id, color) {
                              setState(() {
                                _localHighlights[id] = color;
                              });
                              // Refresh highlight-backed surfaces after a new save.
                              ref.invalidate(paragraphsProvider(widget.bookId));
                              ref.invalidate(highlightsProvider);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: _ReaderTopBar(
                      readerTheme: readerTheme,
                      fontFamily: readerFontFamily,
                      isDownloaded: isDownloaded,
                      isDownloading: isDownloading,
                      onBack: () => context.pop(),
                      onDownload: isDownloaded || isDownloading
                          ? null
                          : _downloadBook,
                      onSettings: () =>
                          _showReaderSettings(context, readerTheme),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: _ReaderBottomBar(
                      readerTheme: readerTheme,
                      current: _currentParagraphOrder,
                      total: paragraphs.length,
                      fontFamily: readerFontFamily,
                      onPrev: _currentIndex > 0 ? _goPrev : null,
                      onNext: () => _goNext(items.length),
                      voiceoverEnabled: ref.watch(voiceoverEnabledProvider),
                      voiceoverLoading: _voiceoverLoading,
                      onVoiceoverToggle: _toggleVoiceover,
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
                  child: Text('Yüklenemedi: $e', textAlign: TextAlign.center),
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

  List<dynamic> _buildItemList(
    List<ParagraphModel> paragraphs,
    bool isPremium,
  ) {
    if (isPremium) {
      return [
        for (var i = 0; i < paragraphs.length; i++)
          _ParagraphItem(paragraphs[i], i + 1),
      ];
    }
    final items = <dynamic>[];
    for (var i = 0; i < paragraphs.length; i++) {
      items.add(_ParagraphItem(paragraphs[i], i + 1));
      if ((i + 1) % _adEveryN == 0 && i < paragraphs.length - 1) {
        items.add(_AdItem());
      }
    }
    return items;
  }

  void _showReaderSettings(BuildContext context, String readerTheme) {
    final settings = ref.read(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151515),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final activeTheme = _readerThemeOverride ?? readerTheme;
          final activeFontSize =
              _readerFontSizeOverride ?? settings.fontSize.toDouble();
          final activeFontFamily = _readerFontFamilyOverride ?? 'classic';
          final activeLineHeight = _readerLineHeightOverride ?? 1.8;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Text(
                      'Okuma Ayarları',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tipografi ve sayfa hissini kendine göre ayarla.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.68),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ReaderSettingsSection(
                      title: 'Tema',
                      child: Row(
                        children: ['light', 'dark', 'sepia'].map((t) {
                          final labels = {
                            'light': 'Açık',
                            'dark': 'Koyu',
                            'sepia': 'Sepya',
                          };
                          final icons = {
                            'light': Icons.light_mode_rounded,
                            'dark': Icons.dark_mode_rounded,
                            'sepia': Icons.auto_stories_rounded,
                          };
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: t == 'sepia' ? 0 : 8,
                              ),
                              child: _ReaderOptionChip(
                                label: labels[t]!,
                                icon: icons[t]!,
                                selected: activeTheme == t,
                                onTap: () {
                                  _readerThemeOverride = t;
                                  setModalState(() {});
                                  if (mounted) setState(() {});
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ReaderSettingsSection(
                      title: 'Yazı Stili',
                      child: Column(
                        children: [
                          _FontChoiceTile(
                            title: 'Klasik',
                            subtitle: 'Roman hissi, sıcak ve dengeli',
                            sampleStyle: GoogleFonts.lora(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            selected: activeFontFamily == 'classic',
                            onTap: () {
                              _readerFontFamilyOverride = 'classic';
                              setModalState(() {});
                              if (mounted) setState(() {});
                            },
                          ),
                          const SizedBox(height: 10),
                          _FontChoiceTile(
                            title: 'Editoryal',
                            subtitle: 'Daha edebi ve dergi benzeri görünüm',
                            sampleStyle: GoogleFonts.crimsonText(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                            selected: activeFontFamily == 'editorial',
                            onTap: () {
                              _readerFontFamilyOverride = 'editorial';
                              setModalState(() {});
                              if (mounted) setState(() {});
                            },
                          ),
                          const SizedBox(height: 10),
                          _FontChoiceTile(
                            title: 'Modern',
                            subtitle: 'Temiz, çağdaş ve çok okunaklı',
                            sampleStyle: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            selected: activeFontFamily == 'modern',
                            onTap: () {
                              _readerFontFamilyOverride = 'modern';
                              setModalState(() {});
                              if (mounted) setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ReaderSettingsSection(
                      title: 'Önizleme',
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          'Denizin üzerinde ağır ağır ilerleyen kadırga, yeni günün sessizliğini taşıyordu.',
                          style: _previewTextStyle(
                            family: activeFontFamily,
                            color: Colors.white.withValues(alpha: 0.94),
                            fontSize: activeFontSize,
                            height: activeLineHeight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ReaderSettingsSection(
                      title: 'Font Boyutu',
                      child: _ReaderSliderRow(
                        leading: 'A',
                        trailing: 'A',
                        trailingSize: 23,
                        valueLabel: '${activeFontSize.toStringAsFixed(0)} pt',
                        child: SliderTheme(
                          data: SliderTheme.of(ctx).copyWith(
                            activeTrackColor: AppColors.primary,
                            thumbColor: AppColors.primary,
                            overlayColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            inactiveTrackColor: Colors.white24,
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                          ),
                          child: Slider(
                            value: activeFontSize,
                            min: 14,
                            max: 26,
                            divisions: 6,
                            onChanged: (v) {
                              _readerFontSizeOverride = v;
                              setModalState(() {});
                              if (mounted) setState(() {});
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ReaderSettingsSection(
                      title: 'Satır Aralığı',
                      child: _ReaderSliderRow(
                        leading: 'Sık',
                        trailing: 'Rahat',
                        trailingSize: 12,
                        valueLabel: activeLineHeight.toStringAsFixed(2),
                        child: SliderTheme(
                          data: SliderTheme.of(ctx).copyWith(
                            activeTrackColor: AppColors.accent,
                            thumbColor: AppColors.accent,
                            overlayColor: AppColors.accent.withValues(
                              alpha: 0.12,
                            ),
                            inactiveTrackColor: Colors.white24,
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                          ),
                          child: Slider(
                            value: activeLineHeight,
                            min: 1.55,
                            max: 2.1,
                            divisions: 5,
                            onChanged: (v) {
                              _readerLineHeightOverride = v;
                              setModalState(() {});
                              if (mounted) setState(() {});
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  _ReaderPalette _paletteForTheme(String theme) {
    return switch (theme) {
      'light' => const _ReaderPalette(
        background: Color(0xFFF8F5EE),
        text: Color(0xFF1F1B16),
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

class _ParagraphItem {
  final ParagraphModel paragraph;
  final int paragraphOrder;

  const _ParagraphItem(this.paragraph, this.paragraphOrder);
}

class _AdItem {}

class _AdPage extends StatelessWidget {
  final _ReaderPalette palette;

  const _AdPage({required this.palette});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: palette.background,
        child: const Center(child: AdBannerWidget(position: 'reader_banner')),
      ),
    );
  }
}

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
                'Bu kitabı okumak için Kitaplig Premium üyeliği gerekiyor.\nAylık ₺14,99 ile sınırsız erişim sağlayın.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.6,
                ),
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

class _ReaderTopBar extends StatelessWidget {
  final String readerTheme;
  final String fontFamily;
  final bool isDownloaded;
  final bool isDownloading;
  final VoidCallback onBack;
  final VoidCallback? onDownload;
  final VoidCallback onSettings;

  const _ReaderTopBar({
    required this.readerTheme,
    required this.fontFamily,
    required this.isDownloaded,
    required this.isDownloading,
    required this.onBack,
    required this.onDownload,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = readerTheme == 'dark';
    final iconColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        MediaQuery.of(context).padding.top + 8,
        14,
        12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          _TopBarButton(
            icon: Icons.arrow_back_ios_new_rounded,
            color: iconColor,
            onTap: onBack,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.52),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              switch (fontFamily) {
                'editorial' => 'Editoryal',
                'modern' => 'Modern',
                _ => 'Klasik',
              },
              style: TextStyle(
                color: iconColor.withValues(alpha: 0.82),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _TopBarButton(
            icon: isDownloaded
                ? Icons.download_done_rounded
                : Icons.download_rounded,
            color: isDownloaded ? AppColors.accent : iconColor,
            onTap: onDownload,
            loading: isDownloading,
          ),
          const SizedBox(width: 10),
          _TopBarButton(
            icon: Icons.tune_rounded,
            color: iconColor,
            onTap: onSettings,
          ),
        ],
      ),
    );
  }
}

class _ReaderBottomBar extends StatelessWidget {
  final String readerTheme;
  final int current;
  final int total;
  final String fontFamily;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final bool voiceoverEnabled;
  final bool voiceoverLoading;
  final VoidCallback? onVoiceoverToggle;

  const _ReaderBottomBar({
    required this.readerTheme,
    required this.current,
    required this.total,
    required this.fontFamily,
    this.onPrev,
    this.onNext,
    this.voiceoverEnabled = false,
    this.voiceoverLoading = false,
    this.onVoiceoverToggle,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;
    final isDark = readerTheme == 'dark';
    final textColor = isDark ? Colors.white70 : Colors.black54;
    final arrowColor = isDark ? Colors.white54 : Colors.black38;

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 2.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NavArrow(
                icon: Icons.keyboard_arrow_up_rounded,
                color: arrowColor,
                enabled: onPrev != null,
                onTap: onPrev,
              ),
              const SizedBox(width: 4),
              _NavArrow(
                icon: Icons.keyboard_arrow_down_rounded,
                color: arrowColor,
                enabled: onNext != null,
                onTap: onNext,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  switch (fontFamily) {
                    'editorial' => 'Editoryal',
                    'modern' => 'Modern',
                    _ => 'Klasik',
                  },
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              // Auto-voiceover toggle
              GestureDetector(
                onTap: onVoiceoverToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: voiceoverEnabled
                        ? AppColors.accent.withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: isDark ? 0.08 : 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: voiceoverEnabled
                          ? AppColors.accent.withValues(alpha: 0.55)
                          : Colors.transparent,
                    ),
                  ),
                  child: voiceoverLoading
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        )
                      : Icon(
                          voiceoverEnabled
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          size: 16,
                          color: voiceoverEnabled
                              ? AppColors.accent
                              : textColor,
                        ),
                ),
              ),
              const SizedBox(width: 10),
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
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

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

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;

  const _TopBarButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: onTap == null ? 0.04 : 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 40,
          height: 40,
          child: AnimatedOpacity(
            opacity: onTap == null && !loading ? 0.65 : 1,
            duration: const Duration(milliseconds: 180),
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, color: color, size: 19),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReaderSettingsSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ReaderSettingsSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ReaderOptionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ReaderOptionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.22)
          : Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.primaryLight : Colors.white70,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FontChoiceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextStyle sampleStyle;
  final bool selected;
  final VoidCallback onTap;

  const _FontChoiceTile({
    required this.title,
    required this.subtitle,
    required this.sampleStyle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.16)
          : Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: sampleStyle),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Colors.white.withValues(alpha: 0.66),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.primary : Colors.white24,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderSliderRow extends StatelessWidget {
  final String leading;
  final String trailing;
  final double trailingSize;
  final String valueLabel;
  final Widget child;

  const _ReaderSliderRow({
    required this.leading,
    required this.trailing,
    required this.trailingSize,
    required this.valueLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              leading,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            Expanded(child: child),
            Text(
              trailing,
              style: TextStyle(fontSize: trailingSize, color: Colors.white),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            valueLabel,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

TextStyle _previewTextStyle({
  required String family,
  required Color color,
  required double fontSize,
  required double height,
}) {
  switch (family) {
    case 'editorial':
      return GoogleFonts.crimsonText(
        color: color,
        fontSize: fontSize,
        height: height,
      );
    case 'modern':
      return GoogleFonts.dmSans(
        color: color,
        fontSize: fontSize,
        height: height,
      );
    default:
      return GoogleFonts.lora(color: color, fontSize: fontSize, height: height);
  }
}
