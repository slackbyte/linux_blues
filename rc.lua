-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
local vicious = require("vicious")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(awful.util.getdir("config") .. "/themes/linux_blues/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "xterm"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- set naughty presets
naughty.config.defaults =
{
    timeout       = 5,
    screen        = 1,
    position      = "bottom_right",
    margin        = 4,
    gap           = 1,
    ontop         = true,
    font          = beautiful.font,
    icon          = nil,
    icon_size     = 16,
    fg            = beautiful.fg_normal,
    bg            = beautiful.bg_normal,
    border_color  = beautiful.border_focus,
    border_width  = 1,
    hover_timeout = nil
}

--naughty.config.presets.critical = { fg = beautiful.bg_urgent,

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.floating,  --------- 1
    awful.layout.suit.tile,  ------------- 2
    awful.layout.suit.tile.left,  -------- 3
    awful.layout.suit.tile.bottom,  ------ 4
    awful.layout.suit.tile.top,  --------- 5
    awful.layout.suit.fair,  ------------- 6
    awful.layout.suit.fair.horizontal,  -- 7
    awful.layout.suit.spiral,  ----------- 8
    awful.layout.suit.spiral.dwindle,  --- 9
    awful.layout.suit.max,  -------------- 10
    awful.layout.suit.max.fullscreen,  --- 11
    awful.layout.suit.magnifier  --------- 12
}
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    --tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
    tags[s] = awful.tag( { "⚀", "⚁", "⚂", "⚃", "⚄", "⚅" }, s, layouts[2]) -- removed icons: "⚈", "⚉", "▪" 
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
mymainmenu = awful.menu() -- Disable the menu... who actually uses that?
mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

function pangoify (attribute, value, text)
   return "<span " .. attribute .. "=\"" .. value .. "\">" .. text .. "</span>"
end

local mouseIsVisible = true
local screenWidth = 1366
local screenHeight = 768
local mouseRestoreLoc = { x = 0, y = 0 }

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox
-- Create a textclock widget
local calendar = nil
local offset = 0

function remove_calendar()
   if calendar ~= nil then
      naughty.destroy(calendar)
      calendar = nil
      offset = 0
   end
end

function add_calendar(inc_offset)
   local save_offset = offset
   remove_calendar()
   offset = save_offset + inc_offset
   local datespec = os.date("*t")
   datespec = datespec.year * 12 + datespec.month - 1 + offset
   datespec = (datespec % 12 + 1) .. " " .. math.floor(datespec / 12)
   local cal = awful.util.pread("cal -m " .. datespec)
   cal = string.gsub(cal, "^%s*(.-)%s*$", "%1")
   calendar = naughty.notify({
      text = string.format('<span font_desc="%s">%s</span>', "monospace", cal),
      position = "top_right", timeout = 0, hover_timeout = 0.5,
      width = 160
   })
end

mytextclock = awful.widget.textclock()
mytextclock:connect_signal("mouse::enter", function() add_calendar(0) end)
mytextclock:connect_signal("mouse::leave", remove_calendar)
mytextclock:buttons(awful.util.table.join(
         awful.button({ }, 4, function() add_calendar(-1) end),
         awful.button({ }, 5, function() add_calendar(1) end)
   ))

-- Create a wibox for each screen and add it
top_wibox = {}
bottom_wibox = {}

mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))


-- Widget margins
left_margin = 3
right_margin = 3
top_margin = 4
bottom_margin = 4

-- widget separator_widget
separator_widget = wibox.widget.textbox()
separator_widget:set_markup(pangoify("fgcolor", theme.grey, "::"))
separator_layout = wibox.layout.margin(separator_widget, left_margin, right_margin, top_margin, bottom_margin)


-- cpu widget
vicious.cache(vicious.widgets.cpu)

cpu_text_widget = wibox.widget.textbox()
cpu_text_widget:set_text("CPU")
cpu_text_layout = wibox.layout.margin(cpu_text_widget, left_margin, right_margin, top_margin, bottom_margin)

