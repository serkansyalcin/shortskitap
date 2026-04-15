import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../core/models/daily_quote_model.dart';

class ShareableQuoteOverlay extends StatelessWidget {
  final DailyQuoteModel quote;
  final bool isDark;

  const ShareableQuoteOverlay({
    super.key,
    required this.quote,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    // We use a fixed width for consistent capture quality
    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Günün Alıntısı',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.format_quote_rounded,
                size: 40,
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            '"${quote.content}"',
            style: TextStyle(
              fontSize: 22,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              height: 1.6,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.book.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (quote.book.author != null)
                      Text(
                        quote.book.author!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          const Divider(height: 1),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'kitaplig.com',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black26,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
