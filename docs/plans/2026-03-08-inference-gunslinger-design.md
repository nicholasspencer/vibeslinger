# Inference Gunslinger — Design

## Concept

An interactive visual metaphor mapping AI/inference SDLCs to marksmanship. The gunslinger (prompt engineer/developer) fires a laser gun (model) at a target. Accuracy depends on skill, gun choice, environmental factors, and fatigue from rapid fire.

Primary use: presentation aid for a talk, hosted on personal GitHub Pages site for future reference.

## Visual Layout

```
+-------------------------------------+
|  [Gun Selector]  [Skill Slider]     |  <- Top controls
|  [Environment Toggles]              |
+-------------------------------------+
|                                     |
|   Stick        ~~~~~~~~~~~~  Target |  <- Figure, laser, target
|   Figure                            |
|                                     |
|  [Accuracy: 87%]  [Shots: 12]      |  <- Stats
+-------------------------------------+
|  [FIRE]          [RAPID FIRE (hold)]|  <- Action buttons
+-------------------------------------+
```

## Architecture

Single-screen Flutter web app using custom `CustomPainter` canvas rendering. No game engine — Flutter's built-in canvas APIs handle the stick figure, laser beams, and target.

## Components

### Stick Figure
Simple drawn figure. Posture shifts based on skill level (stable vs wobbly). Holds a colored laser gun that changes with model selection.

### Target
Concentric circles. Shots appear as glowing dots. Tighter cluster = higher accuracy.

### Laser Beam
Brief animated line from gun to target on each shot. Color matches the gun/model.

## Parameters & Effects

| Parameter | UI Control | Visual Effect |
|-----------|-----------|---------------|
| Gun/Model | Dropdown: "Precision Rifle (Claude Opus)", "Pulse Pistol (GPT-4o)", "Scatter Blaster (Llama 3)" | Gun color changes, base accuracy differs, beam style varies |
| Skill Level | Slider: Novice to Expert | Stick figure posture stabilizes, shot spread tightens |
| Rapid Fire / Burnout | Hold the fire button | First shots accurate, spread increases progressively. Heat meter fills up. |
| Environment | Toggle chips: "Windy" (high temp), "Low Light" (small context), "Unstable Ground" (poor prompt structure) | Each adds spread/wobble. Figure visually reacts (leans, squints, sways). |

## Guided Scenes

Pre-set configurations accessible via number keys or scene menu:

1. **"The Expert"** — max skill, precision rifle, calm environment -> tight grouping
2. **"The Novice"** — low skill, scatter blaster, bad conditions -> wild spread
3. **"Burnout"** — expert + precision rifle, but rapid fire -> starts great, degrades
4. **Free Play** — all controls unlocked

## Deployment

`flutter build web` -> deploy to personal GitHub Pages site.
