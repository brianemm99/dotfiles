-- a restarted Quickshell can re-take the lock instead of leaving a dead lock screen
hl.config({ misc = { allow_session_lock_restore = true } })

-- Hyprland starts hyprland-session.target itself but never stops it
hl.on("hyprland.shutdown", function()
  hl.exec_cmd("systemctl --user stop hyprland-session.target")
end)
