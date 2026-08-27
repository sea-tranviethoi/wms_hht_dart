"""
generate_room_layout.py
────────────────────────
Generates a NEW warehouse_layout.png for testing --rebuild-layout with a
different topology than the current open-floor layout.

Topology (per user request):
  - Each zone (Khu A/B/C) is now its own separate ROOM.
  - Khu A sits BETWEEN Khu B and Khu C: rooms are arranged B | A | C.
  - There is a door between B<->A and between A<->C, but NO direct
    B<->C opening — going from B to C must pass through A.
  - The main warehouse entrance is on Khu A's outer wall.

Bin codes are UNCHANGED from the existing layout (same rack/zone/level/pos
scheme the app + mock_vision_server.py already understand): 5 racks
("Lối đi" 01-05) x zones A/B/C x 4 levels x 6 positions, plus the special
zone "11-A101/102/103" (physically placed inside room A, matching its
"11 · Khu A" label in the original image).

Run:
    python scripts/vision_ai/generate_room_layout.py

Then swap it in and rebuild:
    copy scripts\\vision_ai\\warehouse_layout.png scripts\\vision_ai\\warehouse_layout_open_floor_backup.png
    copy scripts\\vision_ai\\warehouse_layout_rooms.png scripts\\vision_ai\\warehouse_layout.png
    python scripts/vision_ai/mock_vision_server.py --rebuild-layout

IMPORTANT: ENTRANCE_XY_FRAC in mock_vision_server.py is a HARDCODED
fraction of image size (not OCR-detected) and MUST be updated to match
this new image's entrance position — this script prints the exact value
to use.
"""

import os

from PIL import Image, ImageDraw, ImageFont

W, H = 2200, 1600
OUT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                         "warehouse_layout_rooms.png")

FONT_BOLD = "C:/Windows/Fonts/arialbd.ttf"
FONT_REG = "C:/Windows/Fonts/arial.ttf"

WALL_COLOR = (20, 20, 20)
WALL_THICK = 20

ZONE_COLORS = {
    "A": ((59, 130, 246), (219, 234, 254)),   # border, fill (blue)
    "B": ((34, 197, 94), (220, 252, 231)),    # green
    "C": ((249, 115, 22), (255, 237, 213)),   # orange
}
SPECIAL_COLOR = ((220, 38, 38), (254, 226, 226))  # red

img = Image.new("RGB", (W, H), "white")
draw = ImageDraw.Draw(img)

f_row_label = ImageFont.truetype(FONT_BOLD, 64)   # must OCR as TALL (>18px)
f_zone_title = ImageFont.truetype(FONT_BOLD, 26)
f_pos = ImageFont.truetype(FONT_REG, 22)          # must OCR as SMALL (<=18px)
f_caption = ImageFont.truetype(FONT_REG, 18)
f_special = ImageFont.truetype(FONT_BOLD, 24)
f_title = ImageFont.truetype(FONT_BOLD, 34)

# ─── Room boundaries ─────────────────────────────────────────────────────
OUTER = (40, 40, W - 40, H - 40)
WALL_X1 = (700, 720)   # B | A wall band
WALL_X2 = (1480, 1500)  # A | C wall band

ROOM_B = (OUTER[0], OUTER[1], WALL_X1[0], OUTER[3])
ROOM_A = (WALL_X1[1], OUTER[1], WALL_X2[0], OUTER[3])
ROOM_C = (WALL_X2[1], OUTER[1], OUTER[2], OUTER[3])

# Row (Lối đi 01-05) vertical centers, shared by all 3 rooms so OCR's
# nearest-Y row-label matching lines bins up correctly across rooms.
ROW_TOP, ROW_BOTTOM = 130, OUTER[3] - 20
row_band_h = (ROW_BOTTOM - ROW_TOP) / 5
ROW_CENTERS = [ROW_TOP + row_band_h * (i + 0.5) for i in range(5)]

# Door gaps (a walkable break in a wall) — centered on row 03 so the doors
# sit in the middle of the room, not at an edge.
DOOR_Y0, DOOR_Y1 = ROW_CENTERS[2] - 90, ROW_CENTERS[2] + 90

title = "SO DO KHO - KHU A O GIUA (B <-> A <-> C), CUA RA VAO O KHU A"
draw.text((W / 2, 15), title, font=f_title, fill=(20, 20, 20), anchor="mt")

# ─── Outer wall (with entrance gap on room A's top edge) ─────────────────
ENTRANCE_X0, ENTRANCE_X1 = ROOM_A[0] + 260, ROOM_A[0] + 460
draw.rectangle(OUTER, outline=WALL_COLOR, width=WALL_THICK)
# Punch the entrance opening through the top wall (draw over it in white).
draw.rectangle(
    (ENTRANCE_X0, OUTER[1] - WALL_THICK, ENTRANCE_X1, OUTER[1] + WALL_THICK),
    fill="white",
)
draw.text(
    ((ENTRANCE_X0 + ENTRANCE_X1) / 2, OUTER[1] - WALL_THICK - 6),
    "CUA RA VAO KHO", font=f_caption, fill=(150, 20, 20), anchor="mb",
)

