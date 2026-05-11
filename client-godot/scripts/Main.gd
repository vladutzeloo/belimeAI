extends Node2D

const AGENTS_CONFIG_PATH := "res://config/agents_config.json"
const AGENT_NPC_SCENE    := "res://scenes/AgentNPC.tscn"

var _agents_config: Dictionary = {}
var _npc_map:       Dictionary = {}   # agent_id -> AgentNPC

@onready var _agents_root:  Node2D    = $Agents
@onready var _stations_root: Node2D   = $Stations
@onready var _status_label: Label     = $HUD/StatusLabel
@onready var _ws_client:    WSClient  = $WSClient

func _ready() -> void:
	_load_agents_config()
	_ws_client.event_received.connect(_on_event_received)
	_ws_client.connection_changed.connect(_on_connection_changed)

func _load_agents_config() -> void:
	var f := FileAccess.open(AGENTS_CONFIG_PATH, FileAccess.READ)
	if not f:
		push_error("Main: cannot open %s" % AGENTS_CONFIG_PATH)
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		_agents_config = parsed
	else:
		push_error("Main: agents_config.json is not a valid JSON object")

func _on_connection_changed(connected: bool) -> void:
	_status_label.text = (
		"NEON CONTROL ROOM  //  CONNECTED" if connected
		else "NEON CONTROL ROOM  //  AWAITING CONNECTION"
	)

func _on_event_received(data: Dictionary) -> void:
	match data.get("type", ""):
		"agent_state":    _handle_agent_state(data)
		"task_transition": _handle_task_transition(data)
		"system_message": _handle_system_message(data)

func _handle_agent_state(data: Dictionary) -> void:
	var agent_id: String = data.get("agent_id", "")
	var state:    String = data.get("state",    "idle")
	var provider: String = data.get("provider", "claude")

	var npc := _get_or_spawn_npc(agent_id)
	npc.apply_state(state)
	npc.set_provider(provider)

	# move to station
	var cfg: Dictionary = _agents_config.get(agent_id, {})
	var station_path: String = cfg.get("station", "")
	if station_path != "":
		var key := station_path.replace("Stations/", "")
		var station := _stations_root.get_node_or_null(key)
		if station is Node2D:
			npc.move_to_station(station)

func _handle_task_transition(data: Dictionary) -> void:
	var from_id: String = data.get("from_agent", "")
	var to_id:   String = data.get("to_agent",   "")
	_spawn_data_packet(from_id, to_id)

func _handle_system_message(data: Dictionary) -> void:
	_status_label.text = data.get("message", "").to_upper()

func _get_or_spawn_npc(agent_id: String) -> AgentNPC:
	if _npc_map.has(agent_id):
		return _npc_map[agent_id]

	var scene: PackedScene = load(AGENT_NPC_SCENE)
	var npc: AgentNPC = scene.instantiate()
	_agents_root.add_child(npc)

	var cfg: Dictionary = _agents_config.get(agent_id, {})
	npc.setup(agent_id, cfg)

	# start off at the station position
	var station_path: String = cfg.get("station", "")
	if station_path != "":
		var station := _stations_root.get_node_or_null(station_path.replace("Stations/", ""))
		if station is Node2D:
			npc.global_position = station.global_position

	_npc_map[agent_id] = npc
	return npc

func _spawn_data_packet(from_id: String, to_id: String) -> void:
	var from_npc: AgentNPC = _npc_map.get(from_id)
	var to_npc:   AgentNPC = _npc_map.get(to_id)
	if not from_npc or not to_npc:
		return

	var packet := ColorRect.new()
	packet.size  = Vector2(4, 4)
	packet.color = Color(0, 0.94, 1, 0.9)
	_agents_root.add_child(packet)
	packet.global_position = from_npc.global_position

	var tween := packet.create_tween()
	tween.tween_property(packet, "global_position", to_npc.global_position, 0.4) \
		.set_trans(Tween.TRANS_SINE)
	tween.tween_callback(packet.queue_free)
