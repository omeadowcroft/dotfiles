-- Desktop: XG32UCWMG 4K 240 Hz on DP-2 plus DP-1, NVIDIA GPU.
-- Select on that machine with: rice-profile --machine desktop

hl.monitor({
    output = "DP-2",
    mode = "3840x2160@240.02",
    position = "0x0",
    scale = 1.5,
    bitdepth = 10,
})

hl.monitor({
    output = "DP-1",
    mode = "preferred",
    position = "2560x0",
    scale = 1,
})

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")
