import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/paragraph_model.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../../../core/platform/browser_file_download.dart';
import '../../../core/widgets/offline_aware_image.dart';
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
    final illUrl = widget.paragraph.illustrationUrl;
    final hasIllustration = illUrl != null && illUrl.isNotEmpty;
    final illUrlNonNull = illUrl ?? '';

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

    Widget? illustration;

    if (hasIllustration) {
      final placeholder = Container(
        color: widget.mutedColor.withValues(alpha: 0.12),
        alignment: Alignment.center,
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: widget.accentColor.withValues(alpha: 0.5),
          ),
        ),
      );
      final errorBox = Container(
        color: widget.mutedColor.withValues(alpha: 0.12),
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: widget.mutedColor,
          size: 40,
        ),
      );
      illustration = AspectRatio(
        aspectRatio: 16 / 11,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: buildOfflineAwareImage(
            networkUrl: illUrlNonNull,
            localPath: widget.paragraph.localIllustrationPath,
            fit: BoxFit.cover,
            placeholder: placeholder,
            errorWidget: errorBox,
          ),
        ),
      );
    }

    if (hl == null) {
      return _scrollableCenteredColumn(
        children: [
          if (illustration != null) ...[
            illustration,
            const SizedBox(height: 22),
          ],
          textWidget,
        ],
      );
    }

    return _scrollableCenteredColumn(
      children: [
        if (illustration != null) ...[illustration, const SizedBox(height: 22)],
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                decoration: BoxDecoration(
                  color: hl.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: hl.withValues(alpha: 0.25)),
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
      ],
    );
  }

  /// Kısa metin + görsel ortalanır; uzun metinde taşma olmaz, dikey kaydırma açılır.
  Widget _scrollableCenteredColumn({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        );
      },
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
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [quoteContent],
              ),
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        decoration: BoxDecoration(
                          color: hl.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: hl.withValues(alpha: 0.25)),
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
              ],
            ),
          ),
        );
      },
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

              ListTile(
                leading: const Icon(
                  Icons.copy_rounded,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Kopyala',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Paragrafı panoya kopyala',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _copyParagraph(ctx);
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
                      child: Builder(
                        builder: (BuildContext context) {
                          return ElevatedButton.icon(
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
                          );
                        },
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
        if (!parentCtx.mounted) return;
        final xFile = XFile.fromData(
          image,
          mimeType: 'image/png',
          name: 'kitaplig_quote.png',
        );
        // await Share.shareXFiles([
        //   xFile,
        // ], text: '— ${widget.bookTitle ?? 'KitapLig'}\n\nkitaplig.com');

        final box = parentCtx.findRenderObject() as RenderBox;

        await Share.shareXFiles(
          [xFile],
          text: [
            if ((widget.authorName ?? '').trim().isNotEmpty)
              '${widget.bookTitle ?? 'KitapLig'} - ${widget.authorName!.trim()}'
            else
              widget.bookTitle ?? 'KitapLig',
            '',
            'KitapLig\'de keşfettiğim bu alıntıya göz at:',
            'kitaplig.com',
          ].join('\n'),
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        );
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      if (parentCtx.mounted) {
        ScaffoldMessenger.of(parentCtx).showSnackBar(
          SnackBar(
            content: Text(
              userFacingErrorMessage(
                e,
                fallback:
                    'Görsel paylaşılamadı. Bağlantını kontrol edip tekrar dene.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _copyParagraph(BuildContext messengerCtx) async {
    final text = widget.paragraph.content.trim();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!messengerCtx.mounted) return;
    ScaffoldMessenger.of(
      messengerCtx,
    ).showSnackBar(const SnackBar(content: Text('Paragraf panoya kopyalandı')));
  }
}
