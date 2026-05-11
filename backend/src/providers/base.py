from typing import Protocol, runtime_checkable


@runtime_checkable
class LLMProvider(Protocol):
    """Shared interface for all LLM provider implementations."""

    def generate(self, messages: list[dict], model_name: str, **kwargs) -> dict:
        """Send messages and return a response dict with at least a 'content' key."""
        ...
