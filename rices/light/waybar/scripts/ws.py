#!/usr/bin/env python3
import json, subprocess, sys

n = int(sys.argv[1])

def hc(*args):
    return json.loads(subprocess.check_output(["hyprctl", *args, "-j"]))

try:
    active = hc("activeworkspace")["id"]
    wins = {w["id"]: w["windows"] for w in hc("workspaces")}
except Exception:
    active, wins = 0, {}

if n == active:
    cls = "active"
elif wins.get(n, 0) > 0:
    cls = "occupied"
else:
    cls = "empty"

print(json.dumps({"text": "●", "class": ["ws", cls], "tooltip": f"Workspace {n}"}))
