"""
mock_vision_server.py
─────────────────────
Mock Vision AI server for cycle-count (棚卸) testing.

It receives a shelf photo from the handheld and returns which candidate item
codes appear in it. If a local VLM (e.g. Qwen2.5-VL served by LM Studio) is
reachable it forwards the image there; otherwise it returns a canned response
so the app flow can be tested without a model.

Usage:
  1. (Optional) Run LM Studio with a vision model, server on 127.0.0.1:1234
  2. Adjust LMSTUDIO_URL / MODEL below if needed
  3. Run:  python scripts/mock_vision_server.py
  4. Open the firewall for port 9600
  5. In the app, point AppConstants.visionHost to http://<PC_IP>:9600

Endpoint:
  POST /api/vision/identify
      body: {"image": "<base64 jpeg, no data-uri prefix>", "itemCodes": ["A1","A2"]}
      resp: {"identified": ["A1"], "mock": false, "raw": "<model text>"}
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse
import urllib.request
import json
import socket

# ─── CONFIG ──────────────────────────────────────────────────────────────────

PORT = 9600

# LM Studio (or any OpenAI-compatible VLM) endpoint on this PC.
LMSTUDIO_URL = "http://127.0.0.1:1234/v1/chat/completions"
MODEL = "qwen2.5-vl-7b-instruct"          # name of the loaded vision model
LM_TIMEOUT = 60                            # seconds

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


def call_vlm(image_b64, item_codes):
    """Ask the local VLM which candidate codes appear in the image.
    Returns (identified_list, raw_text). Raises on transport failure."""
    prompt = (
        "You are a warehouse cycle-count assistant. The candidate item codes "
        "are: " + ", ".join(item_codes) + ". Look at the shelf photo and reply "
        "with ONLY a JSON array of the item codes that visibly appear. "
        'Example: ["A1","A2"]. If none, reply [].'
    )
    payload = {
        "model": MODEL,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:image/jpeg;base64,{image_b64}"},
                    },
                ],
            }
        ],
        "temperature": 0,
        "max_tokens": 256,
    }
    req = urllib.request.Request(
        LMSTUDIO_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=LM_TIMEOUT) as r:
        data = json.loads(r.read().decode("utf-8"))
    text = data["choices"][0]["message"]["content"]

    # Extract the first JSON array from the model's reply.
    identified = []
    start = text.find("[")
    end = text.rfind("]")
    if start >= 0 and end > start:
        try:
            arr = json.loads(text[start:end + 1])
            identified = [str(x).strip() for x in arr if str(x).strip()]
        except Exception:
            identified = []
    # Keep only codes that were actually candidates.
    valid = {c.strip() for c in item_codes}
    identified = [c for c in identified if c in valid]
    return identified, text


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
        item_codes = [str(c) for c in body.get("itemCodes", [])]
        print(f"[Vision]   {len(item_codes)} candidate codes, "
              f"image {len(image_b64) // 1024} KB")

        # Try the real VLM; fall back to a canned response if unreachable.
        try:
            identified, raw = call_vlm(image_b64, item_codes)
            print(f"[Vision]   identified: {identified}")
            self._send_json({"identified": identified, "mock": False, "raw": raw})
        except Exception as e:
            canned = item_codes[:2]
            print(f"[Vision]   VLM unreachable ({e}); returning canned {canned}")
            self._send_json({"identified": canned, "mock": True, "error": str(e)})

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
    print("  Vision AI Mock Server (cycle count)")
    print("=" * 55)
    print(f"  LM Studio   : {LMSTUDIO_URL}")
    print(f"  Model       : {MODEL}")
    print(f"  Server URL  : http://{local_ip}:{PORT}")
    print(f"  Endpoint    : POST /api/vision/identify")
    print("=" * 55)
    print("  Ctrl+C to stop the server")
    print()

    server = HTTPServer(("0.0.0.0", PORT), VisionHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")
