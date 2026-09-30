import 'dart:io';
import 'package:flutter/material.dart';

import '../network/api_json.dart';

/// Resolves a user's stored `profileImage` string to the right
/// [ImageProvider] — the API-hosted avatar URL, or a local file for a
/// photo just picked on-device via the camera/gallery.
ImageProvider profileImageProvider(String path) {
  return path.startsWith('http')
      ? NetworkImage(path, headers: ApiJson.imageHeaders(path))
      : FileImage(File(path));
}
