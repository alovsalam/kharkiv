# 🛸 VyneDrone: Kharkiv Operation

**VyneDrone** is a low-poly, military-style FPV drone simulator built entirely on **Vyne** — a custom-developed programming language and interpreter written in C++. This project demonstrates the capabilities of the Vyne language in handling real-time 3D rendering, complex math, and state management.

## 🛠️ Technical Architecture

This project is more than just a game; it is an engine showcase for the Vyne language:

- **Core Engine:** Vyne Interpreter (C++ based AST Interpreter).
- **Graphics:** Custom `vglib` module providing a high-level bridge to Raylib.
- **Shaders:** Custom GLSL shaders for VHS distortion, pixelation, and volumetric fog.
- **Memory Management:** Leverages Vyne's internal memory tracking and optimized symbol table lookups.

## 🚀 Features

- **FPV Flight Physics:** Realistic drone handling including Pitch, Yaw, and Roll dynamics.
- **Military OSD/HUD:** A high-fidelity "Night Vision" interface featuring:
  - Dynamic Telemetry (Latitude, Longitude, and Elevation).
  - Live Altimeter and Compass bars.
  - Target Locking indicator.
- **Persistent Impact System:**
  - Procedural Forest & Kharkiv Map generation.
  - **Volumetric Smoke:** When a target is destroyed, a persistent, animated smoke plume remains at the impact site using a custom particle simulation logic.
- **Cinematic Immersion:**
  - VHS Bodycam post-processing.
  - Real-time Radio Chatter with a timed subtitle system.
  - Signal Loss & Crash sequences triggered by terrain collision.

## 📂 Project Structure

```bash
├── assets/             # 3D Models (GLB/OBJ), Textures, and Fonts
├── shaders/            # VHS, Fog, and VHS-Distortion GLSL files
├── src/
│   ├── config.vy       # Flight physics and engine constants
│   ├── loader.vy       # Asset management and group deployment
│   ├── missions.vy     # Target logic and volumetric smoke simulation
│   ├── subtitles.vy    # Timed radio dialogue data
│   └── renderer.vy     # Modular HUD and UI rendering logic
└── main.vy             # Entry point: Main loop and 3D render pipeline
```

## 🎮 Controls

| Key            | Function                        |
| :------------- | :------------------------------ |
| **Mouse**      | Directional Control (Yaw/Pitch) |
| **W / S**      | Elevation (Up/Down)             |
| **Q / E**      | Bank/Roll (Left/Right)          |
| **Left Shift** | Sprint/Boost                    |
| **Enter**      | Reset System (Post-Signal Loss) |
| **Escape**     | Enable Mouse Cursor             |
| **Shift + W**  | Focal Narrowing                 |
| **Shift + S**  | Focal Expansion                 |

## 🛠️ Running the Project

The project requires the **Vyne Interpreter** to be built and accessible in your environment. See official [vyne](https://github.com/t2ncay/vyne) repository for installation.
