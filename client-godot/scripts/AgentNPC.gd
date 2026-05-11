extends Node2D
class_name AgentNPC

var agent_id: String = ""

# Provider icon atlas offsets (x pixel in provider_icons.png)
const PROVIDER_ICON_X: Dictionary = {
	"claude":     0,
	"nvidia_nim": 16,
	"local_llm":  32,
}

# Glow colour + intensity per state.
const GLOW_COLORS: Dictionary = {
	"idle":         Color(0,    0.94, 1,    0.0),
	"planning":     Color(0,    0.94, 1,    0.8),
	"working":      Color(0.5,  1,    0.5,  0.8),
	"calling_tool": Color(1,    0.7,  0,    0.8),
	"error":        Color(1,    0.2,  0.2,  1.0),
}

const WALK_SPEED_PX_PER_S: float = 60.0
const MIN_WALK_DURATION: float = 0.25
const MAX_WALK_DURATION: float = 0.9

var _current_state: String = "idle"
var _is_moving: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _icon:   Sprite2D         = $ProviderIcon
@onready var _glow:   PointLight2D     = $StateGlow
@onready var _label:  Label            = $Label

func setup(id: String, cfg: Dictionary) -> void:
	agent_id = id
	if _label:
		_label.text = cfg.get("label", id.replace("agent_", "")).to_upper()

	var frames_path: String = cfg.get("sprite_frames", "")
	if frames_path != "" and ResourceLoader.exists(frames_path):
		var frames: SpriteFrames = load(frames_path)
		if _sprite and frames:
			_sprite.sprite_frames = frames
			if frames.has_animation("idle"):
				_sprite.play("idle")

func apply_state(state: String) -> void:
	_current_state = state
	# Don't override the walk animation while moving — _on_move_finished
	# will restore the correct state animation when the tween completes.
	if not _is_moving:
		_play_state_anim()

	if _glow:
		var col: Color = GLOW_COLORS.get(state, GLOW_COLORS["idle"])
		_glow.color = Color(col.r, col.g, col.b, 1)
		_glow.energy = col.a

func set_provider(provider: String) -> void:
	if not _icon:
		return
	var x: int = PROVIDER_ICON_X.get(provider, 0)
	_icon.region_enabled = true
	_icon.region_rect = Rect2(x, 0, 16, 16)

func move_to_station(station_node: Node2D) -> void:
	if not station_node:
		return
	var target := station_node.global_position + Vector2(0, -4)
	var dist := global_position.distance_to(target)
	if dist < 1.0:
		return

	# face the direction of travel
	if _sprite:
		var dx := target.x - global_position.x
		if absf(dx) > 0.5:
			_sprite.flip_h = dx < 0

	var duration := clampf(dist / WALK_SPEED_PX_PER_S, MIN_WALK_DURATION, MAX_WALK_DURATION)

	_is_moving = true
	_play_walk_anim()

	var tween := create_tween()
	tween.tween_property(self, "global_position", target, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_on_move_finished)

func _on_move_finished() -> void:
	_is_moving = false
	if _sprite:
		_sprite.flip_h = false
	_play_state_anim()

func _play_state_anim() -> void:
	if not _sprite or not _sprite.sprite_frames:
		return
	var anim := _state_to_anim(_current_state)
	if _sprite.sprite_frames.has_animation(anim) and _sprite.animation != anim:
		_sprite.play(anim)

func _play_walk_anim() -> void:
	if _sprite and _sprite.sprite_frames and _sprite.sprite_frames.has_animation("walk"):
		_sprite.play("walk")

func _state_to_anim(state: String) -> String:
	match state:
		"planning", "working": return "working"
		"calling_tool":        return "working"
		"error":               return "error"
		_:                     return "idle"
