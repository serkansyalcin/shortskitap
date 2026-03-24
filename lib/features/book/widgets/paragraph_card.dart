import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/paragraph_model.dart';
import '../../../core/platform/browser_file_download.dart';
import '../../../core/widgets/shareable_paragraph_overlay.dart';

class ParagraphCard extends StatefulWidget {
  final ParagraphModel paragraph;
  final bool isCurrent;
  final int total;
  final double fontSize;
  final String fontFamily;
  final double lineHeight;
  final Color textColor;
  final Color dividerColor;
  final Color accentColor;
  final Color mutedColor;
  final VoidCallback? onHighlight;

  /// Book info for stylish share
  final String? bookTitle;
  final String? authorName;

  /// If not null, show a highlight tint over the paragraph
  final Color? highlightColor;

  const ParagraphCard({
    super.key,
    required this.paragraph,
    required this.isCurrent,
    required this.total,
    required this.fontSize,
    required this.fontFamily,
    required this.lineHeight,
    required this.textColor,
    required this.dividerColor,
    required this.accentColor,
    required this.mutedColor,
    this.onHighlight,
    this.highlightColor,
    this.bookTitle,
    this.authorName,
  });

  @override
  State<ParagraphCard> createState() => _ParagraphCardState();
}

class _ParagraphCardState extends State<ParagraphCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: widget.isCurrent ? 1.0 : 0.6,
    );
    if (widget.isCurrent) _anim.forward();
  }

  @override
  void didUpdateWidget(ParagraphCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !oldWidget.isCurrent) {
      _anim.forward(from: 0.6);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showBottomSheet(context),
      child: SizedBox.expand(
        child: FadeTransition(
          opacity: _anim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
            child: switch (widget.paragraph.type) {
              ParagraphType.sceneBreak => _buildSceneBreak(),
              ParagraphType.quote => _buildQuote(),
              _ => _buildText(),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildText() {
    final hl = widget.highlightColor;
    final textWidget = Text(
      widget.paragraph.content,
      style: _bodyStyle(
        color: widget.textColor,
        fontSize: widget.fontSize,
        height: widget.lineHeight,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.08,
      ),
      textAlign: TextAlign.left,
    );

    if (hl == null) {
      return Center(child: textWidget);
    }

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: BoxDecoration(
                color: hl.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: hl.withOpacity(0.25)),
              ),
              child: textWidget,
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: Container(width: 4, color: hl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuote() {
    final hl = widget.highlightColor;
    final quoteContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '"',
          style: _bodyStyle(
            color: widget.accentColor.withValues(alpha: 0.20),
            fontSize: 80,
            height: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.paragraph.content,
          style: _bodyStyle(
            color: widget.textColor,
            fontSize: widget.fontSize,
            height: widget.lineHeight + 0.08,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    if (hl == null) {
      return Center(child: quoteContent);
    }

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                color: hl.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: hl.withOpacity(0.25)),
              ),
              child: quoteContent,
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: Container(width: 4, color: hl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSceneBreak() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 60, height: 1, color: widget.dividerColor),
          const SizedBox(height: 12),
          Text(
            '§',
            style: _bodyStyle(
              color: widget.mutedColor,
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(width: 60, height: 1, color: widget.dividerColor),
        ],
      ),
    );
  }

  TextStyle _bodyStyle({
    required Color color,
    required double fontSize,
    required double height,
    required FontWeight fontWeight,
    FontStyle fontStyle = FontStyle.normal,
    double? letterSpacing,
  }) {
    switch (widget.fontFamily) {
      case 'classic':
        return GoogleFonts.lora(
          color: color,
          fontSize: fontSize,
          height: height,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          letterSpacing: letterSpacing,
        );
      case 'editorial':
        return GoogleFonts.crimsonText(
          color: color,
          fontSize: fontSize,
          height: height,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          letterSpacing: letterSpacing,
        );
      default:
        return GoogleFonts.dmSans(
          color: color,
          fontSize: fontSize,
          height: height,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          letterSpacing: letterSpacing,
        );
    }
  }

  void _showBottomSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Şık Paylaş (story format)
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF833AB4),
                        Color(0xFFFD1D1D),
                        Color(0xFFF77737),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Alıntı Paylaş',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'İnstagram Story formatında',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showThemePicker(ctx);
                },
              ),

              // Plain text share
              ListTile(
                leading: const Icon(
                  Icons.share_rounded,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Metin Olarak Paylaş',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _shareParagraph();
                },
              ),

              // Bookmark
              ListTile(
                leading: const Icon(
                  Icons.bookmark_add_outlined,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Yer imi ekle',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Yer imi eklendi')),
                  );
                },
              ),

              // Highlight
              if (widget.onHighlight != null)
                ListTile(
                  leading: const Icon(
                    Icons.format_paint_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Bu paragrafı vurgula',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    widget.onHighlight!();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext parentCtx) {
    final themeColors = [
      [const Color(0xFF1A1A2E), const Color(0xFF0F3460)],
      [const Color(0xFF0D0D0D), const Color(0xFF2D2D2D)],
      [const Color(0xFF2C3E50), const Color(0xFF2980B9)],
      [const Color(0xFF11998E), const Color(0xFF0D3B33)],
      [const Color(0xFF4A1942), const Color(0xFF341F3A)],
      [const Color(0xFF1C1C1C), const Color(0xFF0A3D0A)],
    ];

    int selectedTheme = 0;

    showDialog(
      context: parentCtx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setStateDialog) => Dialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tema Seç',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),

                // Theme picker row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(themeColors.length, (i) {
                    return GestureDetector(
                      onTap: () => setStateDialog(() => selectedTheme = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: themeColors[i],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedTheme == i
                                ? AppColors.primary
                                : Colors.white24,
                            width: selectedTheme == i ? 3 : 1,
                          ),
                        ),
                        child: selectedTheme == i
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('İptal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isCapturing
                            ? null
                            : () {
                                Navigator.pop(dialogCtx);
                                _captureAndShare(selectedTheme, parentCtx);
                              },
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('İndir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _captureAndShare(int themeIndex, BuildContext parentCtx) async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final image = await _screenshotController.captureFromWidget(
        Material(
          child: ShareableParagraphOverlay(
            content: widget.paragraph.content,
            bookTitle: widget.bookTitle ?? 'Kitaplig',
            authorName: widget.authorName,
            themeIndex: themeIndex,
          ),
        ),
        delay: const Duration(milliseconds: 100),
        pixelRatio: 2.0,
      );

      if (kIsWeb) {
        await downloadBytes(
          bytes: image,
          mimeType: 'image/png',
          filename:
              'kitaplig_quote_${DateTime.now().millisecondsSinceEpoch}.png',
        );

        if (parentCtx.mounted) {
          ScaffoldMessenger.of(parentCtx).showSnackBar(
            const SnackBar(
              content: Text('Alıntı indirildi! ✨'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } else {
        final xFile = XFile.fromData(
          image,
          mimeType: 'image/png',
          name: 'kitaplig_quote.png',
        );
        await Share.shareXFiles([
          xFile,
        ], text: '— ${widget.bookTitle ?? 'KitapLig'}\n\nkitaplig.com');
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      if (parentCtx.mounted) {
        ScaffoldMessenger.of(
          parentCtx,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _shareParagraph() {
    Share.share(
      '"${widget.paragraph.content}"\n\n— Kitaplig uygulamasından',
      subject: 'Kitaplig',
    );
  }
}