cpu_graph_widget = awful.widget.graph()
cpu_graph_widget:set_width(60)
cpu_graph_widget:set_height(10)
cpu_graph_widget:set_background_color(beautiful.bg_normal)
cpu_graph_widget:set_border_color(beautiful.fg_normal)
cpu_graph_widget:set_color(beautiful.fg_focus)
vicious.register(cpu_graph_widget, vicious.widgets.cpu, "$1", 7)
cpu_graph_layout = wibox.layout.margin(cpu_graph_widget, left_margin, right_margin, top_margin, bottom_margin)

cpu_freq_widget = wibox.widget.textbox()
vicious.register(cpu_freq_widget, vicious.widgets.cpufreq,
      function (widget, args)
         if args[1] < 1000 then
            return pangoify("fgcolor", beautiful.fg_focus, args[1] .. " MHz")
         else
            return pangoify("fgcolor", beautiful.fg_focus, args[2] .. " GHz")
         end
      end,
7, "cpu0")
cpu_freq_layout = wibox.layout.margin(cpu_freq_widget, left_margin, right_margin, top_margin, bottom_margin)


-- battery widget
bat_text_widget = wibox.widget.textbox()
bat_text_widget:set_text("BAT")
bat_text_layout = wibox.layout.margin(bat_text_widget, left_margin, right_margin, top_margin, bottom_margin)

bat_tooltip = awful.tooltip({ })

bat_bar_widget = awful.widget.progressbar()
bat_bar_widget:set_width(60)
bat_bar_widget:set_height(10)
bat_bar_widget:set_max_value(1)
bat_bar_widget:set_background_color(beautiful.bg_normal)
vicious.register(bat_bar_widget, vicious.widgets.bat, 
    function (widget, args)
        if args[1] ~= "+" then
            widget:set_border_color(beautiful.fg_normal)
            if args[2] <= 10 then
                widget:set_color(beautiful.bg_urgent)
                naughty.notify({
                    title = "BATTERY:",
                    text = args[2] .. "%",
                    position = "bottom_left",
                    timeout = 28,
                    preset = naughty.config.presets.critical
                })
            else
                widget:set_color(beautiful.fg_focus)
            end
        else
            widget:set_color(beautiful.fg_focus)
            widget:set_border_color("#16D016")
        end

        -- create tooltip
        if args[3] ~= "N/A" then
            bat_tooltip:set_text( " " .. args[3] .. " (" .. args[2] .. "%) " )
        else
            bat_tooltip:set_text( " " .. args[2] .. "% " )
        end

        return args[2]
    end,
29, "BAT0")
bat_bar_layout = wibox.layout.margin(bat_bar_widget, left_margin, right_margin, top_margin, bottom_margin)
bat_tooltip:add_to_object(bat_bar_widget)

-- volume widget
vol_text_widget = wibox.widget.textbox()
vol_text_widget:set_text("VOL")
vol_text_layout = wibox.layout.margin(vol_text_widget, left_margin, right_margin, top_margin, bottom_margin)

vol_tooltip = awful.tooltip({ })

vol_bar_widget = awful.widget.progressbar()
vol_bar_widget:set_width(60)
vol_bar_widget:set_height(10)
vol_bar_widget:set_background_color(beautiful.bg_normal)
vol_bar_widget:set_color(beautiful.fg_focus)
vicious.register(vol_bar_widget, vicious.widgets.volume, 
    function (widget, args)
        if args[2] == "♫" then
            widget:set_border_color(beautiful.fg_normal)
            vol_tooltip:set_text( " " .. args[1] .. "% " )
            return args[1]
        else
            widget:set_border_color(beautiful.bg_urgent)
            vol_tooltip:set_text( " muted " )
            return 0
        end
    end,
2, "Master")
vicious.unregister(vol_bar_widget, true)
vol_bar_layout = wibox.layout.margin(vol_bar_widget, left_margin, right_margin, top_margin, bottom_margin)
vol_tooltip:add_to_object(vol_bar_widget)


-- net widgets
upload_text_widget = wibox.widget.textbox()
upload_text_widget:set_text("UP")
upload_text_layout = wibox.layout.margin(upload_text_widget, left_margin, right_margin, top_margin, bottom_margin)

