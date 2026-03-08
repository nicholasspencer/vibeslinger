import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/planning.dart';

class PlanningControls extends StatelessWidget {
  final GameState state;
  final VoidCallback? onActionStarted;

  const PlanningControls({
    super.key,
    required this.state,
    this.onActionStarted,
  });

  @override
  Widget build(BuildContext context) {
    final planning = state.planning;
    final isPlanning = planning.isPlanning;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () => state.togglePlanning(),
          icon: Icon(isPlanning ? Icons.pause : Icons.psychology),
          label: Text(isPlanning ? 'EXIT PLAN (P)' : 'PLAN (P)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isPlanning
                ? Colors.amber.withValues(alpha: 0.8)
                : Colors.amber.withValues(alpha: 0.3),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        const SizedBox(width: 12),
        _actionButton(
          icon: Icons.gps_fixed,
          label: 'Aim (A)',
          action: PlanningAction.aim,
          enabled: isPlanning && !planning.isExecutingAction && !state.contextWindow.isNearFull,
          color: Colors.cyan,
          costLabel: '-${(planning.contextCostFor(PlanningAction.aim) * 100).toStringAsFixed(0)}% ctx',
          benefitLabel: '+${(planning.benefitFor(PlanningAction.aim) * 100).toStringAsFixed(0)}% focus',
        ),
        const SizedBox(width: 8),
        _actionButton(
          icon: Icons.visibility,
          label: 'Scout (S)',
          action: PlanningAction.scout,
          enabled: isPlanning && !planning.isExecutingAction && !state.contextWindow.isNearFull,
          color: Colors.teal,
          costLabel: '-${(planning.contextCostFor(PlanningAction.scout) * 100).toStringAsFixed(0)}% ctx',
          benefitLabel: 'Negate 1 env',
        ),
        const SizedBox(width: 8),
        _actionButton(
          icon: Icons.autorenew,
          label: 'Load (L)',
          action: PlanningAction.load,
          enabled: isPlanning && !planning.isExecutingAction && !state.contextWindow.isNearFull,
          color: Colors.lime,
          costLabel: '-${(planning.contextCostFor(PlanningAction.load) * 100).toStringAsFixed(0)}% ctx',
          benefitLabel: '+${(planning.benefitFor(PlanningAction.load) * 100).toStringAsFixed(0)}% acc',
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required PlanningAction action,
    required bool enabled,
    required Color color,
    required String costLabel,
    required String benefitLabel,
  }) {
    return Tooltip(
      message: '$costLabel / $benefitLabel',
      child: ElevatedButton.icon(
        onPressed: enabled
            ? () {
                state.executePlanningAction(action);
                onActionStarted?.call();
              }
            : null,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? color.withValues(alpha: 0.5) : null,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}
