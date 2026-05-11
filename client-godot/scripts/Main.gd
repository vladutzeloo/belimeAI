extends Node2D

const AGENTS_CONFIG_PATH: String = "res://config/agents_config.json"
const AGENT_NPC_SCENE: String = "res://scenes/AgentNPC.tscn"

var _agents_config: Dictionary = {}
var _npc_map: Dictionary = {}  # agent_id -> AgentNPC

@onready var agents_root: Node2D = $Agents
@onready var stations_root: Node2D = $Stations
@onready var ws_client: WSClient = $WSClient

func _ready() -> void:
	_load_agents_config()
	ws_client.event_received.connect(_on_event_received)

func _load_agents_config() -> void:
	var file := FileAccess.open(AGENTS_CONFIG_PATH, FileAccess.READ)
	if not file:
		push_error("Main: could not open %s" % AGENTS_CONFIG_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_agents_config = parsed
	else:
		push_error("Main: agents_config.json is not a valid JSON object")

func _on_event_received(data: Dictionary) -> void:
	match data.get("type", ""):
		"agent_state":
			_handle_agent_state(data)
		"task_transition":
			_handle_task_transition(data)
		"system_message":
			print("System: ", data.get("message", ""))

func _handle_agent_state(data: Dictionary) -> void:
	var agent_id: String = data.get("agent_id", "")
	var state: String = data.get("state", "idle")
	var provider: String = data.get("provider", "claude")

	var npc: AgentNPC = _get_or_spawn_npc(agent_id)
	npc.apply_state(state)
	npc.set_provider(provider)

	var cfg: Dictionary = _agents_config.get(agent_id, {})
	var station_path: String = cfg.get("station", "")
	if station_path != "":
		var station := stations_root.get_node_or_null(station_path.replace("Stations/", ""))
		if station is Node2D:
			npc.move_to_station(station)

func _handle_task_transition(data: Dictionary) -> void:
	var from_id: String = data.get("from_agent", "")
	var to_id: String = data.get("to_agent", "")
	# TODO: spawn a "data scroll" sprite moving from from_npc to to_npc
	print("Transition: %s -> %s" % [from_id, to_id])

func _get_or_spawn_npc(agent_id: String) -> AgentNPC:
	if _npc_map.has(agent_id):
		return _npc_map[agent_id]

	var scene: PackedScene = load(AGENT_NPC_SCENE)
	var npc: AgentNPC = scene.instantiate()
	agents_root.add_child(npc)
	var cfg: Dictionary = _agents_config.get(agent_id, {})
	npc.setup(agent_id, cfg)
	_npc_map[agent_id] = npc
	return npc
