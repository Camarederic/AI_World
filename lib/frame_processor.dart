import 'package:camera/camera.dart';

import 'ai_frame.dart';

import 'ai_preprocessor.dart';
import 'image_converter.dart';
import 'processed_frame.dart';

class FrameProcessor {
  DateTime? _lastProcessedTime;

  final AiPreprocessor _preprocessor = AiPreprocessor();

  ProcessedFrame? process(
    CameraImage image,
    CameraLensDirection lensDirection,
  ) {
    final now = DateTime.now();

    if (_lastProcessedTime == null ||
        now.difference(_lastProcessedTime!).inMilliseconds >= 200) {
      _lastProcessedTime = now;

      final conversionResult = ImageConverter.convertCameraImage(
        image,
        lensDirection,
      );

      if (conversionResult == null) {
        return null;
      }

      final aiFrame = AiFrame(
        imageBytes: conversionResult.jpegBytes,
        width: conversionResult.image.width,
        height: conversionResult.image.height,
      );

      final aiInput = _preprocessor.process(conversionResult.image);

      if (aiInput == null) {
        return null;
      }

      return ProcessedFrame(aiFrame: aiFrame, aiInput: aiInput);
    }

    return null;
  }
}
