import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'ai_input.dart';

class AiModel {
  Interpreter? _interpreter;

  Future<void> initialize() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/models/efficientdet-lite0.tflite',
    );

    final inputTensors = _interpreter!.getInputTensors();
    final outputTensors = _interpreter!.getOutputTensors();

    debugPrint('AI MODEL');
    debugPrint('Входных tensors: ${inputTensors.length}');

    for (final tensor in inputTensors) {
      debugPrint(
        'INPUT: '
        'shape=${tensor.shape} '
        'type=${tensor.type}',
      );
    }

    debugPrint('Выходных tensors: ${outputTensors.length}');

    for (final tensor in outputTensors) {
      debugPrint(
        'OUTPUT: '
        'shape=${tensor.shape} '
        'type=${tensor.type}',
      );
    }
  }

  List<dynamic>? detect(AiInput input) {
    if (_interpreter == null) {
      debugPrint('AI MODEL ERROR: модель не загружена');
      return null;
    }

    if (input.width != 320 || input.height != 320) {
      debugPrint(
        'AI MODEL ERROR: неправильный размер входа '
        '${input.width}x${input.height}',
      );
      return null;
    }

    final inputTensor = [
      [
        for (var y = 0; y < 320; y++)
          [
            for (var x = 0; x < 320; x++)
              [
                input.pixels[(y * 320 + x) * 3],
                input.pixels[(y * 320 + x) * 3 + 1],
                input.pixels[(y * 320 + x) * 3 + 2],
              ],
          ],
      ],
    ];

    final outputBoxes = List.generate(
      1,
      (_) => List.generate(25, (_) => List.filled(4, 0.0)),
    );

    final outputClasses = List.generate(1, (_) => List.filled(25, 0.0));

    final outputScores = List.generate(1, (_) => List.filled(25, 0.0));

    final outputCount = List.filled(1, 0.0);

    final outputs = {
      0: outputBoxes,
      1: outputClasses,
      2: outputScores,
      3: outputCount,
    };

    final stopwatch = Stopwatch()..start();

    _interpreter!.runForMultipleInputs([inputTensor], outputs);

    stopwatch.stop();

    debugPrint('AI INFERENCE: ${stopwatch.elapsedMilliseconds} ms');

    debugPrint('AI DETECTIONS: ${outputCount[0]}');

    for (var i = 0; i < 25; i++) {
      final score = outputScores[0][i];

      if (score > 0.3) {
        debugPrint(
          'Detection #$i | '
          'class=${outputClasses[0][i]} | '
          'score=$score | '
          'box=${outputBoxes[0][i]}',
        );
      }
    }

    return [outputBoxes, outputClasses, outputScores, outputCount];
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
