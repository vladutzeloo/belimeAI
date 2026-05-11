extends Node
class_name WSClient

signal event_received(data: Dictionary)
signal connection_changed(connected: bool)

const WS_URL: String = "ws://localhost:8000/ws"
const RECONNECT_DELAY: float = 3.0

var _socket:    WebSocketPeer = WebSocketPeer.new()
var _connected: bool = false
var _reconnect_timer: float = 0.0

func _ready() -> void:
	_connect_to_server()

func _connect_to_server() -> void:
	_socket = WebSocketPeer.new()
	var err: int = _socket.connect_to_url(WS_URL)
	if err != OK:
		push_warning("WSClient: connect failed (err %d), retrying in %.0fs" % [err, RECONNECT_DELAY])

func _process(delta: float) -> void:
	_socket.poll()
	var state: int = _socket.get_ready_state()

	match state:
		WebSocketPeer.STATE_OPEN:
			if not _connected:
				_connected = true
				_reconnect_timer = 0.0
				emit_signal("connection_changed", true)

			while _socket.get_available_packet_count() > 0:
				var raw := _socket.get_packet()
				var text := raw.get_string_from_utf8()
				var parsed = JSON.parse_string(text)
				if parsed is Dictionary:
					emit_signal("event_received", parsed)

		WebSocketPeer.STATE_CLOSED:
			if _connected:
				_connected = false
				emit_signal("connection_changed", false)

			# auto-reconnect
			_reconnect_timer += delta
			if _reconnect_timer >= RECONNECT_DELAY:
				_reconnect_timer = 0.0
				_connect_to_server()

		WebSocketPeer.STATE_CONNECTING:
			pass  # waiting
