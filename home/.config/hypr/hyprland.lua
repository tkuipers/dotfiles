-- Hyprland, kept in step with the sway config: same keys, workspaces and apps.
-- Colours come from the theme (Alt+Shift+t picks one); theme-apply renders them to
-- ~/.local/state/theme/hypr/theme.lua.

local home = os.getenv("HOME")
local bin = home .. "/.local/bin/"
local ok, theme = pcall(dofile, home .. "/.local/state/theme/hypr/theme.lua")
if not ok then
    theme = { lavender = "b4befe", mauve = "cba6f7", sapphire = "74c7ec", surface0 = "313244",
        surface1 = "45475a", peach = "fab387", pink = "f5c2e7", text = "cdd6f4", crust = "11111b",
        shadow = "11111bcc", cursor = "phinger-cursors-dark" }
end
local function rgb(hex) return "rgb(" .. hex .. ")" end
local function rgba(hex, alpha) return "rgba(" .. hex .. (alpha or "ff") .. ")" end

local mod = "ALT"
local term = "alacritty"

---- Monitors ----
-- The left monitor is the first viewer, the right one the second. Weaselway's
-- Hyprland follows each viewer's window size by itself.
hl.monitor({ output = "Virtual-1", mode = "preferred", position = "0x0", scale = 1 })
hl.monitor({ output = "Virtual-2", mode = "preferred", position = "auto-right", scale = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.device({ name = "weaselway-pointer", output = "Virtual-1" })
hl.device({ name = "weaselway-pointer-2", output = "Virtual-2" })

hl.env("XCURSOR_THEME", theme.cursor or "phinger-cursors-dark")
hl.env("XCURSOR_SIZE", "24")

---- Autostart, as in the sway config ----
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor " .. (theme.cursor or "phinger-cursors-dark") .. " 24")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd(bin .. "win-media-keys")
    hl.exec_cmd(bin .. "health-log")
    hl.exec_cmd(bin .. "win-to-clipboard")
    hl.exec_cmd("wl-paste --type text --watch " .. bin .. "clipboard-to-win text")
    hl.exec_cmd("wl-paste --type image/png --watch " .. bin .. "clipboard-to-win image")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image/png --watch cliphist store")
    hl.exec_cmd(term .. " --class startup-term")
    hl.exec_cmd("teams-for-linux")
    hl.exec_cmd("prospect-mail")
    hl.exec_cmd("env GSK_RENDERER=cairo swaync -s " .. home .. "/.local/state/theme/swaync/style.css")
    hl.exec_cmd(bin .. "waybar-themed")
    -- Pill tabs over group bars; software Qt Quick because d3d12 garbles GPU text colours
    hl.exec_cmd("env QT_QUICK_BACKEND=software quickshell -p " .. home .. "/.config/quickshell/grouptabs")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd(bin .. "wallpaper-cycle")
end)
-- Every config load, like sway's exec_always
hl.exec_cmd(bin .. "theme-apply")

---- Look ----
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 3,
        border_size = 2,
        col = {
            -- A gradient through three theme colours that slowly turns (borderangle below)
            active_border = { colors = { rgb(theme.lavender), rgb(theme.mauve), rgb(theme.sapphire) }, angle = 45 },
            inactive_border = rgba(theme.surface1, "aa"),
        },
        layout = "dwindle",
        resize_on_border = true,
        snap = { enabled = true },
    },
    decoration = {
        rounding = 10,
        rounding_power = 4,  -- squircle corners
        dim_special = 0.35,  -- dims the workspace behind a scratchpad
        -- Unfocused windows recede a touch; kept faint, they're still read
        dim_inactive = true,
        dim_strength = 0.06,
        -- glass-unfocused's numbers, built in here
        active_opacity = 0.96,
        inactive_opacity = 0.835,
        shadow = {
            enabled = true,
            -- Only floating windows keep a shadow (see the rule below), and a deep one,
            -- so they look lifted off the tiles
            range = 36,
            render_power = 2,
            scale = 1.0,
            offset = "0 8",
            color = "rgba(" .. theme.shadow .. ")",
        },
        blur = {
            enabled = true,
            size = 4,
            passes = 2,
            noise = 0.02,
            vibrancy = 0.1696,
            popups = true,   -- menus and tooltips are glass too
            special = true,  -- so is the backdrop behind a scratchpad
        },
        -- A soft halo in the theme's accent around the focused window
        glow = {
            enabled = true,
            range = 14,
            render_power = 3,
            color = rgba(theme.lavender, "40"),
            color_inactive = rgba(theme.crust, "00"),
        },
    },
    group = {
        col = {
            border_active = { colors = { rgb(theme.peach), rgb(theme.mauve) }, angle = 45 },
            border_inactive = rgba(theme.surface1, "aa"),
        },
        -- Kept only to reserve the strip above a group: it draws nothing, and
        -- quickshell's grouptabs overlay puts floating pill tabs there instead.
        -- height must match stripHeight in quickshell/grouptabs/shell.qml.
        groupbar = {
            font_family = "JetBrainsMono Nerd Font Propo",
            gradients = false,
            render_titles = true, -- without titles the strip collapses; they're transparent
            text_color = rgba(theme.text, "00"),
            text_color_inactive = rgba(theme.text, "00"),
            text_color_locked_active = rgba(theme.text, "00"),
            text_color_locked_inactive = rgba(theme.text, "00"),
            height = 22,
            indicator_height = 0,
            font_size = 11,
            blur = false,
            col = { active = rgba(theme.mauve, "00"), inactive = rgba(theme.surface0, "00"),
                locked_active = rgba(theme.mauve, "00"), locked_inactive = rgba(theme.surface0, "00") },
        },
    },
    -- Alt+n cycles to this niri-style layout: an endless strip of columns
    scrolling = {
        column_width = 0.6,
        follow_focus = true,
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true, smart_resizing = true },
    master = { new_status = "slave", mfact = 0.6 },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        font_family = "JetBrainsMono Nerd Font Propo",
        -- mpv or imv started from a terminal takes the terminal's place until it closes
        enable_swallow = true,
        swallow_regex = "^(alacritty|Alacritty|startup-term|scratchterm)$",
        focus_on_activate = false,
    },
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        float_switch_override_focus = 0,
    },
    -- Weaselway's virtual displays don't show a hardware cursor plane reliably, so
    -- Hyprland draws the pointer itself
    cursor = { hide_on_key_press = true, zoom_rigid = false, no_hardware_cursors = 1 },
    binds = { workspace_back_and_forth = true, allow_workspace_cycles = true },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.08 } } })