# ─── Internal walls B|A and A|C, each with a door gap ────────────────────
for x0, x1 in (WALL_X1, WALL_X2):
    draw.rectangle((x0, OUTER[1], x1, OUTER[3]), fill=WALL_COLOR)
    draw.rectangle((x0 - 4, DOOR_Y0, x1 + 4, DOOR_Y1), fill="white")
    draw.text(((x0 + x1) / 2, (DOOR_Y0 + DOOR_Y1) / 2), "CUA",
               font=f_caption, fill=(90, 90, 90), anchor="mm")

# ─── Room outlines + labels ───────────────────────────────────────────────
for room, letter in ((ROOM_B, "B"), (ROOM_A, "A"), (ROOM_C, "C")):
    draw.text(((room[0] + room[2]) / 2, room[1] + 60), f"PHONG KHU {letter}",
               font=f_zone_title, fill=(60, 60, 60), anchor="mm")


def draw_zone_row(rack_num, zone_letter, room_bounds, row_y_center, left_pad=20):
    """Draws one 'Khu {zone} ({rack}-{zone})' box with 6 position cells,
    matching the visual/OCR convention of the original layout image.
    [left_pad] reserves extra left margin — used for room B, which also
    carries the big row-label digit and must not let it collide with the
    box's own small "01" cell text (Tesseract merges/garbles overlapping
    text of very different sizes)."""
    border, fill = ZONE_COLORS[zone_letter]
    box_w = (room_bounds[2] - room_bounds[0]) - 20 - left_pad
    box_h = row_band_h - 30
    x0 = room_bounds[0] + left_pad
    y0 = row_y_center - box_h / 2
    x1, y1 = x0 + box_w, y0 + box_h

    draw.rounded_rectangle((x0, y0, x1, y1), radius=10, outline=border,
                            fill=fill, width=3)
    # Just "Khu {X}" -- NOT "Khu X (01-X)": Tesseract merges a lone capital
    # letter into an adjacent parenthesized token when they sit close
    # together, dropping the standalone "A"/"B"/"C" token the parser needs.
    draw.text(((x0 + x1) / 2, y0 + 16), f"Khu {zone_letter}",
               font=f_zone_title, fill=border, anchor="mm")
    draw.text(((x0 + x1) / 2, y0 + 38), f"({rack_num}-{zone_letter})",
               font=f_caption, fill=border, anchor="mm")

    n_cells = 6
    gap = 10
    cell_w = (box_w - 30 - gap * (n_cells - 1)) / n_cells
    cell_h = box_h - 80
    cy = y0 + 58 + cell_h / 2
    for i in range(n_cells):
        cx0 = x0 + 15 + i * (cell_w + gap)
        cx1 = cx0 + cell_w
        draw.rectangle((cx0, cy - cell_h / 2, cx1, cy + cell_h / 2),
                        outline=border, fill="white", width=2)
        draw.text(((cx0 + cx1) / 2, cy), f"{i + 1:02d}", font=f_pos,
                   fill=(20, 20, 20), anchor="mm")
    draw.text(((x0 + x1) / 2, y1 - 14), "4 tang x 6 vi tri = 24 bin",
               font=f_caption, fill=(100, 100, 100), anchor="mm")


# Room B: row label (tall "0X") drawn ONLY here, near the GLOBAL left
# margin — the parser's row-label heuristic only looks at x < 13% of the
# full image width, which room B (the leftmost room) satisfies. It gets its
# own reserved 150px-wide column so it never overlaps the zone box's small
# "01" cell text (a big glyph overlapping a small one confuses Tesseract
# into misreading or dropping tokens entirely).
ROW_LABEL_COL_W = 150
for i in range(5):
    rack = f"{i + 1:02d}"
    draw.text((ROOM_B[0] + ROW_LABEL_COL_W / 2, ROW_CENTERS[i]), rack,
               font=f_row_label, fill=(20, 20, 20), anchor="mm")
    draw_zone_row(rack, "B", ROOM_B, ROW_CENTERS[i], left_pad=ROW_LABEL_COL_W)
    draw_zone_row(rack, "A", ROOM_A, ROW_CENTERS[i])
    draw_zone_row(rack, "C", ROOM_C, ROW_CENTERS[i])

# ─── Special zone (11-A101/102/103) — inside room A, per its "Khu A" label ─
special_x0 = ROOM_A[0] + 20
special_x1 = ROOM_A[2] - 20
special_y0 = ROW_TOP - 70
special_y1 = ROW_TOP - 10
draw.rounded_rectangle((special_x0, special_y0, special_x1, special_y1),
                        radius=8, outline=SPECIAL_COLOR[0],
                        fill=SPECIAL_COLOR[1], width=3)
codes = ["11-A101", "11-A102", "11-A103"]
seg_w = (special_x1 - special_x0) / len(codes)
for i, code in enumerate(codes):
    cx = special_x0 + seg_w * (i + 0.5)
    draw.text((cx, (special_y0 + special_y1) / 2), code, font=f_special,
               fill=SPECIAL_COLOR[0], anchor="mm")

img.save(OUT_PATH)

entrance_cx = (ENTRANCE_X0 + ENTRANCE_X1) / 2
entrance_cy = OUTER[1] + 40  # just inside the doorway, inside room A
frac_x, frac_y = entrance_cx / W, entrance_cy / H

print(f"Saved: {OUT_PATH}  ({W}x{H})")
print(f"Entrance point (pixels): ({entrance_cx:.0f}, {entrance_cy:.0f})")
print(f"--> set in mock_vision_server.py:")
print(f"    ENTRANCE_XY_FRAC = ({frac_x:.4f}, {frac_y:.4f})")
