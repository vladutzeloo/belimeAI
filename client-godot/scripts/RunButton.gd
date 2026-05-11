## Top-right HUD button that POSTs to the backend /run endpoint.
extends Button

const BACKEND_URL: String = "http://localhost:8000/run"
const DEFAULT_GOAL: String = "Build a cyberpunk control room visualizer"

@onready var _http: HTTPRequest = $HTTPRequest

func _ready() -> void:
	pressed.connect(_on_pressed)
	_http.request_completed.connect(_on_request_completed)

func _on_pressed() -> void:
	text = "RUNNING..."
	disabled = true
	var body := JSON.stringify({"goal": DEFAULT_GOAL})
	var err := _http.request(
		BACKEND_URL,
		PackedStringArray(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		body,
	)
	if err != OK:
		_reset("ERR " + str(err))

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if response_code == 200:
		_reset("RUN AGAIN")
	else:
		_reset("ERR " + str(response_code))

func _reset(new_text: String) -> void:
	# Re-enable shortly after so users can spam less aggressively
	text = new_text
	await get_tree().create_timer(1.5).timeout
	disabled = false
	text = "RUN DEMO"
