## Procedural cyberpunk-dungeon background.
## Renders four stone-walled cellars in a 2x2 grid, joined by a cross-shaped
## corridor in the middle. Each cellar is themed with the corresponding
## agent's accent neon color. Pure _draw() output — no nodes per element.
extends Node2D

const W := 480
const H := 270
const TILE := 16

# --- palette --------------------------------------------------------------
const C_VOID      := Color(0.015, 0.015, 0.035, 1)
const C_VOID_2    := Color(0.025, 0.025, 0.05,  1)
const C_FLOOR     := Color(0.085, 0.07,  0.105, 1)
const C_FLOOR_2   := Color(0.065, 0.055, 0.085, 1)
const C_FLOOR_LN  := Color(0.04,  0.035, 0.06,  1)
const C_STONE     := Color(0.165, 0.145, 0.185, 1)
const C_STONE_HI  := Color(0.235, 0.205, 0.27,  1)
const C_STONE_LO  := Color(0.085, 0.075, 0.105, 1)
const C_MORTAR    := Color(0.03,  0.03,  0.05,  1)
const C_HUD_BG    := Color(0.025, 0.025, 0.055, 0.95)
const C_HUD_EDGE  := Color(0.0,   0.94,  1.0,   0.45)
const C_HUD_LINE  := Color(0.0,   0.94,  1.0,   0.12)

# --- layout ---------------------------------------------------------------
# Top HUD strip:   y =   0 ..  16
# Cellars region:  y =  18 .. 228
# Bottom HUD:      y = 230 .. 270
const TOP_BAR_H    := 16
const BOTTOM_BAR_Y := 230

const WALL    := 6   # stone wall thickness around each cellar
const DOOR_W  := 22  # opening width in cellar walls (toward center corridor)

# The four cellars. Order: TL=planner, TR=researcher, BL=coder, BR=executor.
# `accent` is the agent's neon color; `door_*` cuts an opening in that wall.
var _cellars: Array = [
	{
		"rect":         Rect2(6,   18, 232, 102),
		"accent":       Color(0.00, 0.94, 1.00, 1),
		"label":        "PLANNING CRYPT",
		"door_right":   true,
		"door_bottom":  true,
	},
	{
		"rect":         Rect2(242, 18, 232, 102),
		"accent":       Color(0.63, 0.00, 1.00, 1),
		"label":        "ARCHIVE VAULT",
		"door_left":    true,
		"door_bottom":  true,
	},
	{
		"rect":         Rect2(6,   124, 232, 104),
		"accent":       Color(0.00, 1.00, 0.53, 1),
		"label":        "FORGE CELLAR",
		"door_right":   true,
		"door_top":     true,
	},
	{
		"rect":         Rect2(242, 124, 232, 104),
		"accent":       Color(1.00, 0.53, 0.00, 1),
		"label":        "EXEC CHAMBER",
		"door_left":    true,
		"door_top":     true,
	},
]


func _draw() -> void:
	_draw_void()
	_draw_corridor()
	for c in _cellars:
		_draw_cellar(c)
	_draw_hud_bars()
	_draw_outer_frame()


# ===== background ==========================================================

func _draw_void() -> void:
	draw_rect(Rect2(0, 0, W, H), C_VOID)
	# faint vertical scanline streaks
	for gx in range(0, W, 32):
		draw_line(Vector2(gx, TOP_BAR_H), Vector2(gx, BOTTOM_BAR_Y),
			Color(C_HUD_EDGE.r, C_HUD_EDGE.g, C_HUD_EDGE.b, 0.025), 1.0)