hl.curve("easy", { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })
hl.curve("bouncy", { type = "spring", mass = 1, stiffness = 120, dampening = 11 })
-- Windows pop in with a little bounce and spring into place when they move
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, spring = "bouncy", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "easeOutQuint", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, spring = "bouncy" })
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "almostLinear" })
-- The gradient border goes round once every ten seconds
hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "linear", style = "loop" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "almostLinear" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 4, bezier = "almostLinear" })
-- Bars and menus slide in from their edge
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3.5, bezier = "overshot", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "easeOutQuint", style = "slide" })
-- Workspaces slide sideways; scratchpads drop in from the top
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.5, bezier = "easeOutQuint", style = "slidefade 15%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3.5, bezier = "overshot", style = "slidefadevert -30%" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 4, bezier = "easeOutQuint" })

-- Bars and panels get blur behind them, as with SwayFX's layer_effects
for _, ns in ipairs({ "waybar", "wofi", "swaync-control-center", "swaync-notification-window", "logout_dialog" }) do
    hl.layer_rule({ name = "blur-" .. ns, match = { namespace = "^" .. ns .. "$" }, blur = true, ignore_alpha = 0.01 })
end
-- The launcher and logout screen pop up from the middle instead of sliding
hl.layer_rule({ name = "pop-wofi", match = { namespace = "^(wofi|logout_dialog)$" }, animation = "popin 85%" })
-- Notifications slide in from the right (the panel has its own animation)
hl.layer_rule({ name = "slide-swaync", match = { namespace = "^swaync-notification-window$" }, animation = "slide right" })
-- Wallpaper changes fade rather than slide
-- Group tab pills (quickshell grouptabs) are frosted glass like the bar
hl.layer_rule({ name = "blur-grouptabs", match = { namespace = "^grouptabs$" }, blur = true, ignore_alpha = 0.3 })
hl.layer_rule({ name = "fade-wallpaper", match = { namespace = "^awww" }, animation = "fade" })

