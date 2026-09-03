import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Helper utility for safe cross-platform image loading (Web, Android, iOS, Desktop)
class ImageHelper {
  ImageHelper._();

  /// Returns a valid [ImageProvider] whether on Web (blob/url) or Native (local file)
  static ImageProvider? getVehicleImageProvider(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    if (kIsWeb || path.startsWith('blob:') || path.startsWith('http')) {
      return NetworkImage(path);
    }
    try {
      final file = File(path);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Checks whether the image path exists and is accessible
  static bool hasValidImage(String? path) {
    if (path == null || path.trim().isEmpty) return false;
    if (kIsWeb || path.startsWith('blob:') || path.startsWith('http')) {
      return true;
    }
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }
}
