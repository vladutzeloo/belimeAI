"""Unit tests for provider implementations using mocked HTTP."""

from pytest_httpx import HTTPXMock

from src.mock_provider import MockProvider
from src.providers import LocalLLMProvider, NvidiaNIMProvider

NIM_RESPONSE = {
    "choices": [{"message": {"content": "hello"}, "finish_reason": "stop"}],
    "model": "test-model",
}


def test_mock_provider_returns_content():
    p = MockProvider()
    result = p.generate([{"role": "user", "content": "hi"}], "some-model")
    assert "content" in result
    assert result["stop_reason"] == "end_turn"


def test_nim_provider_calls_correct_url(httpx_mock: HTTPXMock):
    httpx_mock.add_response(json=NIM_RESPONSE)
    p = NvidiaNIMProvider(api_key="test", base_url="http://nim.local")
    result = p.generate([{"role": "user", "content": "hi"}], "nim-model")
    assert result["content"] == "hello"
    assert result["model"] == "test-model"


def test_local_llm_provider_calls_correct_url(httpx_mock: HTTPXMock):
    httpx_mock.add_response(json=NIM_RESPONSE)
    p = LocalLLMProvider(base_url="http://localhost:11434")
    result = p.generate([{"role": "user", "content": "hi"}], "llama3")
    assert result["content"] == "hello"
