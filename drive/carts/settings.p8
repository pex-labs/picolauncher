pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8
#include utils.p8
#include timer.p8
#include menu.p8
#include vkeyboard.p8
#include tween.lua

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
local wifi_status = {ssid="", state="unknown"}
local airplane_mode = false

function new_wifi_menu(networks)
  wifi_menu_items = {
    {label="[scan]", func=function()request_loadable('wifi_list')end},
    {label="[disconnect]", func=function()
      serial_writeline('wifi_disconnect:')
      request_loadable('wifi_status')
    end},
  }

  for i, network in ipairs(networks) do
    add(wifi_menu_items, {ssid=network.ssid, name=network.name, strength=network.strength, func=function()
      show_keyboard=true
      make_vkeyboard_tween(true)
    end})
  end
  local _wifi_menu = menu_new(wifi_menu_items)
  _wifi_menu.wrap = false
  return _wifi_menu
end

local wifi_menu = new_wifi_menu({})

wifi_menu_scroll_tween = {}
wifi_menu_scroll = 0
function make_wifi_menu_scroll_tween(new_scroll)
  wifi_menu_scroll_tween=tween_machine:add_tween({
    func=outQuart,
    v_start=wifi_menu_scroll,
    v_end=new_scroll,
    duration=1
  })
  wifi_menu_scroll_tween:register_step_callback(function(pos)
    wifi_menu_scroll=pos
  end)
  wifi_menu_scroll_tween:register_finished_callback(function(tween)
    tween:remove()
  end)
  wifi_menu_scroll_tween:restart()
end

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
local keyboard_up_y = 78
local keyboard_down_y = 148
local keyboard = Keyboard:new(7, 0, 8, 14, keyboard_down_y, function(text)
  show_keyboard = false
  make_vkeyboard_tween(false)

  -- no-op if empty string
  if text == "" then return end

  -- currently only used for connecting to networks
  local ssid = wifi_menu:cur().ssid
  local psk = text
  serial_debug('connect to wifi request, ssid: '..ssid..', psk: '..psk)
  request_loadable('wifi_connect', {ssid, psk})
end)

-- tweens for keyboard
vkeyboard_tween = {}
function make_vkeyboard_tween(show_keyboard)
  local vkeyboard_target_y = 0
  if show_keyboard then
    vkeyboard_target_y = keyboard_up_y
  else
    vkeyboard_target_y = keyboard_down_y
  end
  vkeyboard_tween=tween_machine:add_tween({
    func=outQuart,
    v_start=keyboard.y,
    v_end=vkeyboard_target_y,
    duration=0.5
  })
  vkeyboard_tween:register_step_callback(function(pos)
    keyboard.y = pos
  end)
  vkeyboard_tween:register_finished_callback(function(tween)
    tween:remove()
  end)
  vkeyboard_tween:restart()
end


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

  new_loadable('wifi_status', function(resp)
    serial_debug('resp'..tostring(resp))
    wifi_status=table_from_string(resp)
  end, 1)

  request_loadable('wifi_status')
end

function _update60()
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
  tween_machine:update()
end

function _draw()
  cls(1)
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
  -- TODO would be nice to wrap around show keyboard, since we are wasting draw calls here?
  keyboard:draw()
  draw_banner()
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

function wifi_state_color()
  local text_c=5
  if wifi_status.state == "connected" then
    text_c=3
  elseif wifi_status.state == "connecting" then
    text_c=3
  elseif wifi_status.state == "disconnected" or wifi_status.state == "disconnecting" then
    text_c=8
  end
  return text_c
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
      local wifi_text = wifi_status.state
      if wifi_status.state == "connected" then
        wifi_text = wifi_status.ssid
      end
      print(wifi_status.state, 118-#wifi_text*4, y, wifi_state_color())
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
    make_wifi_menu_scroll_tween(-1 * (wifi_menu:index() - 1) * 10)
  elseif btnp(3) then
    wifi_menu:down()
    sfx(0)
    make_wifi_menu_scroll_tween(-1 * (wifi_menu:index() - 1) * 10)
  elseif btnp(5) then
    wifi_menu:cur().func()
  elseif btnp(4) then
    current_screen = "main"
  end
end

local wifi_menu_start_y = menu_start_y
function draw_wifi_menu()

  -- wifi state
  local text_c = wifi_state_color()
  local text = "status: "
  print(text, 10, wifi_menu_start_y + wifi_menu_scroll, 6)
  print(wifi_status.state, 10 + #text*4, wifi_menu_start_y + wifi_menu_scroll, text_c)

  if wifi_menu:index() == 1 then c=c_selected else c=c_text end
  print("[scan]", 10, wifi_menu_start_y + 8 + wifi_menu_scroll, c)

  if wifi_menu:index() == 2 then c=c_selected else c=c_text end
  print("[disconnect]", 10, wifi_menu_start_y + 16 + wifi_menu_scroll, c)

  -- local airplane_y = wifi_menu_start_y + 10
  -- if current_item == 2 then
  --   rectfill(0, airplane_y, screen_width, airplane_y + 9, c_selected)
  --   print("airplane mode", 10, airplane_y + 2, 0)
  -- else
  --   print("airplane mode", 10, airplane_y + 2, c_text)
  -- end
  -- print(airplane_mode and "on" or "off", screen_width - 20, airplane_y + 2, airplane_mode and 11 or 8)

  print("networks", 10, wifi_menu_start_y + 26 + wifi_menu_scroll, c_selected)
  line(10, wifi_menu_start_y + 32 + wifi_menu_scroll, screen_width - 10, wifi_menu_start_y + 32 + wifi_menu_scroll, c_selected)

  -- TODO scrolling
  -- TODO wifi strength level
  for i, network in ipairs(wifi_menu.items) do
    -- skip the non network menu items
    if i > 2 then
      local y = wifi_menu_start_y + wifi_menu_scroll + 36 + (i-3) * 8
      local is_selected = (i == wifi_menu:index())

      if is_selected then
        rectfill(0, y, screen_width, y + 9, c_selected)
        print(network.name, 12, y + 2, 0)
      else
        print(network.name, 12, y + 2, c_text)
      end

      -- for j = 1, 4 do
      --   if j <= network.strength then
      --     line(screen_width - 16 + j*2, y + 9 - j*2, screen_width - 16 + j*2, y + 8, c_text)
      --   end
      -- end
    end
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