---- Workspaces and apps ----
hl.workspace_rule({ workspace = "1", monitor = "Virtual-1", default = true })
hl.workspace_rule({ workspace = "2", monitor = "Virtual-2", default = true })

local assign = {
    ["startup-term"] = 2,
    ["brave-browser|Brave-browser"] = 1,
    ["code|Code|code-oss|cursor|Cursor|neovide|nvim-qt"] = 3,
    ["teams-for-linux|teams|microsoft-teams|microsoft teams"] = 4,
    ["[Cc]ider"] = 5,
    -- Mail joins Teams as a tab (see tabs-4 below)
    ["prospect-mail"] = 4,
}
for class, ws in pairs(assign) do
    hl.window_rule({ name = "assign-" .. ws .. "-" .. class, match = { class = "^(" .. class .. ")$" }, workspace = tostring(ws) .. " silent" })
end
-- Teams and mail share workspace 4 as tabs, each one full size (Alt+Tab flips).
-- The rule makes each open as a group; the hook below folds the second into the
-- first, since rules can't join a group on a workspace you aren't looking at.
local tabs4 = { ["teams-for-linux"] = true, teams = true, ["microsoft-teams"] = true, ["microsoft teams"] = true, ["prospect-mail"] = true }
hl.window_rule({ name = "tabs-4", match = { class = "^(teams-for-linux|teams|microsoft-teams|microsoft teams|prospect-mail)$" }, group = "set" })
local function xOf(w) return type(w.at) == "table" and (w.at.x or w.at[1]) or 0 end
hl.on("window.open", function(w)
    if not tabs4[w.class] then return end
    hl.timer(function()
        local new = hl.get_window("address:" .. w.address)
        if not new or new.floating then return end
        local host
        for _, o in ipairs(hl.get_workspace_windows("4")) do
            if o.address ~= new.address and tabs4[o.class] and not o.floating then host = o break end
        end
        if not host or (new.group and host.group and new.group.size > 1) then return end
        local back = hl.get_active_window()
        hl.dispatch(hl.dsp.focus({ window = "address:" .. new.address }))
        hl.dispatch(hl.dsp.window.move({ into_group = xOf(host) < xOf(new) and "l" or "r" }))
        if back and back.address ~= new.address then hl.dispatch(hl.dsp.focus({ window = "address:" .. back.address })) end
    end, { timeout = 300, type = "oneshot" })
end)

-- Scratchpads: each app gets a hidden special workspace, shown and hidden by wm scratch
local scratch = {
    scratchterm = "monitor_w*0.7 monitor_h*0.6",
    scratchnotes = "monitor_w*0.3 monitor_h*0.45",
    scratchmixer = "monitor_w*0.45 monitor_h*0.55",
}
for app, size in pairs(scratch) do
    hl.window_rule({
        name = "scratch-" .. app,
        match = { class = "^" .. app .. "$" },
        float = true,
        size = size,
        center = true,
        workspace = "special:" .. app,
    })
end

