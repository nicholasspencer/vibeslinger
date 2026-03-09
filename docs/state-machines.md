# Vibeslinger State Machines

## 1. Planning State Machine

The planning system controls how the player prepares before firing. Planning actions consume context window capacity in exchange for accuracy bonuses.

```mermaid
stateDiagram-v2
    [*] --> Planning : initial state

    state Planning {
        [*] --> Idle
        Idle --> ExecutingAction : applyAction(aim | directScout)
        Idle --> AwaitingSubagent : startSubagentScout()
        ExecutingAction --> Idle : action applied
        AwaitingSubagent --> Idle : completeSubagentScout() [3s delay]
    }

    Planning --> NotPlanning : togglePlanning()
    NotPlanning --> Planning : togglePlanning()
    Planning --> [*] : fire() → auto-exits planning
    Planning --> [*] : reset()
    NotPlanning --> [*] : reset()

    note right of Planning
        canFire = !isExecutingAction
        Firing consumes all bonuses
    end note
```

**Key guards:**
- Cannot apply aim/directScout while `isExecutingAction = true`
- Subagent scout bypasses the executing guard (can queue during execution)
- `canFire` returns `false` while executing, blocking shots during subagent wait
- Firing auto-exits planning mode and calls `consumeBonuses()`

**Source:** `lib/models/planning.dart`, `lib/models/game_state.dart:119-137`

---

## 2. Context Window State Machine

The context window tracks how much of the model's capacity is consumed. It has two orthogonal state dimensions: load zones and compaction status.

### Compaction State

```mermaid
stateDiagram-v2
    [*] --> Normal

    Normal --> Compacted : compact() [manual or auto]
    Compacted --> Normal : reset()

    note right of Compacted
        User segments scaled to 40%
        Planning bonus scaled to 40%
        Segments < 0.001 removed
    end note
```

### Load Zones

```mermaid
stateDiagram-v2
    [*] --> Comfortable

    Comfortable --> Overloaded : totalLoad > 0.70
    Overloaded --> Comfortable : totalLoad ≤ 0.70
    Overloaded --> CompactionZone : totalLoad > 0.8164
    CompactionZone --> Overloaded : totalLoad ≤ 0.8164
    CompactionZone --> NearFull : totalLoad > 0.8999
    NearFull --> CompactionZone : totalLoad ≤ 0.8999

    note right of Comfortable
        No penalties
        heatRateMultiplier = 1.0
        loadWobblePenalty = 0.0
    end note

    note right of Overloaded
        wobblePenalty scales 0.0 → 1.0
        heatRate scales 1.0 → 2.0
    end note

    note right of NearFull
        Auto-compact triggered
        New context blocked
    end note
```

**Auto-compact trigger:** When `totalLoad > 0.8999`, `_autoCompactIfNeeded()` fires automatically on every `fire()` and `executePlanningAction()` call.

**Source:** `lib/models/context_window.dart`, `lib/models/game_state.dart:190-196`

---

## 3. Rapid Fire State Machine

Controlled by keyboard input on the space bar. Rapid fire bypasses passive cooldown.

```mermaid
stateDiagram-v2
    [*] --> Idle

    Idle --> SingleShot : Space KeyDown
    SingleShot --> Idle : [immediate]
    Idle --> RapidFiring : Space KeyRepeat
    RapidFiring --> RapidFiring : Timer fires every 250ms
    RapidFiring --> Idle : Space KeyUp

    note right of RapidFiring
        Cooldown disabled during rapid fire
        Timer: 250ms interval
    end note
```

**Source:** `lib/widgets/game_canvas.dart:84-96, 124-131`

---

## 4. Heat Warning State Machine

Hysteresis-based warning that triggers audio feedback when heat is dangerously high.

```mermaid
stateDiagram-v2
    [*] --> Inactive

    Inactive --> Active : heatLevel > 0.8 [on fire()]
    Active --> Inactive : heatLevel < 0.6 [on cooldown tick]

    note right of Active
        Plays heat warning audio once
        Hysteresis gap: 0.6 → 0.8
    end note
```

**The hysteresis gap** (0.6 to 0.8) prevents rapid toggling of the warning sound.

**Source:** `lib/widgets/game_canvas.dart:77-81, 52`

---

## 5. Audio Service Init

One-way initialization guard preventing double-loading of audio assets.

```mermaid
stateDiagram-v2
    [*] --> Uninitialized
    Uninitialized --> Initialized : init()
    Initialized --> Initialized : init() [no-op]
```

**Source:** `lib/services/audio_service.dart`

---

## 6. Firing Flow (Orchestration)

Not a standalone state machine, but the central orchestration that connects all others.

```mermaid
stateDiagram-v2
    [*] --> Ready

    Ready --> CheckCanFire : Space pressed
    CheckCanFire --> Ready : canFire = false [blocked]
    CheckCanFire --> ExitPlanning : canFire = true & isPlanning
    CheckCanFire --> GenerateShot : canFire = true & !isPlanning
    ExitPlanning --> GenerateShot : togglePlanning()

    GenerateShot --> UpdateHeat : shot generated
    UpdateHeat --> CheckHeatWarning : heat updated
    CheckHeatWarning --> ConsumeBonuses : warning check done
    ConsumeBonuses --> AutoCompact : bonuses reset
    AutoCompact --> ConsumeContext : compact if needed
    ConsumeContext --> Ready : context consumed
```

**Source:** `lib/widgets/game_canvas.dart:68-82`, `lib/models/game_state.dart:68-112`

---

## 7. Session State Machine

```mermaid
stateDiagram-v2
    [*] --> Active : Session 1 starts
    Active --> Active : fire, plan, save, load/unload
    Active --> NewSession : New Session (N)
    NewSession --> Active : context cleared, bonuses reset, files unloaded, session++
```

---

## 8. Workspace State Machine

```mermaid
stateDiagram-v2
    [*] --> Empty
    Empty --> HasFiles : Save Plan / Save Research
    HasFiles --> HasFiles : Save more / Load / Unload
    HasFiles --> HasFiles : New Session (unloads all, keeps files)

    state HasFiles {
        [*] --> Unloaded
        Unloaded --> Loaded : Load (costs context)
        Loaded --> Unloaded : Unload (frees context)
    }
```
