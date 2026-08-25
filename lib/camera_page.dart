import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'frame_processor.dart';

class CameraPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraPage({super.key, required this.cameras});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;

  final FrameProcessor _frameProcessor = FrameProcessor();

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

  // Размер последнего полученного кадра.
  int _imageWidth = 0;
  int _imageHeight = 0;

  Uint8List? _lastJpeg;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
    // Каждый вызов этого метода означает,
    // что CameraImage действительно пришёл от камеры.
    _receivedFrames++;

    // Запоминаем реальное разрешение кадра.
    _imageWidth = image.width;
    _imageHeight = image.height;

    // Этот счётчик используется для расчёта реального FPS.
    _fpsFrameCount++;

    final jpeg = _frameProcessor.process(
      image,
      widget.cameras[_currentCameraIndex].lensDirection,
    );

    if (jpeg != null) {
      _processedFrames++;

      if (mounted) {
        setState(() {
          _lastJpeg = jpeg;
        });
      }

      debugPrint(
        'AI обработал кадр #$_processedFrames | '
        'получено: $_receivedFrames | '
        'размер: ${image.width}x${image.height} | '
        'JPEG: ${jpeg.length} байт',
      );
    }

    // Каждые 30 полученных кадров выводим диагностику.
    if (_receivedFrames % 30 == 0) {
      debugPrint(
        'Получено: $_receivedFrames | '
        'Обработано: $_processedFrames | '
        'FPS: ${_fps.toStringAsFixed(1)} | '
        'Размер: ${image.width}x${image.height} | '
        'Плоскостей: ${image.planes.length}',
      );
    }

    // Не перестраиваем интерфейс на каждом кадре.
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

    final controller = _controller;

    if (controller != null && controller.value.isStreamingImages) {
      controller.stopImageStream();
    }

    controller?.dispose();

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

          if (_lastJpeg != null)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  _lastJpeg!,
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
