"""
mock_vision_server.py
─────────────────────
Multi-QR photo scanner for cycle-count (棚卸).

The handheld sends ONE photo of several items (each with a QR or Code128
barcode stuck on it) plus the set of item codes currently being counted. This
server decodes EVERY QR/Code128 code in the photo with pyzbar (deterministic,
not a guess — pyzbar reads the exact bytes encoded in each code), matches each decoded value against
the candidate item codes by PREFIX (a physical unit's QR often encodes the
item code plus a serial suffix, e.g. "2022Sum03017"), and returns:
  - how many units were found per matched item code
  - the same photo with a highlight box drawn around every matched QR
  - how many QR codes were detected but didn't match any candidate

No LLM/VLM is involved — this is plain, reliable barcode decoding, which is
the right tool for "read the QR codes in this photo" (an AI vision-language
model is not a barcode decoder and is not needed here). Classic computer
vision preprocessing (adaptive thresholding, denoising, sharpening — see
multi_pass_decode) is used to make decoding robust against glare, moiré, and
blur, which a single plain zbar pass often misses.

Usage:
  1. Install Tesseract OCR itself (a system binary, not a pip package) --
     e.g. `winget install UB-Mannheim.TesseractOCR` on Windows -- needed for
     the route optimizer below, which reads warehouse_layout.png via OCR.
  2. pip install pyzbar pillow opencv-python numpy ortools networkx
     pytesseract scikit-image   (one-time)
  3. Run:  python scripts/vision_ai/mock_vision_server.py
     The warehouse layout graph (OCR + skeletonize -- the slow part) is
     cached to warehouse_layout_cache.pkl after the first parse. Every
     later run reuses that cache instantly instead of re-parsing the PNG.
     Run with `--rebuild-layout` to force a fresh parse (e.g. after editing
     warehouse_layout.png) and overwrite the cache.
  4. Open the firewall for port 9600
  5. In the app, point AppConstants.visionHost to http://<PC_IP>:9600

Endpoint:
  POST /api/vision/identify
      body: {"image": "<base64 jpeg>", "validCodes": ["2022Sum03", "2022MIWA02"]}
      resp: {
        "matched": {"2022Sum03": 2},       # itemCode -> units found
        "unmatchedCount": 3,               # QR codes detected but not in validCodes
        "totalDetected": 5,                # total QR codes found in the photo
        "annotatedImage": "<base64 jpeg>"  # photo with highlight boxes drawn
      }

This server ALSO hosts the picking route optimizer (proposal #7, "Nhóm A")
on the same port, so only one process needs to run for local testing — see
the module-level comment above optimize_route() below for what that endpoint
does and warehouse_layout.png for the floor plan it reads.

Endpoint:
  POST /api/route/optimize
      body: {"bins": ["01-A203", "02-B105", ...]}
      resp: {
        "order": ["01-A203", "01-C106", "11-A102", ...],
        "totalDistance": 134   # round-trip distance in warehouse_layout.png pixels
      }
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse
import argparse
import base64
import io
import json
import os
import pickle
import re
import socket

import cv2
import networkx as nx
import numpy as np
import pytesseract
from PIL import Image, ImageDraw
from pyzbar.pyzbar import decode as zbar_decode, ZBarSymbol
from skimage.morphology import skeletonize, binary_opening, binary_closing
from ortools.constraint_solver import routing_enums_pb2
from ortools.constraint_solver import pywrapcp

pytesseract.pytesseract.tesseract_cmd = os.environ.get(
    "TESSERACT_CMD", r"C:\Program Files\Tesseract-OCR\tesseract.exe"
)

# ─── CONFIG ──────────────────────────────────────────────────────────────────

PORT = 9600

MATCH_COLOR = "lime"     # box colour for a QR that matched a candidate item code
NO_MATCH_COLOR = "red"   # box colour for a QR detected but not in the candidate list
BOX_WIDTH = 6

LAYOUT_PNG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "warehouse_layout.png")
# Parsing warehouse_layout.png (OCR + skeletonize) is the slow, one-time part
# of the route optimizer. The result is cached here so restarting the server
# does NOT re-run OCR/skeletonize every time -- only an explicit
# `--rebuild-layout` run (or a missing cache file) triggers a fresh parse.
LAYOUT_CACHE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "warehouse_layout_cache.pkl")
BIN_CODE_RE = re.compile(r"^(\w+)-([A-Za-z])(\d)(\d{2})$")

# ─────────────────────────────────────────────────────────────────────────────


def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


def match_prefix(raw_value, sorted_codes):
    """Returns the item code [raw_value] belongs to (exact match or prefix
    match, longest candidate wins), or None."""
    code = raw_value.strip()
    for item_code in sorted_codes:
        if code == item_code or code.startswith(item_code):
            return item_code
    return None


def _decode_qr(pil_img):
    return zbar_decode(pil_img, symbols=[ZBarSymbol.QRCODE, ZBarSymbol.CODE128])


def multi_pass_decode(pil_img):
    """Runs zbar against several classic-CV preprocessed variants of the same
    photo and merges the unique results.

    A photo of a real product's QR is usually clean, but photographing QR
    codes shown on a MONITOR/screen — as used for testing here — introduces
    glare, moiré interference, uneven lighting and slight blur that a plain
    single-pass zbar decode often misses on some of the codes even though
    they're clearly visible to a person. Each variant below targets one of
    those failure modes; results are merged so a code caught by ANY pass
    counts, without double-counting a code caught by several passes (a code
    from the SAME position is decoded once, not once per pass that finds it).
    """
    cv_img = cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)
    gray = cv2.cvtColor(cv_img, cv2.COLOR_BGR2GRAY)

    variants = [pil_img]

    # Adaptive threshold — robust to uneven lighting/glare across the frame,
    # where a single global threshold would blow out or darken part of it.
    adaptive = cv2.adaptiveThreshold(
        gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 35, 10
    )
    variants.append(Image.fromarray(adaptive))

    # Otsu threshold — clean global binarization when lighting is fairly even.
    _, otsu = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    variants.append(Image.fromarray(otsu))

    # Median blur then Otsu — smooths out moiré interference (the wavy
    # pattern that appears when a camera photographs a digital screen),
    # which can otherwise break up a QR module pattern enough to fail decode.
    denoised = cv2.medianBlur(gray, 3)
    _, denoised_bin = cv2.threshold(
        denoised, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU
    )
    variants.append(Image.fromarray(denoised_bin))

    # Unsharp-style sharpening — helps slightly out-of-focus shots.
    sharpen_kernel = np.array([[0, -1, 0], [-1, 5, -1], [0, -1, 0]])
    sharpened = cv2.filter2D(gray, -1, sharpen_kernel)
    variants.append(Image.fromarray(sharpened))

    # Merge: de-dup by (decoded value, rough position) so a code found by
    # multiple passes is only counted once, but two DIFFERENT physical QR
    # codes that happen to encode identical text are still both kept.
    #
    # Position match uses center-distance against each candidate's own box
    # size, not a fixed-size position bucket (e.g. `rect.left // 20`). A
    # bucket boundary is arbitrary — sub-pixel jitter between preprocessing
    # passes can push the SAME physical code's rect across it (e.g. top=419
    # vs top=420 land in different `// 20` buckets), silently double-counting
    # that one code. Comparing centers against box size has no such boundary.
    merged = []  # list of {"raw", "cx", "cy", "w", "h", "d"}
    for variant in variants:
        for d in _decode_qr(variant):
            raw = d.data.decode("utf-8", errors="ignore").strip()
            cx = d.rect.left + d.rect.width / 2
            cy = d.rect.top + d.rect.height / 2

            same = None
            for m in merged:
                if m["raw"] != raw:
                    continue
                if (abs(cx - m["cx"]) < max(d.rect.width, m["w"]) * 0.5
                        and abs(cy - m["cy"]) < max(d.rect.height, m["h"]) * 0.5):
                    same = m
                    break

            if same is None:
                merged.append({
                    "raw": raw, "cx": cx, "cy": cy,
                    "w": d.rect.width, "h": d.rect.height, "d": d,
                })
    return [m["d"] for m in merged]


def process_photo(image_b64, valid_codes):
    """Decodes every QR code in the photo, matches by prefix against
    [valid_codes], draws a highlight box on each, and returns the result
    dict described in the module docstring."""
    img_bytes = base64.b64decode(image_b64)
    img = Image.open(io.BytesIO(img_bytes)).convert("RGB")
    decoded_list = multi_pass_decode(img)

    # Longest codes first so a more specific candidate isn't shadowed by a
    # shorter unrelated one.
    sorted_codes = sorted({c.strip() for c in valid_codes if c.strip()},
                          key=len, reverse=True)

    matched_counts: dict[str, int] = {}
    unmatched_count = 0
    draw = ImageDraw.Draw(img)

    for d in decoded_list:
        raw = d.data.decode("utf-8", errors="ignore").strip()
        item_code = match_prefix(raw, sorted_codes)

        if d.polygon and len(d.polygon) >= 3:
            points = [(p.x, p.y) for p in d.polygon]
        else:
            l, t, w, h = d.rect
            points = [(l, t), (l + w, t), (l + w, t + h), (l, t + h)]

        if item_code:
            matched_counts[item_code] = matched_counts.get(item_code, 0) + 1
            color = MATCH_COLOR
        else:
            unmatched_count += 1
            color = NO_MATCH_COLOR

        draw.line(points + [points[0]], fill=color, width=BOX_WIDTH)
        if item_code:
            label_x = min(p[0] for p in points)
            label_y = max(min(p[1] for p in points) - 22, 0)
            draw.text((label_x, label_y), item_code, fill=color)

    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=85)
    annotated_b64 = base64.b64encode(buf.getvalue()).decode("utf-8")

    return {
        "matched": matched_counts,
        "unmatchedCount": unmatched_count,
        "totalDetected": len(decoded_list),
        "annotatedImage": annotated_b64,
    }


# ─── Route optimizer (proposal #7, "Nhóm A") ─────────────────────────────────
#
# Layout comes from warehouse_layout.png -- a raster image, so unlike a
# structured SVG/CAD source, the walkable structure has to be *inferred*:
#   1. OCR (Tesseract) finds every bin/row/zone label and its pixel position.
#   2. Classic CV (adaptive threshold + morphological opening/closing) turns
#      the image into a walkable/blocked mask -- opening erodes away thin
#      leftover text strokes without eating the much thicker rack/wall lines.
#   3. skeletonize() reduces the walkable area to a thin path network.
#   4. Only the LARGEST connected component of that skeleton is kept -- the
#      rest are small noise fragments (leftover text, stray pixels) that
#      inflate the component count but hold none of the real bins; verified
#      by inspection (see project chat log): the largest component alone
#      covers ~93% of all skeleton pixels and every real bin snaps onto it.
#   5. Each label's pixel position is snapped to its nearest skeleton pixel,
#      giving a graph node per bin; walking distance between any two bins is
#      the shortest path through that skeleton graph.
#
# No OCR/CV would be needed if the source were a structured SVG/CAD file
# instead of a photo/raster export -- that case can read exact coordinates
# directly. This pipeline is specifically for when only a raster image is
# available.
#
# Every rack is a dead-end aisle branching off one shared spine (confirmed:
# rows don't connect directly to each other, only via the spine), so this
# reduces to a TSP over the requested bins, solved as a closed loop (the
# entrance -- the DOCK area -- is both the start and end point).

ENTRANCE_XY_FRAC = (0.4909, 0.0500)  # main entrance doorway on Khu A's outer wall (warehouse_layout.png)

_layout_graph_cache = None  # (graph, spatial_bin_keys, special_bin_keys), built once


def _ocr_tokens(img_gray):
    data = pytesseract.image_to_data(img_gray, output_type=pytesseract.Output.DICT, config="--psm 11")
    tokens = []
    for i in range(len(data["text"])):
        t = data["text"][i].strip()
        if t and data["conf"][i] > 40:
            tokens.append({"text": t, "x": data["left"][i], "y": data["top"][i],
                           "w": data["width"][i], "h": data["height"][i]})
    return tokens


def _parse_layout_png():
    img = Image.open(LAYOUT_PNG).convert("L")
    arr = np.array(img)
    H, W = arr.shape
    tokens = _ocr_tokens(img)

    # Special zone: OCR reads the full bin code directly (e.g. "11-A101").
    special_bins = {}
    for t in tokens:
        if re.fullmatch(r"11-A10\d", t["text"]):
            special_bins[t["text"]] = (t["x"] + t["w"] / 2, t["y"] + t["h"] / 2)

    # Row labels: big "Lối đi 0X" numbers (tall text, near the left margin) --
    # distinct from the small per-cell position numbers "01".."06", which
    # reuse the same text but are much shorter and spread across the width.
    row_label_tokens = sorted(
        (t for t in tokens if re.fullmatch(r"0[1-5]", t["text"]) and t["h"] > 18 and t["x"] < W * 0.13),
        key=lambda t: t["y"],
    )

    def nearest_rack(y):
        return min(row_label_tokens, key=lambda t: abs(t["y"] - y))["text"]

    # Zone column bands ("Khu A/B/C") repeat at the same x in every row, so
    # ANY row's letter tokens are enough to classify any cell's column --
    # no need to isolate "the first row" (fragile: depends on exact layout
    # proportions, and broke when the row-height threshold didn't match).
    khu_letter_tokens = []
    for t in tokens:
        if t["text"] == "Khu":
            for t2 in tokens:
                if t2["text"] in ("A", "B", "C") and abs(t2["y"] - t["y"]) < 5 and t2["x"] > t["x"]:
                    khu_letter_tokens.append(t2)
                    break

    def nearest_zone_letter(x):
        return min(khu_letter_tokens, key=lambda t: abs(t["x"] - x))["text"]

    pos_tokens = [t for t in tokens if re.fullmatch(r"0[1-6]", t["text"]) and t["h"] <= 18]

    bins = {}  # "{rack}-{row}{pos:02d}" (level omitted, spatial only) -> (x, y)
    for t in pos_tokens:
        cx, cy = t["x"] + t["w"] / 2, t["y"] + t["h"] / 2
        key = f"{nearest_rack(cy)}-{nearest_zone_letter(cx)}{t['text']}"
        bins.setdefault(key, (cx, cy))

    # Walkable/blocked mask -> skeleton path network.
    dark = (arr < 200).astype(np.uint8)
    opened = binary_opening(dark, footprint=np.ones((3, 3)))
    closed = binary_closing(opened, footprint=np.ones((5, 5)))
    walkable = ~closed
    skeleton = skeletonize(walkable)
    ys, xs = np.nonzero(skeleton)
    skel_set = set(zip(xs.tolist(), ys.tolist()))

    raw_graph = nx.Graph()
    for x, y in skel_set:
        for dx, dy in ((-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)):
            nb = (x + dx, y + dy)
            if nb in skel_set:
                raw_graph.add_edge((x, y), nb, weight=(dx * dx + dy * dy) ** 0.5)

    largest = max(nx.connected_components(raw_graph), key=len)
    walk_graph = raw_graph.subgraph(largest)

    def nearest_skel_node(px, py, max_r=80):
        best, best_d = None, float("inf")
        for x, y in largest:
            d = (x - px) ** 2 + (y - py) ** 2
            if d < best_d:
                best_d, best = d, (x, y)
        return best if best_d <= max_r ** 2 else None

    graph = nx.Graph()
    all_points = {**{f"BIN_{k}": v for k, v in bins.items()},
                  **{f"BIN_{k}": v for k, v in special_bins.items()},
                  "ENTRANCE": (W * ENTRANCE_XY_FRAC[0], H * ENTRANCE_XY_FRAC[1])}
    hub = {}
    unplaced = []
    for node_id, (x, y) in all_points.items():
        anchor = nearest_skel_node(x, y)
        if anchor is None:
            unplaced.append(node_id)
            continue
        hub[node_id] = anchor
    if unplaced:
        print(f"[Route]    WARNING: could not place on skeleton: {unplaced}")

    # Connect every hub through the walk graph via its nearest anchor pixel;
    # edges between two hubs are the shortest path in walk_graph between
    # their anchors (computed lazily per-request in optimize_route, not
    # precomputed here -- keeps this one-time parse step fast).
    graph.add_nodes_from(hub.keys())
    graph.graph["walk_graph"] = walk_graph
    graph.graph["anchors"] = hub

    spatial_bins = set(bins.keys())
    special_bin_codes = set(special_bins.keys())
    return graph, spatial_bins, special_bin_codes


def load_layout_graph(force_rebuild=False):
    """Returns the (graph, spatial_bins, special_bin_codes) tuple.

    Resolution order: in-memory cache -> disk cache (LAYOUT_CACHE) -> parse
    warehouse_layout.png from scratch (OCR + skeletonize, the slow path).
    [force_rebuild] skips the first two and always re-parses + overwrites the
    disk cache -- this is what `--rebuild-layout` triggers.
    """
    global _layout_graph_cache

    if _layout_graph_cache is not None and not force_rebuild:
        return _layout_graph_cache

    if not force_rebuild and os.path.exists(LAYOUT_CACHE):
        print(f"[Route]    Loading cached layout graph from {LAYOUT_CACHE}")
        with open(LAYOUT_CACHE, "rb") as f:
            _layout_graph_cache = pickle.load(f)
        return _layout_graph_cache

    print(f"[Route]    Parsing {LAYOUT_PNG} (OCR + skeletonize)... "
          f"this can take a few seconds")
    _layout_graph_cache = _parse_layout_png()
    with open(LAYOUT_CACHE, "wb") as f:
        pickle.dump(_layout_graph_cache, f)
    print(f"[Route]    Saved layout graph cache to {LAYOUT_CACHE}")

    return _layout_graph_cache


def _hub_distance(graph, node_a, node_b):
    walk_graph = graph.graph["walk_graph"]
    anchors = graph.graph["anchors"]
    if node_a not in anchors or node_b not in anchors:
        raise ValueError(f"Bin khong the dat len ban do (OCR khong doc duoc hoac qua xa loi di): {node_a!r}/{node_b!r}")
    return nx.shortest_path_length(walk_graph, anchors[node_a], anchors[node_b], weight="weight")


def bin_node(code, spatial_bins, special_bins):
    """"01-A203" -> graph node "BIN_01-A03" (level digit dropped -- it's
    vertical, not spatial). Special-zone codes ("11-A101") already include
    their level digit and match a graph node as-is."""
    m = BIN_CODE_RE.match(code.strip())
    if not m:
        raise ValueError(f"Bin code khong dung dinh dang: {code!r}")
    rack, row, _level, pos = m.groups()
    spatial_key = f"{rack}-{row.upper()}{pos}"
    if spatial_key in spatial_bins:
        return f"BIN_{spatial_key}"
    if code in special_bins:
        return f"BIN_{code}"
    raise ValueError(f"Khong tim thay bin {code!r} trong warehouse_layout.png")


def optimize_route(bins):
    graph, spatial_bins, special_bins = load_layout_graph()
    nodes = ["ENTRANCE"] + bins
    graph_nodes = ["ENTRANCE"] + [bin_node(c, spatial_bins, special_bins) for c in bins]
    n = len(nodes)

    if n <= 2:  # 0 or 1 bin -- nothing to order, just report the round trip
        total = 0 if n < 2 else 2 * _hub_distance(graph, graph_nodes[0], graph_nodes[1])
        return {"order": bins, "totalDistance": round(total)}

    # OR-Tools' transit callback must return an int; pixel distances are
    # floats, so scale up before rounding to avoid losing precision.
    SCALE = 1000
    dist = [[round(_hub_distance(graph, graph_nodes[i], graph_nodes[j]) * SCALE)
             for j in range(n)] for i in range(n)]

    manager = pywrapcp.RoutingIndexManager(n, 1, 0)
    routing = pywrapcp.RoutingModel(manager)

    def distance_callback(from_index, to_index):
        return dist[manager.IndexToNode(from_index)][manager.IndexToNode(to_index)]

    transit_index = routing.RegisterTransitCallback(distance_callback)
    routing.SetArcCostEvaluatorOfAllVehicles(transit_index)

    params = pywrapcp.DefaultRoutingSearchParameters()
    params.first_solution_strategy = routing_enums_pb2.FirstSolutionStrategy.PATH_CHEAPEST_ARC
    params.local_search_metaheuristic = routing_enums_pb2.LocalSearchMetaheuristic.GUIDED_LOCAL_SEARCH
    params.time_limit.FromSeconds(2)

    solution = routing.SolveWithParameters(params)
    if solution is None:
        raise RuntimeError("OR-Tools khong tim duoc loi giai")

    order, travel = [], 0
    index = routing.Start(0)
    while not routing.IsEnd(index):
        node = manager.IndexToNode(index)
        if nodes[node] != "ENTRANCE":
            order.append(nodes[node])
        next_index = solution.Value(routing.NextVar(index))
        travel += routing.GetArcCostForVehicle(index, next_index, 0)
        index = next_index

    return {"order": order, "totalDistance": round(travel / SCALE)}


class VisionHandler(BaseHTTPRequestHandler):

    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path == "/api/vision/identify":
            self._handle_vision_identify()
        elif parsed.path == "/api/route/optimize":
            self._handle_route_optimize()
        else:
            self._send_404(parsed.path)

    def _handle_vision_identify(self):
        try:
            length = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(length).decode("utf-8"))
        except Exception as e:
            self._send_json({"error": f"bad request: {e}"}, 400)
            return

        image_b64 = body.get("image", "")
        valid_codes = [str(c) for c in body.get("validCodes", [])]
        print(f"[Vision]   photo {len(image_b64) // 1024} KB, "
              f"{len(valid_codes)} candidate codes: {valid_codes}")

        try:
            result = process_photo(image_b64, valid_codes)
            print(f"[Vision]   detected={result['totalDetected']} "
                  f"matched={result['matched']} "
                  f"unmatched={result['unmatchedCount']}")
            self._send_json(result)
        except Exception as e:
            print(f"[Vision]   ERROR: {e}")
            self._send_json({"error": str(e)}, 500)

    def _handle_route_optimize(self):
        try:
            length = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(length).decode("utf-8"))
        except Exception as e:
            self._send_json({"error": f"bad request: {e}"}, 400)
            return

        bins = body.get("bins", [])
        print(f"[Route]    {len(bins)} bins: {bins}")

        try:
            result = optimize_route(bins)
            print(f"[Route]    order={result['order']} "
                  f"total={result['totalDistance']}")
            self._send_json(result)
        except ValueError as e:
            print(f"[Route]    REJECTED: {e}")
            self._send_json({"error": str(e)}, 400)
        except Exception as e:
            print(f"[Route]    ERROR: {e}")
            self._send_json({"error": str(e)}, 500)

    def _send_json(self, obj, code=200):
        body = json.dumps(obj).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_404(self, path=""):
        print(f"[404]      {path}")
        self.send_response(404)
        self.end_headers()

    def log_message(self, format, *args):
        pass


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--rebuild-layout", action="store_true",
        help="Force re-parsing warehouse_layout.png (OCR + skeletonize) even "
             "if a cached graph already exists, and overwrite the cache.",
    )
    args = parser.parse_args()

    # Fail fast if warehouse_layout.png is missing/invalid; also builds or
    # loads the layout graph cache before the server starts accepting requests.
    load_layout_graph(force_rebuild=args.rebuild_layout)

    local_ip = get_local_ip()
    print("=" * 55)
    print("  Multi-QR Photo Scanner + Route Optimizer")
    print("=" * 55)
    print(f"  Server URL  : http://{local_ip}:{PORT}")
    print(f"  Endpoints   : POST /api/vision/identify")
    print(f"                POST /api/route/optimize")
    print(f"  Decoder     : pyzbar + OpenCV multi-pass (no LLM needed)")
    print(f"  Layout file : {LAYOUT_PNG}")
    print(f"  Layout cache: {LAYOUT_CACHE}")
    print("=" * 55)
    print("  Ctrl+C to stop the server")
    print()

    server = HTTPServer(("0.0.0.0", PORT), VisionHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")
