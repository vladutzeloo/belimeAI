## Scrolling event log shown in the bottom-left of the HUD.
## Receives Dictionary events from Main and renders the last MAX_LINES of them.
extends Control

const MAX_LINES: int = 4

const COLOR_BY_TYPE: Dictionary = {
	"agent_state":      Color(0,    0.94, 1,    1),
	"task_transition":  Color(1,    0.7,  0,    1),
	"system_message":   Color(0.5,  1,    0.5,  1),
}

var _lines: Array[String] = []
var _colors: Array[Color] = []

@onready var _label: RichTextLabel = $Lines

func push_event(data: Dictionary) -> void:
	var line := _format(data)
	if line == "":
		return

	var col: Color = COLOR_BY_TYPE.get(data.get("type", ""), Color.WHITE)
	_lines.append(line)
	_colors.append(col)

	while _lines.size() > MAX_LINES:
		_lines.pop_front()
		_colors.pop_front()

	_render()

func _render() -> void:
	if not _label:
		return
	_label.clear()
	for i in _lines.size():
		_label.push_color(_colors[i])
		_label.add_text(_lines[i])
		_label.pop()
		_label.newline()

func _format(data: Dictionary) -> String:
	match data.get("type", ""):
		"agent_state":
			var who: String = data.get("agent_id", "").replace("agent_", "")
			var state: String = data.get("state", "")
			var prov: String = data.get("provider", "")
			return "[%s] %s @ %s" % [who.to_upper(), state, prov]

		"task_transition":
			var f: String = data.get("from_agent", "").replace("agent_", "")
			var t: String = data.get("to_agent",   "").replace("agent_", "")
			return "%s -> %s" % [f.to_upper(), t.to_upper()]

		"system_message":
			return "SYS: " + data.get("message", "")

		_:
			return ""
