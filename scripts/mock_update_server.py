"""
mock_update_server.py
─────────────────────
Mock OTA update server for local testing.

Usage:
  1. Adjust NEW_VERSION and APK_PATH below
  2. Run:  python scripts/mock_update_server.py
  3. Open the firewall for port 9500 (if needed)
  4. In the app, set the hostname to http://<PC_IP>:9500

Endpoints:
  GET /api/Devices
      → returns version info (app compares against the installed version)
  GET /api/Devices/DownloadApiAsync?pathFile=...
      → streams the APK file to the phone
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse
import json
import os
import socket

# ─── CONFIG ──────────────────────────────────────────────────────────────────

# Version the server reports (must differ from the version installed on the phone)
NEW_VERSION = "1.0.2"

# Path to the new APK (built with: flutter build apk --release)
APK_PATH = r"D:\Project\wms_hht_dart\build\app\outputs\flutter-apk\app-debug.apk"

# Server port (must match defaultHost in app_constants.dart)
PORT = 9500

# ─────────────────────────────────────────────────────────────────────────────


def get_local_ip():
    """Returns the machine's local IP on the LAN."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


class UpdateHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        parsed = urlparse(self.path)

        # ── GET /api/Devices ──────────────────────────────────────
        if parsed.path == "/api/Devices":
            self._handle_devices()

        # ── GET /api/Devices/DownloadApiAsync?pathFile=... ────────
        elif parsed.path == "/api/Devices/DownloadApiAsync":
            self._handle_download()

        else:
            self._send_404(parsed.path)

    # ─── /api/Devices ────────────────────────────────────────────

    def _handle_devices(self):
        body = json.dumps([
            {
                "currentVersionCommon": NEW_VERSION,   # version string (app strips the 'V')
                "currentVersion": "downloads/fbt_hht.apk",  # apkPath passed to download
            }
        ]).encode("utf-8")

        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
        print(f"[Devices]  version={NEW_VERSION}")

    # ─── /api/Devices/DownloadApiAsync ───────────────────────────

    def _handle_download(self):
        if not os.path.exists(APK_PATH):
            print(f"[Download] ERROR: APK not found → {APK_PATH}")
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"APK file not found")
            return

        file_size = os.path.getsize(APK_PATH)
        print(f"[Download] Sending APK ({file_size / 1024 / 1024:.1f} MB) → {self.client_address[0]}")

        self.send_response(200)
        self.send_header("Content-Type", "application/vnd.android.package-archive")
        self.send_header("Content-Length", str(file_size))
        self.send_header("Content-Disposition", "attachment; filename=fbt_hht.apk")
        self.end_headers()

        with open(APK_PATH, "rb") as f:
            sent = 0
            chunk_size = 1024 * 1024  # 1 MB chunks (was 64 KB → too many writes)
            next_log = 5  # only print every 5% to avoid console I/O slowdown
            while chunk := f.read(chunk_size):
                self.wfile.write(chunk)
                sent += len(chunk)
                pct = sent / file_size * 100
                if pct >= next_log:
                    print(f"\r[Download] {pct:5.1f}%", end="", flush=True)
                    next_log += 5
        print("\r[Download] 100.0% done")

    # ─── 404 ─────────────────────────────────────────────────────

    def _send_404(self, path=""):
        print(f"[404]      {path}")
        self.send_response(404)
        self.end_headers()

    # ─── Disable the default HTTPServer logging ──────────────────

    def log_message(self, format, *args):
        pass  # use manual print() instead of the noisy default log


# ─── MAIN ─────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    local_ip = get_local_ip()

    print("=" * 55)
    print("  OTA Mock Server")
    print("=" * 55)
    print(f"  New version : {NEW_VERSION}")
    print(f"  APK path    : {APK_PATH}")
    print(f"  APK exists  : {'✓' if os.path.exists(APK_PATH) else '✗  (not built yet)'}")
    print("-" * 55)
    print(f"  Server URL  : http://{local_ip}:{PORT}")
    print(f"  → Use this URL as the hostname in the app")
    print("=" * 55)
    print("  Ctrl+C to stop the server")
    print()

    server = HTTPServer(("0.0.0.0", PORT), UpdateHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")
