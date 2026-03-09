# Session & Workspace Redesign

## Summary

Replace the "Planning" sidebar section with two sections: **Session** (ephemeral context actions) and **Workspace** (persistent file storage). Introduces save/load mechanics that teach how AI agents persist knowledge across conversations.

## Sidebar Structure

```
SESSION
  New Session (replaces Reset)
  Aim (Focus)
  Scout (Direct / Subagent)
  Tools
  Compact

WORKSPACE
  Save Plan / Save Research
  [saved file list with Load/Unload toggles]

FIRE
  Fire / Rapid Fire

CONTEXT WINDOW (bar)
MODEL SELECTION
```

## Save Actions & File Types

Save actions are available anytime during a session. Each costs context (distilling knowledge is work).

| File Type | Icon | Save Cost | Load Cost | Passive Benefit When Loaded |
|-----------|------|-----------|-----------|----------------------------|
| Plan | `Icons.map` | 4% context | 6% context | -10% spread reduction |
| Research | `Icons.science` | 3% context | 4% context | +5% scout effectiveness, -5% aim cost |

- Plans: expensive but direct accuracy benefit (structured reasoning)
- Research: cheaper, indirect benefits (raw findings improve future planning)
- File Reader tool reduces load costs by 50%
- Auto-named by session: `plan_s1.md`, `research_s2.md`
- Workspace capacity is unlimited; natural constraint is context cost of loading

## Session Lifecycle

1. Player starts Session 1, planning mode active, workspace empty
2. Within a session: Aim/Scout/Tools build understanding, Save Plan/Research persists insights, Fire consumes planning bonuses
3. **New Session**: context clears, session counter increments, planning bonuses reset, all workspace files unloaded (but not deleted), tools stay loaded
4. Player selectively loads files back in, plans, fires

Mirrors starting a new AI conversation: thread is lost but saved artifacts remain on disk.

## Workspace UI

- Save buttons at top of Workspace section, always visible
- File list below, scrollable
- Each file shows: type icon, name, load/unload toggle, context cost percentage
- Loaded files get highlighted background
- File Reader discount shown on cost label (e.g., strikethrough original cost)
- Load/Unload are instant toggles
- Empty state: "No saved files"

## Impact on Existing Systems

**Context Window:** No changes. File load costs go into user segment.

**Tools:** File Reader gets clear role — 50% reduction on workspace file load costs. Others unchanged.

**Accuracy formula:** Loaded file bonuses fold into existing formula:
- Plan spread reduction adds to `planning.bonus.spreadReduction`
- Research scout effectiveness applies as multiplier on scout actions
- Research aim cost reduction applied via `contextCostFor()` scaling

**Planning model:**
- `consumeBonuses()` on fire clears aim/scout bonuses but NOT file bonuses (persist while loaded)
- File bonuses recalculated on load/unload

**New model:** `WorkspaceState` — tracks saved files, loaded status, session counter. Lives alongside `PlanningState` and `ContextWindow`.

**Reset -> New Session:** Same context/planning clear, plus unloads all workspace files without deleting.

**No changes to:** firing mechanics, heat system, rapid fire, model selection, target/canvas.
