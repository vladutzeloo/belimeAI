from abc import ABC, abstractmethod
from collections.abc import AsyncIterator

from ..events import AgentStateEvent
from ..providers.base import LLMProvider


class BaseAgent(ABC):
    """Abstract base for all orchestrator agents."""

    agent_id: str
    provider_name: str
    model_name: str

    def __init__(self, provider: LLMProvider, provider_name: str, model_name: str):
        self.provider = provider
        self.provider_name = provider_name  # type: ignore[assignment]
        self.model_name = model_name

    def _state_event(self, state: str, task_id: str) -> AgentStateEvent:
        return AgentStateEvent(
            agent_id=self.agent_id,  # type: ignore[arg-type]
            state=state,  # type: ignore[arg-type]
            task_id=task_id,
            provider=self.provider_name,  # type: ignore[arg-type]
        )

    @abstractmethod
    async def run(self, task: dict) -> AsyncIterator[AgentStateEvent]:
        ...
