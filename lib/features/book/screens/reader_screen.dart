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
import '../../../features/subscription/widgets/ad_banner.dart';
import '../widgets/paragraph_card.dart';

/// Every N paragraphs, an ad slot is inserted for non-premium users.
const _adEveryN = 5;

class ReaderScreen extends ConsumerStatefulWidget {
  final int bookId;

  /// Optional flag passed from BookDetailScreen via route `extra`.
  final bool bookIsPremium;

  const ReaderScreen({
    super.key,
    required this.bookId,
    this.bookIsPremium = false,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _debounce;
  Timer? _sessionTimer;
  int _sessionSeconds = 0;
  bool _showControls = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _showControlsTemporarily();

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(progressSyncProvider.notifier).sync(
            widget.bookId,
            index + 1,
            _sessionSeconds,
          );
      _sessionSeconds = 0;
    });
  }

  void _showControlsTemporarily() {
    setState(() => _showControls = true);
    _startControlsTimer();
  }

  @override
  Widget build(BuildContext context) {
    final paragraphsAsync = ref.watch(paragraphsProvider(widget.bookId));
    final settings = ref.watch(settingsProvider);
    final isPremium = ref.watch(isPremiumProvider);

    // Gate: if book is premium and user is not premium, redirect to paywall
    if (widget.bookIsPremium && !isPremium) {
      return _PremiumGateScreen(
        onUpgrade: () => context.push('/premium'),
        onBack: () => context.pop(),
      );
    }

    return GestureDetector(
      onTap: _showControlsTemporarily,
      child: Scaffold(
        body: paragraphsAsync.when(
          data: (paragraphs) {
            if (paragraphs.isEmpty) {
              return const Center(child: Text('Bu kitapta henüz içerik yok.'));
            }

            // Build a list of page items: paragraphs + ad slots for non-premium
            final items = _buildItemList(paragraphs, isPremium);

            return Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: items.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (ctx, index) {
                    final item = items[index];
                    if (item is _AdItem) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            const AdBannerWidget(position: 'reader_banner'),
                            const Spacer(),
                          ],
                        ),
                      );
                    }
                    final para = item as _ParagraphItem;
                    return ParagraphCard(
                      paragraph: para.paragraph,
                      isCurrent: index == _currentIndex,
                      total: paragraphs.length,
                      fontSize: settings.fontSize.toDouble(),
                    );
                  },
                ),

                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: _ReaderTopBar(
                    onBack: () => context.pop(),
                    onSettings: () => _showReaderSettings(context),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: _ReaderBottomBar(
                      current: _currentIndex + 1,
                      total: items.length,
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Yüklenemedi: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(paragraphsProvider(widget.bookId)),
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
      // Insert an ad every _adEveryN paragraphs (not at the very end)
      if ((i + 1) % _adEveryN == 0 && i < paragraphs.length - 1) {
        items.add(_AdItem());
      }
    }
    return items;
  }

  void _showReaderSettings(BuildContext context) {
    final settings = ref.read(settingsProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Okuma Ayarları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              const Text('Tema', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: ['light', 'dark', 'sepia'].map((t) {
                  final labels = {'light': '☀️ Açık', 'dark': '🌙 Koyu', 'sepia': '🍂 Sepya'};
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(settingsProvider.notifier).setTheme(t);
                        setModalState(() {});
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: settings.theme == t ? AppColors.primary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          labels[t]!,
                          style: TextStyle(
                            color: settings.theme == t ? Colors.white : Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              const Text('Font Boyutu', style: TextStyle(fontWeight: FontWeight.w500)),
              Row(
                children: [
                  const Text('A', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: settings.fontSize.toDouble(),
                      min: 12,
                      max: 22,
                      divisions: 5,
                      activeColor: AppColors.primary,
                      onChanged: (v) {
                        ref.read(settingsProvider.notifier).setFontSize(v.round());
                        setModalState(() {});
                      },
                    ),
                  ),
                  const Text('A', style: TextStyle(fontSize: 22)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Page item types ────────────────────────────────────────────────────────────

class _ParagraphItem {
  final dynamic paragraph;
  const _ParagraphItem(this.paragraph);
}

class _AdItem {}

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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Premium\'a Geç',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onBack,
                child: const Text('Geri Dön', style: TextStyle(color: AppColors.primaryLight)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── UI components ─────────────────────────────────────────────────────────────

class _ReaderTopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSettings;

  const _ReaderTopBar({required this.onBack, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
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
              Colors.black.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            ),
            const Spacer(),
            IconButton(
              onPressed: onSettings,
              icon: const Icon(Icons.tune, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderBottomBar extends StatelessWidget {
  final int current;
  final int total;

  const _ReaderBottomBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$current / $total',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              color: AppColors.accent,
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}
