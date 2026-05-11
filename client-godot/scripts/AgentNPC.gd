extends Node2D
class_name AgentNPC

# Loaded from agents_config.json by Main.gd before calling setup().
var agent_id: String = ""
var _config: Dictionary = {}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var provider_icon: Sprite2D = $ProviderIcon
@onready var label: Label = $Label

const PROVIDER_COLORS: Dictionary = {
	"claude":     Color(0.0, 0.94, 1.0),
	"nvidia_nim": Color(0.63, 0.0, 1.0),
	"local_llm":  Color(0.0, 1.0, 0.53),
}

func setup(id: String, cfg: Dictionary) -> void:
	agent_id = id
	_config = cfg
	if label:
		label.text = id.replace("agent_", "")
	# SpriteFrames are loaded at editor time for real assets.
	# In headless / test mode the AnimatedSprite2D may not have frames yet.
	if sprite and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

func apply_state(state: String) -> void:
	if not sprite or not sprite.sprite_frames:
		return
	var anim: String = state
	if not sprite.sprite_frames.has_animation(anim):
		anim = "idle"
	sprite.play(anim)

func set_provider(provider: String) -> void:
	if provider_icon:
		provider_icon.modulate = PROVIDER_COLORS.get(provider, Color.WHITE)

func move_to_station(station_node: Node2D) -> void:
	if station_node:
		global_position = station_node.global_position
