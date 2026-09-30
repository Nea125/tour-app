import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/itinerary.dart';
import '../../domain/entities/itinerary_activity.dart';
import '../providers/itinerary_provider.dart';
import 'itinerary_day_form_screen.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Admin/Tour Manager screen for managing a tour's itinerary: add/remove
/// days, and add/edit/remove/reorder each day's activities.
class ItineraryManagementScreen extends ConsumerWidget {
  final String tourId;
  const ItineraryManagementScreen({super.key, required this.tourId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryAsync = ref.watch(itineraryByTourProvider(tourId));

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Itinerary')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ItineraryDayFormScreen(tourId: tourId),
          ),
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: itineraryAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (days) {
          if (days.isEmpty) {
            return const Center(
              child: Text(
                'No itinerary days yet. Tap + to add Day 1.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.s16),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              return _DayCard(day: day, tourId: tourId);
            },
          );
        },
      ),
    );
  }
}

Future<void> _showActivityDialog(
  BuildContext context,
  WidgetRef ref, {
  required String itineraryId,
  required int sortOrder,
  ItineraryActivity? existing,
}) async {
  final titleController = TextEditingController(text: existing?.title ?? '');
  final descController = TextEditingController(
    text: existing?.description ?? '',
  );
  final locationController = TextEditingController(
    text: existing?.location ?? '',
  );
  TimeOfDay start = existing?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay end = existing?.endTime ?? const TimeOfDay(hour: 10, minute: 0);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(existing == null ? 'Add Activity' : 'Edit Activity'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: start,
                            );
                            if (picked != null) setState(() => start = picked);
                          },
                          child: Text('Start: ${start.format(context)}'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: end,
                            );
                            if (picked != null) setState(() => end = picked);
                          },
                          child: Text('End: ${end.format(context)}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final activity = ItineraryActivity(
                    id: existing?.id ?? '',
                    itineraryId: itineraryId,
                    title: titleController.text.trim(),
                    description: descController.text.trim(),
                    startTime: start,
                    endTime: end,
                    location: locationController.text.trim(),
                    sortOrder: existing?.sortOrder ?? sortOrder,
                  );
                  final controller = ref.read(
                    itineraryControllerProvider.notifier,
                  );
                  if (existing == null) {
                    await controller.addActivity(activity);
                  } else {
                    await controller.updateActivity(activity);
                  }
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
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

class _DayCard extends ConsumerWidget {
  final Itinerary day;
  final String tourId;
  const _DayCard({required this.day, required this.tourId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesByItineraryProvider(day.id));

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s14),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Day ${day.dayNumber}: ${day.title}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ItineraryDayFormScreen(tourId: tourId, day: day),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete day'),
                        content: Text(
                          'Delete Day ${day.dayNumber} and all its activities?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref
                          .read(itineraryControllerProvider.notifier)
                          .deleteDay(day.id);
                    }
                  },
                ),
              ],
            ),
            Text(
              day.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppFontSizes.f13,
              ),
            ),
            const SizedBox(height: AppSpacing.s10),
            activitiesAsync.when(
              data: (activities) => Column(
                children: [
                  ...activities.map((a) => _ActivityTile(activity: a)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Activity'),
                      onPressed: () => _showActivityDialog(
                        context,
                        ref,
                        itineraryId: day.id,
                        sortOrder: activities.length,
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorView(message: e.toString()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends ConsumerWidget {
  final ItineraryActivity activity;
  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        activity.title,
        style: const TextStyle(
          fontSize: AppFontSizes.f13,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${activity.startTime.format(context)} - ${activity.endTime.format(context)} • ${activity.location}',
        style: const TextStyle(fontSize: AppFontSizes.f11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined, size: 16),
            onPressed: () => _showActivityDialog(
              context,
              ref,
              itineraryId: activity.itineraryId,
              sortOrder: activity.sortOrder,
              existing: activity,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 16,
              color: AppColors.error,
            ),
            onPressed: () => ref
                .read(itineraryControllerProvider.notifier)
                .deleteActivity(activity.id),
          ),
        ],
      ),
    );
  }
}
