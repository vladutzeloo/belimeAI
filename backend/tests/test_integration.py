"""Integration test: run a demo scenario and assert event order and schema."""

import pytest

from src.mock_provider import MockProvider
from src.orchestrator import DemoOrchestrator
from src.routing import build_routing, load_routing_config


def _routing():
    p = MockProvider()
    return {
        agent_id: {"provider": p, "provider_name": "claude", "model_name": "claude-sonnet-4-6"}
        for agent_id in ("agent_planner", "agent_researcher", "agent_coder", "agent_executor")
    }


@pytest.mark.asyncio
async def test_demo_run_event_schema():
    orchestrator = DemoOrchestrator(routing=_routing())
    events = []
    async for event in orchestrator.run_demo("test goal"):
        events.append(event)

    assert len(events) > 0
    for e in events:
        assert "type" in e
        assert "timestamp" in e
        assert e["type"] in ("agent_state", "task_transition", "system_message")


@pytest.mark.asyncio
async def test_demo_run_agent_state_events():
    orchestrator = DemoOrchestrator(routing=_routing())
    agent_states = []
    async for event in orchestrator.run_demo("build something"):
        if event["type"] == "agent_state":
            agent_states.append(event)

    agent_ids_seen = {e["agent_id"] for e in agent_states}
    assert "agent_planner" in agent_ids_seen
    assert "agent_researcher" in agent_ids_seen
    assert "agent_coder" in agent_ids_seen
    assert "agent_executor" in agent_ids_seen

    for e in agent_states:
        assert e["state"] in ("idle", "planning", "calling_tool", "working", "error")
        assert e["provider"] in ("claude", "nvidia_nim", "local_llm")


@pytest.mark.asyncio
async def test_demo_run_task_transitions():
    orchestrator = DemoOrchestrator(routing=_routing())
    transitions = []
    async for event in orchestrator.run_demo("research something"):
        if event["type"] == "task_transition":
            transitions.append(event)

    assert len(transitions) == 3  # planner->researcher, researcher->coder, coder->executor
    assert transitions[0]["from_agent"] == "agent_planner"
    assert transitions[0]["to_agent"] == "agent_researcher"


@pytest.mark.asyncio
async def test_demo_run_starts_and_ends_with_system_message():
    orchestrator = DemoOrchestrator(routing=_routing())
    events = []
    async for event in orchestrator.run_demo("hello"):
        events.append(event)

    assert events[0]["type"] == "system_message"
    assert events[-1]["type"] == "system_message"
    assert "complete" in events[-1]["message"].lower()


@pytest.mark.asyncio
async def test_demo_run_respects_routing_config_per_agent():
    cfg = load_routing_config()
    orchestrator = DemoOrchestrator(routing=build_routing(cfg))

    seen: dict[str, set[str]] = {}
    async for event in orchestrator.run_demo("routed run"):
        if event["type"] == "agent_state":
            seen.setdefault(event["agent_id"], set()).add(event["provider"])

    for agent_id, entry in cfg.items():
        assert seen[agent_id] == {entry["provider"]}, (
            f"{agent_id} should only emit provider {entry['provider']!r}, got {seen[agent_id]}"
        )
