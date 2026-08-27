import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageConversionResult {
  final img.Image image;
  final Uint8List jpegBytes;

  const ImageConversionResult({required this.image, required this.jpegBytes});
}
