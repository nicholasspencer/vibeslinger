import 'package:flutter/material.dart';
import 'models/game_state.dart';
import 'widgets/game_canvas.dart';
import 'widgets/sidebar_panel.dart';

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
  final GlobalKey<FiringRangeState> _firingRangeKey = GlobalKey<FiringRangeState>();

  @override
  void dispose() {
    _gameState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarPanel(
            state: _gameState,
            onFire: () => _firingRangeKey.currentState?.fire(),
            onStartRapidFire: () => _firingRangeKey.currentState?.startRapidFire(),
            onStopRapidFire: () => _firingRangeKey.currentState?.stopRapidFire(),
            onSubagentScoutStarted: () => _firingRangeKey.currentState?.startSubagentScoutTimer(),
            onFocusFiringRange: () => _firingRangeKey.currentState?.requestFiringFocus(),
          ),
          const VerticalDivider(width: 1, color: Colors.white24),
          Expanded(
            child: FiringRange(key: _firingRangeKey, state: _gameState),
          ),
        ],
      ),
    );
  }
}
