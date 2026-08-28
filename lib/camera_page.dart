import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'ai_frame.dart';
import 'detection.dart';
import 'detection_overlay.dart';
import 'frame_processor.dart';

import 'ai_model.dart';
import 'ai_input.dart';

class CameraPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraPage({super.key, required this.cameras});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;

  final FrameProcessor _frameProcessor = FrameProcessor();

  final AiModel _aiModel = AiModel();

  bool _aiModelReady = false;

  int _currentCameraIndex = 0;

  bool _isCameraInitialized = false;
  bool _isProcessingFrames = false;

  // Общее количество полученных кадров.
  int _receivedFrames = 0;

  // Количество кадров, которые реально передали в обработку.
  int _processedFrames = 0;

  // Реальный FPS входящего потока CameraImage.
  double _fps = 0.0;

  // Счётчики для расчёта FPS.
  DateTime? _fpsStartTime;
  int _fpsFrameCount = 0;

  Timer? _fpsTimer;

  Timer? _aiTimer;

  // Размер последнего полученного кадра.
  int _imageWidth = 0;
  int _imageHeight = 0;

  AiFrame? _lastAiFrame;
  List<Detection> _detections = [];

  AiInput? _latestAiInput;

  bool _isAiProcessing = false;

  void _startAiProcessing() {
    _aiTimer?.cancel();

    _aiTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (!_aiModelReady) {
        return;
      }

      if (_isAiProcessing) {
        return;
      }

      final input = _latestAiInput;

      if (input == null) {
        return;
      }

      _isAiProcessing = true;

      try {
        debugPrint('AI INFERENCE: запускаем inference');

        final detections = _aiModel.detect(input);

        if (detections != null && mounted) {
          setState(() {
            _detections = detections;
          });
        }
      } finally {
        _isAiProcessing = false;
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _initializeAiModel();
    _initializeCamera();
  }

  Future<void> _initializeAiModel() async {
    debugPrint('AI MODEL: начинаем загрузку');

    try {
      await _aiModel.initialize();
      _aiModelReady = true;

      debugPrint('AI MODEL: модель успешно загружена');
    } catch (e) {
      debugPrint('AI MODEL ERROR: $e');
    }
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) {
      return;
    }

    final camera = widget.cameras[_currentCameraIndex];

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _controller = controller;

      // Сбрасываем данные именно для новой камеры.
      _receivedFrames = 0;
      _processedFrames = 0;
      _fps = 0.0;
      _fpsFrameCount = 0;
      _fpsStartTime = null;
      _imageWidth = 0;
      _imageHeight = 0;

      setState(() {
        _isCameraInitialized = true;
      });

      _startFpsCalculation();
      _startAiProcessing();

      await _startImageStream();
    } on CameraException catch (e) {
      debugPrint('Ошибка камеры: ${e.code} - ${e.description}');
    }
  }

  Future<void> _startImageStream() async {
    if (_controller == null) {
      return;
    }

    if (_isProcessingFrames) {
      return;
    }

    _isProcessingFrames = true;

    await _controller!.startImageStream((CameraImage image) {
      _processCameraFrame(image);
    });
  }

  void _processCameraFrame(CameraImage image) {
    _receivedFrames++;

    _imageWidth = image.width;
    _imageHeight = image.height;

    _fpsFrameCount++;

    final processedFrame = _frameProcessor.process(
      image,
      widget.cameras[_currentCameraIndex].lensDirection,
    );

    if (processedFrame != null) {
      _processedFrames++;

      final aiFrame = processedFrame.aiFrame;
      final aiInput = processedFrame.aiInput;

      _latestAiInput = aiInput;

      if (mounted) {
        setState(() {
          _lastAiFrame = aiFrame;
        });
      }

      debugPrint(
        'AI обработал кадр #$_processedFrames | '
        'получено: $_receivedFrames | '
        'размер: ${aiFrame.width}x${aiFrame.height} | '
        'JPEG: ${aiFrame.imageBytes.length} байт | '
        'AI INPUT: ${aiInput.width}x${aiInput.height}',
      );
    }

    if (_receivedFrames % 30 == 0) {
      debugPrint(
        'Получено: $_receivedFrames | '
        'Обработано: $_processedFrames | '
        'FPS: ${_fps.toStringAsFixed(1)} | '
        'Размер: ${image.width}x${image.height} | '
        'Плоскостей: ${image.planes.length}',
      );
    }

    if (_receivedFrames % 10 == 0 && mounted) {
      setState(() {});
    }
  }

  void _startFpsCalculation() {
    _fpsStartTime = DateTime.now();
    _fpsFrameCount = 0;

    _fpsTimer?.cancel();

    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_fpsStartTime == null) {
        return;
      }

      final elapsed = DateTime.now().difference(_fpsStartTime!);

      if (elapsed.inMilliseconds > 0) {
        _fps = _fpsFrameCount / (elapsed.inMilliseconds / 1000);

        _fpsFrameCount = 0;
        _fpsStartTime = DateTime.now();

        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  String _getCameraName() {
    final camera = widget.cameras[_currentCameraIndex];

    switch (camera.lensDirection) {
      case CameraLensDirection.front:
        return 'передняя';

      case CameraLensDirection.back:
        return 'задняя';

      case CameraLensDirection.external:
        return 'внешняя';
    }
  }

  Future<void> _switchCamera() async {
    if (widget.cameras.length < 2) {
      return;
    }

    final oldController = _controller;

    // Сначала останавливаем поток кадров.
    if (oldController != null) {
      try {
        await oldController.stopImageStream();
      } catch (_) {}
    }

    if (!mounted) {
      await oldController?.dispose();
      return;
    }

    // Сначала убираем старую камеру из интерфейса.
    setState(() {
      _controller = null;
      _isCameraInitialized = false;
      _isProcessingFrames = false;
    });

    // Даём Flutter завершить перерисовку без старого CameraPreview.
    await Future<void>.delayed(Duration.zero);

    // Теперь старый контроллер можно безопасно уничтожить.
    await oldController?.dispose();

    if (!mounted) {
      return;
    }

    // Переходим к следующей камере.
    _currentCameraIndex = (_currentCameraIndex + 1) % widget.cameras.length;

    await _initializeCamera();
  }

  @override
  void dispose() {
    _fpsTimer?.cancel();
    _aiTimer?.cancel();

    final controller = _controller;

    if (controller != null && controller.value.isStreamingImages) {
      controller.stopImageStream();
    }

    controller?.dispose();
    _aiModel.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cameras.isEmpty) {
      return const Scaffold(body: Center(child: Text('Камеры не найдены')));
    }

    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),

          if (_detections.isNotEmpty) DetectionOverlay(detections: _detections),

          if (_lastAiFrame != null)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  _lastAiFrame!.imageBytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
            ),

          // Диагностическая информация.
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI WORLD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'FPS камеры: ${_fps.toStringAsFixed(1)}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),

                  Text(
                    'Кадров получено: $_receivedFrames',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),

                  Text(
                    'Кадров обработано: $_processedFrames',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),

                  Text(
                    'Разрешение: $_imageWidth × $_imageHeight',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),

                  Text(
                    'Камера: ${_getCameraName()}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // Переключение камеры.
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _switchCamera,
                child: const Icon(Icons.cameraswitch),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
