import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/gun.dart';
import '../models/planning.dart';
import '../models/tool.dart';
import '../models/workspace.dart';
import '../services/audio_service.dart';
import 'sidebar_info_page.dart';

class SidebarPanel extends StatefulWidget {
  final GameState state;
  final VoidCallback onFire;
  final VoidCallback onStartRapidFire;
  final VoidCallback onStopRapidFire;
  final VoidCallback? onSubagentScoutStarted;
  final VoidCallback? onFocusFiringRange;

  const SidebarPanel({
    super.key,
    required this.state,
    required this.onFire,
    required this.onStartRapidFire,
    required this.onStopRapidFire,
    this.onSubagentScoutStarted,
    this.onFocusFiringRange,
  });

  @override
  State<SidebarPanel> createState() => _SidebarPanelState();
}

class _SidebarPanelState extends State<SidebarPanel> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final _audio = AudioService.instance;

  void _showInfo(String title, String description, {String? accuracyImpact}) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => SidebarInfoPage(
          title: title,
          description: description,
          accuracyImpact: accuracyImpact,
          onBack: () {
            _navigatorKey.currentState?.pop();
            widget.onFocusFiringRange?.call();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) => _buildMainPanel(),
        ),
      ),
    );
  }

  Widget _buildMainPanel() {
    return Container(
      color: const Color(0xFF16162B),
      child: ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) {
          final planning = widget.state.planning;
          final isPlanning = planning.isPlanning;
          final isExecuting = planning.isExecutingAction;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            children: [
              // Model section
              _sectionLabel('MODEL'),
              _infoRow(
                child: _buildGunSelector(),
                onInfo: () => _showInfo(
                  'Model Selection',
                  'Choose your inference model. Each has different base accuracy and heat rate. Even the best models start around 55% — planning and tools are needed to push toward 99%.\n\n'
                  '• Claude Opus 4.6 — 55% base, 1.3x heat (best reasoning, burns context fast)\n'
                  '• GPT-5.4 — 52% base, 1.2x heat (strong reasoning)\n'
                  '• Claude Sonnet 4.6 — 48% base, 1.0x heat (balanced)\n'
                  '• Gemini 2.5 Pro — 45% base, 1.0x heat (balanced)\n'
                  '• GPT-4.1 — 42% base, 0.8x heat (fast, low heat)\n'
                  '• Claude Haiku 4.5 — 35% base, 0.6x heat (fast/cheap, many shots)',
                  accuracyImpact: 'Base accuracy: 35–55% depending on model',
                ),
              ),
              const SizedBox(height: 16),

              // Skill section
              _sectionLabel('SKILL'),
              _infoRow(
                child: _buildSkillSlider(),
                onInfo: () => _showInfo(
                  'Prompt Engineering',
                  'Your prompt engineering skill level. The model\'s base accuracy is fixed — skill affects how efficiently you plan.\n\n'
                  'Expert: planning actions cost less context and aim gives more spread reduction.\n'
                  'Novice: planning actions cost 1.5x context and aim gives half the spread reduction.',
                  accuracyImpact: 'Planning cost: 1.0x (expert) to 1.5x (novice)\nAim benefit: 30% (expert) to 15% (novice)',
                ),
              ),
              const SizedBox(height: 16),

              // Session section
              _sectionLabel('SESSION'),
              _infoRow(
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _audio.playClear();
                      widget.state.newSession();
                      widget.onFocusFiringRange?.call();
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text(
                      'New Session (N) — S${widget.state.workspace.sessionNumber}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: const BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
                onInfo: () => _showInfo(
                  'New Session',
                  'Clears the context window and starts a new session. All planning bonuses reset. '
                  'Workspace files remain saved but are unloaded — you choose what to bring back.\n\n'
                  'Tools stay loaded (they are system-level). Session number increments.\n\n'
                  'Maps to starting a new AI conversation — your saved artifacts persist on disk, '
                  'but the conversation context is fresh.',
                  accuracyImpact: 'Resets all session-level bonuses, unloads workspace files',
                ),
              ),
              const SizedBox(height: 6),
              _infoRow(
                child: _buildPlanToggle(isPlanning, () => _audio.playPlanToggle(!isPlanning)),
                onInfo: () => _showInfo(
                  'Planning Mode',
                  'Pauses firing to improve accuracy. While in plan mode, you can Aim, Scout, load Tools, and Compact.\n\n'
                  'Maps to chain-of-thought / reasoning — spending compute time thinking before acting.',
                  accuracyImpact: 'Enables planning actions that improve accuracy',
                ),
              ),
              const SizedBox(height: 6),
              _infoRow(
                child: _buildPlanAction(
                  icon: Icons.gps_fixed,
                  label: 'Focus (A)',
                  enabled: isPlanning && !isExecuting,
                  color: Colors.cyan,
                  onPressed: () {
                    if (widget.state.executePlanningAction(PlanningAction.aim)) {
                      _audio.playAim();
                    }
                    widget.onFocusFiringRange?.call();
                  },
                ),
                onInfo: () => _showInfo(
                  'Improve Accuracy (Aim)',
                  'Improves accuracy by tightening shot grouping (diminishing returns on repeated use). Costs 5% of user context.\n\n'
                  'Maps to focused reasoning — spending tokens to narrow down the answer space.',
                  accuracyImpact: '+9% accuracy per aim (expert), +4.5% (novice), diminishing returns',
                ),
              ),
              const SizedBox(height: 6),
              _infoRow(
                child: _buildScoutButton(isPlanning, isExecuting),
                onInfo: () => _showInfo(
                  'Improve Accuracy (Scout)',
                  'Improves accuracy by reducing shot spread.\n\n'
                  '• Direct Scout: 8% user context, +20% spread reduction (instant)\n'
                  '• Subagent Scout: 3% user context, +15% spread reduction (~3s delay)\n\n'
                  'Maps to retrieval / tool use — gathering information to improve response quality.',
                  accuracyImpact: '+6% accuracy per direct scout, +4.5% per subagent',
                ),
              ),
              const SizedBox(height: 6),
              _infoRow(
                child: _buildToolsButton(isPlanning, isExecuting),
                onInfo: () => _showInfo(
                  'Tool Loading',
                  'Increases system context permanently. Each tool provides a passive benefit:\n\n'
                  '• Web Search — +10% scout effectiveness (8% system)\n'
                  '• Code Analysis — +10% base accuracy (10% system)\n'
                  '• File Reader — -5% spread (6% system)\n'
                  '• Code Review — +5% accuracy, -8% spread (12% system)\n'
                  '  ⚠ +50% heat generation (overheats faster)\n'
                  '• Skill Creator — +25% accuracy (15% system) ⭐ cheat',
                  accuracyImpact: 'Varies by tool, costs permanent system context',
                ),
              ),
              const SizedBox(height: 6),
              _infoRow(
                child: _buildPlanAction(
                  icon: Icons.compress,
                  label: 'Compact (X)',
                  enabled: widget.state.contextWindow.userLoad > 0,
                  color: Colors.deepOrange,
                  onPressed: () {
                    _audio.playCompact();
                    widget.state.compact();
                    widget.onFocusFiringRange?.call();
                  },
                ),
                onInfo: () => _showInfo(
                  'Compaction',
                  'Compresses user context by ~60%. This is lossy — planning bonuses (aim focus, scout negations) are also reduced.\n\n'
                  'Auto-compaction triggers when context reaches ~90% full.\n\n'
                  'Maps to context window compaction in long conversations.',
                  accuracyImpact: 'Frees ~60% user context, reduces planning bonuses',
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),

              // Workspace section
              _sectionLabel('WORKSPACE'),
              _infoRow(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPlanAction(
                        icon: Icons.map,
                        label: 'Save Plan (W)',
                        enabled: !isExecuting && !widget.state.contextWindow.isNearFull,
                        color: const Color(0xFF8866CC),
                        onPressed: () {
                          if (widget.state.saveToWorkspace(WorkspaceFileType.plan)) {
                            _audio.playAim();
                          }
                          widget.onFocusFiringRange?.call();
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildPlanAction(
                        icon: Icons.science,
                        label: 'Research (E)',
                        enabled: !isExecuting && !widget.state.contextWindow.isNearFull,
                        color: const Color(0xFF6688BB),
                        onPressed: () {
                          if (widget.state.saveToWorkspace(WorkspaceFileType.research)) {
                            _audio.playScout();
                          }
                          widget.onFocusFiringRange?.call();
                        },
                      ),
                    ),
                  ],
                ),
                onInfo: () => _showInfo(
                  'Workspace Files',
                  'Save insights from your session as persistent files.\n\n'
                  '• Save Plan (4% context): Structured reasoning → -10% spread when loaded\n'
                  '• Save Research (3% context): Raw findings → +5% scout effectiveness, -5% aim cost when loaded\n\n'
                  'Files persist across sessions. Loading files costs context (reduced 50% by File Reader tool). '
                  'Your workspace is unlimited, but loading too many files bloats context.\n\n'
                  'Maps to saving conversation artifacts (plans, research notes) to the file system — '
                  'cheap to store, but costs context to reference.',
                  accuracyImpact: 'Save: 3-4% context cost. Load: 4-6% context (halved with File Reader)',
                ),
              ),
              const SizedBox(height: 6),
              _buildWorkspaceFileList(),
              const SizedBox(height: 8),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),

              // Fire section
              _sectionLabel('FIRE'),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.state.planning.canFire
                      ? () {
                          if (widget.state.planning.isPlanning) {
                            widget.state.togglePlanning();
                          }
                          widget.onFire();
                          widget.onFocusFiringRange?.call();
                        }
                      : null,
                  icon: const Icon(Icons.flash_on),
                  label: const Text('FIRE (Space)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPlanning
                        ? Colors.amber.withValues(alpha: 0.4)
                        : widget.state.selectedGun.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onLongPressStart: widget.state.planning.canFire
                      ? (_) {
                          if (widget.state.planning.isPlanning) {
                            widget.state.togglePlanning();
                          }
                          widget.onStartRapidFire();
                        }
                      : null,
                  onLongPressEnd: widget.state.planning.canFire
                      ? (_) {
                          widget.onStopRapidFire();
                          widget.onFocusFiringRange?.call();
                        }
                      : null,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.local_fire_department),
                    label: const Text('RAPID FIRE (Hold)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Keyboard hints
              const Text(
                'Space: Fire\n'
                'P: Plan mode  N: New Session\n'
                'A: Focus  S: Scout  D: Subagent\n'
                'X: Compact  W: Save Plan  E: Save Research',
                style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _infoRow({required Widget child, required VoidCallback onInfo}) {
    return Row(
      children: [
        Expanded(child: child),
        IconButton(
          onPressed: onInfo,
          icon: const Icon(Icons.info_outline, size: 16, color: Colors.white38),
          tooltip: 'Info',
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildGunSelector() {
    return DropdownButton<GunType>(
      value: widget.state.selectedGun.type,
      isExpanded: true,
      dropdownColor: const Color(0xFF2A2A4E),
      style: const TextStyle(color: Colors.white),
      items: Gun.all.map((gun) {
        return DropdownMenuItem(
          value: gun.type,
          child: Text(
            '${gun.name} (${gun.modelLabel})',
            style: TextStyle(color: gun.color),
          ),
        );
      }).toList(),
      onChanged: (type) {
        if (type != null) {
          _audio.playGunSelect();
          widget.state.selectGun(Gun.all.firstWhere((g) => g.type == type));
          widget.onFocusFiringRange?.call();
        }
      },
    );
  }

  Widget _buildSkillSlider() {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: widget.state.skillLevel,
            onChanged: (v) {
              widget.state.setSkillLevel(v);
            },
            onChangeEnd: (_) => widget.onFocusFiringRange?.call(),
            activeColor: Colors.white70,
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(
            widget.state.skillLevel < 0.3
                ? 'Novice'
                : widget.state.skillLevel < 0.7
                    ? 'Mid'
                    : 'Expert',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanToggle(bool isPlanning, VoidCallback onSound) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          onSound();
          widget.state.togglePlanning();
          widget.onFocusFiringRange?.call();
        },
        icon: Icon(isPlanning ? Icons.pause : Icons.psychology, size: 16),
        label: Text(
          isPlanning ? 'EXIT PLAN (P)' : 'PLAN (P)',
          style: const TextStyle(fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPlanning
              ? Colors.amber.withValues(alpha: 0.8)
              : Colors.amber.withValues(alpha: 0.3),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildPlanAction({
    required IconData icon,
    required String label,
    required bool enabled,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? color.withValues(alpha: 0.5) : null,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildScoutButton(bool isPlanning, bool isExecuting) {
    final enabled = isPlanning && !isExecuting;
    return PopupMenuButton<PlanningAction>(
      enabled: enabled,
      tooltip: 'Scout modes (S)',
      offset: const Offset(260, 0),
      color: const Color(0xFF2A2A4E),
      onSelected: (action) {
        if (action == PlanningAction.directScout) {
          if (widget.state.executePlanningAction(PlanningAction.directScout)) {
            _audio.playScout();
          }
        } else if (action == PlanningAction.subagentScout) {
          final success = widget.state.startSubagentScout();
          if (success) {
            _audio.playScoutStart();
            widget.onSubagentScoutStarted?.call();
          }
        }
        widget.onFocusFiringRange?.call();
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
                      '${(widget.state.planning.contextCostFor(PlanningAction.directScout, skillLevel: widget.state.skillLevel) * 100).toStringAsFixed(0)}% user ctx • +20% spread reduction (instant)',
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
                      '${(widget.state.planning.contextCostFor(PlanningAction.subagentScout, skillLevel: widget.state.skillLevel) * 100).toStringAsFixed(0)}% user ctx • +15% spread reduction (~3s delay)',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: enabled ? null : null,
          icon: const Icon(Icons.visibility, size: 16),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Scout (S)', style: TextStyle(fontSize: 12)),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: enabled
                ? Colors.teal.withValues(alpha: 0.7)
                : Colors.teal.withValues(alpha: 0.2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspaceFileList() {
    final files = widget.state.workspace.files;
    final hasFileReader = widget.state.loadedTools.contains(ToolType.fileReader);
    if (files.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No saved files',
          style: TextStyle(color: Colors.white24, fontSize: 11, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      children: [
        for (int i = 0; i < files.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _buildWorkspaceFileRow(files[i], i, hasFileReader),
          ),
      ],
    );
  }

  Widget _buildWorkspaceFileRow(WorkspaceFile file, int index, bool hasFileReader) {
    final icon = file.type == WorkspaceFileType.plan ? Icons.map : Icons.science;
    final color = file.type == WorkspaceFileType.plan
        ? const Color(0xFF8866CC)
        : const Color(0xFF6688BB);
    final cost = file.discountedLoadCost(hasFileReader: hasFileReader);
    final costPercent = (cost * 100).toStringAsFixed(0);
    final originalCost = (file.loadCost * 100).toStringAsFixed(0);
    final hasDiscount = hasFileReader && cost < file.loadCost;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: file.isLoaded ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              file.name,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
          if (hasDiscount)
            Text(
              '$originalCost%',
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 10,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          if (hasDiscount) const SizedBox(width: 4),
          Text(
            '$costPercent%',
            style: TextStyle(
              color: hasDiscount ? Colors.greenAccent.withValues(alpha: 0.7) : Colors.white38,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              if (file.isLoaded) {
                widget.state.unloadWorkspaceFile(index);
                _audio.playToolUnload();
              } else {
                if (widget.state.loadWorkspaceFile(index)) {
                  _audio.playToolLoad();
                }
              }
              widget.onFocusFiringRange?.call();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: file.isLoaded ? color.withValues(alpha: 0.4) : Colors.transparent,
                border: Border.all(color: file.isLoaded ? color : Colors.white24),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                file.isLoaded ? 'Unload' : 'Load',
                style: TextStyle(
                  color: file.isLoaded ? Colors.white : Colors.white54,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsButton(bool isPlanning, bool isExecuting) {
    final enabled = isPlanning && !isExecuting;
    final loadedCount = widget.state.loadedTools.length;
    return PopupMenuButton<ToolType>(
      enabled: enabled,
      tooltip: 'Load/unload tools',
      offset: const Offset(260, 0),
      color: const Color(0xFF2A2A4E),
      onSelected: (type) {
        if (widget.state.loadedTools.contains(type)) {
          if (widget.state.unloadTool(type)) _audio.playToolUnload();
        } else {
          if (widget.state.loadTool(type)) _audio.playToolLoad();
        }
        widget.onFocusFiringRange?.call();
      },
      itemBuilder: (context) => Tool.all.map((tool) {
        final isLoaded = widget.state.loadedTools.contains(tool.type);
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: enabled ? null : null,
          icon: const Icon(Icons.build, size: 16),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tools ${loadedCount > 0 ? "[$loadedCount]" : ""}',
                style: const TextStyle(fontSize: 12),
              ),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: enabled
                ? Colors.lime.withValues(alpha: 0.7)
                : Colors.lime.withValues(alpha: 0.2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }
}
