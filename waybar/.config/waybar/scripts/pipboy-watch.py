#!/usr/bin/env python3
# Refresh the Pip-Boy tabs whenever Hyprland changes workspace/windows.
import os, socket, subprocess, time
path = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/run/user/%d" % os.getuid()), "hypr",
                    os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", ""), ".socket2.sock")
EVENTS = ("workspace", "focusedmon", "openwindow", "closewindow", "movewindow", "createworkspace", "destroyworkspace")
while True:
    try:
        s = socket.socket(socket.AF_UNIX); s.connect(path); buf = b""
        while True:
            data = s.recv(4096)
            if not data: break
            buf += data
            *lines, buf = buf.split(b"\n")
            if any(l.split(b">>")[0].decode(errors="ignore").rstrip("v2") in EVENTS for l in lines):
                subprocess.run(["pkill", "-RTMIN+8", "waybar"])
    except OSError:
        time.sleep(2)
