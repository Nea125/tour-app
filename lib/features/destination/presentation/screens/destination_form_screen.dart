import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_app/core/widgets/multi_image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../domain/entities/destination.dart';
import '../../domain/entities/destination_status.dart';
import '../providers/destination_provider.dart';
import '../../../../core/constants/app_spacing.dart';

class DestinationFormScreen extends ConsumerStatefulWidget {
  final Destination? destination;
  const DestinationFormScreen({super.key, this.destination});

  @override
  ConsumerState<DestinationFormScreen> createState() =>
      _DestinationFormScreenState();
}

class _DestinationFormScreenState extends ConsumerState<DestinationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _provinceController;
  late final TextEditingController _countryController;
  late final TextEditingController _descriptionController;
  late List<String> _images;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  // The API has no destination status; kept as-is so edits don't flip it.
  DestinationStatus _status = DestinationStatus.active;
  bool _submitting = false;

  bool get _isEditing => widget.destination != null;

  @override
  void initState() {
    super.initState();
    final d = widget.destination;
    _nameController = TextEditingController(text: d?.name ?? '');
    _provinceController = TextEditingController(text: d?.province ?? '');
    _countryController = TextEditingController(text: d?.country ?? '');
    _descriptionController = TextEditingController(text: d?.description ?? '');
    _images = d == null
        ? []
        : d.images.isNotEmpty
        ? d.images
        : [if (d.imageUrl.isNotEmpty) d.imageUrl];
    _latController = TextEditingController(text: d?.latitude.toString() ?? '');
    _lngController = TextEditingController(text: d?.longitude.toString() ?? '');
    _status = d?.status ?? DestinationStatus.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _provinceController.dispose();
    _countryController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final now = DateTime.now();
    final destination = Destination(
      id: widget.destination?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      province: _provinceController.text.trim(),
      country: _countryController.text.trim(),
      latitude: double.parse(_latController.text.trim()),
      longitude: double.parse(_lngController.text.trim()),
      imageUrl: _images.isEmpty ? '' : _images.first,
      images: _images,
      status: _status,
      createdAt: widget.destination?.createdAt ?? now,
      updatedAt: now,
    );

    final controller = ref.read(destinationListControllerProvider.notifier);
    final error = _isEditing
        ? await controller.updateDestination(destination)
        : await controller.createDestination(destination);

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
        title: Text(_isEditing ? 'Edit Destination' : 'Add Destination'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s20),
          children: [
            CustomTextField(
              controller: _nameController,
              label: 'Destination Name',
              validator: (v) => Validators.required(v, label: 'Name'),
            ),
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _provinceController,
                    label: 'Province',
                    validator: (v) => Validators.required(v, label: 'Province'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: CustomTextField(
                    controller: _countryController,
                    label: 'Country',
                    validator: (v) => Validators.required(v, label: 'Country'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _latController,
                    label: 'Latitude',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (v) => Validators.number(v, label: 'Latitude'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: CustomTextField(
                    controller: _lngController,
                    label: 'Longitude',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (v) => Validators.number(v, label: 'Longitude'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            MultiImagePickerField(
              label: 'Images',
              initialValue: _images,
              // The API only accepts new images when creating.
              canAddRemove: !_isEditing,
              onChanged: (images) => _images = images,
            ),
            const SizedBox(height: AppSpacing.s16),
            CustomTextField(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 4,
              validator: (v) => Validators.required(v, label: 'Description'),
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
                  : Text(_isEditing ? 'Save Changes' : 'Create Destination'),
            ),
          ],
        ),
      ),
    );
  }
}