upload_graph_widget = awful.widget.graph()
upload_graph_widget:set_width(60)
upload_graph_widget:set_height(10)
upload_graph_widget:set_background_color(beautiful.bg_normal)
upload_graph_widget:set_color(beautiful.fg_focus)
vicious.register(upload_graph_widget, vicious.widgets.net, 
    function (widget, args)
            return args["{wlan0 up_kb}"]
    end,
3)
upload_graph_layout = wibox.layout.margin(upload_graph_widget, left_margin, right_margin, top_margin, bottom_margin)

download_text_widget = wibox.widget.textbox()
download_text_widget:set_text("DOWN")
download_text_layout = wibox.layout.margin(download_text_widget, left_margin, right_margin, top_margin, bottom_margin)

download_graph_widget = awful.widget.graph()
download_graph_widget:set_width(60)
download_graph_widget:set_height(10)
download_graph_widget:set_background_color(beautiful.bg_normal)
download_graph_widget:set_color(beautiful.fg_focus)
vicious.register(download_graph_widget, vicious.widgets.net, 
    function (widget, args)
            return args["{wlan0 down_kb}"]
    end,
3)
download_graph_layout = wibox.layout.margin(download_graph_widget, left_margin, right_margin, top_margin, bottom_margin)

network_text_widget = wibox.widget.textbox()
network_text_widget:set_text("WIFI")
network_text_layout = wibox.layout.margin(network_text_widget, left_margin, right_margin, top_margin, bottom_margin)

wifi_tooltip = awful.tooltip({ })

wifi_bar_widget = awful.widget.progressbar()
wifi_bar_widget:set_width(60)
wifi_bar_widget:set_height(10)
wifi_bar_widget:set_max_value(1)
wifi_bar_widget:set_background_color(beautiful.bg_normal)
wifi_bar_widget:set_color(beautiful.fg_focus)
essid_text_widget = wibox.widget.textbox()
vicious.register(wifi_bar_widget, vicious.widgets.wifi,
    function (widget, args)
        if args["{ssid}"] == "N/A" or args["{link}"] == 0 then
            essid_text_widget:set_text("")
            wifi_bar_widget:set_border_color(beautiful.bg_urgent)
            upload_graph_widget:set_border_color(beautiful.bg_urgent)
            download_graph_widget:set_border_color(beautiful.bg_urgent)
            return 0
        else
            essid_text_widget:set_markup("(" .. pangoify("fgcolor", beautiful.fg_focus, args["{ssid}"]) .. ")")
            wifi_tooltip:set_text( " " .. args["{link}"] .. "/70 ")
            wifi_bar_widget:set_border_color(beautiful.fg_normal)
            upload_graph_widget:set_border_color(beautiful.fg_normal)
            download_graph_widget:set_border_color(beautiful.fg_normal)
            return args["{link}"]
        end
    end,
7, "wlan0")
essid_text_layout = wibox.layout.margin(essid_text_widget, left_margin, right_margin, top_margin, bottom_margin)
wifi_bar_layout = wibox.layout.margin(wifi_bar_widget, left_margin, right_margin, top_margin, bottom_margin)
wifi_tooltip:add_to_object(wifi_bar_widget)


