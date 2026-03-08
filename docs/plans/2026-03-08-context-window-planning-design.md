# Context Window Backpack + Planning System — Design

## Concept

Two new visual systems added to the Inference Gunslinger app:
1. A backpack on the stick figure representing context window capacity (system/buffer/user space)
2. A planning mode with three actions (Aim, Scout, Load) that improve accuracy but consume context and time

## Context Window (Backpack)

A visual backpack on the stick figure representing context window capacity.

### Three compartments (stacked bar):
- **Water (System/Tools)** — blue, fixed ~20% base
- **Survival Gear (Buffer)** — amber, fixed ~15%
- **Operational Gear (User Space)** — green, remaining usable space

### Gameplay effects:
- Total load is 0.0–1.0 (empty to full)
- Load > 0.7 increases wobble (accuracy penalty)
- Load > 0.7 increases heat buildup rate (burns out faster)
- Planning actions add to the operational gear section

### Visual:
- Stacked bar beside or on the stick figure, color-coded
- Figure visibly hunches/leans as load increases

## Planning System

A planning mode that locks out firing while the figure prepares.

### Three planning actions:

| Action | Visual | Backpack Cost | Benefit |
|---|---|---|---|
| Aim | Figure steadies stance, breath animation | +5% context per use | -30% shot spread next volley |
| Scout | Figure raises hand to brow, scans | +8% context per use | Negates one environment penalty |
| Load | Figure swaps ammo, clicks magazine | +6% context per use | +15% base accuracy next volley |

### Mechanics:
- PLAN button/mode toggle (or P key). While active, FIRE is disabled.
- Each action takes ~1.5s (animated), then benefit applied
- Benefits stack with diminishing returns: first Aim gives -30% spread, second -15%, third -8%...
- Each action adds weight to backpack (consumes context window)
- Planning bonuses decay after firing (consumed on use)
- Context window >90% full disables planning actions

### New scene:
- Scene 4: "The Planner" — expert, precision rifle, moderate planning, shows the sweet spot

## UI Layout

```
+------------------------------------------+
|  [Gun] [Skill] [Env] [Scenes] [Clear]   |  <- existing controls
+------------------------------------------+
|  Accuracy: 87%  Shots: 12               |
|                                          |
|  Figure+Pack    ~~~~~~~~~~~~  Target     |  <- backpack on figure
|                                          |
|  [Context: ========-- 72%]               |  <- context window bar
|  [Water:20%|Buffer:15%|User:37%]         |
+------------------------------------------+
|  [PLAN MODE]  [Aim] [Scout] [Load]       |  <- planning controls
|  [FIRE]  [RAPID FIRE]                    |  <- disabled during planning
+------------------------------------------+
```

## Keyboard Shortcuts
- P — toggle plan mode
- A — aim (while in plan mode)
- S — scout (while in plan mode)
- L — load (while in plan mode)
