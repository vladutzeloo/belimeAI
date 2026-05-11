# Agentic Orchestrator – Neon District Edition

This document is the implementation roadmap for the **AI Orchestrator + Godot visualizer** that shows multiple AI agents working inside a cyberpunk control room built from the **Neon District FREE** 16×16 pixel‑art pack.

The project is structured as a small mono‑repo with two main apps:
- `backend/`: Python multi‑agent orchestrator (Claude + NVIDIA NIM + local LLMs).
- `client-godot/`: Godot 4 2D visual client using Neon District as a control room.

---

## 1. High‑level goals

1. Visualize AI agents (planner, researcher, coder, tools) as animated NPCs walking around a Neon District style room.
2. Support multiple model providers behind one interface: Claude, NVIDIA NIM models, and local LLMs (Ollama/LM Studio).
3. Stream orchestrator events over WebSocket and have the Godot client react in real time (movement, animations, icons).
4. Keep assets and code cleanly separated, with a reusable pipeline for future projects.

---

## 2. Repo layout

```text
ai-orchestrator-visualizer/
  plan.md
  CLAUDE.md
  backend/
    src/
    tests/
    pyproject.toml or requirements.txt
  client-godot/
    project.godot
    scenes/
    scripts/
    assets/
      tilesets/
      characters/
      ui/
    config/
      agents_config.json
    tests/
```

You can split into two repos later, but starting as a mono‑repo keeps iteration with Claude simpler.

---

## 3. Backend (Python orchestrator)

**Tech:** Python 3, FastAPI or Flask + WebSockets, LangGraph or a lightweight custom agent graph.

### 3.1 Provider abstraction

Implement a simple provider interface:

```python
class LLMProvider(Protocol):
    def generate(self, messages: list[dict], model_name: str, **kwargs) -> dict: ...
```

Concrete implementations:
- `ClaudeProvider`: uses Claude API.
- `NvidiaNIMProvider`: uses NIM HTTP API (OpenAI‑style JSON).
- `LocalLLMProvider`: points to Ollama or LM Studio running on localhost.

Agents must **only** call `LLMProvider.generate`, never vendor‑specific SDKs.

### 3.2 Agent graph

Define agents:
- `agent_planner`: breaks user tasks into steps.
- `agent_researcher`: web/docs research + summaries.
- `agent_coder`: code generation and patch planning.
- `agent_executor`: runs tools (shell, HTTP calls, MES APIs).

Use LangGraph or a custom state machine to:
- Accept a high‑level request.
- Plan steps.
- Route steps to agents according to routing rules (which provider/model each agent prefers).

### 3.3 Event schema & WebSocket

Define a minimal JSON schema shared with the client:

```json
{
  "type": "agent_state",      // or "task_transition", "system_message"
  "agent_id": "agent_planner",
  "state": "working",         // idle | planning | calling_tool | working | error
  "task_id": "task-42",
  "provider": "claude",       // claude | nvidia_nim | local_llm
  "timestamp": "..."
}
```

Responsibilities:
- Every significant state change emits an event.
- WebSocket endpoint `/ws` streams events to any client.
- REST endpoint `POST /run` starts a demo scenario; events go out over WebSocket.

### 3.4 Tests

- Unit tests for each provider using mocked HTTP.
- Integration test that runs a minimal graph and asserts the order & shape of emitted events.

---

## 4. Client (Godot 4 – Neon control room)

**Tech:** Godot 4, GDScript, 16×16 pixel‑art pipeline.

### 4.1 Pixel‑art project setup

- Configure project for crisp pixel art (nearest‑neighbor filtering, integer scaling, low base resolution).
- Create `Main.tscn` with:
  - `TileMap` for the room.
  - `Stations` (Node2D) with empty station nodes.
  - `Agents` (Node2D) where NPCs will be instanced.

### 4.2 Neon District asset integration

1. Copy Neon District FREE PNGs into:
   - `assets/tilesets/neon_district/...`
   - `assets/characters/neon_operator.png`
   - `assets/ui/neon_hud/...`
2. In the editor, create:
   - A `TileSet` resource for the floor/walls/props.
   - `SpriteFrames` resources for one or more NPCs (planner, researcher, coder) based on the Neon operator.
