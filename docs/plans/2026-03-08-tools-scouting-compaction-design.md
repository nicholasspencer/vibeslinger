# Tools, Scouting Modes, Compaction Buffer & Compact Action — Design

## 1. Load → Tools Menu

"Load" planning action becomes a tools menu. Loading a tool increases the system compartment (permanent overhead). Tools stay loaded until explicitly unloaded (toggle).

### Available tools:

| Tool | System Context Cost | Passive Benefit |
|---|---|---|
| Web Search | +8% system | +10% scout effectiveness |
| Code Analysis | +10% system | +10% base accuracy |
| File Reader | +6% system | -5% spread |

- Multiple tools can be loaded simultaneously
- Unloading frees system context back
- Replaces the old "Load" accuracy boost entirely

UI: Load (L) button opens a popup menu with checkboxes. Loaded tools show as badges near controls.

## 2. Scout → Direct vs Subagent

Scout splits into two modes:

| Mode | Context Cost | Time Cost | Benefit |
|---|---|---|---|
| Direct Scout | 8% user space | Instant | Negate 1 env penalty |
| Subagent Scout | 3% user space | ~3s delay | Negate 1 env penalty |

Subagent scout shows a loading indicator for ~3 seconds before benefit applies. Other planning actions still available during wait, but cannot fire.

UI: Two buttons — "Scout (S)" and "Subagent (D)".

## 3. Compaction Buffer

Context bar layout changes. A compaction buffer zone (~16.5%) is reserved at the right end:

```
[System|Buffer|User.....free space|░░Compact Buffer░░]
```

- Always visible as a distinct dark zone at the right
- When total load grows into the compact buffer zone, context indicator turns red
- Warning zone, does not prevent usage

## 4. Compact Action

New "Compact" button available anytime (not just during planning).

- Compresses user space by ~60% (e.g., 40% -> 16%)
- ~1 second squishing/compression animation
- After compression, user space turns desaturated green (lossy summary visual)
- Planning bonuses reduced proportionally (lose some of what you planned)
- Keyboard shortcut: X

## 5. Updated Context Bar

```
[System|Buffer|User........free|░░Compact Buffer░░]
 blue    amber  green           gray/dark
                (desaturated after compact)
```

Turns red when load encroaches into compact buffer zone.
