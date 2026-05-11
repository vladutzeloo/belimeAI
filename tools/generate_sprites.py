"""
Generates placeholder 16x16 pixel-art sprites for the Neon Control Room.

Outputs:
  client-godot/assets/characters/<agent>_sheet.png  – 6-frame sprite strip
  client-godot/assets/stations/<agent>_station.png  – 32x32 station marker
  client-godot/assets/ui/provider_icons.png         – 3-icon strip (16x16 each)

Run from repo root:  python tools/generate_sprites.py
"""

from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).parent.parent / "client-godot" / "assets"

# ── palette ───────────────────────────────────────────────────────────────────
T = (0, 0, 0, 0)          # transparent

AGENT_COLORS = {
    "planner":    {"body": (0, 220, 255), "hi": (160, 245, 255), "dk": (0, 120, 180), "eye": (255, 255, 80)},
    "researcher": {"body": (160, 0, 255), "hi": (210, 140, 255), "dk": (80, 0, 140),  "eye": (255, 80, 220)},
    "coder":      {"body": (0, 220, 120), "hi": (140, 255, 200), "dk": (0, 120, 60),  "eye": (80, 255, 80)},
    "executor":   {"body": (255, 120, 0), "hi": (255, 200, 120), "dk": (160, 60, 0),  "eye": (255, 60, 60)},
}

PROVIDER_COLORS = {
    "claude":     (0, 220, 255),
    "nvidia_nim": (118, 185, 0),
    "local_llm":  (200, 160, 255),
}


# ── helpers ───────────────────────────────────────────────────────────────────
def px(img: Image.Image, data: list[list]) -> None:
    """Paint a 2-D pixel array onto an RGBA image. Each cell is an RGBA tuple or T."""
    for y, row in enumerate(data):
        for x, col in enumerate(row):
            if col != T:
                img.putpixel((x, y), col)


# ── character template ────────────────────────────────────────────────────────
def make_char_frame(colors: dict, variant: str = "idle") -> Image.Image:
    """Draw a 16x16 cyberpunk humanoid.

    variant: 'idle' | 'idle2' | 'work' | 'work2' | 'error' | 'error2'
    """
    b  = colors["body"]
    hi = colors["hi"]
    dk = colors["dk"]
    ey = colors["eye"]
    rd = (255, 60, 60, 255)

    img = Image.new("RGBA", (16, 16), T)

    # ── base humanoid ─────────────────────────────────────────────────────────
    # head (rows 1-5, cols 5-10)
    head = [
        (6, 1), (7, 1), (8, 1), (9, 1),
        (5, 2), (6, 2), (7, 2), (8, 2), (9, 2), (10, 2),
        (5, 3), (6, 3), (7, 3), (8, 3), (9, 3), (10, 3),
        (5, 4), (6, 4), (7, 4), (8, 4), (9, 4), (10, 4),
        (6, 5), (7, 5), (8, 5), (9, 5),
    ]
    # eyes
    eyes = [(6, 3), (9, 3)]
    # body (rows 6-10, cols 5-10)
    body = [
        (5, 6), (6, 6), (7, 6), (8, 6), (9, 6), (10, 6),
        (5, 7), (6, 7), (7, 7), (8, 7), (9, 7), (10, 7),
        (5, 8), (6, 8), (7, 8), (8, 8), (9, 8), (10, 8),
        (5, 9), (6, 9), (7, 9), (8, 9), (9, 9), (10, 9),
    ]
    # legs (rows 11-14) — variant-aware: walking shifts opposite legs forward
    if variant == "walk":
        # left leg forward
        legs = [
            (4, 11), (5, 11), (9, 11), (10, 11),
            (4, 12), (5, 12), (9, 12), (10, 12),
            (4, 13), (5, 13), (10, 13), (11, 13),
            (4, 14), (5, 14), (10, 14), (11, 14),
        ]
    elif variant == "walk2":
        # right leg forward
        legs = [
            (5, 11), (6, 11), (10, 11), (11, 11),
            (5, 12), (6, 12), (10, 12), (11, 12),
            (4, 13), (5, 13), (10, 13), (11, 13),
            (4, 14), (5, 14), (10, 14), (11, 14),
        ]
    else:
        legs = [
            (5, 11), (6, 11), (9, 11), (10, 11),
            (5, 12), (6, 12), (9, 12), (10, 12),
            (5, 13), (6, 13), (9, 13), (10, 13),
            (5, 14), (6, 14), (9, 14), (10, 14),
        ]

    # base arm positions
    arms_idle  = [(3, 7), (4, 7), (11, 7), (12, 7)]
    arms_work  = [(3, 6), (4, 6), (11, 6), (12, 6),
                  (2, 7), (13, 7)]
    arms_walk  = [(3, 7), (4, 7), (11, 6), (12, 6)]
    arms_walk2 = [(3, 6), (4, 6), (11, 7), (12, 7)]
    arms_error = arms_idle

    # pick arms
    if variant == "walk":
        arms = arms_walk
    elif variant == "walk2":
        arms = arms_walk2
    elif "work" in variant:
        arms = arms_work
    else:
        arms = arms_idle

    # body shift for idle2 (breathing bob) and walk frames
    dy = 1 if variant in ("idle2", "work2") else 0

    def shift(pts: list[tuple[int,int]], delta: int) -> list[tuple[int,int]]:
        return [(x, y + delta) for x, y in pts]

    def paint(pts, color):
        for x, y in pts:
            if 0 <= x < 16 and 0 <= y < 16:
                img.putpixel((x, y), color + (255,))

    shifted_head = shift(head, dy)
    shifted_eyes = shift(eyes, dy)
    shifted_body = shift(body, dy)
    shifted_legs = shift(legs, dy)
    shifted_arms = shift(arms, dy)

    # draw highlights on head
    highlight_head = [p for p in shifted_head if p in
                      [shift([(6, 2)], dy)[0], shift([(7, 2)], dy)[0]]]

    paint(shifted_head, b)
    paint(shifted_body, dk)
    paint(shifted_arms, b)
    paint(shifted_legs, b)
    # highlights on top of head
    for x, y in shifted_head[:4]:
        if 0 <= x < 16 and 0 <= y < 16:
            img.putpixel((x, y), hi + (255,))

    # eyes
    for x, y in shifted_eyes:
        if 0 <= x < 16 and 0 <= y < 16:
            img.putpixel((x, y), ey + (255,))

    # error flash: red chest overlay
    if "error" in variant and variant == "error2":
        for x, y in shifted_body:
            if 0 <= x < 16 and 0 <= y < 16:
                img.putpixel((x, y), (220, 30, 30, 255))

    # screen on body (terminal-style)
    screen_col = hi if "error" not in variant else (255, 60, 60)
    screen_pts = shift([(7, 7), (8, 7), (7, 8), (8, 8)], dy)
    for x, y in screen_pts:
        if 0 <= x < 16 and 0 <= y < 16:
            img.putpixel((x, y), screen_col + (255,))

    return img


