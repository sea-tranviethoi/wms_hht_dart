"""
mock_vision_server.py
─────────────────────
Multi-QR photo scanner for cycle-count (棚卸).

The handheld sends ONE photo of several items (each with a QR code stuck on
it) plus the set of item codes currently being counted. This server decodes
EVERY QR code in the photo with pyzbar (deterministic, not a guess — pyzbar
reads the exact bytes encoded in each QR), matches each decoded value against
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
  1. pip install pyzbar pillow opencv-python numpy   (one-time)
  2. Run:  python scripts/mock_vision_server.py
  3. Open the firewall for port 9600
  4. In the app, point AppConstants.visionHost to http://<PC_IP>:9600

Endpoint:
  POST /api/vision/identify
      body: {"image": "<base64 jpeg>", "validCodes": ["2022Sum03", "2022MIWA02"]}
      resp: {
        "matched": {"2022Sum03": 2},       # itemCode -> units found
        "unmatchedCount": 3,               # QR codes detected but not in validCodes
        "totalDetected": 5,                # total QR codes found in the photo
        "annotatedImage": "<base64 jpeg>"  # photo with highlight boxes drawn
      }
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse
import base64
import io
import json
import socket

import cv2
import numpy as np
from PIL import Image, ImageDraw
from pyzbar.pyzbar import decode as zbar_decode, ZBarSymbol

# ─── CONFIG ──────────────────────────────────────────────────────────────────

PORT = 9600

MATCH_COLOR = "lime"     # box colour for a QR that matched a candidate item code
NO_MATCH_COLOR = "red"   # box colour for a QR detected but not in the candidate list
BOX_WIDTH = 6

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
    return zbar_decode(pil_img, symbols=[ZBarSymbol.QRCODE])


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
    merged = {}
    for variant in variants:
        for d in _decode_qr(variant):
            raw = d.data.decode("utf-8", errors="ignore").strip()
            key = (raw, d.rect.left // 20, d.rect.top // 20)
            merged.setdefault(key, d)
    return list(merged.values())


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


class VisionHandler(BaseHTTPRequestHandler):

    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path != "/api/vision/identify":
            self._send_404(parsed.path)
            return

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
    local_ip = get_local_ip()
    print("=" * 55)
    print("  Multi-QR Photo Scanner (cycle count)")
    print("=" * 55)
    print(f"  Server URL  : http://{local_ip}:{PORT}")
    print(f"  Endpoint    : POST /api/vision/identify")
    print(f"  Decoder     : pyzbar + OpenCV multi-pass (no LLM needed)")
    print("=" * 55)
    print("  Ctrl+C to stop the server")
    print()

    server = HTTPServer(("0.0.0.0", PORT), VisionHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")
