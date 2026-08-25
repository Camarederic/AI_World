import 'package:camera/camera.dart';

import 'ai_frame.dart';
import 'image_converter.dart';

class FrameProcessor {
  DateTime? _lastProcessedTime;

  AiFrame? process(CameraImage image, CameraLensDirection lensDirection) {
    final now = DateTime.now();

    if (_lastProcessedTime == null ||
        now.difference(_lastProcessedTime!).inMilliseconds >= 200) {
      _lastProcessedTime = now;

      final jpeg = ImageConverter.convertCameraImage(image, lensDirection);

      if (jpeg == null) {
        return null;
      }

      return AiFrame(
        imageBytes: jpeg,
        width: image.width,
        height: image.height,
      );
    }

    return null;
  }
}
