pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8
#include utils.p8
#include timer.p8
#include menu.p8
#include vkeyboard.p8

local screen_width = 128
local screen_height = 128
local menu_start_y = 20
local items_visible = 5

local c_text = 6
local c_selected = 7
local c_banner = 14

local current_screen = "main"
local show_keyboard = false

-- main menu
local main_menu = menu_new({
  {label="theme",func=function()current_screen="theme"end},
  {label="wifi",func=function()current_screen="wifi"end},
  {label="bluetooth",func=function()current_screen="bluetooth"end},
  {label="controls",func=function()current_screen="controls"end}
})
local scroll_offset = 0

-- wifi related

-- create new wifi menu
function new_wifi_menu(networks)
  wifi_menu_items = {
    {label="[scan]", func=function()request_loadable('wifi_list')end},
    --{label="airplane mode", func=function()airplane_mode=not airplane_mode}
  }
  for i, network in ipairs(networks) do
    add(wifi_menu_items, {ssid=network.ssid, name=network.name, strength=network.strength, func=function()
      show_keyboard=true
    end})
  end
  local _wifi_menu = menu_new(wifi_menu_items)
  _wifi_menu.wrap = false
  return _wifi_menu
end

local wifi_menu = new_wifi_menu({})
local wifi_status = "connected"
local airplane_mode = false

-- controller menu
local joycon_controls = {
  up = 2,
  down = 3,
  left = 0,
  right = 1,
  a = 4,
  b = 5
}
local control_names = {"up", "down", "left", "right", "a", "b"}
local current_control = 1

-- virtual keyboard
local keyboard = Keyboard:new(7, 0, 8, 14, 78, function(text)
  show_keyboard=false
  -- currently only used for connecting to networks
  local ssid = wifi_menu:cur().ssid
  local psk = text
  serial_debug('connect to wifi request, ssid: '..ssid..', psk: '..psk)
  request_loadable('wifi_connect', {ssid, psk})
end)

function _init()
  init_timers()

  new_loadable('wifi_list', function(resp)
    serial_debug('resp'..tostring(resp))
    local split_wifi=split(resp, ',', false)
    for k, v in pairs(split_wifi) do
      split_wifi[k]=table_from_string(v)
      split_wifi[k].strength=tonum(split_wifi[k].strength)
    end
    wifi_menu=new_wifi_menu(split_wifi)
  end, 1)

  new_loadable('wifi_connect', function(resp)
    serial_debug('resp'..tostring(resp))
  end, 1)

end

function _update()
  update_loadables()
  if show_keyboard then
    keyboard:input()
  else
    if current_screen == "main" then
      update_main_menu()
    elseif current_screen == "wifi" then
      update_wifi_menu()
    elseif current_screen == "controls" then
      update_controls_menu()
    else
      update_generic_menu()
    end
  end
end

function _draw()
  cls(1)
  draw_banner()
  if current_screen == "main" then
    draw_main_menu()
  elseif current_screen == "wifi" then
    draw_wifi_menu()
  elseif current_screen == "controls" then
    --draw_controls_menu()
    draw_generic_menu()
  else
    draw_generic_menu()
  end
  if show_keyboard then
    keyboard:draw()
  end
end

function draw_banner()
  rectfill(0, 0, screen_width, 8, c_banner)
  local breadcrumb = "settings"
  if current_screen != "main" then
    breadcrumb = breadcrumb .. "/" .. current_screen
  end
  print(breadcrumb, 2, 2, c_selected)
end

-- main menu
function update_main_menu()
  if btnp(2) then
    main_menu:up()
    sfx(0)
  elseif btnp(3) then
    main_menu:down()
    sfx(0)
  elseif btnp(4) then
    os_back()
  elseif btnp(5) then
    main_menu:cur().func()
  end
end

function draw_main_menu()
  local curitem = main_menu:index()
  for i, menuitem in ipairs(main_menu.items) do
    local y = menu_start_y + (i-1) * 8
    local color = (i == curitem) and c_selected or c_text
    if i == curitem then
      print("▶", 4, y, color)
    end
    print(menuitem.label, 10, y, color)
    if menuitem.label == "wifi" then
      print(wifi_status, 70, y, 3)
    end
  end

  sysinfo_y_offset=70
  print("system information", 10, sysinfo_y_offset, c_text)
  line(10, sysinfo_y_offset+7, 118, sysinfo_y_offset+7, c_text)
  print("version    v0.1.0", 10, sysinfo_y_offset+10, c_text)
  print("model      pex one", 10, sysinfo_y_offset+18, c_text)
end

-- wifi menu
function update_wifi_menu()
  if btnp(2) then
    wifi_menu:up()
    sfx(0)
  elseif btnp(3) then
    wifi_menu:down()
    sfx(0)
  elseif btnp(5) then
    wifi_menu:cur().func()
  elseif btnp(4) then
    current_screen = "main"
  end
