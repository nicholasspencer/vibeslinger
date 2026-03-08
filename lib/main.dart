import 'package:flutter/material.dart';

void main() {
  runApp(const InferenceGunslingerApp());
}

class InferenceGunslingerApp extends StatelessWidget {
  const InferenceGunslingerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inference Gunslinger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      ),
      home: const GunslingerScreen(),
    );
  }
}

class GunslingerScreen extends StatelessWidget {
  const GunslingerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Inference Gunslinger')),
    );
  }
}
