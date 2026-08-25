import 'dart:typed_data';

class AiFrame {
  final Uint8List imageBytes;
  final int width;
  final int height;

  const AiFrame({
    required this.imageBytes,
    required this.width,
    required this.height,
  });
}
