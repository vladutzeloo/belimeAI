"""Unit tests for the routing config loader."""

import json

import pytest

from src.routing import build_routing, load_routing_config


def _write(tmp_path, payload):
    p = tmp_path / "routing.json"
    p.write_text(json.dumps(payload))
    return p


VALID_CFG = {
    "agent_planner":    {"provider": "claude",     "model_name": "claude-sonnet-4-6"},
    "agent_researcher": {"provider": "nvidia_nim", "model_name": "meta/llama-3.1-70b-instruct"},
    "agent_coder":      {"provider": "claude",     "model_name": "claude-sonnet-4-6"},
    "agent_executor":   {"provider": "local_llm",  "model_name": "llama3"},
}


def test_load_default_config_succeeds():
    cfg = load_routing_config()
    assert set(cfg) >= {"agent_planner", "agent_researcher", "agent_coder", "agent_executor"}


def test_root_must_be_object(tmp_path):
    p = _write(tmp_path, ["not", "a", "dict"])
    with pytest.raises(ValueError, match="must be a JSON object"):
        load_routing_config(p)


def test_missing_agent_raises(tmp_path):
    bad = {k: v for k, v in VALID_CFG.items() if k != "agent_coder"}
    p = _write(tmp_path, bad)
    with pytest.raises(ValueError, match="missing agent: agent_coder"):
        load_routing_config(p)


def test_entry_must_be_object(tmp_path):
    bad = {**VALID_CFG, "agent_coder": "claude"}
    p = _write(tmp_path, bad)
    with pytest.raises(ValueError, match="entry must be an object"):
        load_routing_config(p)


def test_invalid_provider_rejected(tmp_path):
    bad = {**VALID_CFG, "agent_coder": {"provider": "openai", "model_name": "gpt-4"}}
    p = _write(tmp_path, bad)
    with pytest.raises(ValueError, match="invalid provider"):
        load_routing_config(p)


def test_build_routing_ignores_extra_keys(tmp_path):
    cfg = {**VALID_CFG, "agent_bogus": {"provider": "claude", "model_name": "x"}}
    routing = build_routing(cfg)
    assert set(routing) == {"agent_planner", "agent_researcher", "agent_coder", "agent_executor"}
