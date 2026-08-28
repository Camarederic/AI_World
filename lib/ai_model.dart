import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'ai_input.dart';
import 'detection.dart';

class AiModel {
  Interpreter? _interpreter;

  List<String> _labels = [];

  static const double confidenceThreshold = 0.5;

  Future<void> initialize() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/models/efficientdet-lite0.tflite',
    );

    final labelsText = await rootBundle.loadString(
      'assets/labels/coco_labels.txt',
    );

    _labels = labelsText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    debugPrint('AI MODEL: загружено labels: ${_labels.length}');

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

  List<Detection>? detect(AiInput input) {
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

    final detections = <Detection>[];

    for (var i = 0; i < 25; i++) {
      final score = outputScores[0][i];

      if (score < confidenceThreshold) {
        continue;
      }

      final classId = outputClasses[0][i].toInt();

      final label = classId >= 0 && classId < _labels.length
          ? _labels[classId]
          : 'unknown';

      final box = outputBoxes[0][i];

      detections.add(
        Detection(
          label: label,
          classId: classId,
          score: score,
          top: box[0],
          left: box[1],
          bottom: box[2],
          right: box[3],
        ),
      );
    }

    debugPrint('AI DETECTIONS: ${detections.length}');

    for (final detection in detections) {
      debugPrint(
        'OBJECT: ${detection.label} | '
        'class=${detection.classId} | '
        'score=${(detection.score * 100).toStringAsFixed(1)}% | '
        'box=['
        '${detection.top.toStringAsFixed(3)}, '
        '${detection.left.toStringAsFixed(3)}, '
        '${detection.bottom.toStringAsFixed(3)}, '
        '${detection.right.toStringAsFixed(3)}'
        ']',
      );
    }

    return detections;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
