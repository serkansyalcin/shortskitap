import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class StarRatingWidget extends StatelessWidget {
  const StarRatingWidget({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 40,
  });

  final int rating;
  final ValueChanged<int> onRatingChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final filled = starValue <= rating;
        return GestureDetector(
          onTap: () => onRatingChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: filled ? const Color(0xFFFBBF24) : AppColors.lightOutline,
            ),
          ),
        );
      }),
    );
  }
}
