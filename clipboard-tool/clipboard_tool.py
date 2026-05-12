#!/usr/bin/env python3
"""剪切板翻译辅助工具 — 监控剪切板，自动添加前缀和后缀。"""

import json
import os
import subprocess
import sys
import threading
import time
import webbrowser
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

CONFIG_PATH = os.path.expanduser("~/.clipboard-translator-config.json")
DEFAULT_CONFIG = {
    "prefix": "请将以下英文翻译成中文：\n\n",
    "suffix": "",
    "enabled": True,
    "port": 9876,
}
MAX_LOG = 50

config = {}
config_lock = threading.Lock()
logs = []
logs_lock = threading.Lock()


def load_config():
    global config
    if os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, "r", encoding="utf-8") as f:
            config = json.load(f)
        for key in DEFAULT_CONFIG:
            if key not in config:
                config[key] = DEFAULT_CONFIG[key]
    else:
        config = dict(DEFAULT_CONFIG)
        save_config()


def save_config():
    with open(CONFIG_PATH, "w", encoding="utf-8") as f:
        json.dump(config, f, ensure_ascii=False, indent=4)


def get_clipboard():
    try:
        result = subprocess.run(
            ["pbpaste"], capture_output=True, text=True, timeout=2
        )
        return result.stdout
    except Exception:
        return ""


def set_clipboard(text):
    try:
        subprocess.run(["pbcopy"], input=text, text=True, timeout=2)
    except Exception:
        pass


def notify(title, message):
    script = f'display notification "{message}" with title "{title}"'
    subprocess.run(["osascript", "-e", script], timeout=3)


def add_log(text, original, transformed):
    with logs_lock:
        preview = original[:60] + ("..." if len(original) > 60 else "")
        logs.append({
            "time": time.strftime("%H:%M:%S"),
            "preview": preview,
            "original": original,
            "transformed": transformed,
        })
        if len(logs) > MAX_LOG:
            logs.pop(0)


def monitor_clipboard():
    last_text = get_clipboard()
    while True:
        time.sleep(0.5)
        try:
            current = get_clipboard()
            if current and current != last_text:
                with config_lock:
                    enabled = config.get("enabled", True)
                    prefix = config.get("prefix", "")
                    suffix = config.get("suffix", "")
                if not enabled:
                    last_text = current
                    continue
                # 跳过已经带有前缀的文本，避免重复转换
                if prefix and current.startswith(prefix):
                    last_text = current
                    continue
                transformed = prefix + current + suffix
                set_clipboard(transformed)
                last_text = transformed
                add_log(current, transformed, transformed)
                notify("剪切板翻译工具", f"已添加前后缀（{len(current)}字符）")
        except Exception:
            pass


class APIHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def _json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self._cors()
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        path = urlparse(self.path).path
        if path == "/" or path == "/index.html":
            frontend = os.path.join(os.path.dirname(__file__), "frontend.html")
            try:
                with open(frontend, "rb") as f:
                    content = f.read()
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self._cors()
                self.end_headers()
                self.wfile.write(content)
            except FileNotFoundError:
                self._json({"error": "frontend.html not found"}, 404)
        elif path == "/api/status":
            with config_lock:
                self._json({
                    "enabled": config.get("enabled", True),
                    "prefix": config.get("prefix", ""),
                    "suffix": config.get("suffix", ""),
                })
        elif path == "/api/logs":
            with logs_lock:
                self._json({"logs": list(logs)})
        else:
            self._json({"error": "not found"}, 404)

    def do_POST(self):
        path = urlparse(self.path).path
        content_length = int(self.headers.get("Content-Length", 0))
        body_raw = self.rfile.read(content_length) if content_length > 0 else b"{}"
        try:
            body = json.loads(body_raw)
        except json.JSONDecodeError:
            body = {}

        if path == "/api/toggle":
            with config_lock:
                config["enabled"] = not config.get("enabled", True)
                save_config()
                self._json({"enabled": config["enabled"]})
                notify(
                    "剪切板翻译工具",
                    "已启用" if config["enabled"] else "已禁用",
                )
        elif path == "/api/config":
            with config_lock:
                if "prefix" in body:
                    config["prefix"] = body["prefix"]
                if "suffix" in body:
                    config["suffix"] = body["suffix"]
                save_config()
                self._json({
                    "prefix": config["prefix"],
                    "suffix": config["suffix"],
                })
        else:
            self._json({"error": "not found"}, 404)


def main():
    load_config()
    port = config.get("port", 9876)

    monitor_thread = threading.Thread(target=monitor_clipboard, daemon=True)
    monitor_thread.start()

    server = HTTPServer(("127.0.0.1", port), APIHandler)
    url = f"http://127.0.0.1:{port}"

    print(f"剪切板翻译工具已启动")
    print(f"配置: {'启用' if config['enabled'] else '已禁用'}")
    print(f"前缀: {repr(config['prefix'])}")
    print(f"后缀: {repr(config['suffix'])}")
    print(f"前端地址: {url}")
    print("按 Ctrl+C 退出")

    webbrowser.open(url)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n已退出")
        server.shutdown()
        sys.exit(0)


if __name__ == "__main__":
    main()
