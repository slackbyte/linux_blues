-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Widget library
require("vicious")
-- Notification library
require("naughty")
-- Dynamic tagging library
require("eminent")

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(awful.util.getdir("config") .. "/themes/archbyte/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "xterm -fg green -bg black"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- set naughty default configuration
naughty.config.default_preset.timeout       = 5
naughty.config.default_preset.screen        = 1
naughty.config.default_preset.position      = "bottom_right"
naughty.config.default_preset.margin        = 4
naughty.config.default_preset.gap           = 1
naughty.config.default_preset.ontop         = true
naughty.config.default_preset.font          = beautiful.font
naughty.config.default_preset.icon          = nil
naughty.config.default_preset.icon_size     = 16
naughty.config.default_preset.fg            = beautiful.naughty_fg
naughty.config.default_preset.bg            = beautiful.naughty_bg
naughty.config.default_preset.border_color  = beautiful.naughty_border
naughty.config.default_preset.border_width  = 1
naughty.config.default_preset.hover_timeout = nil

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
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

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
   -- Each screen has its own tag table.
   tags[s] = awful.tag( { "⚀", "⚁", "⚂", "⚃", "⚄", "⚅", "⚈", "⚉", "▪" }, s, layouts[6])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })

-- pangoify(attribute, value, text) = <span attribute="value">text</span>
function pangoify (attribute, value, text)
   return "<span " .. attribute .. "=\"" .. value .. "\">" .. text .. "</span>"
end

-- }}}

