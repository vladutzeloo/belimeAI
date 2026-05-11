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
        self._routing = routing

    def _make_agent(self, agent_id: str):
        cfg = self._routing[agent_id]
        cls_map = {
            "agent_planner": PlannerAgent,
            "agent_researcher": ResearcherAgent,
            "agent_coder": CoderAgent,
            "agent_executor": ExecutorAgent,
        }
        return cls_map[agent_id](
            provider=cfg["provider"],
            provider_name=cfg["provider_name"],
            model_name=cfg["model_name"],
        )

    async def run_demo(self, goal: str) -> AsyncIterator[dict]:
        run_id = str(uuid.uuid4())[:8]
        task_id = f"task-{run_id}"

        yield SystemMessageEvent(message=f"Starting demo run: {goal}", task_id=task_id).model_dump()

        pipeline: list[tuple[str, str]] = [
            ("agent_planner", "agent_researcher"),
            ("agent_researcher", "agent_coder"),
            ("agent_coder", "agent_executor"),
        ]

        current_agent_id = "agent_planner"
        task = {"task_id": task_id, "goal": goal}

        async for event in self._make_agent(current_agent_id).run(task):
            yield event.model_dump()

        for from_id, to_id in pipeline:
            yield TaskTransitionEvent(
                from_agent=from_id,  # type: ignore[arg-type]
                to_agent=to_id,  # type: ignore[arg-type]
                task_id=task_id,
            ).model_dump()
            await asyncio.sleep(0.1)
            async for event in self._make_agent(to_id).run(task):
                yield event.model_dump()

        yield SystemMessageEvent(message="Demo run complete.", task_id=task_id).model_dump()
