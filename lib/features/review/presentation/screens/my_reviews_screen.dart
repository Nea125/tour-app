import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../tour/presentation/providers/tour_provider.dart';
import '../../domain/entities/review.dart';
import '../providers/review_provider.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(myReviewsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Reviews')),
      body: reviewsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.read(myReviewsControllerProvider.notifier).refresh(),
        ),
        data: (reviews) {
          if (reviews.isEmpty) {
            return const EmptyView(
              message: 'You have not written any reviews yet.',
              icon: Icons.rate_review_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(myReviewsControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.s16),
              itemCount: reviews.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.s10),
              itemBuilder: (context, index) {
                final review = reviews[index];
                final tourAsync = ref.watch(tourByIdProvider(review.tourId));
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tourAsync.valueOrNull?.title ?? '...',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            RatingStars(
                              rating: review.rating.toDouble(),
                              size: 14,
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () =>
                                  _editReview(context, ref, review),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(review.comment),
                        const SizedBox(height: AppSpacing.s6),
                        Text(
                          Formatters.date(review.createdAt),
                          style: const TextStyle(
                            fontSize: AppFontSizes.f11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _editReview(
    BuildContext context,
    WidgetRef ref,
    Review review,
  ) async {
    final commentController = TextEditingController(text: review.comment);
    double rating = review.rating.toDouble();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Review'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InteractiveRatingStars(
                    rating: rating,
                    onChanged: (v) => setState(() => rating = v),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Comment'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final error = await ref
                        .read(myReviewsControllerProvider.notifier)
                        .updateReview(
                          id: review.id,
                          rating: rating.round(),
                          comment: commentController.text.trim(),
                        );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
