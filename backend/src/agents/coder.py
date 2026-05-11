import asyncio
from collections.abc import AsyncIterator

from ..events import AgentStateEvent
from .base import BaseAgent


class CoderAgent(BaseAgent):
    agent_id = "agent_coder"

    async def run(self, task: dict) -> AsyncIterator[AgentStateEvent]:  # type: ignore[override]
        task_id = task["task_id"]
        yield self._state_event("working", task_id)
        await asyncio.sleep(1.3)

        yield self._state_event("calling_tool", task_id)
        await asyncio.sleep(0.7)

        await self.provider.generate(
            messages=[{"role": "user", "content": f"Write code for: {task['goal']}"}],
            model_name=self.model_name,
        )
        yield self._state_event("working", task_id)
        await asyncio.sleep(1.4)
        yield self._state_event("idle", task_id)
