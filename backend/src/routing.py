"""Routing config loader: maps each agent to a provider name + model + provider instance."""

import json
from pathlib import Path

from .mock_provider import MockProvider
from .providers.base import LLMProvider

_AGENT_IDS = ("agent_planner", "agent_researcher", "agent_coder", "agent_executor")
_PROVIDER_NAMES = ("claude", "nvidia_nim", "local_llm")

DEFAULT_CONFIG_PATH = Path(__file__).resolve().parent.parent / "config" / "routing_config.json"


def load_routing_config(path: Path | str = DEFAULT_CONFIG_PATH) -> dict[str, dict[str, str]]:
    """Load the JSON routing config and validate agent IDs and provider names."""
    data = json.loads(Path(path).read_text())

    for agent_id in _AGENT_IDS:
        if agent_id not in data:
            raise ValueError(f"routing config missing agent: {agent_id}")
        entry = data[agent_id]
        if entry.get("provider") not in _PROVIDER_NAMES:
            raise ValueError(f"{agent_id}: invalid provider {entry.get('provider')!r}")
        if not entry.get("model_name"):
            raise ValueError(f"{agent_id}: model_name is required")

    return data


def build_routing(
    config: dict[str, dict[str, str]] | None = None,
    provider: LLMProvider | None = None,
) -> dict[str, dict]:
    """Build the orchestrator routing dict.

    The MockProvider is used by default so the demo runs without API keys.
    The `provider_name` per agent still reflects the real routing so the
    Godot client can show the correct provider icon.
    """
    cfg = config if config is not None else load_routing_config()
    shared_provider = provider if provider is not None else MockProvider()
    return {
        agent_id: {
            "provider": shared_provider,
            "provider_name": entry["provider"],
            "model_name": entry["model_name"],
        }
        for agent_id, entry in cfg.items()
    }
