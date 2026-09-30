import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../guide/presentation/providers/guide_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../domain/entities/schedule_status.dart';
import '../../domain/entities/tour_schedule.dart';
import '../providers/schedule_provider.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class ScheduleFormScreen extends ConsumerStatefulWidget {
  final String tourId;
  final TourSchedule? schedule;
  const ScheduleFormScreen({super.key, required this.tourId, this.schedule});

  @override
  ConsumerState<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends ConsumerState<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _capacityController;
  DateTime _startDate = DateTime.now().add(const Duration(days: 14));
  DateTime _endDate = DateTime.now().add(const Duration(days: 18));
  ScheduleStatus _status = ScheduleStatus.open;
  bool _submitting = false;

  bool get _isEditing => widget.schedule != null;

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _capacityController = TextEditingController(
      text: s?.capacity.toString() ?? '',
    );
    _startDate = s?.startDate ?? _startDate;
    _endDate = s?.endDate ?? _endDate;
    _status = s?.status ?? ScheduleStatus.open;
  }

  @override
  void dispose() {
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final now = DateTime.now();
    final schedule = TourSchedule(
      id: widget.schedule?.id ?? '',
      tourId: widget.tourId,
      startDate: _startDate,
      endDate: _endDate,
      capacity: int.parse(_capacityController.text.trim()),
      status: _status,
      createdAt: widget.schedule?.createdAt ?? now,
      updatedAt: now,
    );

    final controller = ref.read(scheduleControllerProvider.notifier);
    final error = _isEditing
        ? await controller.updateSchedule(schedule)
        : await controller.createSchedule(schedule);

    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Schedule' : 'Add Schedule'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s20),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isStart: true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                          ),
                          child: Text(Formatters.date(_startDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isStart: false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                          ),
                          child: Text(Formatters.date(_endDate)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),
                CustomTextField(
                  controller: _capacityController,
                  label: 'Capacity',
                  keyboardType: TextInputType.number,
                  validator: (v) => Validators.number(v, label: 'Capacity'),
                ),
                const SizedBox(height: AppSpacing.s16),
                DropdownButtonFormField<ScheduleStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ScheduleStatus.values
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _status = v ?? _status),
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
                      : Text(_isEditing ? 'Save Changes' : 'Create Schedule'),
                ),
              ],
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: AppSpacing.s32),
            const Text(
              'Assigned Guides',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: AppFontSizes.f16,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            _GuideAssignmentSection(scheduleId: widget.schedule!.id),
          ],
        ],
      ),
    );
  }
}

class _GuideAssignmentSection extends ConsumerWidget {
  final String scheduleId;
  const _GuideAssignmentSection({required this.scheduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideIdsAsync = ref.watch(guideIdsForScheduleProvider(scheduleId));
    final allGuidesAsync = ref.watch(guideListControllerProvider);

    return guideIdsAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (assignedIds) {
        return allGuidesAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorView(message: e.toString()),
          data: (allGuides) {
            return Column(
              children: allGuides.map((guide) {
                final assigned = assignedIds.contains(guide.id);
                final userAsync = ref.watch(userByIdProvider(guide.userId));
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: assigned,
                  title: Text(
                    userAsync.valueOrNull?.fullName ?? guide.licenseNumber,
                  ),
                  subtitle: Text(
                    guide.languages,
                    style: const TextStyle(fontSize: AppFontSizes.f12),
                  ),
                  onChanged: (checked) async {
                    final controller = ref.read(
                      scheduleControllerProvider.notifier,
                    );
                    final error = checked == true
                        ? await controller.assignGuide(scheduleId, guide.id)
                        : await controller.removeGuide(scheduleId, guide.id);
                    if (context.mounted && error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
