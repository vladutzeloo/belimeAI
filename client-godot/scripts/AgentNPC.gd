extends Node2D
class_name AgentNPC

var agent_id: String = ""

# Provider icon atlas offsets (x pixel in provider_icons.png)
const PROVIDER_ICON_X: Dictionary = {
	"claude":     0,
	"nvidia_nim": 16,
	"local_llm":  32,
}

# Colors matching AGENT_COLORS in generate_sprites.py
const GLOW_COLORS: Dictionary = {
	"idle":         Color(0,    0.94, 1,    0.0),
	"planning":     Color(0,    0.94, 1,    0.8),
	"working":      Color(0.5,  1,    0.5,  0.8),
	"calling_tool": Color(1,    0.7,  0,    0.8),
	"error":        Color(1,    0.2,  0.2,  1.0),
}

@onready var _sprite:  AnimatedSprite2D = $AnimatedSprite2D
@onready var _icon:    Sprite2D         = $ProviderIcon
@onready var _glow:    PointLight2D     = $StateGlow
@onready var _label:   Label            = $Label

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
	if _sprite and _sprite.sprite_frames:
		var anim := _state_to_anim(state)
		if _sprite.sprite_frames.has_animation(anim):
			if _sprite.animation != anim:
				_sprite.play(anim)

	if _glow:
		var col: Color = GLOW_COLORS.get(state, GLOW_COLORS["idle"])
		_glow.color = Color(col.r, col.g, col.b, 1)
		_glow.energy = col.a

func set_provider(provider: String) -> void:
	if not _icon:
		return
	var x: int = PROVIDER_ICON_X.get(provider, 0)
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/ui/provider_icons.png")
	atlas.region = Rect2(x, 0, 16, 16)
	_icon.texture = atlas

func move_to_station(station_node: Node2D) -> void:
	if station_node:
		var tween := create_tween()
		tween.tween_property(self, "global_position",
			station_node.global_position + Vector2(0, -4), 0.3) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _state_to_anim(state: String) -> String:
	match state:
		"planning", "working": return "working"
		"calling_tool":        return "working"
		"error":               return "error"
		_:                     return "idle"
