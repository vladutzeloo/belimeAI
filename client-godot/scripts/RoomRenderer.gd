## Draws the cyberpunk control-room background procedurally until real
## Neon District tiles are imported. Uses _draw() so it's zero-node overhead.
extends Node2D

const W := 320
const H := 180
const TILE := 16

# palette
const C_FLOOR  := Color(0.06, 0.06, 0.14, 1)
const C_WALL   := Color(0.04, 0.04, 0.10, 1)
const C_GRID   := Color(0.00, 0.90, 1.00, 0.07)
const C_ACCENT := Color(0.00, 0.90, 1.00, 0.25)
const C_DIVIDER:= Color(0.00, 0.90, 1.00, 0.18)

func _draw() -> void:
	# floor fill
	draw_rect(Rect2(0, 0, W, H), C_FLOOR)

	# top wall strip
	draw_rect(Rect2(0, 0, W, TILE * 2), C_WALL)
	# bottom wall strip
	draw_rect(Rect2(0, H - TILE, W, TILE), C_WALL)

	# horizontal grid lines
	for gy in range(0, H + 1, TILE):
		draw_line(Vector2(0, gy), Vector2(W, gy), C_GRID, 1.0)

	# vertical grid lines
	for gx in range(0, W + 1, TILE):
		draw_line(Vector2(gx, 0), Vector2(gx, H), C_GRID, 1.0)

	# centre dividers
	draw_line(Vector2(W / 2, TILE * 2), Vector2(W / 2, H - TILE), C_DIVIDER, 1.0)
	draw_line(Vector2(0, H / 2), Vector2(W, H / 2), C_DIVIDER, 1.0)

	# neon accent border
	draw_rect(Rect2(0, 0, W, H), C_ACCENT, false, 1.0)

	# corner brackets
	var bracket := 8
	for cx: int in [0, W]:
		for cy: int in [0, H]:
			var sx := 1 if cx == 0 else -1
			var sy := 1 if cy == 0 else -1
			draw_line(Vector2(cx, cy), Vector2(cx + sx * bracket, cy), C_ACCENT, 1.5)
			draw_line(Vector2(cx, cy), Vector2(cx, cy + sy * bracket), C_ACCENT, 1.5)

	# station zone labels (top-left of each quadrant)
	# drawn as subtle rectangles so zones are visible even without NPC
	var zones := [
		Rect2(4,      TILE * 2 + 4, W / 2 - 8, H / 2 - TILE * 3),
		Rect2(W/2+4,  TILE * 2 + 4, W / 2 - 8, H / 2 - TILE * 3),
		Rect2(4,      H / 2 + 4,    W / 2 - 8, H / 2 - TILE - 8),
		Rect2(W/2+4,  H / 2 + 4,    W / 2 - 8, H / 2 - TILE - 8),
	]
	var zone_cols := [
		Color(0, 0.94, 1, 0.05),
		Color(0.63, 0, 1, 0.05),
		Color(0, 1, 0.53, 0.05),
		Color(1, 0.53, 0, 0.05),
	]
	for i in zones.size():
		draw_rect(zones[i], zone_cols[i])
		draw_rect(zones[i], zone_cols[i] * 3, false, 0.8)
