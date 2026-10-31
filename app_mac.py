#!/usr/bin/env python3
import html as html_lib
import http.server
import json
import os
import re
import socket
import socketserver
import subprocess
import sys
import threading
import webbrowser
from concurrent.futures import ThreadPoolExecutor

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def find_open_port(start=8765, end=8785):
    for p in range(start, end + 1):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            try:
                s.bind(("127.0.0.1", p))
                return p
            except OSError:
                continue
    return start

def parse_follower_count(raw_html: str) -> int:
    if not raw_html:
        return -1
    m_json = re.search(r'"(?:edge_followed_by"\s*:\s*\{\s*"count|follower_count)"\s*:\s*(\d+)', raw_html, flags=re.I)
    if m_json:
        return int(m_json.group(1))

    decoded = html_lib.unescape(raw_html)
    m_fol = re.search(
        r'(?:content=["'][^"']*?|\b)([0-9][0-9.,\s]*?)\s*(k|m|b|mil|millones|de\s+millones)?\s*(?:de\s+)?(?:followers|follower|seguidores|seguidor)\b',
        decoded,
        flags=re.I
    )
    if m_fol:
        num_raw = re.sub(r'\s+', '', m_fol.group(1) or '')
        suffix = (m_fol.group(2) or '').strip().lower()
        mult = 1
        if suffix in ('k', 'mil'):
            mult = 1_000
        elif suffix in ('m', 'millones', 'de millones'):
            mult = 1_000_000
        elif suffix == 'b':
            mult = 1_000_000_000

        if mult > 1:
            try:
                return int(round(float(num_raw.replace(',', '.')) * mult))
            except ValueError:
                return -1
        else:
            digits = re.sub(r'[^\d]', '', num_raw)
            return int(digits) if digits else -1
    return -1

def check_single_username(username: str) -> dict:
    user_lower = username.strip().lower()
    url = f"https://www.instagram.com/{user_lower}/"

    try:
        proc = subprocess.run(
            [
                "curl", "-s", "-L", "--max-time", "8", "--compressed",
                "-A", "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)",
                "-H", "Accept-Language: en-US,en;q=0.9",
                url
            ],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="ignore"
        )
        raw_text = proc.stdout or ""
        raw = raw_text.lower()
        if len(raw) > 200:
            if 'property="og:title"' in raw or 'property="og:description"' in raw or f"(@{user_lower})" in raw:
                return {"u": username, "active": True, "followers": parse_follower_count(raw_text)}

            proc2 = subprocess.run(
                [
                    "curl", "-s", "-L", "--max-time", "8", "--compressed",
                    "-A", "TelegramBot (like TwitterBot)",
                    "-H", "Accept-Language: en-US,en;q=0.9",
                    url
                ],
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="ignore"
            )
            raw_text2 = proc2.stdout or ""
            raw2 = raw_text2.lower()
            if 'property="og:title"' in raw2 or 'property="og:description"' in raw2 or f"(@{user_lower})" in raw2:
                return {"u": username, "active": True, "followers": parse_follower_count(raw_text2)}

            if "<title>instagram</title>" in raw or "page isn't available" in raw or "page not found" in raw:
                return {"u": username, "active": False, "followers": -1}
    except Exception:
        pass

    return {"u": username, "active": True, "followers": -1}


class AppHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=BASE_DIR, **kwargs)

    def log_message(self, format, *args):
        pass

    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
        self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()

    def do_GET(self):
        path = self.path.split("?")[0]
        if path == "/api/ping":
            body = json.dumps({"status": "ok", "version": "v6-mac"}).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if path == "/":
            self.path = "/index.html"
        return super().do_GET()

    def do_POST(self):
        path = self.path.split("?")[0]
        if path == "/api/verify":
            length = int(self.headers.get("Content-Length", 0))
            raw = self.rfile.read(length).decode("utf-8", errors="ignore")
            try:
                payload = json.loads(raw)
                usernames = payload.get("usernames", [])
            except Exception:
                usernames = []

            active_list = []
            dead_list = []
            counts_map = {}
            with ThreadPoolExecutor(max_workers=5) as pool:
                results = list(pool.map(check_single_username, usernames))

            for res in results:
                if not res["active"]:
                    dead_list.append(res["u"])
                else:
                    active_list.append(res["u"])
                    if res.get("followers", -1) >= 0:
                        counts_map[res["u"]] = res["followers"]

            print(f" [Verified Batch] Active: {len(active_list)} | Dead/404: {len(dead_list)} | Counts: {len(counts_map)}")
            body = json.dumps({"active": active_list, "dead": dead_list, "counts": counts_map}).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        self.send_response(404)
        self.end_headers()


def open_mac_window(url: str):
    chrome_app = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    edge_app = "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
    if os.path.exists(chrome_app):
        try:
            subprocess.Popen([chrome_app, f"--app={url}", "--window-size=940,860"])
            return
        except Exception:
            pass
    if os.path.exists(edge_app):
        try:
            subprocess.Popen([edge_app, f"--app={url}", "--window-size=940,860"])
            return
        except Exception:
            pass
    webbrowser.open(url)


if __name__ == "__main__":
    port = find_open_port()
    socketserver.TCPServer.allow_reuse_address = True
    url = f"http://127.0.0.1:{port}/index.html"
    print(f" Status : Running locally at {url}")
    print(" Engine : macOS Live 404 Verifier + Follower Count Extractor")
    print(" -> Opening app window now...")
    print(" -> Keep this terminal window open while using the app.")
    threading.Timer(0.6, open_mac_window, args=[url]).start()
    with socketserver.ThreadingTCPServer(("127.0.0.1", port), AppHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down app...")
