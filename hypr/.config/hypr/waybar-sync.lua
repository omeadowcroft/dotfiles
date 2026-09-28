-- Refresh the Pip-Boy workspace tabs in Waybar on every workspace/window change
local function refresh() hl.exec_cmd("pkill -RTMIN+8 waybar") end
for _, ev in ipairs({ "workspace.active", "workspace.created", "workspace.removed",
                      "window.open", "window.close", "window.move_to_workspace" }) do
    hl.on(ev, refresh)
end
