// lib/widgets/planning_controls.dart
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/planning.dart';
import '../models/tool.dart';

class PlanningControls extends StatelessWidget {
  final GameState state;
  final VoidCallback? onSubagentScoutStarted;

  const PlanningControls({
    super.key,
    required this.state,
    this.onSubagentScoutStarted,
  });

  @override
  Widget build(BuildContext context) {
    final planning = state.planning;
    final isPlanning = planning.isPlanning;
    final isExecuting = planning.isExecutingAction;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        // Plan mode toggle
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
        // Aim
        _planButton(
          icon: Icons.gps_fixed,
          label: 'Aim (A)',
          enabled: isPlanning && !isExecuting && !state.contextWindow.isNearFull,
          color: Colors.cyan,
          tooltip: '-5% ctx / Focus',
          onPressed: () => state.executePlanningAction(PlanningAction.aim),
        ),
        // Scout menu
        _ScoutMenuButton(
          state: state,
          enabled: isPlanning && !isExecuting && !state.contextWindow.isNearFull,
          onSubagentScoutStarted: onSubagentScoutStarted,
        ),
        // Tools (Load)
        _ToolsMenuButton(state: state, enabled: isPlanning && !isExecuting),
        // Compact (always available)
        _planButton(
          icon: Icons.compress,
          label: 'Compact (X)',
          enabled: state.contextWindow.userLoad > 0,
          color: Colors.deepOrange,
          tooltip: 'Compress user space ~60% (lossy)',
          onPressed: () => state.compact(),
        ),
      ],
    );
  }

  Widget _planButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
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

class _ScoutMenuButton extends StatelessWidget {
  final GameState state;
  final bool enabled;
  final VoidCallback? onSubagentScoutStarted;

  const _ScoutMenuButton({
    required this.state,
    required this.enabled,
    this.onSubagentScoutStarted,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PlanningAction>(
      enabled: enabled,
      tooltip: 'Scout modes (S)',
      offset: const Offset(0, -120),
      color: const Color(0xFF2A2A4E),
      onSelected: (action) {
        if (action == PlanningAction.directScout) {
          state.executePlanningAction(PlanningAction.directScout);
        } else if (action == PlanningAction.subagentScout) {
          final success = state.startSubagentScout();
          if (success) {
            onSubagentScoutStarted?.call();
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: PlanningAction.directScout,
          child: Row(
            children: [
              const Icon(Icons.visibility, color: Colors.teal, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Direct', style: TextStyle(color: Colors.white)),
                    Text(
                      '${(state.planning.contextCostFor(PlanningAction.directScout) * 100).toStringAsFixed(0)}% user ctx • Negate 1 env (instant)',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: PlanningAction.subagentScout,
          child: Row(
            children: [
              const Icon(Icons.smart_toy, color: Colors.tealAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Subagent', style: TextStyle(color: Colors.white)),
                    Text(
                      '${(state.planning.contextCostFor(PlanningAction.subagentScout) * 100).toStringAsFixed(0)}% user ctx • Negate 1 env (~3s delay)',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      child: ElevatedButton.icon(
        onPressed: enabled ? null : null, // PopupMenuButton handles tap
        icon: const Icon(Icons.visibility, size: 16),
        label: const Text('Scout (S)', style: TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? Colors.teal.withValues(alpha: 0.5) : null,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}

class _ToolsMenuButton extends StatelessWidget {
  final GameState state;
  final bool enabled;

  const _ToolsMenuButton({required this.state, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final loadedCount = state.loadedTools.length;
    return PopupMenuButton<ToolType>(
      enabled: enabled,
      tooltip: 'Load/unload tools (L)',
      offset: const Offset(0, -200),
      color: const Color(0xFF2A2A4E),
      onSelected: (type) {
        if (state.loadedTools.contains(type)) {
          state.unloadTool(type);
        } else {
          state.loadTool(type);
        }
      },
      itemBuilder: (context) => Tool.all.map((tool) {
        final isLoaded = state.loadedTools.contains(tool.type);
        return PopupMenuItem(
          value: tool.type,
          child: Row(
            children: [
              Icon(
                isLoaded ? Icons.check_box : Icons.check_box_outline_blank,
                color: isLoaded ? Colors.lime : Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tool.name, style: const TextStyle(color: Colors.white)),
                    Text(
                      '${(tool.systemCost * 100).toStringAsFixed(0)}% system • ${tool.passiveBenefit}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: ElevatedButton.icon(
        onPressed: enabled ? null : null, // PopupMenuButton handles tap
        icon: const Icon(Icons.build, size: 16),
        label: Text('Tools (L) ${loadedCount > 0 ? "[$loadedCount]" : ""}',
            style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? Colors.lime.withValues(alpha: 0.5) : null,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}
