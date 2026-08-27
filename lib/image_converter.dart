import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

import 'image_conversion_result.dart';

class ImageConverter {
  static ImageConversionResult? convertCameraImage(
    CameraImage image,
    CameraLensDirection lensDirection,
  ) {
    if (image.format.group != ImageFormatGroup.yuv420) {
      return null;
    }

    final width = image.width;
    final height = image.height;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    var result = img.Image(width: width, height: height);

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final yRowStride = yPlane.bytesPerRow;
    final uRowStride = uPlane.bytesPerRow;
    final vRowStride = vPlane.bytesPerRow;

    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final yIndex = y * yRowStride + x;

        final uvX = x ~/ 2;
        final uvY = y ~/ 2;

        final uIndex = uvY * uRowStride + uvX * uPixelStride;
        final vIndex = uvY * vRowStride + uvX * vPixelStride;

        final yValue = yBytes[yIndex];
        final uValue = uBytes[uIndex];
        final vValue = vBytes[vIndex];

        var r = yValue + 1.402 * (vValue - 128);
        var g = yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128);
        var b = yValue + 1.772 * (uValue - 128);

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        result.setPixelRgb(x, y, r.toInt(), g.toInt(), b.toInt());
      }
    }

    // Исправляем ориентацию изображения.
    // Исправляем ориентацию изображения.
    if (lensDirection == CameraLensDirection.back) {
      result = img.copyRotate(result, angle: 90);
    } else if (lensDirection == CameraLensDirection.front) {
      result = img.copyRotate(result, angle: -90);
    }

    final jpegBytes = Uint8List.fromList(img.encodeJpg(result, quality: 90));

    return ImageConversionResult(image: result, jpegBytes: jpegBytes);
  }
}
