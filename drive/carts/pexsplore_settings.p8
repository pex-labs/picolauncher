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

function _init()
end

function _update()
  if current_screen == "main" then
    update_main_menu()
  elseif current_screen == "wifi" then
    update_wifi_menu()
  else
    update_generic_menu()
  end
end

function _draw()
  cls(1)
  draw_banner()
  if current_screen == "main" then
    draw_main_menu()
  elseif current_screen == "wifi" then
    draw_wifi_menu()
  else
    draw_generic_menu()
  end
end

function draw_banner()
  rectfill(0, 0, screen_width, 12, c_banner)
  local breadcrumb = "settings"
  if current_screen != "main" then
    breadcrumb = breadcrumb .. "/" .. current_screen
  end
  print(breadcrumb, 4, 4, c_selected)
end

function update_main_menu()
  local menu_size = #menu_items
  if btnp(2) then
    current_item = (current_item - 2 + menu_size) % menu_size + 1
    update_scroll()
  elseif btnp(3) then
    current_item = current_item % menu_size + 1
    update_scroll()
  elseif btnp(4) then
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
    local y = menu_start_y + (i-1) * 10
    local color = (item_index == current_item) and c_selected or c_text
    
    if item_index == current_item then
      print("▶", 2, y, color)
    else
      print("", 2, y, color)
    end
    
    print(menu_items[item_index], 10, y, color)
    
    if menu_items[item_index] == "wifi" then
      print(wifi_status, 70, y, 3)
    end
  end
  
  print("system information", 4, 90, c_text)
  print("version    v5.2.58", 4, 100, c_text)
  print("model      pek one", 4, 108, c_text)
  print("updates    1 pending", 4, 116, c_text)
  print("storage    233mb used", 4, 124, c_text)
end

local airplane_mode = false
local current_item = 2

function update_wifi_menu()
  local menu_size = #wifi_networks + 1
  if btnp(2) then
    current_item = max(2, current_item - 1)
  elseif btnp(3) then
    current_item = min(menu_size + 1, current_item + 1)
  elseif btnp(4) then
    if current_item == 2 then
      airplane_mode = not airplane_mode
    end
  elseif btnp(5) then
    current_screen = "main"
    current_item = 1
    scroll_offset = 0
  end
end

function draw_wifi_menu()
  print("[scan]", 4, menu_start_y, c_text)
  
  local airplane_y = menu_start_y + 10
  if current_item == 2 then
    rectfill(0, airplane_y, screen_width, airplane_y + 9, c_selected)
    print("airplane mode", 4, airplane_y + 2, 0)
  else
    print("airplane mode", 4, airplane_y + 2, c_text)
  end
  print(airplane_mode and "on" or "off", screen_width - 20, airplane_y + 2, airplane_mode and 11 or 8)
  
  print("networks", 4, menu_start_y + 25, c_text)
  line(4, menu_start_y + 33, screen_width - 4, menu_start_y + 33, c_text)
  
  for i, network in ipairs(wifi_networks) do
    local y = menu_start_y + 35 + (i-1) * 10
    local is_selected = (i + 2 == current_item)
    
    if is_selected then
      rectfill(0, y, screen_width, y + 9, c_selected)
      print(network.name, 4, y + 2, 0)
    else
      print(network.name, 4, y + 2, c_text)
    end
    
    for j = 1, 4 do
      if j <= network.strength then
        line(screen_width - 10 + j*2, y + 9 - j*2, screen_width - 10 + j*2, y + 8, c_text)
      end
    end
  end
end

function update_generic_menu()
  if btnp(5) then
    current_screen = "main"
    current_item = 1
    scroll_offset = 0
  end
end

function draw_generic_menu()
  print(current_screen .. " settings", 10, menu_start_y, c_text)
  print("(not implemented)", 10, menu_start_y + 10, c_text)
end
