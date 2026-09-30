import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import 'app_network_image.dart';

/// Form field for a single image the API will receive as a multipart
/// upload. Its value is either the current server-hosted image URL or the
/// local path of a photo just picked from the gallery.
class ImagePickerField extends FormField<String> {
  ImagePickerField({
    super.key,
    required String label,
    String initialValue = '',
    required ValueChanged<String> onChanged,
    bool required = false,
  }) : super(
         initialValue: initialValue,
         validator: (value) => required && (value == null || value.isEmpty)
             ? '$label is required'
             : null,
         builder: (state) {
           final path = state.value ?? '';
           Future<void> pick() async {
             final picked = await ImagePicker().pickImage(
               source: ImageSource.gallery,
               maxWidth: 1600,
               imageQuality: 85,
             );
             if (picked == null) return;
             state.didChange(picked.path);
             onChanged(picked.path);
           }

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(label, style: Theme.of(state.context).textTheme.labelLarge),
               const SizedBox(height: AppSpacing.s8),
               InkWell(
                 onTap: pick,
                 borderRadius: BorderRadius.circular(16),
                 child: path.startsWith('http') || path.isEmpty
                     ? AppNetworkImage(
                         url: path,
                         height: 160,
                         width: double.infinity,
                         placeholderIcon: Icons.add_photo_alternate_outlined,
                       )
                     : ClipRRect(
                         borderRadius: BorderRadius.circular(16),
                         child: Image.file(
                           File(path),
                           height: 160,
                           width: double.infinity,
                           fit: BoxFit.cover,
                         ),
                       ),
               ),
               TextButton.icon(
                 onPressed: pick,
                 icon: const Icon(Icons.photo_library_outlined),
                 label: Text(path.isEmpty ? 'Choose image' : 'Change image'),
               ),
               if (state.hasError)
                 Text(
                   state.errorText!,
                   style: const TextStyle(color: AppColors.error, fontSize: 12),
                 ),
             ],
           );
         },
       );
}
