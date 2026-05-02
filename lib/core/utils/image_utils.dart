import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io';

/// Returns an [Image] widget from a network URL or local file path.
/// On web, [localImagePath] is ignored (dart:io is unavailable).
Widget buildToolImage({
  required String? imageUrl,
  required String? localImagePath,
  required Widget placeholder,
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
}) {
  if (imageUrl != null && imageUrl.isNotEmpty) {
    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
  if (!kIsWeb && localImagePath != null && localImagePath.isNotEmpty) {
    final f = File(localImagePath);
    if (f.existsSync()) {
      return Image.file(
        f,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
  }
  return placeholder;
}

/// Returns an [ImageProvider] for use in [DecorationImage] / [Image].
/// On web, only network images are returned.
ImageProvider? buildImageProvider(String? imageUrl, String? localImagePath) {
  if (imageUrl != null && imageUrl.isNotEmpty) {
    return NetworkImage(imageUrl);
  }
  if (!kIsWeb && localImagePath != null && localImagePath.isNotEmpty) {
    final f = File(localImagePath);
    if (f.existsSync()) return FileImage(f);
  }
  return null;
}

/// Builds an [Image] from a picked [XFile] — web uses network (blob URL),
/// mobile uses [Image.file].
Widget buildPickedImage({
  required Object xfile, // XFile — typed as Object to avoid dart:io import here
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
}) {
  final path = (xfile as dynamic).path as String;
  if (kIsWeb) {
    return Image.network(path, fit: fit, width: width, height: height);
  }
  return Image.file(File(path), fit: fit, width: width, height: height);
}
