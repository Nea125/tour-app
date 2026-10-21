import 'dart:io';
import 'package:flutter/material.dart';

import '../network/api_json.dart';

// ImageProvider profileImageProvider(String path) {
//   return path.startsWith('http')
//       ? NetworkImage(path, headers: ApiJson.imageHeaders(path))
//       : FileImage(File(path));
// }

ImageProvider? profileImageProvider(String? path) {
  if (path == null || path.trim().isEmpty) {
    return null;
  }

  if (path.startsWith('http')) {
    return NetworkImage(
      path,
      headers: ApiJson.imageHeaders(path),
    );
  }

  return FileImage(File(path));
}
