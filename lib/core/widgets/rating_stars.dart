import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showValue;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: AppColors.secondary, size: size),
        SizedBox(width: size * 0.2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size * 0.85,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class InteractiveRatingStars extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onChanged;
  final double size;

  const InteractiveRatingStars({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return GestureDetector(
          onTap: () => onChanged(starValue.toDouble()),
          child: Icon(
            starValue <= rating
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            color: AppColors.secondary,
            size: size,
          ),
        );
      }),
    );
  }
}
