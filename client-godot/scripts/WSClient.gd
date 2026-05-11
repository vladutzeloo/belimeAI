extends Node
class_name WSClient

signal event_received(data: Dictionary)

const WS_URL: String = "ws://localhost:8000/ws"

var _socket: WebSocketPeer = WebSocketPeer.new()
var _connected: bool = false

func _ready() -> void:
	_connect_to_server()

func _connect_to_server() -> void:
	var err: int = _socket.connect_to_url(WS_URL)
	if err != OK:
		push_warning("WSClient: could not initiate connection to %s (err %d)" % [WS_URL, err])

func _process(_delta: float) -> void:
	_socket.poll()
	var state: int = _socket.get_ready_state()

	match state:
		WebSocketPeer.STATE_OPEN:
			if not _connected:
				_connected = true
				print("WSClient: connected to ", WS_URL)
			while _socket.get_available_packet_count() > 0:
				var raw: PackedByteArray = _socket.get_packet()
				var text: String = raw.get_string_from_utf8()
				var parsed = JSON.parse_string(text)
				if parsed is Dictionary:
					emit_signal("event_received", parsed)

		WebSocketPeer.STATE_CLOSED:
			if _connected:
				_connected = false
				push_warning("WSClient: disconnected – will not auto-reconnect in this build")
