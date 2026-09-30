import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../providers/review_provider.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class AddReviewScreen extends ConsumerStatefulWidget {
  final String tourId;
  final String bookingId;
  const AddReviewScreen({
    super.key,
    required this.tourId,
    required this.bookingId,
  });

  @override
  ConsumerState<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends ConsumerState<AddReviewScreen> {
  final _commentController = TextEditingController();
  double _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a comment'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final error = await ref
        .read(myReviewsControllerProvider.notifier)
        .addReview(
          tourId: widget.tourId,
          bookingId: widget.bookingId,
          rating: _rating.round(),
          comment: _commentController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks for your review!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Write a Review')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How was your trip?', style: AppTextStyles.screenTitle),
            const SizedBox(height: AppSpacing.s8),
            const Text(
              'Your feedback helps other travelers.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s24),
            Center(
              child: InteractiveRatingStars(
                rating: _rating,
                size: 40,
                onChanged: (v) => setState(() => _rating = v),
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            CustomTextField(
              controller: _commentController,
              label: 'Your Review',
              hint: 'Tell us about your experience...',
              maxLines: 6,
            ),
            const SizedBox(height: AppSpacing.s24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: AppSpacing.s20,
                      width: AppSpacing.s20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}
