VyneDrone: Kharkiv Operation

This is a fork of the VyneDrone project, a low-poly military FPV drone
simulator. What makes this project interesting is that it isn't built in Unity
or Unreal—it's written entirely in Vyne, a custom C++ based programming language
and AST interpreter.

I didn't create the Vyne language or the original codebase, but I'm
maintaining/expanding this fork to see how far we can push a custom interpreter
with real-time 3D rendering, flight math, and state management.

Under the Hood

Because this relies entirely on the Vyne interpreter instead of an established
game engine, the tech stack looks a bit different:

  - The Engine: Runs strictly on the Vyne C++ AST Interpreter.
  - Graphics Bridge: Uses a custom vglib module that allows the Vyne code to
    communicate directly with Raylib for rendering.
  - Shaders: The visual style (VHS distortion, pixelation, and volumetric fog)
    is handled by custom GLSL shaders hooked into the pipeline.
  - Memory Handling: The simulator relies heavily on Vyne's internal memory
    tracking and symbol table lookups to keep the framerate steady during
    flight.

Features

The focus is on making the drone flight feel heavy and realistic, with a gritty
military aesthetic.

  - Flight Physics: Handles true FPV dynamics. Pitch, yaw, and roll use actual
    momentum and bank mechanics rather than simple directional movement.
  - Tactical HUD: A night-vision interface that pulls live telemetry
    (lat/long/elevation), an active altimeter, compass data, and a target lock
    indicator.
  - Persistent Destruction: The map is a procedurally generated forest set in
    Kharkiv. Destroying a target triggers a custom particle system, leaving
    behind a persistent volumetric smoke plume while you keep flying.
  - Cinematics: Visuals are run through a VHS post-processing filter. There's
    also a timed subtitle system for live radio chatter, and a hard signal-loss
    sequence if you crash into the terrain.

Project Structure

If you're curious about how a 3D application looks when written in Vyne, here is
the layout:

├── assets/             # 3D models (GLB/OBJ), textures, and UI fonts
├── shaders/            # GLSL files for the VHS tape, fog, and distortion effects
├── src/
│   ├── config.vy       # Flight physics tuning and engine constants
│   ├── loader.vy       # Asset loading and 3D group deployment
│   ├── missions.vy     # Target logic, hits, and the smoke particle system
│   ├── subtitles.vy    # Data for the timed radio dialogue
│   └── renderer.vy     # Modular logic for drawing the HUD and UI
└── main.vy             # Entry point: core game loop and render pipeline

Flight Controls

| Input         | Action                        |
| :------------ | :---------------------------- |
| Mouse         | Look around (Yaw/Pitch)       |
| W / S         | Altitude (Up/Down)            |
| Q / E         | Bank/Roll (Left/Right)        |
| Left Shift    | Throttle Boost                |
| Shift + W / S | Adjust Camera FOV / Zoom      |
| Enter         | Reboot system (after a crash) |
| Escape        | Free the mouse cursor         |

How to Run It

Since this is written in Vyne, there's no standalone executable. You will need
the Vyne interpreter installed on your machine to run the scripts.

1.  Grab the interpreter from the original creator's repo: t2ncay/vyne
2.  Build and install it using their provided instructions.
3.  Clone this fork, navigate to the directory, and run:
    vyne main.vy

