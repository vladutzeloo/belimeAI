"""
Demo orchestrator: runs a scripted sequence of agent steps and emits events.
Real task routing uses the routing config; this demo uses mock providers.
"""

import asyncio
import uuid
from collections.abc import AsyncIterator

from .agents import CoderAgent, ExecutorAgent, PlannerAgent, ResearcherAgent
from .events import SystemMessageEvent, TaskTransitionEvent


class DemoOrchestrator:
    """Runs a scripted demo scenario, streaming events to listeners."""

    def __init__(self, routing: dict[str, dict]):
        """
        routing: {agent_id: {"provider": <LLMProvider>, "provider_name": str, "model_name": str}}
        """
        cls_map = {
            "agent_planner": PlannerAgent,
            "agent_researcher": ResearcherAgent,
            "agent_coder": CoderAgent,
            "agent_executor": ExecutorAgent,
        }
        self._agents = {
            agent_id: cls_map[agent_id](
                provider=cfg["provider"],
                provider_name=cfg["provider_name"],
                model_name=cfg["model_name"],
            )
            for agent_id, cfg in routing.items()
        }

    async def run_demo(self, goal: str) -> AsyncIterator[dict]:
        run_id = str(uuid.uuid4())[:8]
        task_id = f"task-{run_id}"

        yield SystemMessageEvent(message=f"Starting demo run: {goal}", task_id=task_id).model_dump()

        pipeline: list[tuple[str, str]] = [
            ("agent_planner", "agent_researcher"),
            ("agent_researcher", "agent_coder"),
            ("agent_coder", "agent_executor"),
        ]

        task = {"task_id": task_id, "goal": goal}

        async for event in self._agents["agent_planner"].run(task):
            yield event.model_dump()

        for from_id, to_id in pipeline:
            yield TaskTransitionEvent(
                from_agent=from_id,  # type: ignore[arg-type]
                to_agent=to_id,  # type: ignore[arg-type]
                task_id=task_id,
            ).model_dump()
            # pause so the Godot data-packet tween (~0.4s) and NPC walk (~0.9s) are visible
            await asyncio.sleep(1.2)
            async for event in self._agents[to_id].run(task):
                yield event.model_dump()

        yield SystemMessageEvent(message="Demo run complete.", task_id=task_id).model_dump()
