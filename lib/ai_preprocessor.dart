import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'ai_input.dart';

class AiPreprocessor {
  static const int targetSize = 320;

  AiInput? process(img.Image image) {
    final resized = img.copyResize(
      image,
      width: targetSize,
      height: targetSize,
      maintainAspect: false,
    );

    final pixels = Uint8List.fromList(
      resized.getBytes(order: img.ChannelOrder.rgb),
    );

    return AiInput(
      pixels: pixels,
      width: resized.width,
      height: resized.height,
    );
  }
}
