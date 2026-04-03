# FireStep: Industrial Fire Safety Training Simulator

FireStep is a 3D educational simulator developed in **Godot 4.6.2 Standard**. It is designed as a training tool for industrial safety, specifically focusing on "VR in Production" scenarios. While the current implementation uses standard Mouse & Keyboard controls, the core logic follows professional safety protocols: prioritizing human life and evacuation over equipment preservation.

## 🚀 Overview

The simulator guides the user through a critical malfunction event at a compressor station. The goal is to demonstrate the correct sequence of actions when smoke and alarm indicators appear.

### Key Features
- **Scenario-Based Learning**: A structured flow from briefing to performance evaluation (debrief).
- **Interactive Environment**: Functioning emergency stop systems, hazard zones, and evacuation routes.
- **Dynamic Visuals**: Smoke intensity and lighting effects that react to player decisions.
- **Customizable Assets**: Easily swap out placeholder primitives for high-quality 3D models using a built-in export system.

## 🎮 Getting Started

1. Download and install **Godot 4.6.2 Standard** (GDScript version).
2. Clone this repository or download the source code.
3. Open `project.godot` in the Godot Editor.
4. Press `F5` to start the simulation.

## ⌨️ Controls

| Action | Key |
| :--- | :--- |
| **Movement** | `W`, `A`, `S`, `D` |
| **Look Around** | `Mouse` |
| **Interact** | `E` |
| **Sprint** | `Shift` |
| **Release/Capture Mouse** | `Esc` |
| **Restart Scene** (after finish) | `R` |

## 🛠 Asset Integration

The project is architected to be "model-agnostic." You can replace the default geometry without touching the underlying logic.

### How to Swap Models
1. Place your `.glb` or `.tscn` files in `res://assets/models/`.
2. Open `Main.tscn` or `Evacuation.tscn`.
3. Select the root node and locate the **Export Variables** in the Inspector:
   - `workshop_props_scene`: Decorative industrial props.
   - `machine_visual_scene`: The main compressor/machine model.
   - `wall_material` / `floor_material`: Custom textures for the environment.
4. Drag and drop your assets into these slots.

Detailed instructions can be found in [docs/ASSET_PIPELINE.md](docs/ASSET_PIPELINE.md).

## 📋 Scenario Flow

1. **Briefing**: Objectives and safety rules are presented to the operator.
2. **The Incident**: Smoke appears. The player must:
   - Perform an **Emergency Stop**.
   - Retreat to a **Safe Distance**.
   - **Call for Help** before exiting.
3. **Evacuation**: Navigate the corridor to the **Assembly Point**. Returning to the hazard zone results in failure.
4. **Debrief**: A summary of performance highlighting correct actions or critical errors.

## 🏗 Technical Stack

- **Engine**: Godot 4.6.2
- **Language**: GDScript
- **Architecture**: Decoupled state management via `GameSession` and `ScenarioState`.
- **UI**: Purely built-in Control nodes for maximum compatibility.

## ⚖️ License

This project is intended for educational and demonstration purposes. Please refer to `AGENTS.md` for specific development constraints and goals.