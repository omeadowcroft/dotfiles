-- Per-machine settings (monitors, GPU env vars) live in machine.lua, which is
-- NOT in git: scripts/rice-profile generates it, or links it to one of the
-- files in machines/ (e.g. `rice-profile --machine desktop`).
-- Without it, Hyprland falls back to each monitor's preferred mode with auto scale.
local ok, err = pcall(require, "machine")
if not ok and not tostring(err):find("module 'machine' not found", 1, true) then
    error(err)  -- machine.lua exists but is broken: surface the real error
end