# ===== central corridor ====================================================
# Plus-shaped passage between cellars, lit cyan along the seams.
func _draw_corridor() -> void:
	var vx0 := 238
	var vx1 := 242
	var hy0 := 120
	var hy1 := 124

	# vertical strip
	draw_rect(Rect2(vx0, TOP_BAR_H + 2, vx1 - vx0, BOTTOM_BAR_Y - TOP_BAR_H - 4), C_VOID_2)
	# horizontal strip
	draw_rect(Rect2(6, hy0, W - 12, hy1 - hy0), C_VOID_2)

	# subtle neon center cross
	var c := Color(C_HUD_EDGE.r, C_HUD_EDGE.g, C_HUD_EDGE.b, 0.45)
	draw_line(Vector2(240, TOP_BAR_H + 2), Vector2(240, BOTTOM_BAR_Y - 2), c, 1.0)
	draw_line(Vector2(6, 122),             Vector2(W - 6, 122),           c, 1.0)

	# crossroad node
	draw_circle(Vector2(240, 122), 4.0, Color(c.r, c.g, c.b, 0.25))
	draw_circle(Vector2(240, 122), 2.0, Color(c.r, c.g, c.b, 0.85))


# ===== cellar drawing ======================================================

func _draw_cellar(c: Dictionary) -> void:
	var r: Rect2 = c.rect
	var accent: Color = c.accent

	# 1. outer stone wall block
	draw_rect(r, C_STONE)

	# 2. inner floor pit
	var inner := Rect2(r.position.x + WALL, r.position.y + WALL,
		r.size.x - WALL * 2, r.size.y - WALL * 2)
	draw_rect(inner, C_FLOOR)

	# 3. brick pattern across the wall ring
	_draw_wall_bricks(r, inner)

	# 4. floor tile pattern
	_draw_floor_tiles(inner, accent)

	# 5. cut doorways into the inner walls
	_cut_doors(r, c)

	# 6. neon trim hugging the inner wall
	_draw_neon_trim(inner, accent)

	# 7. back-wall altar / banner (under top wall)
	_draw_altar(r, inner, accent)

	# 8. torches near the front corners (bottom of cellar)
	_draw_torch(Vector2(r.position.x + 10, r.position.y + r.size.y - 10), accent)
	_draw_torch(Vector2(r.position.x + r.size.x - 10, r.position.y + r.size.y - 10), accent)


# Brick lines and corner blocks on the wall ring (between r and inner).
func _draw_wall_bricks(r: Rect2, inner: Rect2) -> void:
	# horizontal mortar lines across top and bottom walls
	var x0: float = r.position.x
	var x1: float = r.position.x + r.size.x
	var y_top: float = r.position.y
	var y_bot: float = r.position.y + r.size.y
	var y_in_top: float = inner.position.y
	var y_in_bot: float = inner.position.y + inner.size.y

	# top wall: 2 mortar lines
	draw_line(Vector2(x0, y_top + 2),  Vector2(x1, y_top + 2),  C_STONE_HI, 1.0)
	draw_line(Vector2(x0, y_top + 4),  Vector2(x1, y_top + 4),  C_MORTAR,   1.0)
	# bottom wall mortar
	draw_line(Vector2(x0, y_bot - 2),  Vector2(x1, y_bot - 2),  C_MORTAR,   1.0)
	draw_line(Vector2(x0, y_bot - 4),  Vector2(x1, y_bot - 4),  C_STONE_HI, 1.0)

	# vertical staggered brick seams (top wall)
	var stagger := 0
	for bx in range(int(x0), int(x1), 12):
		var dx := bx + (6 if stagger == 1 else 0)
		draw_line(Vector2(dx, y_top), Vector2(dx, y_in_top), C_MORTAR, 1.0)
		stagger = 1 - stagger
	# vertical staggered brick seams (bottom wall)
	stagger = 1
	for bx in range(int(x0), int(x1), 12):
		var dx := bx + (6 if stagger == 1 else 0)
		draw_line(Vector2(dx, y_in_bot), Vector2(dx, y_bot), C_MORTAR, 1.0)
		stagger = 1 - stagger

	# side walls: horizontal staggered seams
	stagger = 0
	for by in range(int(y_top), int(y_bot), 10):
		var dy := by + (5 if stagger == 1 else 0)
		draw_line(Vector2(x0, dy), Vector2(inner.position.x, dy), C_MORTAR, 1.0)
		draw_line(Vector2(inner.position.x + inner.size.x, dy), Vector2(x1, dy), C_MORTAR, 1.0)
		stagger = 1 - stagger

	# corner blocks — chunky stones at all four corners
	for cx in [x0, x1 - 6]:
		for cy in [y_top, y_bot - 6]:
			draw_rect(Rect2(cx, cy, 6, 6), C_STONE_HI)
			draw_rect(Rect2(cx, cy, 6, 6), C_STONE_LO, false, 1.0)

	# inner shadow line just inside the wall (depth)
	draw_rect(inner, C_STONE_LO, false, 1.0)


