import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/paragraph_model.dart';

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
  });

  @override
  State<ParagraphCard> createState() => _ParagraphCardState();
}

class _ParagraphCardState extends State<ParagraphCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

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
    return Center(
      child: Text(
        widget.paragraph.content,
        style: _bodyStyle(
          color: widget.textColor,
          fontSize: widget.fontSize,
          height: widget.lineHeight,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.08,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildQuote() {
    return Center(
      child: Column(
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

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
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
              ListTile(
                leading: const Icon(
                  Icons.share_rounded,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Paylaş',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareParagraph();
                },
              ),
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
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yer imi eklendi')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareParagraph() {
    Share.share(
      '"${widget.paragraph.content}"\n\n— KitapLig uygulamasından',
      subject: 'KitapLig',
    );
  }
}
