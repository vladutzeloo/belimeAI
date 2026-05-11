import asyncio
from collections.abc import AsyncIterator

from ..events import AgentStateEvent
from .base import BaseAgent


class ExecutorAgent(BaseAgent):
    agent_id = "agent_executor"

    async def run(self, task: dict) -> AsyncIterator[AgentStateEvent]:  # type: ignore[override]
        task_id = task["task_id"]
        yield self._state_event("calling_tool", task_id)
        await asyncio.sleep(0.8)

        yield self._state_event("working", task_id)
        await asyncio.sleep(1.0)

        yield self._state_event("calling_tool", task_id)
        await asyncio.sleep(0.6)

        await self.provider.generate(
            messages=[{"role": "user", "content": f"Execute: {task['goal']}"}],
            model_name=self.model_name,
        )
        yield self._state_event("working", task_id)
        await asyncio.sleep(1.2)
        yield self._state_event("idle", task_id)
