#!/usr/bin/env python3
import json, subprocess, sys
n, name = int(sys.argv[1]), sys.argv[2]
q = lambda *a: json.loads(subprocess.run(["hyprctl", *a, "-j"], capture_output=True, text=True).stdout or "null")
try:
    act = (q("activeworkspace") or {}).get("id")
    occ = any(w.get("id") == n and w.get("windows", 0) > 0 for w in (q("workspaces") or []))
except Exception:
    act, occ = None, False
cls = "active" if act == n else ("occupied" if occ else "empty")
print(json.dumps({"text": name, "class": cls, "tooltip": f"Workspace {n}"}))
