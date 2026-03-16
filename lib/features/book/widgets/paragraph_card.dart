import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/paragraph_model.dart';

class ParagraphCard extends StatelessWidget {
  final ParagraphModel paragraph;
  final bool isCurrent;
  final int total;
  final double fontSize;

  const ParagraphCard({
    super.key,
    required this.paragraph,
    required this.isCurrent,
    required this.total,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showBottomSheet(context),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        child: switch (paragraph.type) {
          ParagraphType.sceneBreak => _buildSceneBreak(context),
          ParagraphType.quote => _buildQuote(context),
          _ => _buildText(context),
        },
      ),
    );
  }

  Widget _buildText(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    return Center(
      child: Text(
        paragraph.content,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.8,
          color: textColor,
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildQuote(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '"',
            style: TextStyle(
              fontSize: 80,
              color: AppColors.primary.withOpacity(0.2),
              height: 0.8,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            paragraph.content,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.9,
              color: textColor,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSceneBreak(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 1,
            color: Theme.of(context).dividerColor,
          ),
          const SizedBox(height: 12),
          const Text(
            '⁂',
            style: TextStyle(
              fontSize: 24,
              color: AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 60,
            height: 1,
            color: Theme.of(context).dividerColor,
          ),
        ],
      ),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.share, color: AppColors.primary),
                title: const Text('Paylaş'),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareParagraph();
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_add_outlined, color: AppColors.primary),
                title: const Text('Yer İmi Ekle'),
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
      '"${paragraph.content}"\n\n— Shorts Kitap uygulamasından',
      subject: 'Shorts Kitap',
    );
  }
}
