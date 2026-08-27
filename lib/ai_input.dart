import 'dart:typed_data';

class AiInput {
  final Uint8List pixels;
  final int width;
  final int height;

  const AiInput({
    required this.pixels,
    required this.width,
    required this.height,
  });
}
