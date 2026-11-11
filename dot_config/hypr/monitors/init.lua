local dev = require("monitors.devices")

Display = { mode = nil, override = nil, facts = nil, applied = nil }   -- fresh on every reload
local D = Display

---------------------------------------------------------------- state
-- facts come from the kernel, not from Hyprland's rule-dependent monitor list

local function read(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local s = f:read("*a")
  f:close()
  return s
end

-- no lid file (a desktop) reads as open
local function lid_closed()
  local s = read("/proc/acpi/button/lid/LID0/state")
  return s ~= nil and s:match("closed") ~= nil
end

-- connected non-eDP connectors, named as Hyprland names them (DP-3, HDMI-A-1).
-- One popen: Lua can't list a directory, and MST docks create connectors at runtime.
local function externals()
  local list = {}
  local p = io.popen("grep -H . /sys/class/drm/card*-*/status 2>/dev/null")
  if not p then return list end
  local out = p:read("*a") or ""
  p:close()
  for conn, status in out:gmatch("card%d+%-([%w%-]+)/status:(%a+)") do
    if status == "connected" and not conn:match("^eDP") then
      table.insert(list, conn)
    end
  end
  table.sort(list)
  return list
end

---------------------------------------------------------------- profiles

local placement = {
  below = "auto-center-down",
  left  = "auto-center-left",
  right = "auto-center-right",
}

-- rules merge into the existing one for that output: a field left out keeps its old
-- value, so every enabling rule must say disabled = false or a disabled output stays off
local function panel(position)
  hl.monitor({ output = dev.internal.output, mode = dev.internal.mode,
               position = position, scale = dev.internal.scale, disabled = false })
end

local function panel_off()
  hl.monitor({ output = dev.internal.output, disabled = true })
end

-- the fallback rule is never disabled: a monitor that appears while its rule says
-- disabled aborts Hyprland 0.57.1 (bad_any_cast in CMonitorResources::initFB)
local function externals_on(position)
  local f, u = dev.fallback, dev.ultrawide
  hl.monitor({ output = f.output, mode = f.mode, position = f.position, scale = f.scale })
  hl.monitor({ output = u.output, mode = u.mode, position = position or "0x0", scale = u.scale, vrr = u.vrr,
               disabled = false })
end

local profiles = {
  -- automatic only: nothing is connected; keep external rules enabled so the next
  -- plug-in arrives lit
  laptop   = function() panel("0x0"); externals_on("auto") end,
  dual     = function() externals_on(); panel(placement[dev.dual_placement] or placement.below) end,
  external = function() externals_on(); panel_off() end,
}

---------------------------------------------------------------- controller

-- the only override is "external" with the lid open; it needs an external to show on
local function allowed(o, lid, ext)
  return o == "external" and #ext > 0
end

local function pick(lid, ext)
  if D.override and allowed(D.override, lid, ext) then return D.override end
  D.override = nil
  if #ext == 0 then return "laptop" end   -- lid closed here = logind suspends
  if lid then return "external" end
  return "dual"
end

local function publish(lid, ext)
  local path = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-display.json"
  local f = io.open(path .. ".tmp", "w")
  if not f then return end
  f:write(string.format(
    '{"mode":"%s","override":%s,"lid":"%s","externals":[%s],"workspace_split":%d}',
    D.mode, D.override and ('"' .. D.override .. '"') or "null",
    lid and "closed" or "open",
    #ext > 0 and ('"' .. table.concat(ext, '","') .. '"') or "",
    dev.workspace_split))
  f:close()
  os.rename(path .. ".tmp", path)          -- atomic: Quickshell never reads half a file
end

-- one line per event and decision; $XDG_RUNTIME_DIR is tmpfs, so it clears on logout
local function log(msg)
  local f = io.open((os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-display.log", "a")
  if not f then return end
  f:write(os.date("%H:%M:%S "), msg, "\n")
  f:close()
end
D.log = log

-- move focus and cursor to the center of an output (by connector name).
-- Done now and again once the layout has settled: when the panel actually goes dark,
-- Hyprland clamps the cursor to the nearest edge of what's left, undoing the first move.
local function center(name)
  for _, m in ipairs(hl.get_monitors()) do
    if m.name == name then
      hl.dispatch(hl.dsp.focus({ monitor = name }))
      hl.dispatch(hl.dsp.cursor.move({ x = math.floor(m.x + m.width / m.scale / 2),
                                       y = math.floor(m.y + m.height / m.scale / 2) }))
      return
    end
  end
end

local landing
local function land_on(name)
  center(name)
  if landing then landing:set_enabled(false) end
  landing = hl.timer(function() landing = nil; center(name) end, { timeout = 300, type = "oneshot" })
end

function D.reconcile(reason, force)
  local lid, ext = lid_closed(), externals()
  local facts = (lid and "closed" or "open") .. "|" .. table.concat(ext, ",")
  log(string.format("reconcile %s: facts %s, override %s, mode %s",
                    reason, facts, tostring(D.override), tostring(D.mode)))
  if D.facts and facts ~= D.facts and reason ~= "override" then
    D.override = nil                        -- hardware changed: back to auto
  end
  D.facts = facts

  local mode = pick(lid, ext)
  local key = mode .. "|" .. facts
  if key == D.applied and not force then return end

  local prev = D.mode
  log("apply " .. mode)
  profiles[mode]()
  D.mode, D.applied = mode, key
  if mode ~= prev then
    if mode == "external" then land_on(ext[1])
    elseif mode == "laptop" then land_on(dev.internal.output) end
  end
  if mode == "dual" and prev ~= "dual" then D.restore_pending = true end
  publish(lid, ext)
end

function D.can(mode)                 -- would this override be honored right now?
  return allowed(mode, lid_closed(), externals())
end

function D.set_override(mode)        -- nil = back to automatic
  D.override = mode
  D.reconcile("override")
end

---------------------------------------------------------------- events

-- plug-in is debounced: docks fire several hotplug events per plug.
-- unplug is handled at once as well: if the unplugged output was the only one lit,
-- Hyprland has no monitor left and the debounce timer may never fire
-- a oneshot timer is dead once it has fired (set_enabled(true) no longer restarts it),
-- so every hotplug burst gets a fresh one and the pending one is cancelled
local pending
local function soon()
  if pending then pending:set_enabled(false) end
  pending = hl.timer(function()
    pending = nil
    D.reconcile("hotplug")
  end, { timeout = 400, type = "oneshot" })
end

hl.on("monitor.added", function() log("event monitor.added"); soon() end)
hl.on("monitor.removed", function()
  log("event monitor.removed")
  D.reconcile("removed")
  soon()
end)
hl.bind("switch:on:Lid Switch",  function() D.reconcile("lid") end, { locked = true })
hl.bind("switch:off:Lid Switch", function() D.reconcile("lid") end, { locked = true })

---------------------------------------------------------------- manual (bound in hyprland.lua)

-- dual ↔ external. Does nothing in laptop mode or with the lid closed (already external).
-- Unplugging or a lid change clears the override, so unplugged always ends in laptop.
function D.toggle()
  if D.mode == "dual" then D.set_override("external")
  elseif D.override then D.set_override(nil) end
end

function D.redetect()                -- clear override, force re-apply
  D.override = nil
  D.reconcile("manual", true)
end

---------------------------------------------------------------- workspaces

-- with one screen the rule's monitor may be absent; Hyprland then opens the workspace
-- on the focused monitor, so 1..split land on whichever screen is lit
local function home(i)
  return i <= dev.workspace_split and dev.ultrawide.output or dev.internal.output
end

for i = 1, 10 do
  hl.workspace_rule({ workspace = tostring(i), monitor = home(i) })
end

local function is_on(m, sel)
  if not m then return false end
  if sel:sub(1, 5) == "desc:" then return m.description:find(sel:sub(6), 1, true) == 1 end
  return m.name == sel
end

-- send workspaces back to their home monitor after entering dual
local function restore()
  local focused = hl.get_active_workspace()
  for i = 1, 10 do
    local ws = hl.get_workspace(i)
    if ws and not is_on(ws.monitor, home(i)) then
      hl.dispatch(hl.dsp.workspace.move({ workspace = i, monitor = home(i) }))
    end
  end
  if focused then hl.dispatch(hl.dsp.focus({ workspace = focused.id })) end
end

hl.on("monitor.layout_changed", function()
  if D.restore_pending then
    D.restore_pending = false
    restore()
  end
end)

---------------------------------------------------------------- apply

D.reconcile("load", true)