def make_sprite_sheet(agent: str) -> Image.Image:
    """8-frame horizontal sheet: idle×2, walk×2, work×2, error×2."""
    c = AGENT_COLORS[agent]
    frames = [
        make_char_frame(c, "idle"),
        make_char_frame(c, "idle2"),
        make_char_frame(c, "walk"),
        make_char_frame(c, "walk2"),
        make_char_frame(c, "work"),
        make_char_frame(c, "work2"),
        make_char_frame(c, "error"),
        make_char_frame(c, "error2"),
    ]
    sheet = Image.new("RGBA", (16 * 8, 16), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * 16, 0))
    return sheet


# ── station markers ───────────────────────────────────────────────────────────
STATION_LABELS = {
    "planner":    "PLAN",
    "researcher": "RSCH",
    "coder":      "CODE",
    "executor":   "EXEC",
}

def make_station(agent: str) -> Image.Image:
    """32x32 cyberpunk terminal/desk marker."""
    c = AGENT_COLORS[agent]["body"]
    dk = AGENT_COLORS[agent]["dk"]
    hi = AGENT_COLORS[agent]["hi"]
    ey = AGENT_COLORS[agent]["eye"]

    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # desk base
    d.rectangle([2, 22, 30, 30], fill=dk + (255,))
    d.rectangle([2, 22, 30, 22], fill=c + (255,))  # desk top edge

    # monitor stand
    d.rectangle([14, 18, 18, 22], fill=dk + (255,))

    # monitor frame
    d.rectangle([4, 4, 28, 18], fill=dk + (255,))
    d.rectangle([5, 5, 27, 17], fill=(10, 10, 20, 255))  # screen black

    # screen glow
    d.rectangle([6, 6, 26, 16], fill=c + (80,))

    # screen content lines (terminal style)
    for row_y in [8, 11, 14]:
        d.rectangle([7, row_y, 20, row_y], fill=hi + (200,))

    # scan-line accent
    d.rectangle([7, 9, 14, 9], fill=ey + (180,))

    # corner pixels of monitor (neon outline)
    for x, y in [(4,4),(28,4),(4,18),(28,18)]:
        img.putpixel((x, y), hi + (255,))

    # keyboard hint
    d.rectangle([5, 25, 16, 28], fill=c + (120,))
    d.rectangle([18, 25, 29, 28], fill=c + (80,))

    return img


# ── provider icons (16x16) ────────────────────────────────────────────────────
def make_provider_icon(color: tuple) -> Image.Image:
    """16x16 icon: a simple hexagon badge."""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(8, 1), (14, 4), (14, 12), (8, 15), (2, 12), (2, 4)],
              fill=color + (200,), outline=color + (255,))
    # inner dot
    d.rectangle([7, 7, 9, 9], fill=(255, 255, 255, 220))
    return img


def make_provider_sheet() -> Image.Image:
    """48x16 strip: claude | nvidia_nim | local_llm."""
    sheet = Image.new("RGBA", (48, 16), (0, 0, 0, 0))
    for i, (name, col) in enumerate(PROVIDER_COLORS.items()):
        sheet.paste(make_provider_icon(col), (i * 16, 0))
    return sheet


# ── main ──────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    char_dir = ROOT / "characters"
    sta_dir  = ROOT / "stations"
    ui_dir   = ROOT / "ui"
    char_dir.mkdir(parents=True, exist_ok=True)
    sta_dir.mkdir(parents=True, exist_ok=True)
    ui_dir.mkdir(parents=True, exist_ok=True)

    for agent in AGENT_COLORS:
        sheet = make_sprite_sheet(agent)
        path = char_dir / f"{agent}_sheet.png"
        sheet.save(path)
        print(f"  {path}  ({sheet.size})")

        station = make_station(agent)
        spath = sta_dir / f"{agent}_station.png"
        station.save(spath)
        print(f"  {spath}  ({station.size})")

    provider_sheet = make_provider_sheet()
    ppath = ui_dir / "provider_icons.png"
    provider_sheet.save(ppath)
    print(f"  {ppath}  ({provider_sheet.size})")

    print("\nDone. All sprites written.")
