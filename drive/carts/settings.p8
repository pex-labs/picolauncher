pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8
#include utils.p8
#include timer.p8

local screen_width = 128
local screen_height = 128
local menu_start_y = 20
local items_visible = 5

local c_text = 6
local c_selected = 7
local c_banner = 14

local menu_items = {"theme", "wifi", "bluetooth", "controls"}
local current_item = 1
local scroll_offset = 0
local wifi_status = "connected"

local wifi_networks = {
  {name="myphone", strength=3},
  {name="yourhome", strength=2},
  {name="router1", strength=3},
  {name="router2", strength=1},
  {name="karatsurf", strength=1},
  {name="network", strength=1}
}

local current_screen = "main"

local airplane_mode = false

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

wifi_list={}

function _init()
  init_timers()
  new_loadable('wifi_list', function(resp)
    local split_wifi=split(resp, ',', false)
    serial_debug('resp'..tostring(resp))
    wifi_list=resp
  end, 1)
end

function _update()
  if current_screen == "main" then
    update_main_menu()
  elseif current_screen == "wifi" then
    update_wifi_menu()
  elseif current_screen == "controls" then
    update_controls_menu()
  else
    update_generic_menu()
  end
  update_loadables()
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
end

function draw_banner()
  rectfill(0, 0, screen_width, 8, c_banner)
  local breadcrumb = "settings"
  if current_screen != "main" then
    breadcrumb = breadcrumb .. "/" .. current_screen
  end
  print(breadcrumb, 2, 2, c_selected)
end

function update_main_menu()
  local menu_size = #menu_items
  if btnp(2) then
    current_item = (current_item - 2 + menu_size) % menu_size + 1
    sfx(0)
    update_scroll()
  elseif btnp(3) then
    current_item = current_item % menu_size + 1
    sfx(0)
    update_scroll()
  elseif btnp(4) then
    os_back()
  elseif btnp(5) then
    current_screen = menu_items[current_item]
    current_item = 1
    scroll_offset = 0
  end
end

function update_scroll()
  if current_item - scroll_offset > items_visible then
    scroll_offset = current_item - items_visible
  elseif current_item <= scroll_offset then
    scroll_offset = current_item - 1
  end
end

function draw_main_menu()
  for i = 1, min(items_visible, #menu_items) do
    local item_index = i + scroll_offset
    local y = menu_start_y + (i-1) * 8
    local color = (item_index == current_item) and c_selected or c_text

    if item_index == current_item then
      print("▶", 4, y, color)
    end

    print(menu_items[item_index], 10, y, color)

    if menu_items[item_index] == "wifi" then
      print(wifi_status, 70, y, 3)
    end
  end

  sysinfo_y_offset=70
  print("system information", 10, sysinfo_y_offset, c_text)
  line(10, sysinfo_y_offset+7, 118, sysinfo_y_offset+7, c_text)
  print("version    v0.1.0", 10, sysinfo_y_offset+10, c_text)
  print("model      pex one", 10, sysinfo_y_offset+18, c_text)
end

function update_wifi_menu()
  local menu_size = #wifi_networks + 2  -- +2 for [scan] and airplane mode
  if btnp(2) then
    current_item = max(1, current_item - 1)
    sfx(0)
  elseif btnp(3) then
    current_item = min(menu_size, current_item + 1)
    sfx(0)
  elseif btnp(5) then
    request_loadable('wifi_list')
    -- if current_item == 2 then
    --   airplane_mode = not airplane_mode
    -- end
  elseif btnp(4) then
    current_screen = "main"
    current_item = 1
    scroll_offset = 0
  end
end

function draw_wifi_menu()
  print("[scan]", 10, menu_start_y, c_text)

  local airplane_y = menu_start_y + 10
  if current_item == 2 then
    rectfill(0, airplane_y, screen_width, airplane_y + 9, c_selected)
    print("airplane mode", 10, airplane_y + 2, 0)
  else
    print("airplane mode", 10, airplane_y + 2, c_text)
  end
  print(airplane_mode and "on" or "off", screen_width - 20, airplane_y + 2, airplane_mode and 11 or 8)

  print("networks", 10, menu_start_y + 25, c_text)
  line(10, menu_start_y + 33, screen_width - 10, menu_start_y + 33, c_text)

  for i, network in ipairs(wifi_networks) do
    local y = menu_start_y + 35 + (i-1) * 10
    local is_selected = (i + 2 == current_item)

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
