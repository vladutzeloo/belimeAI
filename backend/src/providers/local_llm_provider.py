import httpx


class LocalLLMProvider:
    """LLM provider backed by a local Ollama / LM Studio OpenAI-compatible server."""

    def __init__(self, base_url: str = "http://localhost:11434"):
        self._base_url = base_url.rstrip("/")

    async def generate(self, messages: list[dict], model_name: str, **kwargs) -> dict:
        headers = {"Content-Type": "application/json"}
        payload = {
            "model": model_name,
            "messages": messages,
            "max_tokens": kwargs.pop("max_tokens", 1024),
            **kwargs,
        }
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self._base_url}/v1/chat/completions",
                headers=headers,
                json=payload,
                timeout=120,
            )
        response.raise_for_status()
        data = response.json()
        choice = data["choices"][0]
        return {
            "content": choice["message"]["content"],
            "model": data.get("model", model_name),
            "stop_reason": choice.get("finish_reason"),
        }