for s = 1, screen.count() do
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the top wibox
    top_wibox[s] = awful.wibox({ position = "top", screen = s })

    -- Widgets that are aligned to the left
    local top_left_layout = wibox.layout.fixed.horizontal()
    top_left_layout:add(mylauncher)
    top_left_layout:add(mytaglist[s])

    -- Widgets that are aligned to the right
    local top_right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then top_right_layout:add(wibox.widget.systray()) end
    top_right_layout:add(mytextclock)
    top_right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local top_layout = wibox.layout.align.horizontal()
    top_layout:set_left(top_left_layout)
    top_layout:set_middle(mytasklist[s])
    top_layout:set_right(top_right_layout)

    top_wibox[s]:set_widget(top_layout)

    -- Create the bottom wibox
    bottom_wibox[s] = awful.wibox({ position = "bottom", screen = s })

    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()

    -- Widgets that are aligned to the left
    local bottom_left_layout = wibox.layout.fixed.horizontal()
    bottom_left_layout:add(separator_layout)
    bottom_left_layout:add(cpu_text_layout)
    bottom_left_layout:add(cpu_graph_layout)
    bottom_left_layout:add(cpu_freq_layout)
    bottom_left_layout:add(separator_layout)
    bottom_left_layout:add(bat_text_layout)
    bottom_left_layout:add(bat_bar_layout)
    bottom_left_layout:add(separator_layout)
    bottom_left_layout:add(vol_text_layout)
    bottom_left_layout:add(vol_bar_layout)
    bottom_left_layout:add(separator_layout)

    -- Widgets that are aligned to the right
    local bottom_right_layout = wibox.layout.fixed.horizontal()
    bottom_right_layout:add(separator_layout)
    bottom_right_layout:add(download_graph_layout)
    bottom_right_layout:add(download_text_layout)
    bottom_right_layout:add(separator_layout)
    bottom_right_layout:add(upload_graph_layout)
    bottom_right_layout:add(upload_text_layout)
    bottom_right_layout:add(separator_layout)
    bottom_right_layout:add(essid_text_layout)
    bottom_right_layout:add(wifi_bar_layout)
    bottom_right_layout:add(network_text_layout)
    bottom_right_layout:add(separator_layout)

    local bottom_layout = wibox.layout.align.horizontal()
    bottom_layout:set_left(bottom_left_layout)
    bottom_layout:set_middle(mypromptbox[s])
    bottom_layout:set_right(bottom_right_layout)
    
    bottom_wibox[s]:set_widget(bottom_layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Control"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),

    -- Multimedia
    awful.key({},                    "XF86AudioMute", 
        function ()
            awful.util.spawn("amixer -q sset Master toggle")
            vicious.force({ vol_bar_widget })
        end),
    awful.key({ modkey, "Control" }, "-",
        function ()
            awful.util.spawn("amixer -q sset Master 2%-")
            vicious.force({ vol_bar_widget })
        end),
    awful.key({ modkey, "Control" }, "=",
        function ()
            awful.util.spawn("amixer -q sset Master 2%+")
            vicious.force({ vol_bar_widget })
        end),

    --awful.key({},                    "XF86AudioLowerVolume",
    --    function ()
    --        awful.util.spawn("amixer -q sset Master 2%-")
    --        vicious.force({ vol_bar_widget })
    --    end),
    --awful.key({},                    "XF86AudioRaiseVolume",
    --    function ()
    --        awful.util.spawn("amixer -q sset Master 2%+")
    --        vicious.force({ vol_bar_widget })
    --    end),
    awful.key({}, "Print", function () awful.util.spawn_with_shell("imlib2_grab /tmp/screenshot-$(date +%H%M%S).jpg") end),

    -- Shortcuts
    awful.key({ modkey },            "i",    function () awful.util.spawn(os.getenv("BROWSER")) end),
    awful.key({ modkey, "Shift"   }, "i",    function () awful.util.spawn(os.getenv("BROWSER2")) end),

    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end),
    awful.key({ modkey,           }, "]",
        function (c)
            if c.opacity < 0.95 then
                c.opacity = c.opacity + 0.05
            else
                c.opacity = 1.00
            end
            c.redraw()
        end),
    awful.key({ modkey,           }, "[",
        function (c)
            if c.opacity > 0.05 then
                c.opacity = c.opacity - 0.05
            else
                c.opacity = 0.00
            end
            c.redraw()
        end),
    awful.key({ modkey, "Shift"   }, "]", function (c) c.opacity = 1.00 end),
    awful.key({ modkey, "Shift"   }, "[", function (c) c.opacity = 0.05 end),

    awful.key({ modkey, "Shift"   }, "m", 
            function ()
                if mouseIsVisible then
                    mouseIsVisible = false
                    mouse.coords({ x=screenWidth*1.5, y=screenHeight*1.5 })
                else
                    mouse.coords({ x=screenWidth/2, y=screenHeight/2 })
                    mouseIsVisible = true
                end
            end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber))
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    { rule = { class = "XTerm" },
      properties = { opacity = 0.80, size_hints_honor = false } },
    { rule = { class = "google-chrome" },
      properties = { maximized_vertical = true, maximized_horizontal = true } }
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local title = awful.titlebar.widget.titlewidget(c)
        title:buttons(awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                ))

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(title)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
