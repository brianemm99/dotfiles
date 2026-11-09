return {
  internal = {
    output = "eDP-1",
    mode   = "preferred",
    -- pinned, never "auto": Quickshell sizes widgets from it. Must divide 2256x1504 evenly:
    -- 1.175 (1920x1280)  1.333333 (1692x1128)  1.566667 (1440x960)  1.6 (1410x940)  2 (1128x752)
    scale  = 1.566667,
  },

  ultrawide = {
    -- make + model from `hyprctl monitors all`, no serial: it reports 0xA9CCBC47 over
    -- DisplayPort (dock) but 0x0000041E over HDMI
    output   = "desc:Microstep MSI MP341CQ",
    mode     = "3440x1440@100",
    scale    = 1,              -- ~110 PPI, no scaling needed
    vrr      = 0,              -- 2 (fullscreen FreeSync) blanks the screen over HDMI: not vrr-capable there
  },

  fallback = { output = "", mode = "preferred", position = "auto", scale = "auto" },

  -- where the panel sits in dual mode: "below" | "left" | "right"
  dual_placement = "left",

  -- workspaces 1..split go to the panel, the rest to the ultrawide
  workspace_split = 5,
}
