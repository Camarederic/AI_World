import 'dart:typed_data';

import 'package:camera/camera.dart';

import 'image_converter.dart';

class FrameProcessor {
  DateTime? _lastProcessedTime;

  Uint8List? process(CameraImage image, CameraLensDirection lensDirection) {
    final now = DateTime.now();

    if (_lastProcessedTime == null ||
        now.difference(_lastProcessedTime!).inMilliseconds >= 200) {
      _lastProcessedTime = now;

      return ImageConverter.convertCameraImage(image, lensDirection);
    }

    return null;
  }
}
