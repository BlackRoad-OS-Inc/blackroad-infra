#!/usr/bin/env python3
"""
BlackRoad Pi Stats Server — port 8090
Serves /stats and /health as JSON for iOS app + monitoring.
Install: sudo systemctl enable br-stats; sudo systemctl start br-stats
"""

import json
import os
import re
import subprocess
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(os.environ.get("STATS_PORT", "8090"))
HOST = os.environ.get("STATS_HOST", "0.0.0.0")


def _run(cmd: str) -> str:
    try:
        return subprocess.check_output(cmd, shell=True, text=True, timeout=3).strip()
    except Exception:
        return ""


def get_cpu_percent() -> float:
    """Read CPU idle from /proc/stat, return usage %"""
    try:
        with open("/proc/stat") as f:
            line = f.readline()
        parts = line.split()
        total = sum(int(x) for x in parts[1:])
        idle  = int(parts[4])
        time.sleep(0.2)
        with open("/proc/stat") as f:
            line = f.readline()
        parts2 = line.split()
        total2 = sum(int(x) for x in parts2[1:])
        idle2  = int(parts2[4])
        delta_total = total2 - total
        delta_idle  = idle2  - idle
        if delta_total == 0:
            return 0.0
        return round((1 - delta_idle / delta_total) * 100, 1)
    except Exception:
        return 0.0


def get_mem_percent() -> float:
    try:
        with open("/proc/meminfo") as f:
            lines = f.readlines()
        info = {}
        for line in lines:
            k, v = line.split(":")
            info[k.strip()] = int(v.strip().split()[0])
        total    = info.get("MemTotal", 1)
        available = info.get("MemAvailable", total)
        return round((1 - available / total) * 100, 1)
    except Exception:
        return 0.0


def get_uptime() -> str:
    try:
        with open("/proc/uptime") as f:
            secs = float(f.read().split()[0])
        d = int(secs // 86400)
        h = int((secs % 86400) // 3600)
        m = int((secs % 3600) // 60)
        if d:   return f"{d}d {h}h"
        if h:   return f"{h}h {m}m"
        return f"{m}m"
    except Exception:
        return ""


def get_services() -> list:
    """Return list of active BlackRoad services."""
    services = []
    checks = {
        "ollama":    "pgrep -x ollama",
        "nginx":     "pgrep -x nginx",
        "cloudflared": "pgrep -x cloudflared",
        "gateway":   "pgrep -f blackroad-gateway",
        "agents":    "pgrep -f br-agents",
        "dashboard": "ss -tlnp | grep :4000",
        "api":       "ss -tlnp | grep :3000",
    }
    for name, cmd in checks.items():
        if _run(cmd):
            services.append(name)
    return services


def get_disk_percent() -> float:
    try:
        out = _run("df / --output=pcent | tail -1")
        return float(out.replace("%", "").strip())
    except Exception:
        return 0.0


def get_temp() -> float:
    try:
        raw = _run("cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null")
        return round(float(raw) / 1000, 1) if raw else 0.0
    except Exception:
        return 0.0


class StatsHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass   # silence access log

    def do_GET(self):
        if self.path in ("/stats", "/health", "/_br/health", "/"):
            self._send_stats()
        elif self.path == "/ping":
            self._send_json({"pong": True}, 200)
        else:
            self._send_json({"error": "not found"}, 404)

    def _send_stats(self):
        data = {
            "status":   "ok",
            "hostname": _run("hostname") or "pi",
            "cpu":      get_cpu_percent(),
            "mem":      get_mem_percent(),
            "disk":     get_disk_percent(),
            "temp_c":   get_temp(),
            "uptime":   get_uptime(),
            "services": get_services(),
            "ts":       int(time.time()),
        }
        self._send_json(data, 200)

    def _send_json(self, data: dict, code: int):
        body = json.dumps(data).encode()
        self.send_response(code)
        self.send_header("Content-Type",  "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    server = HTTPServer((HOST, PORT), StatsHandler)
    print(f"BlackRoad Pi Stats → http://{HOST}:{PORT}/stats", flush=True)
    server.serve_forever()
