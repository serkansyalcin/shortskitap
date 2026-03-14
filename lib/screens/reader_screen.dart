import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/reader_mood.dart';
import '../models/book.dart';
import '../services/streak_service.dart';

/// Okuma ekranı: UI sıfıra indirildi.
/// Sadece metin + üstte ince progress bar. Tap = geçici geri butonu.
/// Kullanıcı "kitap okuyorum" hissinde kalır.
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.book});

  final Book book;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _showOverlay = false;
  Timer? _overlayHideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _overlayHideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onTap() {
    setState(() {
      _showOverlay = !_showOverlay;
      _overlayHideTimer?.cancel();
      if (_showOverlay) {
        _overlayHideTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showOverlay = false);
        });
      }
    });
  }

  void _closeReader() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final paragraphs = widget.book.paragraphs;
    final total = paragraphs.length;
    final progress = total > 0 ? (_currentPage / (total + 1)) : 0.0;
    final progressColor = _currentPage > 0
        ? ReaderMood.progressAccentForPage(_currentPage - 1)
        : AppColors.accent;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) StreakService.recordReading();
      },
      child: Scaffold(
        body: Stack(
        children: [
          GestureDetector(
            onTap: _onTap,
            behavior: HitTestBehavior.opaque,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: total + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _CoverPage(
                    book: widget.book,
                    onStart: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOutCubic,
                      );
                    },
                  );
                }
                return _ParagraphPage(
                  paragraph: paragraphs[index - 1],
                  pageIndex: index - 1,
                );
              },
            ),
          ),
          // İnce progress bar — her zaman üstte, minimal
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: IgnorePointer(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Tap ile açılan tek kontrol: geri
          if (_showOverlay)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _closeReader,
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 20,
                              color: AppColors.textPrimary.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

class _CoverPage extends StatelessWidget {
  const _CoverPage({required this.book, required this.onStart});

  final Book book;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: ReaderMood.decorationForPage(0),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Icon(
                Icons.auto_stories_rounded,
                size: 56,
                color: AppColors.accent.withValues(alpha: 0.75),
              ),
              const SizedBox(height: 28),
              Text(
                book.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.28,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                book.author,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(flex: 2),
              Text(
                'Yukarı kaydır',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 28,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onStart,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: BorderSide(color: AppColors.accent.withValues(alpha: 0.7)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Başla'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sadece metin. Arka plan paragraf index'e göre değişir — kaydırdıkça renk geçişi.
class _ParagraphPage extends StatelessWidget {
  const _ParagraphPage({required this.paragraph, required this.pageIndex});

  final String paragraph;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: ReaderMood.decorationForPage(pageIndex),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Center(
            child: Text(
              paragraph,
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 22,
                height: 1.75,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
