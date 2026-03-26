import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/review_model.dart';

class BookReviewTile extends StatelessWidget {
  const BookReviewTile({
    super.key,
    required this.review,
    required this.accentColor,
  });

  final ReviewModel review;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: accentColor.withOpacity(0.2),
                backgroundImage: review.userAvatarUrl != null
                    ? CachedNetworkImageProvider(review.userAvatarUrl!)
                    : null,
                child: review.userAvatarUrl == null
                    ? Icon(Icons.person, size: 14, color: accentColor)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                review.userName ?? 'İsimsiz',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (sIndex) => Icon(
                    sIndex < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 14,
                    color: const Color(0xFFFFC107),
                  ),
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Color reviewAccentFromCategory(String? rawColor) {
  if (rawColor == null || rawColor.isEmpty) return AppColors.primary;
  try {
    return Color(int.parse(rawColor.replaceFirst('#', '0xFF')));
  } catch (_) {
    return AppColors.primary;
  }
}
