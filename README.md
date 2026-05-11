# Neon Control Room — AI Orchestrator Visualizer

A cyberpunk pixel-art control room where you watch four AI agents (Planner → Researcher → Coder → Executor) coordinate in real time.

## Quick Start (First Demo)

### 1. Start the backend

```bash
cd backend
pip install -r requirements.txt
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

The server starts at `http://localhost:8000`. WebSocket at `ws://localhost:8000/ws`.

### 2. Open the Godot client

1. Install [Godot 4.x](https://godotengine.org/download)
2. Open `client-godot/project.godot`
3. Press **F5** (Run)

The window opens at **1920×1080** (pixel-perfect 4× scale of a 480×270 internal viewport). The HUD will show **AWAITING CONNECTION** until the backend is up, then switch to **CONNECTED**.

### 3. Hit RUN DEMO

Click the **[ RUN DEMO ]** button (top right of the HUD).

You'll see:
- Four stone-walled **agent cellars** — Planning Crypt (cyan), Archive Vault (purple), Forge Cellar (green), Exec Chamber (orange) — joined by a central neon corridor
- The Planner NPC glow cyan and animate at the Planning Console
- A data packet fly across the room to the Researcher
- Each agent walk to its station, animate through its states (planning → working → calling_tool → idle)
- The EventLog panel (bottom strip) stream live state changes

### Architecture

```
POST /run  ──►  DemoOrchestrator  ──►  AgentStateEvent / TaskTransitionEvent
                                              │
                                    WebSocket /ws broadcast
                                              │
                                    Godot WSClient ──► AgentNPC (tween, glow, icon)
```

### Providers

The demo uses `MockProvider` (no API keys needed). To use real models:

| Provider     | Env var needed           |
|--------------|--------------------------|
| claude       | `ANTHROPIC_API_KEY`      |
| nvidia_nim   | `NVIDIA_API_KEY`         |
| local_llm    | Run Ollama on port 11434 |

### Re-generating sprites

```bash
pip install Pillow
python tools/generate_sprites.py   # PNGs
python tools/generate_tres.py      # SpriteFrames .tres
```

### Running tests

```bash
cd backend && pytest
```
