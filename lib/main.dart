import 'package:flutter/material.dart';
import 'models/game_state.dart';
import 'widgets/control_panel.dart';
import 'widgets/game_canvas.dart';

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

class GunslingerScreen extends StatefulWidget {
  const GunslingerScreen({super.key});

  @override
  State<GunslingerScreen> createState() => _GunslingerScreenState();
}

class _GunslingerScreenState extends State<GunslingerScreen> {
  final GameState _gameState = GameState();

  @override
  void dispose() {
    _gameState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _gameState,
        builder: (context, _) {
          return Column(
            children: [
              ControlPanel(state: _gameState),
              const Divider(color: Colors.white24),
              Expanded(child: GameCanvas(state: _gameState)),
            ],
          );
        },
      ),
    );
  }
}