3. Save them as `.tres`:
   - `res://assets/tilesets/neon_controlroom.tres`
   - `res://assets/characters/planner.tres`
   - `res://assets/characters/researcher.tres`

### 4.3 Config‑driven mapping

- Create `config/agents_config.json` like:

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

- On startup, load this JSON into a global `Dictionary`.

### 4.4 AgentNPC scene

- `scenes/AgentNPC.tscn`: `Node2D` with `AnimatedSprite2D` and an optional `provider_icon` sprite.
- `scripts/AgentNPC.gd`:
  - `setup(agent_id, config)` loads `SpriteFrames` from the path in JSON.
  - `apply_state(state: String)` switches animations (`idle`, `working`, `error`).
  - Optionally updates provider icon.

### 4.5 WebSocket client

- Add a WebSocket client that connects to `ws://localhost:8000/ws`.
- On `agent_state` events:
  - Look up or spawn the corresponding `AgentNPC`.
  - Move it to the configured station.
  - Call `apply_state`.
- On `task_transition` events:
  - Spawn a small “data scroll” sprite moving between stations.

### 4.6 Testing

- Use GdUnit4 tests to:
  - Load `agents_config.json` and ensure all referenced paths exist.
  - Instantiate `AgentNPC`, apply a `working` state, and assert the animation name.
- Add a CI workflow that runs GdUnit tests headless.

---

## 5. Asset workflow

### 5.1 Art source vs runtime

- `art/` (separate repo or folder): original Neon District pack + any edits, `.aseprite`/`.psd` files, references.
- `client-godot/assets/`: only optimized PNGs and `.tres` resources.

Maintain `ASSETS_LICENSES.md` listing Neon District FREE and any other packs, with links and license summary.

### 5.2 Export flow

1. Download or edit assets in `art/`.
2. Standardize as 16×16 tiles and sprite frames.
3. Export to PNG sprite sheets and copy into `client-godot/assets/`.
4. Update `.tres` and `agents_config.json` as needed.

---

## 6. Model provider integration

### 6.1 Claude

- Configure `ClaudeProvider` with API key and model (e.g. `claude-3.7-sonnet`, etc.).
- Use Claude primarily for complex orchestrator logic, planning, and coding tasks.

### 6.2 NVIDIA NIM

- Store `NIM_API_KEY` and `NIM_BASE_URL` in environment variables.
- Add mapping from logical model names to NIM models.
- Use NIM for high‑capacity or specialized models when needed.

### 6.3 Local LLMs

- Choose Ollama or LM Studio.
- Run server on localhost, expose an OpenAI‑style API.
- Implement `LocalLLMProvider` pointing at the local endpoint.

### 6.4 Routing rules

- Config file (YAML/JSON) defining, per agent:
  - `provider` (claude / nvidia_nim / local_llm)
  - `model_name`
- Godot only cares about the `provider` string for icons; all logic lives in backend.

---

## 7. Phased implementation

**Phase 1 – Backend skeleton**
- Implement `LLMProvider` interface and a single provider (Claude).
- Build minimal graph with fake tasks.
- Emit hard‑coded demo events over WebSocket.

**Phase 2 – Godot client skeleton**
- Create Godot project, main scene, and pixel‑art settings.
- Integrate Neon District tileset and one animated NPC.
- Hard‑code a fake event sequence in Godot to drive animations.

**Phase 3 – Wire WebSocket**
- Connect Godot to backend WebSocket.
- Replace fake events with real ones.

**Phase 4 – Multi‑provider support**
- Implement NIM and local providers.
- Add provider routing and small provider icons above agents.

**Phase 5 – Testing & polish**
- Add GdUnit4 tests and backend integration tests.
- Tune room layout, lighting, and small VFX (particles when tasks complete).

---

## 8. Definition of done

The project is “v1 done” when:
- A user can start a run from the backend and see multiple agents move and animate in the Neon control room.
- Provider icons change based on which model is being used.
- Adding a new agent or tool only requires:
  - Updating config (backend routing + `agents_config.json`).
  - Adding or reusing assets.
- CI runs tests for both backend and client successfully.