# Subtle stone-tile pattern across the cellar floor.
func _draw_floor_tiles(inner: Rect2, accent: Color) -> void:
	var x0: int = int(inner.position.x)
	var y0: int = int(inner.position.y)
	var x1: int = int(inner.position.x + inner.size.x)
	var y1: int = int(inner.position.y + inner.size.y)

	# alternating darker tile bands every 16px (vertical stripes)
	var col := 0
	for gx in range(x0, x1, TILE):
		if col == 1:
			draw_rect(Rect2(gx, y0, TILE, y1 - y0), C_FLOOR_2)
		col = 1 - col

	# faint tile grid lines
	for gx in range(x0, x1 + 1, TILE):
		draw_line(Vector2(gx, y0), Vector2(gx, y1), C_FLOOR_LN, 1.0)
	for gy in range(y0, y1 + 1, TILE):
		draw_line(Vector2(x0, gy), Vector2(x1, gy), C_FLOOR_LN, 1.0)

	# faint accent wash so each cellar reads as its agent's color
	draw_rect(inner, Color(accent.r, accent.g, accent.b, 0.035))


# Cut openings in the inner walls toward the center corridor.
# We "cut" by re-drawing the opening with floor + corridor colors and
# capping it with arched stone above so it reads as a doorway.
func _cut_doors(r: Rect2, c: Dictionary) -> void:
	var cx: float = r.position.x + r.size.x * 0.5
	var cy: float = r.position.y + r.size.y * 0.5

	if c.get("door_right", false):
		_cut_door_at(Rect2(r.position.x + r.size.x - WALL, cy - DOOR_W * 0.5, WALL, DOOR_W), false)
	if c.get("door_left", false):
		_cut_door_at(Rect2(r.position.x, cy - DOOR_W * 0.5, WALL, DOOR_W), false)
	if c.get("door_bottom", false):
		_cut_door_at(Rect2(cx - DOOR_W * 0.5, r.position.y + r.size.y - WALL, DOOR_W, WALL), true)
	if c.get("door_top", false):
		_cut_door_at(Rect2(cx - DOOR_W * 0.5, r.position.y, DOOR_W, WALL), true)


func _cut_door_at(door: Rect2, horizontal_arch: bool) -> void:
	draw_rect(door, C_VOID_2)
	_draw_arch(door.position,
		Vector2(door.position.x + door.size.x, door.position.y + door.size.y),
		horizontal_arch)


# Decorative archway frame around a doorway opening.
# `horizontal_arch` = true means the doorway runs along x (top/bottom walls).
func _draw_arch(a: Vector2, b: Vector2, horizontal_arch: bool) -> void:
	# Edge highlights
	draw_rect(Rect2(a, b - a), C_STONE_HI, false, 1.0)
	# Small keystones
	if horizontal_arch:
		var mid := (a.x + b.x) * 0.5
		draw_rect(Rect2(mid - 2, a.y, 4, 2), C_STONE_HI)
		draw_rect(Rect2(mid - 2, b.y - 2, 4, 2), C_STONE_HI)
	else:
		var mid_y := (a.y + b.y) * 0.5
		draw_rect(Rect2(a.x, mid_y - 2, 2, 4), C_STONE_HI)
		draw_rect(Rect2(b.x - 2, mid_y - 2, 2, 4), C_STONE_HI)


