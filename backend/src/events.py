from datetime import datetime, timezone
from typing import Literal

from pydantic import BaseModel, Field

AgentId = Literal["agent_planner", "agent_researcher", "agent_coder", "agent_executor"]
AgentState = Literal["idle", "planning", "calling_tool", "working", "error"]
Provider = Literal["claude", "nvidia_nim", "local_llm"]
EventType = Literal["agent_state", "task_transition", "system_message"]


class AgentStateEvent(BaseModel):
    type: EventType = "agent_state"
    agent_id: AgentId
    state: AgentState
    task_id: str
    provider: Provider
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())


class TaskTransitionEvent(BaseModel):
    type: EventType = "task_transition"
    from_agent: AgentId
    to_agent: AgentId
    task_id: str
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())


class SystemMessageEvent(BaseModel):
    type: EventType = "system_message"
    message: str
    task_id: str
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
