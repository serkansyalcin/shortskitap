import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/paragraph_model.dart';

class ParagraphCard extends StatefulWidget {
  final ParagraphModel paragraph;
  final bool isCurrent;
  final int total;
  final double fontSize;
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
  void didUpdateWidget(ParagraphCard old) {
    super.didUpdateWidget(old);
    if (widget.isCurrent && !old.isCurrent) {
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
        style: TextStyle(
          fontSize: widget.fontSize,
          height: 1.85,
          color: widget.textColor,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
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
            style: TextStyle(
              fontSize: 80,
              color: widget.accentColor.withOpacity(0.20),
              height: 0.8,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.paragraph.content,
            style: TextStyle(
              fontSize: widget.fontSize,
              height: 1.9,
              color: widget.textColor,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
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
          Text('⁂', style: TextStyle(fontSize: 24, color: widget.mutedColor)),
          const SizedBox(height: 12),
          Container(width: 60, height: 1, color: widget.dividerColor),
        ],
      ),
    );
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
                leading: const Icon(Icons.share_rounded, color: AppColors.primary),
                title: const Text('Paylaş', style: TextStyle(color: Colors.white)),
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
                title: const Text('Yer imi ekle', style: TextStyle(color: Colors.white)),
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
