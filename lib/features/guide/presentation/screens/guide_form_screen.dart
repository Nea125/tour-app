import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/entities/user_role.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../domain/entities/guide_status.dart';
import '../../domain/entities/tour_guide.dart';
import '../providers/guide_provider.dart';
import '../../../../core/constants/app_spacing.dart';

class GuideFormScreen extends ConsumerStatefulWidget {
  final TourGuide? guide;
  const GuideFormScreen({super.key, this.guide});

  @override
  ConsumerState<GuideFormScreen> createState() => _GuideFormScreenState();
}

class _GuideFormScreenState extends ConsumerState<GuideFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _licenseController;
  late final TextEditingController _experienceController;
  late final TextEditingController _languagesController;
  late final TextEditingController _bioController;
  String? _userId;
  GuideStatus _status = GuideStatus.active;
  bool _submitting = false;

  bool get _isEditing => widget.guide != null;

  @override
  void initState() {
    super.initState();
    final g = widget.guide;
    _licenseController = TextEditingController(text: g?.licenseNumber ?? '');
    _experienceController = TextEditingController(
      text: g?.experienceYears.toString() ?? '',
    );
    _languagesController = TextEditingController(text: g?.languages ?? '');
    _bioController = TextEditingController(text: g?.bio ?? '');
    _userId = g?.userId;
    _status = g?.status ?? GuideStatus.active;
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _experienceController.dispose();
    _languagesController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a guide user'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final now = DateTime.now();
    final guide = TourGuide(
      id: widget.guide?.id ?? '',
      userId: _userId!,
      licenseNumber: _licenseController.text.trim(),
      experienceYears: int.parse(_experienceController.text.trim()),
      languages: _languagesController.text.trim(),
      bio: _bioController.text.trim(),
      status: _status,
      createdAt: widget.guide?.createdAt ?? now,
      updatedAt: now,
    );

    final controller = ref.read(guideListControllerProvider.notifier);
    final error = _isEditing
        ? await controller.updateGuide(guide)
        : await controller.createGuide(guide);

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
    final usersAsync = ref.watch(userListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Guide' : 'Add Guide')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s20),
          children: [
            if (_isEditing)
              CustomTextField(
                controller: TextEditingController(
                  text:
                      ref
                          .watch(userByIdProvider(_userId!))
                          .valueOrNull
                          ?.fullName ??
                      '',
                ),
                label: 'Guide User',
                enabled: false,
              )
            else
              usersAsync.when(
                data: (users) {
                  final guideUsers = users
                      .where((u) => u.role == UserRole.tourGuide)
                      .toList();
                  return DropdownButtonFormField<String>(
                    initialValue: guideUsers.any((u) => u.id == _userId)
                        ? _userId
                        : null,
                    decoration: const InputDecoration(labelText: 'Guide User'),
                    items: guideUsers
                        .map(
                          (u) => DropdownMenuItem(
                            value: u.id,
                            child: Text('${u.fullName} (${u.email})'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _userId = v),
                    validator: (v) =>
                        v == null ? 'Select a user with Tour Guide role' : null,
                  );
                },
                loading: () => const LoadingWidget(),
                error: (e, _) => ErrorView(message: e.toString()),
              ),
            const SizedBox(height: AppSpacing.s16),
            CustomTextField(
              controller: _licenseController,
              label: 'License Number',
              validator: (v) => Validators.required(v, label: 'License number'),
            ),
            const SizedBox(height: AppSpacing.s16),
            CustomTextField(
              controller: _experienceController,
              label: 'Years of Experience',
              keyboardType: TextInputType.number,
              validator: (v) => Validators.number(v, label: 'Experience'),
            ),
            const SizedBox(height: AppSpacing.s16),
            CustomTextField(
              controller: _languagesController,
              label: 'Languages (comma separated)',
              hint: 'English, French',
            ),
            const SizedBox(height: AppSpacing.s16),
            CustomTextField(
              controller: _bioController,
              label: 'Bio',
              maxLines: 4,
              validator: (v) => Validators.required(v, label: 'Bio'),
            ),
            const SizedBox(height: AppSpacing.s8),
            DropdownButtonFormField<GuideStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: GuideStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: AppSpacing.s16),
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
                  : Text(_isEditing ? 'Save Changes' : 'Add Guide'),
            ),
          ],
        ),
      ),
    );
  }
}