-- {{{ Wibox
-- Create a textclock widget with popup calendar
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

mytextclock = awful.widget.textclock({ align = "right" })
mytextclock:add_signal("mouse::enter", function() add_calendar(0) end)
mytextclock:add_signal("mouse::leave", remove_calendar)
mytextclock:buttons(awful.util.table.join(
         awful.button({ }, 4, function() add_calendar(-1) end),
         awful.button({ }, 5, function() add_calendar(1) end)
   ))

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
topwibox = {}
bottomwibox = {}

mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
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


-- widget spacer
spacer = widget({ type = "textbox" })
spacer.text = " "

-- widget separator
separator = widget({ type = "textbox" })
separator.text = pangoify("fgcolor", theme.arch_grey, " :: ")

-- battery widget
battext = widget({ type = "textbox" })
battext.text = "BAT "

battooltip = awful.tooltip({ })

batbar = awful.widget.progressbar()
batbar:set_width(60)
batbar:set_height(10)
batbar:set_max_value(1)
batbar:set_background_color(beautiful.bg_normal)
batbar:set_border_color(beautiful.widget_label)
awful.widget.layout.margins[batbar.widget] = { top = 4 }
vicious.register(batbar, vicious.widgets.bat, 
    function (widget, args)
        -- 
        if args[1] ~= "+" then
            if args[2] <= 10 then
                widget:set_color(beautiful.widget_urgent)
                naughty.notify({
                    title = "BATTERY:",
                    text = args[2] .. "%",
                    position = "bottom_left",
                    timeout = 28,
                    fg = beautiful.widget_urgent,
                    screen = 1,
                    ontop = true
                })
            else
                widget:set_color(beautiful.widget_data)
            end
        else
            widget:set_color(beautiful.widget_data)
            widget:set_border_color(beautiful.arch_green)
        end

        -- create tooltip
        if args[3] ~= "N/A" then
            battooltip:set_text( args[3] .. " (" .. args[2] .. "%)" )
        else
            battooltip:set_text( "(" .. args[2] .. "%)" )
        end

        return args[2]
    end,
29, "BAT0")

battooltip:add_to_object( batbar.widget )
batwidget = { battext, batbar.widget, layout = awful.widget.layout.horizontal.leftright }

-- cpu widget
vicious.cache(vicious.widgets.cpu)

cputext = widget({ type = "textbox" })
cputext.text = "CPU "

cpugraph = awful.widget.graph()
cpugraph:set_width(60)
cpugraph:set_height(10)
cpugraph:set_background_color(beautiful.bg_normal)
cpugraph:set_border_color(beautiful.widget_label)
cpugraph:set_color(beautiful.widget_data)
awful.widget.layout.margins[cpugraph.widget] = { top = 4 }
vicious.register(cpugraph, vicious.widgets.cpu, "$1", 7)

cpufreq = widget({ type = "textbox" })
vicious.register(cpufreq, vicious.widgets.cpufreq,
      function (widget, args)
         if args[1] < 1000 then
            return "(" .. pangoify("fgcolor", beautiful.widget_data, args[1] .. " MHz") .. ") "
         else
            return "(" .. pangoify("fgcolor", beautiful.widget_data, args[2] .. " GHz") .. ")"
         end
      end,
7, "cpu0")

cpuwidget = { cputext, cpugraph.widget, spacer, cpufreq, layout = awful.widget.layout.horizontal.leftright }

-- volume widget
voltext = widget({ type = "textbox" })
voltext.text = "VOL "

volbar = awful.widget.progressbar()
volbar:set_width(60)
volbar:set_height(10)
volbar:set_background_color(beautiful.bg_normal)
volbar:set_color(beautiful.widget_data)
awful.widget.layout.margins[volbar.widget] = { top = 4 }
vicious.register(volbar, vicious.widgets.volume, 
    function (widget, args)
        if args[2] == "♫" then
            widget:set_border_color(beautiful.widget_urgent)
            return 0
        else
            widget:set_border_color(beautiful.widget_border)
            return args[1]
        end
    end,
2, "Master")
vicious.unregister(volbar, true)

volwidget = { voltext, volbar.widget, layout = awful.widget.layout.horizontal.leftright }

-- net widget
wifitooltip = awful.tooltip({ })

wifitext = widget({ type = "textbox" })
wifitext.text = "WIFI "

wifibar = awful.widget.progressbar()
wifibar:set_width(60)
wifibar:set_height(10)
wifibar:set_max_value(1)
wifibar:set_background_color(beautiful.bg_normal)
wifibar:set_color(beautiful.widget_data)
awful.widget.layout.margins[wifibar.widget] = { top = 4 }
essidtext = widget({ type="textbox" })
vicious.register(wifibar, vicious.widgets.wifi,
    function (widget, args)
        if args["{ssid}"] == "N/A" or args["{link}"] == 0 then
            essidtext.text = ""
            wifibar:set_border_color(beautiful.widget_urgent)
            upgraph:set_border_color(beautiful.widget_urgent)
            downgraph:set_border_color(beautiful.widget_urgent)
            return 0
        else
            essidtext.text = " (" .. pangoify("fgcolor", beautiful.widget_data, args["{ssid}"]) .. ")"
            wifitooltip:set_text(args["{link}"] .. "/70")
            wifibar:set_border_color(beautiful.widget_label)
            upgraph:set_border_color(beautiful.widget_label)
            downgraph:set_border_color(beautiful.widget_label)
            return args["{link}"]
        end
    end,
7, "wlan0")
wifitooltip:add_to_object( wifibar.widget )



uptext = widget({ type = "textbox" })
uptext.text = "UP "

upgraph = awful.widget.graph()
upgraph:set_width(60)
upgraph:set_height(10)
upgraph:set_background_color(beautiful.bg_normal)
upgraph:set_color(beautiful.widget_data)
awful.widget.layout.margins[upgraph.widget] = { top = 4 }
vicious.register(upgraph, vicious.widgets.net, 
    function (widget, args)
            return args["{wlan0 up_kb}"]
    end,
3)

downtext = widget({ type = "textbox" })
downtext.text = "DOWN "

downgraph = awful.widget.graph()
downgraph:set_width(60)
downgraph:set_height(10)
downgraph:set_background_color(beautiful.bg_normal)
downgraph:set_color(beautiful.widget_data)
awful.widget.layout.margins[downgraph.widget] = { top = 4 }
vicious.register(downgraph, vicious.widgets.net, 
    function (widget, args)
            return args["{wlan0 down_kb}"]
    end,
3)

netwidget = { downgraph.widget, downtext, separator, upgraph.widget, uptext, separator, essidtext, wifibar.widget, wifitext, separator, layout = awful.widget.layout.horizontal.rightleft }


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
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create top wibox
    topwibox[s] = awful.wibox({ position = "top", screen = s })
    -- Add widgets to the top wibox - order matters
    topwibox[s].widgets = {
        {
            mylauncher,
            mytaglist[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        mytextclock,
        s == 1 and mysystray or nil,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }

    -- Create bottom wibox
    bottomwibox[s] = awful.wibox({ position = "bottom", screen = s })

    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })

    bottomwibox[s].widgets = {
       {
          separator, cpuwidget,
          separator, batwidget,
          separator, volwidget,
          separator, mypromptbox[s],
          layout = awful.widget.layout.horizontal.leftright
       },
       separator, netwidget,
       layout = awful.widget.layout.horizontal.rightleft
    }
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
    awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end),

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
    awful.key({ modkey },            "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),

    -- Multimedia / extra
    awful.key({},                    "XF86AudioMute", 
        function ()
            awful.util.spawn_with_shell("amixer -q set Master toggle")
            vicious.force({ volbar })
        end),
    awful.key({},                    "XF86AudioLowerVolume",
        function ()
            awful.util.spawn_with_shell("amixer -q set Master 2%-")
            vicious.force({ volbar })
        end),
    awful.key({},                    "XF86AudioRaiseVolume",
        function ()
            awful.util.spawn_with_shell("amixer -q set Master 2%+")
            vicious.force({ volbar })
        end),

    -- Shortcuts
    awful.key({ modkey },            "i",      function () awful.util.spawn(os.getenv("BROWSER")) end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
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
    awful.key({ modkey, "Shift"   }, "[", function (c) c.opacity = 0.05 end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
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
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "Gimp" },
      properties = { } },

    { rule = { class = "XTerm" },
      properties = { opacity = 0.75, size_hints_honor = false } },
    { rule = { class = "google-chrome" },
      properties = { maximized_vertical = true, maximized_horizontal = true } }
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Floating clients open offscreen
    awful.placement.no_offscreen(c)
    -- Floating clients don't overlap
    --awful.placement.no_overlap(c)

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
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
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
