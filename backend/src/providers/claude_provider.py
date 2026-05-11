import os

import anthropic


class ClaudeProvider:
    """LLM provider backed by the Anthropic Claude API."""

    def __init__(self, api_key: str | None = None):
        self._client = anthropic.Anthropic(api_key=api_key or os.environ["ANTHROPIC_API_KEY"])

    def generate(self, messages: list[dict], model_name: str, **kwargs) -> dict:
        max_tokens = kwargs.pop("max_tokens", 1024)
        response = self._client.messages.create(
            model=model_name,
            max_tokens=max_tokens,
            messages=messages,
            **kwargs,
        )
        return {
            "content": response.content[0].text,
            "model": response.model,
            "stop_reason": response.stop_reason,
        }
