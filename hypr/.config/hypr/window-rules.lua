hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.window_rule({
    name = "expressvpn-tile",
    match = { class = "expressvpn" },
    tile = true,
    max_size = "99999 99999",
})

hl.window_rule({
    name = "tile-obsidian",
    match = { class = "^.*obsidian.*$" },
    tile = true,
    max_size = "99999 99999",
})

hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move = "20 monitor_h-120",
    float = true,
})

-- Drop-down terminal living in the magic scratchpad
hl.window_rule({
    name = "scratchpad-terminal",
    match = { class = "^scratchpad$" },
    float = true,
    center = true,
    size = { "monitor_w * 0.6", "monitor_h * 0.6" },
    workspace = "special:magic silent",
})
