import os

import httpx


class NvidiaNIMProvider:
    """LLM provider backed by NVIDIA NIM (OpenAI-compatible HTTP API)."""

    def __init__(self, api_key: str | None = None, base_url: str | None = None):
        self._api_key = api_key or os.environ.get("NIM_API_KEY", "")
        self._base_url = (base_url or os.environ.get("NIM_BASE_URL", "")).rstrip("/")

    async def generate(self, messages: list[dict], model_name: str, **kwargs) -> dict:
        headers = {
            "Authorization": f"Bearer {self._api_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": model_name,
            "messages": messages,
            "max_tokens": kwargs.pop("max_tokens", 1024),
            **kwargs,
        }
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self._base_url}/chat/completions",
                headers=headers,
                json=payload,
                timeout=60,
            )
        response.raise_for_status()
        data = response.json()
        choice = data["choices"][0]
        return {
            "content": choice["message"]["content"],
            "model": data.get("model", model_name),
            "stop_reason": choice.get("finish_reason"),
        }