end

function draw_wifi_menu()
  if wifi_menu:index() == 1 then c=c_selected else c=c_text end
  print("[scan]", 10, menu_start_y, c)

  -- local airplane_y = menu_start_y + 10
  -- if current_item == 2 then
  --   rectfill(0, airplane_y, screen_width, airplane_y + 9, c_selected)
  --   print("airplane mode", 10, airplane_y + 2, 0)
  -- else
  --   print("airplane mode", 10, airplane_y + 2, c_text)
  -- end
  -- print(airplane_mode and "on" or "off", screen_width - 20, airplane_y + 2, airplane_mode and 11 or 8)

  print("networks", 10, menu_start_y + 25, c_text)
  line(10, menu_start_y + 33, screen_width - 10, menu_start_y + 33, c_text)

  -- TODO scrolling
  -- TODO wifi strength level
  for i, network in ipairs(wifi_menu.items) do
    -- skip the non network menu items
    if i > 1 then
      local y = menu_start_y + 35 + (i-1) * 10
      local is_selected = (i == wifi_menu:index())

      if is_selected then
        rectfill(0, y, screen_width, y + 9, c_selected)
        print(network.name, 10, y + 2, 0)
      else
        print(network.name, 10, y + 2, c_text)
      end

      for j = 1, 4 do
        if j <= network.strength then
          line(screen_width - 16 + j*2, y + 9 - j*2, screen_width - 16 + j*2, y + 8, c_text)
        end
      end
    end
  end

  -- TODO don't really like tying the wifi menu password screen with show_keyboard state
  if show_keyboard then
    rectfill(10, 32, 118, 42, 5)
    rectfill(9, 31, 119, 43, 6)
    print(keyboard.text, 12, 34, 7)
  end
end

-- controls menu
function update_controls_menu()
  if btnp(2) then
    current_control = max(1, current_control - 1)
    sfx(0)
  elseif btnp(3) then
    current_control = min(#control_names, current_control + 1)
    sfx(0)
  elseif btnp(5) then
    wait_for_button_press()
  elseif btnp(4) then
    current_screen = "main"
    current_item = 1
  end
end

function draw_accurate_joycon()
  local x, y = 10, 20  -- starting position
  local w, h = 110, 70  -- width and height
  local c = 7  -- main color (white)
  
  -- draw the elongated oval outline
  -- top curve
  line(x+4, y, x+w-5, y, c)
  line(x+2, y+1, x+w-3, y+1, c)
  line(x+1, y+2, x+w-2, y+2, c)
  line(x, y+3, x+w-1, y+3, c)
  
  -- bottom curve
  line(x+4, y+h-1, x+w-5, y+h-1, c)
  line(x+2, y+h-2, x+w-3, y+h-2, c)
  line(x+1, y+h-3, x+w-2, y+h-3, c)
  line(x, y+h-4, x+w-1, y+h-4, c)
  
  -- left and right sides
  for i=4, h-5 do
    pset(x, y+i, c)
    pset(x+w-1, y+i, c)
  end
  
  -- top buttons
  rect(x+8, y+4, x+20, y+8, c)
  rect(x+w-21, y+4, x+w-9, y+8, c)
  
  -- left analog stick
  for r=8,10 do circ(x+30, y+30, r, c) end
  circfill(x+30, y+30, 3, c)
  
  -- button cluster
  circ(x+w-30, y+30, 7, c)  -- top button
  circ(x+w-42, y+42, 7, c)  -- left button
  circ(x+w-18, y+42, 7, c)  -- right button
  circ(x+w-30, y+54, 7, 8)  -- bottom button (red)
  circfill(x+w-30, y+54, 3, 8)  -- red center
  
  -- center button
  rect(x+48, y+40, x+60, y+48, c)
end

function draw_controls_menu()
  cls(1)  -- clear screen with dark blue background
  
  draw_accurate_joycon()
  
  print("controls", 4, 4, 10)  -- title in yellow
  
  local start_y = 15
  for i, control in ipairs(control_names) do
    local y = start_y + i * 8
    local color = (i == current_control) and 10 or 7
    
    print(control, 4, y, color)
    print(joycon_controls[control], 30, y, color)
  end
end

function wait_for_button_press()
  while true do
    for i = 0, 5 do
      if btnp(i) then
        joycon_controls[control_names[current_control]] = i
        return
      end
    end
    yield()
  end
end

function update_generic_menu()
  if btnp(4) then
    current_screen = "main"
    current_item = 1
    scroll_offset = 0
  end
end

function draw_generic_menu()
  print(current_screen .. " settings", 10, menu_start_y, c_text)
  print("(not implemented)", 10, menu_start_y + 10, c_text)
end

__sfx__
000200000d7500d7500d7000840008400084000c4000c4000c4000b40012400074000a40008400034000630000000000000000000000000000000000000000000000000000000000000000000000000000000000
