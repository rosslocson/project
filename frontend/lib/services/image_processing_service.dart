import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Platform-safe image resize/compress.
///
/// - Flutter Web: NO `dart:isolate` usage (web runtime doesn't support it).
/// - Android/iOS/Desktop: still avoids UI blocking by keeping the work small.
///   (If you later want isolates on non-web, use conditional imports.)
class ImageProcessingService {
  static Future<Uint8List> resizeAndCompressJpg({
    required Uint8List bytes,
    int maxSide = 512,
    int quality = 85,
  }) async {
    // Web-safe: run synchronously but still behind an async boundary.
    // This avoids the unsupported isolate runtime on web.
    return Future<Uint8List>(() {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;

      var w = decoded.width;
      var h = decoded.height;

      if (w > maxSide || h > maxSide) {
        if (w >= h) {
          h = (maxSide * h) ~/ w;
          w = maxSide;
        } else {
          w = (maxSide * w) ~/ h;
          h = maxSide;
        }
      }

      final resized = img.copyResize(
        decoded,
        width: w,
        height: h,
        interpolation: img.Interpolation.average,
      );

      final compressed = img.encodeJpg(resized, quality: quality);
      return Uint8List.fromList(compressed);
    });
  }
}


