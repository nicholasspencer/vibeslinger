# Itemized Context Tracking Design

## Overview

Replace aggregate context tracking (single `_systemLoad` / `_userLoad` doubles) with itemized segment-based tracking. Each action that consumes context is tracked individually and rendered as sub-bars in the context bar visualization. Additionally, each shot now consumes user context, creating a natural resource pressure mechanic.

## Data Model

### ContextSegment

```dart
class ContextSegment {
  final ContextSegmentType type; // harness, tool, aim, scout, shot
  final String label;            // "Harness", "Web Search", "Aim x3", etc.
  double amount;                 // 0.15, 0.06, etc.
  final Color color;             // for rendering
}

enum ContextSegmentType { harness, tool, aim, scout, shot }
```

### ContextWindow Changes

- `_systemLoad` and `_userLoad` replaced by `List<ContextSegment> systemSegments` and `List<ContextSegment> userSegments`
- `systemLoad` and `userLoad` become computed getters that sum their segment lists
- Harness is always the first system segment at **15%** (reduced from 20%)
- Each tool adds a system segment with its own cost
- User segments are grouped by type: one segment for aims, one for scouts, one for shots — updated in place as actions occur
- `compact()` scales each user segment's amount by 0.4; removes segments < 0.001

### Per-Shot Context Cost

- Base cost: **2%** per shot
- Skill scaling (linear interpolation on skill slider 0.0–1.0):
  - Novice (0.0): **1.5x** cost
  - Expert (1.0): **0.75x** cost
- Tool penalty: each loaded tool adds its `shotCostPenalty` to the cost
- Formula: `baseShotCost (0.02) × skillMultiplier × (1 + Σ toolShotPenalties)`
- Cost is added to the "shots" user segment

## Tool Shot Cost Values

| Tool          | System Cost | Accuracy | Spread | Heat    | Shot Cost Penalty |
|---------------|-------------|----------|--------|---------|-------------------|
| Web Search    | 6%          | —        | —      | —       | +0.5%             |
| Code Analysis | 8%          | —        | -5%    | —       | +1.0%             |
| File Reader   | 6%          | +3%      | —      | —       | +0.5%             |
| Code Review   | 12%         | +5%      | -8%    | +50%    | +1.5%             |

All 4 tools loaded adds +3.5% per shot on top of base.

## Context Bar Visualization

### System Sub-Segments (blue section)

- **Harness** (darker blue) — always present, leftmost, 15%
- **Each loaded tool** (slightly different blue shades) — appended left to right
- 1px divider lines between sub-segments

### User Sub-Segments (green section, left to right)

- **Aims** (teal-green) — one segment, grows with each aim action
- **Scouts** (yellow-green) — one segment, grows with each scout action
- **Shots** (bright green, desaturated if compacted) — grows per shot

1px dividers between segment types.

### Legend

Stays simple: System XX% | User XX% | Compact XX%. Sub-bar colors are self-explanatory for presentation context.

## Compaction

- Each user segment's amount scaled by **0.4** (same ratio as current)
- Segments with amount < 0.001 after scaling are removed
- Desaturated color treatment remains
- Planning bonuses still scale by 0.4

## GameState Integration

### fire()

After calculating shot and recording it:
1. Compute shot cost: `0.02 × skillMultiplier × (1 + Σ tool.shotCostPenalty)`
2. Add cost to "shots" user segment via `contextWindow.consumeShotContext(cost)`
3. Firing blocked if context is near full (unchanged)

### executePlanningAction()

Consume context into the appropriate segment:
- Aim actions → update "aims" segment
- Scout actions → update "scouts" segment

### Skill Multiplier

Linear interpolation from skill slider:
- 0.0 (novice): 1.5x
- 0.5 (mid): 1.125x
- 1.0 (expert): 0.75x

Formula: `1.5 - (skillLevel × 0.75)`