hl.window_rule({ name = "float-satty", match = { class = "^com.gabm.satty$" }, float = true })
-- File dialogs float and dim everything behind them
hl.window_rule({ name = "float-dialogs", match = { title = "^((Open|Save) (File|Folder|As)|File Upload)$" }, float = true, pin = true, dim_around = true, center = true })
-- Picture-in-picture: small, on top, bottom right of the right screen
hl.window_rule({
    name = "float-pip",
    match = { title = "^Picture-in-Picture$" },
    float = true,
    pin = true,
    monitor = "Virtual-2",
    size = "480 270",
    move = "monitor_w-496 monitor_h-286",
})
hl.window_rule({ name = "float-media", match = { class = "^(qemu|zenmonitor|mpv|imv|timeshift-gtk|telegram-desktop)$" }, float = true })
-- Video and pictures stay fully opaque
hl.window_rule({ name = "opaque-media", match = { class = "^(mpv|imv)$" }, opacity = "1.0 override 1.0 override" })
hl.window_rule({ name = "opaque-pip", match = { title = "^Picture-in-Picture$" }, opacity = "1.0 override 1.0 override", keep_aspect_ratio = true })
-- Tiled windows sit flat; floating ones keep the shadow
hl.window_rule({ name = "flat-tiles", match = { float = false }, no_shadow = true })
-- Scratchpads stand apart from ordinary floating windows by their warm border
hl.window_rule({
    name = "scratch-border",
    match = { workspace = "s[true]" },
    border_color = { colors = { rgb(theme.peach), rgb(theme.pink) }, angle = 45 },
})
-- Smart gaps: a window alone on a workspace fills the screen with no gaps or
-- border, but keeps its rounded corners
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({ name = "alone-tv1", match = { float = false, workspace = "w[tv1]" }, border_size = 0 })
hl.window_rule({ name = "alone-f1", match = { float = false, workspace = "f[1]" }, border_size = 0 })
hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })

---- Keys: the sway bindings ----
local function bind(keys, action, opts) hl.bind(mod .. " + " .. keys, action, opts) end
local exec = hl.dsp.exec_cmd

bind("Return", exec(term), { description = "terminal" })
bind("SHIFT + Q", hl.dsp.window.close(), { description = "close the window" })
bind("D", exec("wofi"), { description = "app launcher" })
bind("SHIFT + C", exec("hyprctl reload"), { description = "reload Hyprland" })
bind("SHIFT + T", exec(bin .. "theme-set"), { description = "pick a theme" })
bind("SHIFT + W", exec(bin .. "session-switch"), { description = "switch compositor (this once)" })
bind("SHIFT + E", exec("wlogout"), { description = "log out / power" })
bind("SHIFT + S", exec(bin .. "screenshot"), { description = "screenshot a region" })
bind("SHIFT + V", exec(bin .. "clipboard-pick"), { description = "clipboard history" })
bind("SHIFT + M", exec(bin .. "scratch-toggle mixer"), { description = "audio mixer" })
bind("SPACE", exec(bin .. "scratch-tap"), { description = "scratch terminal (tap) / notes (hold)" })

local dirs = { h = "left", j = "down", k = "up", l = "right", left = "left", down = "down", up = "up", right = "right" }
for key, dir in pairs(dirs) do
    bind(key, hl.dsp.focus({ direction = dir }), { description = "focus " .. dir })
    bind("SHIFT + " .. key, hl.dsp.window.move({ direction = dir }), { description = "move the window " .. dir })
end