# Neon trim along the inside of the cellar wall.
func _draw_neon_trim(inner: Rect2, accent: Color) -> void:
	var c1 := Color(accent.r, accent.g, accent.b, 0.55)
	var c2 := Color(accent.r, accent.g, accent.b, 0.18)
	# bright inner outline
	draw_rect(inner, c1, false, 1.0)
	# soft outer halo
	var halo := Rect2(inner.position - Vector2(1, 1), inner.size + Vector2(2, 2))
	draw_rect(halo, c2, false, 1.0)


# Back-wall altar where the station sprite sits.
func _draw_altar(r: Rect2, inner: Rect2, accent: Color) -> void:
	var cx: float = r.position.x + r.size.x * 0.5
	var alt_w := 60
	var alt_h := 4
	var alt_y: float = inner.position.y + 2

	# narrow banner strip just under the top wall
	draw_rect(Rect2(cx - alt_w * 0.5, alt_y, alt_w, alt_h),
		Color(accent.r, accent.g, accent.b, 0.18))
	draw_rect(Rect2(cx - alt_w * 0.5, alt_y, alt_w, 1),
		Color(accent.r, accent.g, accent.b, 0.8))
	draw_rect(Rect2(cx - alt_w * 0.5, alt_y + alt_h - 1, alt_w, 1),
		Color(accent.r, accent.g, accent.b, 0.8))

	# decorative runes on either side of banner
	for off in [-alt_w * 0.5 - 6, alt_w * 0.5 + 4]:
		var rx := cx + off
		draw_rect(Rect2(rx, alt_y + 1, 2, 2), Color(accent.r, accent.g, accent.b, 0.7))


# Small wall torch with halo glow.
func _draw_torch(pos: Vector2, accent: Color) -> void:
	# bracket
	draw_rect(Rect2(pos.x - 1, pos.y + 1, 2, 3), C_STONE_HI)
	# flame core
	draw_rect(Rect2(pos.x - 1, pos.y - 2, 2, 3),
		Color(accent.r, accent.g, accent.b, 0.95))
	# glow halos
	draw_circle(pos, 8.0, Color(accent.r, accent.g, accent.b, 0.08))
	draw_circle(pos, 5.0, Color(accent.r, accent.g, accent.b, 0.14))
	draw_circle(pos, 3.0, Color(accent.r, accent.g, accent.b, 0.30))


# ===== HUD bars ============================================================

func _draw_hud_bars() -> void:
	# top bar
	draw_rect(Rect2(0, 0, W, TOP_BAR_H), C_HUD_BG)
	draw_line(Vector2(0, TOP_BAR_H - 1), Vector2(W, TOP_BAR_H - 1), C_HUD_EDGE, 1.0)
	# tick marks along the top bar
	for tx in range(0, W, 8):
		draw_line(Vector2(tx, TOP_BAR_H - 3), Vector2(tx, TOP_BAR_H - 1), C_HUD_LINE, 1.0)

	# bottom bar
	draw_rect(Rect2(0, BOTTOM_BAR_Y, W, H - BOTTOM_BAR_Y), C_HUD_BG)
	draw_line(Vector2(0, BOTTOM_BAR_Y), Vector2(W, BOTTOM_BAR_Y), C_HUD_EDGE, 1.0)


func _draw_outer_frame() -> void:
	# cyan border + corner brackets
	var c := Color(C_HUD_EDGE.r, C_HUD_EDGE.g, C_HUD_EDGE.b, 0.6)
	draw_rect(Rect2(0, 0, W, H), c, false, 1.0)
	var b := 10
	for cx in [0, W]:
		for cy in [0, H]:
			var sx := 1 if cx == 0 else -1
			var sy := 1 if cy == 0 else -1
			draw_line(Vector2(cx, cy), Vector2(cx + sx * b, cy), c, 2.0)
			draw_line(Vector2(cx, cy), Vector2(cx, cy + sy * b), c, 2.0)
