"""Stub provider used in demo mode and tests — never calls external APIs."""


class MockProvider:
    def generate(self, messages: list[dict], model_name: str, **kwargs) -> dict:
        return {
            "content": f"[mock response from {model_name}]",
            "model": model_name,
            "stop_reason": "end_turn",
        }
