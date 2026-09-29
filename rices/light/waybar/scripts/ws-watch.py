#!/usr/bin/env python3
import os, socket, subprocess

path = f"{os.environ['XDG_RUNTIME_DIR']}/hypr/{os.environ['HYPRLAND_INSTANCE_SIGNATURE']}/.socket2.sock"
s = socket.socket(socket.AF_UNIX)
s.connect(path)

events = (b"workspace>>", b"workspacev2>>", b"openwindow>>", b"closewindow>>",
          b"movewindow>>", b"movewindowv2>>", b"focusedmon>>",
          b"createworkspace", b"destroyworkspace")

while True:
    data = s.recv(4096)
    if not data:
        break
    for line in data.split(b"\n"):
        if line.startswith(events):
            subprocess.run(["pkill", "-RTMIN+8", "waybar"])
