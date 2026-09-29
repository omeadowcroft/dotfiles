hl.config({
    input = {
        kb_layout = "gb",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.device({
    name = "logitech-pro-x-1",
    accel_profile = "flat",
    sensitivity = 0.2,
})

hl.device({
    name = "logitech-x2-superstrike-1",
    accel_profile = "flat",
    sensitivity = 0.2,
})
