import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'camera_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  runApp(AIWorldApp(cameras: cameras));
}

class AIWorldApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const AIWorldApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI World',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(cameras: cameras),
    );
  }
}

// ─────────────────────────────────────────────
// ГЛАВНЫЙ ЭКРАН
// ─────────────────────────────────────────────

class HomePage extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HomePage({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI WORLD'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.public, size: 100),

              const SizedBox(height: 30),

              const Text(
                'Добро пожаловать в AI World!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              const Text(
                'AI, который понимает окружающий мир.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: cameras.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CameraPage(cameras: cameras),
                            ),
                          );
                        },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text(
                    'Открыть камеру',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