for i = 1, 10 do
    local key = i % 10
    bind(tostring(key), hl.dsp.focus({ workspace = i }), { description = "workspace " .. i })
    bind("SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }), { description = "send the window to workspace " .. i })
end

bind("greater", hl.dsp.workspace.move({ monitor = "r" }), { description = "move workspace to the right screen" })
bind("less", hl.dsp.workspace.move({ monitor = "l" }), { description = "move workspace to the left screen" })
bind("SHIFT + period", hl.dsp.workspace.move({ monitor = "r" }), { description = "move workspace to the right screen" })
bind("SHIFT + comma", hl.dsp.workspace.move({ monitor = "l" }), { description = "move workspace to the left screen" })

-- sway's split/layout keys, as close as dwindle and groups get
bind("B", hl.dsp.layout("togglesplit"), { description = "flip the split" })
bind("V", hl.dsp.layout("togglesplit"), { description = "flip the split" })
bind("E", hl.dsp.layout("togglesplit"), { description = "flip the split" })
bind("W", hl.dsp.group.toggle(), { description = "group windows as tabs" })
bind("S", hl.dsp.group.toggle(), { description = "group windows as tabs" })
bind("TAB", hl.dsp.group.next(), { description = "next tab in the group" })
bind("F", hl.dsp.window.fullscreen(), { description = "fullscreen" })
bind("SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }), { description = "float / tile" })
bind("MINUS", hl.dsp.workspace.toggle_special("scratchpad"), { description = "show the scratchpad" })
bind("SHIFT + MINUS", hl.dsp.window.move({ workspace = "special:scratchpad" }), { description = "send the window to the scratchpad" })

bind("G", hl.dsp.group.lock_active({ action = "toggle" }), { description = "lock the tab group" })
bind("P", hl.dsp.window.pin(), { description = "pin the window on top" })
bind("grave", hl.dsp.focus({ workspace = "previous" }), { description = "previous workspace" })
-- Alt+u goes to whatever asked for attention (Teams, mail)
bind("U", function()
    local w = hl.get_urgent_window()
    if w then hl.dispatch(hl.dsp.focus({ window = "address:" .. w.address })) end
end, { description = "go to the window asking for attention" })
bind("SHIFT + R", exec(bin .. "record-toggle"), { description = "record a region / stop" })
bind("slash", exec(bin .. "keys"), { description = "this list" })

-- Alt+n: dwindle -> master -> scrolling, with a note saying which
local layouts = { "dwindle", "master", "scrolling" }
bind("N", function()
    local now = hl.get_config("general.layout")
    local nextLayout = layouts[1]
    for i, name in ipairs(layouts) do
        if name == now then nextLayout = layouts[i % #layouts + 1] end
    end
    hl.config({ general = { layout = nextLayout } })
    hl.notification.create({ text = "Layout: " .. nextLayout, timeout = 1200, icon = "info" })
end, { description = "next layout" })

-- Alt+z zooms around the cursor; Alt+scroll zooms in and out, Alt+Shift+z resets
local function zoom(factor)
    hl.config({ cursor = { zoom_factor = math.max(1, math.min(factor, 6)) } })
end
bind("Z", function() zoom(hl.get_config("cursor.zoom_factor") > 1 and 1 or 2) end, { description = "zoom in on the cursor" })
bind("SHIFT + Z", function() zoom(1) end, { description = "reset zoom" })
bind("mouse_down", function() zoom(hl.get_config("cursor.zoom_factor") * 1.25) end, { description = "zoom in" })
bind("mouse_up", function() zoom(hl.get_config("cursor.zoom_factor") / 1.25) end, { description = "zoom out" })

bind("mouse:272", hl.dsp.window.drag(), { mouse = true, description = "drag: move the window" })
bind("mouse:273", hl.dsp.window.resize(), { mouse = true, description = "right-drag: resize the window" })

-- Resize mode, as sway's Alt+r
bind("R", hl.dsp.submap("resize"), { description = "resize mode" })
hl.define_submap("resize", function()
    local steps = {
        h = { -10, 0 }, j = { 0, 10 }, k = { 0, -10 }, l = { 10, 0 },
        left = { -10, 0 }, down = { 0, 10 }, up = { 0, -10 }, right = { 10, 0 },
    }
    for key, step in pairs(steps) do
        hl.bind(key, hl.dsp.window.resize({ x = step[1], y = step[2], relative = true }), { repeating = true })
    end
    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
end)

---- Living touches ----

-- A new window's border flashes bright, then settles back to the theme
hl.on("window.open", function(w)
    local sel = "address:" .. w.address
    hl.dispatch(hl.dsp.window.set_prop({ window = sel, prop = "active_border_color",
        value = rgb(theme.text) .. " " .. rgb(theme.lavender) .. " 45deg" }))
    hl.timer(function()
        hl.dispatch(hl.dsp.window.set_prop({ window = sel, prop = "active_border_color", value = "unset" }))
    end, { timeout = 450, type = "oneshot" })
end)

-- The focused border breathes: its gradient brightens and dims over eight seconds,
-- one step every half second, which the border animation blends together.
local function lighten(hex, amount)
    local out = ""
    for i = 1, 5, 2 do
        local v = tonumber(hex:sub(i, i + 1), 16)
        out = out .. string.format("%02x", math.floor(v + (255 - v) * amount + 0.5))
    end
    return out
end
local breath = { 0, 0.08, 0.16, 0.24, 0.32, 0.24, 0.16, 0.08 }
local step = 0
local function breathe()
    step = step % #breath + 1
    local a = breath[step]
    hl.config({ general = { col = { active_border = {
        colors = { rgb(lighten(theme.lavender, a)), rgb(lighten(theme.mauve, a)), rgb(lighten(theme.sapphire, a)) },
        angle = 45,
    } } } })
end

-- The weather outside (weather-now keeps the reading in $XDG_RUNTIME_DIR/weather-now)
-- shows on the screens without the mouse: rain runs down them, and below -20
-- frost creeps up them. The glass itself (blur, the bar) stays the same in all
-- weathers; only the focused window's halo takes the weather's colour.
-- `glass frost` (or snowy, rainy, cloudy, sunny) previews one; `glass auto` goes back.
local glass = {
    frost  = { glow = "a3ecff", shader = "frost.frag" },
    snowy  = { glow = "edecee", shader = "snow.frag" },
    rainy  = { glow = "6fd3ff", shader = "rain.frag" },
    cloudy = { glow = "8f8c9e", shader = "fog.frag" },
    sunny  = { glow = "ffca85", shader = "sun.frag" },
}
-- The weather now, from weather-now's cache (see its header), with sensible
-- values for anything missing. The shaders get these as #defines.
local conditions = {}
local function readConditions()
    local c = { code = 0, temp = 10, cover = 0, precip = 0, snow = 0, wind = 10, winddir = 270, humidity = 60 }
    local f = io.open((os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/weather-now")
    if f then
        local v = { f:read("*n", "*n", "*n", "*n", "*n", "*n", "*n", "*n", "*n") }
        f:close()
        c.code, c.temp = v[1] or c.code, v[2] or c.temp
        -- Older answers lack the rest: guess the cloud from the code
        c.cover = v[4] or ({ [0] = 0, [1] = 20, [2] = 50 })[c.code] or 50
        c.precip, c.snow, c.wind = v[5] or c.precip, v[6] or c.snow, v[7] or c.wind
        c.winddir, c.humidity = v[8] or c.winddir, v[9] or c.humidity
    end
    return c
end

local function weather()
    conditions = readConditions()
    local c = conditions
    -- A preview from `glass`: a name, then optional key=value overrides
    -- (cover, precip, snow, wind, winddir, humidity, temp, code), or a bare
    -- number for the sun's cloud cover
    local override = io.open(home .. "/.local/state/theme/hypr/glass")
    if override then
        local line = override:read("*l") or ""
        override:close()
        local name, rest = line:match("^(%a+)%s*(.*)$")
        if name and glass[name] then
            local bare = rest:match("^(%d+)%s*$")
            if bare then c.cover = tonumber(bare) end
            for key, value in rest:gmatch("(%a+)=([%d%.%-]+)") do
                if c[key] then c[key] = tonumber(value) end
            end
            return name
        end
    end
    local code, temp = c.code, c.temp
    -- Snow and rain (drizzle, showers, storms) win; overcast or fog is cloudy;
    -- a clear sky at -10 or colder is frost; otherwise (clear to partly cloudy)
    -- it's the sun, its beams set by the cloud cover
    if (code >= 71 and code <= 77) or code == 85 or code == 86 then return "snowy" end
    if code >= 51 then return "rainy" end
    if code >= 3 then return "cloudy" end
    if code <= 1 and temp <= -10 then return "frost" end
    return "sunny"
end

-- The weather's shader. It follows focus by itself: Weaselway's Hyprland patch
-- tells screen shaders which screen has focus and since when, so it closes in
-- from the edges of the screen just left and clears out from the middle of the
-- one reached (see reach() in the shaders) without being reloaded.
--
-- It's loaded as a copy with the weather filled into its #defines (only the
-- ones it has): DAY_FRACTION (0 at 6:00 to 1 at 18:00, by the hour),
-- CLOUD_COVER %, PRECIP mm/h, SNOWFALL cm/h, WIND km/h, WIND_DIR (degrees it
-- blows from), HUMIDITY %, TEMP °C, STORM (1 in a thunderstorm), FOG (1 in fog).
-- The copy is only rewritten, and the shader recompiled, when those change.
local weatherShader      -- file in shaders/, or nil for none
local loadedSource
local function defines()
    local c = conditions
    local hour = os.date("*t").hour
    return {
        DAY_FRACTION = string.format("%.3f", (hour + 0.5 - 6) / 12),
        CLOUD_COVER = string.format("%.1f", c.cover),
        PRECIP = string.format("%.2f", c.precip),
        SNOWFALL = string.format("%.2f", c.snow),
        WIND = string.format("%.1f", c.wind),
        WIND_DIR = string.format("%.1f", c.winddir),
        HUMIDITY = string.format("%.1f", c.humidity),
        TEMP = string.format("%.1f", c.temp),
        STORM = c.code >= 95 and "1.0" or "0.0",
        FOG = (c.code == 45 or c.code == 48) and "1.0" or "0.0",
    }
end
local function loadWeatherShader(force)
    if not weatherShader then
        loadedSource = nil
        hl.config({ decoration = { screen_shader = "" } })
        hl.config({ debug = { damage_tracking = 2 } })
        return
    end
    local f = io.open(home .. "/.config/hypr/shaders/" .. weatherShader)
    if not f then return end
    local source = f:read("*a")
    f:close()
    for name, value in pairs(defines()) do
        source = source:gsub("#define " .. name .. " [%d%.%-]+", "#define " .. name .. " " .. value, 1)
    end
    if source == loadedSource and not force then return end
    loadedSource = source
    local path = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-weather-" .. weatherShader
    local out = io.open(path, "w")
    if not out then return end
    out:write(source)
    out:close()
    -- Its animation needs Hyprland to redraw every frame, so damage tracking is
    -- off while a shader runs: switched before it goes on, and back after it
    -- comes off, so Hyprland never warns about it. Hyprland only reloads a
    -- shader whose path changed, hence the blank first.
    hl.config({ debug = { damage_tracking = 0 } })
    hl.config({ decoration = { screen_shader = "" } })
    hl.config({ decoration = { screen_shader = path } })
end

local shownWeather
local function applyWeather()
    local now = weather()
    if now ~= shownWeather then
        shownWeather = now
        -- The focused window's halo takes the weather's colour too
        hl.config({ decoration = { glow = { color = rgba(glass[now].glow, "50") } } })
        weatherShader = glass[now].shader
        loadWeatherShader(true)
    else
        -- Same weather, but its rate, wind or hour may have moved on
        loadWeatherShader(false)
    end
end
applyWeather()

-- Timers need Hyprland's event loop: creating one while the config loads at
-- startup crashes it. So they start once Hyprland is up, and again after each reload,
-- which throws the old ones away with the rest of the Lua state.
local timersStarted = false
local function startTimers()
    if timersStarted then return end
    timersStarted = true
    hl.timer(breathe, { timeout = 500, type = "repeat" })
    hl.timer(applyWeather, { timeout = 300000, type = "repeat" })
end
-- The checker (--verify-config) fires these hooks too, with no monitors and no
-- event loop, so only start them when there's a screen. If a viewer connects
-- after Hyprland starts, its monitor appearing starts them.
local function startIfRunning()
    if #hl.get_monitors() > 0 then startTimers() end
end
hl.on("hyprland.start", startIfRunning)
hl.on("config.reloaded", startIfRunning)
hl.on("monitor.added", startIfRunning)
