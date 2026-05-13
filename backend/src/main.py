"""FastAPI application: HTTP /run endpoint and WebSocket /ws for event streaming."""

import asyncio
import json

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from .orchestrator import DemoOrchestrator
from .routing import build_routing


class ConnectionManager:
    def __init__(self):
        self._active: list[WebSocket] = []

    async def connect(self, ws: WebSocket):
        await ws.accept()
        self._active.append(ws)

    def disconnect(self, ws: WebSocket):
        self._active.remove(ws)

    async def broadcast(self, data: dict):
        payload = json.dumps(data)
        dead = []
        for ws in self._active:
            try:
                await ws.send_text(payload)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self._active.remove(ws)


manager = ConnectionManager()

# Built once at startup: file I/O + JSON parse + MockProvider instance are shared
# across requests. The orchestrator itself is cheap to construct per-run.
_routing = build_routing()


app = FastAPI(title="AI Orchestrator", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class RunRequest(BaseModel):
    goal: str = "Build a cyberpunk control room visualizer"


@app.post("/run")
async def run_endpoint(req: RunRequest):
    """Start a demo orchestrator run and stream events over WebSocket."""
    orchestrator = DemoOrchestrator(routing=_routing)

    async def _stream():
        async for event in orchestrator.run_demo(req.goal):
            await manager.broadcast(event)

    asyncio.create_task(_stream())
    return {"status": "started", "goal": req.goal}


@app.websocket("/ws")
async def ws_endpoint(ws: WebSocket):
    await manager.connect(ws)
    try:
        while True:
            await ws.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(ws)


@app.get("/health")
async def health():
    return {"status": "ok"}
