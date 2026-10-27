hl.monitor({ output = "DP-1", mode = "2560x1440@180", position = "0x0", scale = 1, icc = "/home/rtxbb/Документы/MAG274Q QD E2_15-12-2024.icm"  })
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@120", position = "-1152x-500", scale = 1.25, transform = 3  })
-- hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1, mirror = "DP-1" })

-- Keyboard layouts: English + Russian, switch with Alt+Shift
hl.config({
    input = {
        kb_layout  = "us,ru",
        kb_options = "grp:alt_shift_toggle",
    },
})

-- Asymmetric outer gaps: keep the left gap wider for the left panel.
-- Single source of truth for the values below.
local gaps_out = { top = 10, right = 10, bottom = 10, left = 20 }

-- Apply at config load
hl.config({
    general = {
        gaps_out = gaps_out,
    },
})

-- Re-assert shortly after Hyprland starts, so the value is enforced
-- automatically on every login even if something overwrote it during startup.
-- NOTE: `hyprctl keyword` does not work with the Lua config manager
-- ("keyword can't work with non-legacy parsers"), use `hyprctl eval`.
hl.on("hyprland.start", function()
    hl.exec_cmd(
        "sleep 1 && hyprctl eval 'hl.config({ general = { gaps_out = { top = " ..
        gaps_out.top .. ", right = " .. gaps_out.right ..
        ", bottom = " .. gaps_out.bottom .. ", left = " .. gaps_out.left .. " } } })'"
    )
    -- angelOS desktop widgets beside Caelestia (~/.config/quickshell/angelos-widgets)
    hl.exec_cmd("qs -c angelos-widgets -n -d")

    -- Proxy GUI. Kill leftovers from a dead session first: a stale
    -- instance still holds the single-instance lock at login, which both
    -- skips a naive launch and then crashes on the dead Wayland socket.
    -- Wait until it is really gone (SIGTERM shutdown takes a few seconds),
    -- otherwise the fresh instance sees the lock and exits immediately.
    hl.exec_cmd("pkill -x koala-clash; for i in $(seq 1 20); do pgrep -x koala-clash >/dev/null || break; sleep 0.5; done; /opt/Koala.Clash/koala-clash")

    -- FX240 LCD pump monitor (starts minimized to tray)
    hl.exec_cmd("/usr/bin/python3 /home/rtxbb/code/id-cooling_lcd/app.py --minimized")
end)

hl.device({
    name = "wacom-intuos-s-pen",
    output = "DP-1"
})

-- OCR: select a screen region, its text goes to the clipboard (~/.local/bin/ocr-region, from angelOS)
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("ocr-region"))

-- VM passthrough: Super+Escape toggles; while active every key goes to the focused window
hl.bind("SUPER + Escape", hl.dsp.submap("passthru"))
hl.define_submap("passthru", function()
    hl.bind("SUPER + Escape", hl.dsp.submap("reset"))
end)

-- Auto passthru while a VirtualBox VM window is focused
hl.on("window.active", function()
    local w = hl.get_active_window()
    local vm = w ~= nil and w.class == "VirtualBox Machine"
    local on = hl.get_current_submap() == "passthru"
    if vm and not on then
        hl.dispatch(hl.dsp.submap("passthru"))
    elseif not vm and on then
        hl.dispatch(hl.dsp.submap("reset"))
    end
end)

