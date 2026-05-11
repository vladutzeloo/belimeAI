# Context for Claude – Agentic Orchestrator Neon Control Room

This file gives Claude (and other coding copilots) the context it needs to work on this project safely and consistently.

---

## Project summary

We are building a **multi‑agent AI orchestrator** with a 2D **cyberpunk control room** visualizer.

- Backend: Python orchestrator that coordinates multiple AI agents (planner, researcher, coder, executor) across **Claude**, **NVIDIA NIM**, and **local LLMs**.
- Frontend: **Godot 4** pixel‑art client that shows each agent as an NPC walking around a room built from the **Neon District FREE — Cyberpunk Pixel Art Starter Kit (16×16)**.

User goal: see AI workflows play out visually, like a Travelers Rest tavern but cyberpunk, and keep the system production‑grade (config‑driven, testable, extensible).

Repo layout (mono‑repo):

```text
ai-orchestrator-visualizer/
  plan.md
  CLAUDE.md
  backend/
  client-godot/
```

`plan.md` contains the high‑level roadmap and MUST stay in sync with what you implement.

---

## Terminology and IDs

- **Agents (backend logical roles):**
  - `agent_planner` – plans and decomposes tasks.
  - `agent_researcher` – web/docs research.
  - `agent_coder` – writes and refactors code.
  - `agent_executor` – runs tools, commands, and API calls.

- **Providers (model backends):**
  - `claude` – Anthropic Claude API.
  - `nvidia_nim` – NVIDIA NIM models via NGC / NIM endpoints.
  - `local_llm` – local models via Ollama or LM Studio HTTP server.

These strings are shared between backend config and frontend visuals (provider icons).

---

## Backend expectations (Python)

**Language & style:**
- Python 3.x, type‑hinted, black/ruff‑friendly.
- Prefer FastAPI + `uvicorn` for HTTP/WebSocket, but keep framework choice contained.

**Provider abstraction:**
- Implement an `LLMProvider` interface with a `generate(messages, model_name, **kwargs)` method.
- Implement `ClaudeProvider`, `NvidiaNIMProvider`, and `LocalLLMProvider` behind that interface.
- Agents must call only the interface, not a vendor SDK directly.

**Event schema:**

All events sent to the Godot client MUST follow this shape:

```jsonc
{
  "type": "agent_state",        // or "task_transition", "system_message"
  "agent_id": "agent_planner",  // one of the agent IDs above
  "state": "working",           // idle | planning | calling_tool | working | error
  "task_id": "task-42",         // opaque identifier for a subtask
  "provider": "claude",         // claude | nvidia_nim | local_llm
  "timestamp": "ISO8601 string"
}
```

Transport:
- HTTP `POST /run` – start a demo run.
- WebSocket `/ws` – stream events to any connected client.

**Important:** The backend does not know about Godot nodes or sprites. It only emits semantic events.

---

## Client expectations (Godot 4)

**Engine & language:**
- Godot 4.x, GDScript.
- 2D only, pixel‑art friendly settings.

**Pixel‑art configuration:**
- 16×16 base grid (Neon District tiles).
- Use nearest‑neighbor filtering, pixel snap, integer scaling, and a low base resolution so the art stays crisp.

**Scenes:**

- `scenes/Main.tscn`
  - Root `Node2D` with:
    - `TileMap` – room layout using Neon District tiles.
    - `Stations` (Node2D) – child nodes for each station (e.g. `PlanningConsole`, `LibraryCorner`).
    - `Agents` (Node2D) – parent for all `AgentNPC` instances.

- `scenes/AgentNPC.tscn`
  - Root `Node2D` with:
    - `AnimatedSprite2D` – main character sprite.
    - `Sprite2D` or similar for a small provider icon above the head.

**Config‑driven mapping:**

We use JSON config to avoid hard‑coding asset paths and node names in scripts.

- `config/agents_config.json`:

```json
{
  "agent_planner": {
    "sprite_frames": "res://assets/characters/planner.tres",
    "station": "Stations/PlanningConsole"
  },
  "agent_researcher": {
    "sprite_frames": "res://assets/characters/researcher.tres",
    "station": "Stations/LibraryCorner"
  }
}
```

At runtime:
- Load this JSON once into a `Dictionary`.
- Use it to configure each `AgentNPC` (set `AnimatedSprite2D.sprite_frames`, initial position, etc.).

**WebSocket client behavior:**

- Connect to `ws://localhost:8000/ws` (configurable).
- On receiving an `agent_state` event:
  - Find or spawn the corresponding `AgentNPC` under `Agents`.
  - Look up config for that `agent_id`.
  - Move the NPC to the configured `station` (or other logic based on state).
  - Switch animation based on `state`.
  - Update provider icon based on `provider`.

- On `task_transition` events:
  - Spawn and animate a small “data scroll” / packet sprite moving from one station to another.

**Animations:**
- Each NPC should support at least `idle`, `working`, and `error` animation names.
- These must exist as animations in the `SpriteFrames` resources.

---

## Assets and licensing

We are using **Neon District FREE — Cyberpunk Pixel Art Starter Kit (16×16)** from itch.io as the main visual style.

Rules:
- Keep original pack files in a separate `art/` folder (or repo) as the source of truth.
- `client-godot/assets/` should contain only PNGs and `.tres` resources actually used by the project.
- Maintain `ASSETS_LICENSES.md` listing:
  - Pack name, author (Abk— Premium Pixel Art).
  - itch.io URL.
  - License terms summary.

Claude MUST NOT change license text or remove attribution requirements.

---

## Testing & CI expectations

Backend:
- Use `pytest` for unit and integration tests.
- Have at least one integration test that simulates a short run and asserts the event sequence and schema.

Client (Godot):
- Use **GdUnit4** for automated tests.
- Tests should:
  - Validate that `agents_config.json` entries point to existing resources and nodes.
  - Instantiate `AgentNPC` and assert animation/state changes when given a mock event.

CI:
- Add GitHub Actions (or similar) workflows for:
  - `backend/`: install deps, run tests, lint.
  - `client-godot/`: install Godot headless, run GdUnit4 tests.

---

## How to work with this file

For Claude (and other copilots):
- Always read this file and `plan.md` before making structural changes.
- When you add new agents, providers, or stations, update both:
  - Backend config and event logic.
  - `agents_config.json` and any relevant sections here.
- Do not introduce new global strings for agent IDs or providers; reuse the ones defined here or add them systematically.

For the human (me):
- Keep this file short but accurate.
- Update it whenever you change the architecture, event schema, or asset structure.
- Use it as pinned/system context when asking Claude to implement features in this repo.