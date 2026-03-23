import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Instagram Story (9:16) formatted shareable image overlay for a paragraph.
class ShareableParagraphOverlay extends StatelessWidget {
  final String content;
  final String bookTitle;
  final String? authorName;

  /// 0–5 selects the gradient theme
  final int themeIndex;

  const ShareableParagraphOverlay({
    Key? key,
    required this.content,
    required this.bookTitle,
    this.authorName,
    this.themeIndex = 0,
  }) : super(key: key);

  static const List<List<Color>> _gradients = [
    [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
    [Color(0xFF0D0D0D), Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
    [Color(0xFF2C3E50), Color(0xFF3498DB), Color(0xFF2980B9)],
    [Color(0xFF11998E), Color(0xFF1A5276), Color(0xFF0D3B33)],
    [Color(0xFF4A1942), Color(0xFF9B59B6), Color(0xFF341F3A)],
    [Color(0xFF1C1C1C), Color(0xFF2E7D32), Color(0xFF0A3D0A)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[themeIndex % _gradients.length];

    return Container(
      width: 400,
      height: 711, // 9:16 ratio → 400 × (16/9) ≈ 711
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          // Decorative quote mark background
          Positioned(
            top: -10,
            left: -10,
            child: Text(
              '\u201c',
              style: TextStyle(
                fontSize: 260,
                color: Colors.white.withOpacity(0.04),
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          Positioned(
            bottom: 140,
            right: -10,
            child: Text(
              '\u201d',
              style: TextStyle(
                fontSize: 180,
                color: Colors.white.withOpacity(0.04),
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),

          // Soft glow blob
          Positioned(
            top: 100,
            right: 40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.12),
              ),
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top brand chip
                _BrandChip(),

                const Spacer(),

                // Opening quote mark
                Text(
                  '\u201c',
                  style: TextStyle(
                    fontSize: 64,
                    color: AppColors.primary.withOpacity(0.8),
                    fontWeight: FontWeight.w900,
                    height: 0.8,
                  ),
                ),
                const SizedBox(height: 8),

                // Quote content
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.7,
                    letterSpacing: 0.2,
                  ),
                ),

                const Spacer(),

                // Thin divider line
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Book info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bookTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (authorName != null)
                            Text(
                              authorName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Bottom KitapLig brand
                Center(
                  child: Text(
                    'kitaplig.com',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.4),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.menu_book_rounded, size: 8, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text(
            'Kitaplig Alıntısı',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.8),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
