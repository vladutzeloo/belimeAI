"""
Generates Godot 4 SpriteFrames .tres files for each agent.

Sheet layout (96x16, 6 frames of 16x16):
  frames 0-1  → idle   (5 fps, loop)
  frames 2-3  → working (8 fps, loop)
  frames 4-5  → error   (4 fps, loop)

Run from repo root:  python tools/generate_tres.py
"""

from pathlib import Path

AGENTS = ["planner", "researcher", "coder", "executor"]
CHAR_DIR = Path("client-godot/assets/characters")

TRES_TEMPLATE = """\
[gd_resource type="SpriteFrames" load_steps={load_steps} format=3]

{ext_resources}
{sub_resources}
[resource]
animations = [{animations}
]
"""

ANIM_TEMPLATE = """{{
"frames": [{frame_list}
],
"loop": true,
"name": &"{name}",
"speed": {speed}
}}"""

FRAME_TEMPLATE = """{{
"duration": 1.0,
"texture": SubResource("{sub_id}")
}}"""

ATLAS_TEMPLATE = """\
[sub_resource type="AtlasTexture" id="{sub_id}"]
atlas = ExtResource("{ext_id}")
region = Rect2({x}, 0, 16, 16)
"""

# animation definitions: name, fps, frame indices
ANIMATIONS = [
    ("idle",    5.0, [0, 1]),
    ("working", 8.0, [2, 3]),
    ("error",   4.0, [4, 5]),
]


def generate_tres(agent: str) -> str:
    ext_id = f"1_{agent}"
    sheet_path = f"res://assets/characters/{agent}_sheet.png"

    ext_resources = (
        f'[ext_resource type="Texture2D" '
        f'path="{sheet_path}" id="{ext_id}"]\n'
    )

    sub_resources = ""
    load_steps = 2  # 1 ext + 1 for [resource]

    # build atlas sub-resources
    frame_to_sub: dict[int, str] = {}
    for frame_idx in range(6):
        sub_id = f"AtlasTexture_{agent}_{frame_idx}"
        x_offset = frame_idx * 16
        sub_resources += ATLAS_TEMPLATE.format(
            sub_id=sub_id, ext_id=ext_id, x=x_offset
        )
        frame_to_sub[frame_idx] = sub_id
        load_steps += 1

    # build animation blocks
    anim_blocks = []
    for anim_name, fps, indices in ANIMATIONS:
        frames_str = ""
        for idx in indices:
            frames_str += "\n" + FRAME_TEMPLATE.format(sub_id=frame_to_sub[idx]) + ", "
        anim_blocks.append(
            ANIM_TEMPLATE.format(name=anim_name, speed=fps, frame_list=frames_str.rstrip(", "))
        )

    animations_str = ", ".join(anim_blocks)

    return TRES_TEMPLATE.format(
        load_steps=load_steps,
        ext_resources=ext_resources,
        sub_resources=sub_resources,
        animations=animations_str,
    )


if __name__ == "__main__":
    for agent in AGENTS:
        content = generate_tres(agent)
        out = CHAR_DIR / f"{agent}.tres"
        out.write_text(content)
        print(f"  {out}")
    print("\nDone.")
