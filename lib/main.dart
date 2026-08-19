import 'package:flutter/material.dart';

void main() {
  runApp(const AIWorldApp());
}

class AIWorldApp extends StatelessWidget {
  const AIWorldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI World',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AIWorldHomePage(),
    );
  }
}

class AIWorldHomePage extends StatelessWidget {
  const AIWorldHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI World',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              const Icon(Icons.public, size: 100),

              const SizedBox(height: 24),

              const Text(
                'Я готов увидеть мир',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              const Text(
                'Покажи мне то, что хочешь узнать.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.camera_alt),
                  label: const Text(
                    'Открыть камеру',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.mic),
                  label: const Text(
                    'Спросить голосом',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
