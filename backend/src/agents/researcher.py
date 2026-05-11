import asyncio
from collections.abc import AsyncIterator

from ..events import AgentStateEvent
from .base import BaseAgent


class ResearcherAgent(BaseAgent):
    agent_id = "agent_researcher"

    async def run(self, task: dict) -> AsyncIterator[AgentStateEvent]:  # type: ignore[override]
        task_id = task["task_id"]
        yield self._state_event("working", task_id)
        await asyncio.sleep(0.3)

        self.provider.generate(
            messages=[{"role": "user", "content": f"Research: {task.get('topic', task['goal'])}"}],
            model_name=self.model_name,
        )
        yield self._state_event("idle", task_id)
