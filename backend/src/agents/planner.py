import asyncio
from collections.abc import AsyncIterator

from ..events import AgentStateEvent
from .base import BaseAgent


class PlannerAgent(BaseAgent):
    agent_id = "agent_planner"

    async def run(self, task: dict) -> AsyncIterator[AgentStateEvent]:  # type: ignore[override]
        task_id = task["task_id"]
        yield self._state_event("planning", task_id)
        await asyncio.sleep(0.3)

        await self.provider.generate(
            messages=[{"role": "user", "content": f"Break this into 3 steps: {task['goal']}"}],
            model_name=self.model_name,
        )
        yield self._state_event("working", task_id)
        await asyncio.sleep(0.4)
        yield self._state_event("idle", task_id)
