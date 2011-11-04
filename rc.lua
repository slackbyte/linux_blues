-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
-- Widget library
require("vicious")

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(awful.util.getdir("config") .. "/themes/archlinux/theme.lua")

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
   tags[s] = awful.tag( { 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[6])
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
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock({ align = "right" })

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
separator.text = " | "

-- battery widget
battext = widget({ type = "textbox" })
baticon = widget({ type = "imagebox" })
vicious.register(battext, vicious.widgets.bat, 
    function (widget, args)
       
        if (args[2] >= 95) then
           baticon.image = image(awful.util.getdir("config") .. "/themes/archlinux/icons/bat_full.png")
        elseif (args[2] >= 80) then
           baticon.image = image(awful.util.getdir("config") .. "/themes/archlinux/icons/bat_100.png")
        elseif (args[2] >= 60) then
           baticon.image = image(awful.util.getdir("config") .. "/themes/archlinux/icons/bat_75.png")
        elseif (args[2] >= 35) then
           baticon.image = image(awful.util.getdir("config") .. "/themes/archlinux/icons/bat_50.png")
        elseif (args[2] >= 10) then
           baticon.image = image(awful.util.getdir("config") .. "/themes/archlinux/icons/bat_25.png")
        else
           baticon.image = image(awful.util.getdir("config") .. "/themes/archlinux/icons/bat_empty.png")
        end

        return "BAT: <span fgcolor=\"".. beautiful.widget_field .. "\">" .. args[2] .. "% (" .. args[3] .. ") " .. args[1] .. " </span>"
    end,
29, "BAT0")

-- cpu widget
cpubuttons = awful.util.table.join(
      awful.button({ }, 1,
         function()
            --naughty.notify({ text="hello world", timeout=0 })
         end)
      )

cpulabel = widget({ type = "textbox" })
cpulabel.text = "CPU: "
cpulabel:buttons(cpubuttons)

cpuusage = widget({ type = "textbox" })
vicious.register(cpuusage, vicious.widgets.cpu, 
      "<span fgcolor=\""..beautiful.widget_field.."\">$1%</span>", 7)
cpuusage:buttons(cpubuttons)

cpufreq = widget({ type = "textbox" })
vicious.register(cpufreq, vicious.widgets.cpufreq,
      function (widget, args)
         if args[1] < 1000 then
            return "<span fgcolor=\""..beautiful.widget_field.."\">"..args[1].." MHz ("..args[5]..")</span>"
         else
            return "<span fgcolor=\""..beautiful.widget_field.."\">"..args[2].." GHZ ("..args[5]..")</span>"
         end
      end,
7, "cpu0")
cpufreq:buttons(cpubuttons)

cpuwidget = { cpulabel, cpuusage, spacer, cpufreq, layout = awful.widget.layout.horizontal.leftright }

-- volume widget
voltext = widget({ type = "textbox" })
volicon = widget({ type = "imagebox" })
vicious.register(voltext, vicious.widgets.volume, 
    function (widget, args)
        if args[2] == "" then
            volicon.image = image(awful.util.getdir("config") .. "/themes/archlinux/icons/vol_on.png")
            return "" .. args[1] .. "% "
        else
            volicon.image = image(awful.util.getdir("config") .. "/themes/slackware/icons/vol_muted.png")
            return "--  "
        end
    end,
3, "Master")
vicious.unregister(voltext, true)

-- net widget
netbuttons = awful.util.table.join(
      awful.button({ }, 1,
         function()
         end)
      )

wifiwidget = widget({ type = "textbox" })
wlan = true;
eth = false;
vicious.register(wifiwidget, vicious.widgets.wifi,
    function (widget, args)
        if args["{ssid}"] == "N/A" or args["{link}"] == 0 then
            wlan = false;
            return ""
        else
            wlan = true;
            return separator.text .. "WIFI: <span fgcolor=\"" .. beautiful.widget_field .. "\">" .. args["{link}"] .. "/70</span>" .. 
               " ".. separator.text .. " " .. "essid: <span fgcolor=\"" .. beautiful.widget_field .. "\">" .. args["{ssid}"] .. "</span>"
        end
    end,
7, "wlan0")

trafficwidget = widget({ type = "textbox" })
vicious.register(trafficwidget, vicious.widgets.net, 
    function (widget, args)
         if wlan then
            return " " .. separator.text .. " up: <span fgcolor=\"" .. beautiful.widget_field .. "\">" .. args["{wlan0 up_kb}"] ..
                " Kb/s</span> down: <span fgcolor=\"" .. beautiful.widget_field .. "\">" .. args["{wlan0 down_kb}"] .. " Kb/s</span>"
         end
    end,
3)

netwidget = { trafficwidget, wifiwidget, layout = awful.widget.layout.horizontal.rightleft }


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
        baticon,
        voltext, volicon, spacer, 
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }

    -- Create bottom wibox
    bottomwibox[s] = awful.wibox({ position = "bottom", screen = s })

    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })

    bottomwibox[s].widgets = {
       {
          spacer, cpuwidget,
          separator, battext,
          separator, mypromptbox[s],
          layout = awful.widget.layout.horizontal.leftright
       },
       spacer, netwidget,
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
            awful.util.spawn_with_shell("amixer set Master toggle")
            vicious.force({ voltext })
        end),
    awful.key({},                    "XF86AudioLowerVolume",
        function ()
            awful.util.spawn_with_shell("amixer set Master playback 2-")
            vicious.force({ voltext })
        end),
    awful.key({},                    "XF86AudioRaiseVolume",
        function ()
            awful.util.spawn_with_shell("amixer set Master playback 2+")
            vicious.force({ voltext })
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
        end)
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