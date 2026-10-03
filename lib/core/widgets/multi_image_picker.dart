import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import 'app_network_image.dart';

/// Form field for several images the API receives as multipart uploads.
/// Each value is either a server-hosted image URL or the local path of a
/// photo just picked on-device; the first image is the cover.
///
/// With [canAddRemove] off (editing an existing record, where the API can
/// only replace images in place), tapping an image swaps it for a new one
/// and the count stays fixed.
class MultiImagePickerField extends FormField<List<String>> {
  MultiImagePickerField({
    super.key,
    required String label,
    List<String> initialValue = const [],
    required ValueChanged<List<String>> onChanged,
    bool required = false,
    bool canAddRemove = true,
    int maxImages = 10,
  }) : super(
         initialValue: List.unmodifiable(initialValue),
         validator: (value) => required && (value == null || value.isEmpty)
             ? 'Add at least one image'
             : null,
         builder: (state) {
           final images = state.value ?? const <String>[];

           void update(List<String> next) {
             state.didChange(List.unmodifiable(next));
             onChanged(next);
           }

           Future<void> addImages() async {
             final room = maxImages - images.length;
             // pickMultiImage rejects a limit below 2.
             final picked = room == 1
                 ? [
                     ?await ImagePicker().pickImage(
                       source: ImageSource.gallery,
                       maxWidth: 1600,
                       imageQuality: 85,
                     ),
                   ]
                 : await ImagePicker().pickMultiImage(
                     maxWidth: 1600,
                     imageQuality: 85,
                     limit: room,
                   );
             if (picked.isEmpty) return;
             update([...images, ...picked.take(room).map((x) => x.path)]);
           }

           Future<void> replaceAt(int index) async {
             final picked = await ImagePicker().pickImage(
               source: ImageSource.gallery,
               maxWidth: 1600,
               imageQuality: 85,
             );
             if (picked == null) return;
             update([...images]..[index] = picked.path);
           }

           void removeAt(int index) => update([...images]..removeAt(index));

           final canAdd = canAddRemove && images.length < maxImages;

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 children: [
                   Expanded(
                     child: Text(
                       label,
                       style: Theme.of(state.context).textTheme.labelLarge,
                     ),
                   ),
                   if (canAddRemove)
                     Text(
                       '${images.length}/$maxImages',
                       style: const TextStyle(
                         color: AppColors.textSecondary,
                         fontSize: 12,
                       ),
                     ),
                 ],
               ),
               const SizedBox(height: AppSpacing.s8),
               SizedBox(
                 height: 110,
                 child: ListView.separated(
                   scrollDirection: Axis.horizontal,
                   itemCount: images.length + (canAdd ? 1 : 0),
                   separatorBuilder: (_, _) =>
                       const SizedBox(width: AppSpacing.s8),
                   itemBuilder: (context, index) {
                     if (index == images.length) {
                       return _AddTile(onTap: addImages);
                     }
                     return _ImageTile(
                       path: images[index],
                       isCover: index == 0,
                       onTap: () => replaceAt(index),
                       onRemove: canAddRemove ? () => removeAt(index) : null,
                     );
                   },
                 ),
               ),
               const SizedBox(height: AppSpacing.s6),
               Text(
                 canAddRemove
                     ? 'The first image is the cover. Tap an image to change it.'
                     : images.isEmpty
                     ? 'No images. Images can only be added when creating.'
                     : 'Tap an image to replace it.',
                 style: const TextStyle(
                   color: AppColors.textSecondary,
                   fontSize: 12,
                 ),
               ),
               if (state.hasError)
                 Padding(
                   padding: const EdgeInsets.only(top: AppSpacing.s4),
                   child: Text(
                     state.errorText!,
                     style: const TextStyle(
                       color: AppColors.error,
                       fontSize: 12,
                     ),
                   ),
                 ),
             ],
           );
         },
       );
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
            SizedBox(height: AppSpacing.s4),
            Text(
              'Add photos',
              style: TextStyle(color: AppColors.primary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String path;
  final bool isCover;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _ImageTile({
    required this.path,
    required this.isCover,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final image = path.startsWith('http')
        ? AppNetworkImage(url: path, width: 110, height: 110)
        : Image.file(File(path), width: 110, height: 110, fit: BoxFit.cover);

    return SizedBox(
      width: 110,
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: image,
              ),
            ),
          ),
          if (isCover)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s6,
                  vertical: AppSpacing.s2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Cover',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.s2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
