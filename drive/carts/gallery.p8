pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- screenshot and recording viewer

-- constants
local grid_cols = 3
local grid_rows = 4
local thumb_size = 32
local grid_offset_x = 10
local grid_offset_y = 20

-- state
local photos = {}
local current_photo = 1
local is_fullscreen = false
local scroll_y = 0

function _init()
  cartdata("screenshot_gallery_data")
  load_photos()
end

function _update()
  if is_fullscreen then
    update_fullscreen()
  else
    update_gallery()
  end
end

function _draw()
  cls(1)  -- dark blue background
  if is_fullscreen then
    draw_fullscreen()
  else
    draw_gallery()
  end
end

function update_gallery()
  if btnp(2) then  
    current_photo = max(1, current_photo - grid_cols)
  elseif btnp(3) then  -- down
    current_photo = min(#photos, current_photo + grid_cols)
  elseif btnp(0) then  -- left
    current_photo = max(1, current_photo - 1)
  elseif btnp(1) then  -- right
    current_photo = min(#photos, current_photo + 1)
  elseif btnp(4) then  -- o button
    is_fullscreen = true
  elseif btnp(5) then  -- x button
    take_screenshot()
  end
   
  local target_y = flr((current_photo - 1) / grid_cols) * (thumb_size + 4) - 32
  scroll_y = scroll_y + (target_y - scroll_y) / 4
end

function draw_gallery()
  -- draw header
  rectfill(0, 0, 128, 16, 9) 
  print("photos", 4, 5, 7)
  print("❎ screenshot", 75, 5, 7)
   
  for i, photo in ipairs(photos) do
    local col = (i-1) % grid_cols
    local row = flr((i-1) / grid_cols)
    local x = grid_offset_x + col * (thumb_size + 4)
    local y = grid_offset_y + row * (thumb_size + 4) - scroll_y
    
    if y > 16 and y < 128 then
      -- draw thumbnail (placeholder)
      rectfill(x, y, x+thumb_size-1, y+thumb_size-1, 13)
      print(photo.index, x+2, y+2, 7)
      
      -- highlight selected photo
      if i == current_photo then
        rect(x-1, y-1, x+thumb_size, y+thumb_size, 7)
      end
    end
  end
end

function update_fullscreen()
  if btnp(5) then  
    is_fullscreen = false
  elseif btnp(0) then  
    current_photo = max(1, current_photo - 1)
  elseif btnp(1) then  
    current_photo = min(#photos, current_photo + 1)
  end
end

function draw_fullscreen()
  local photo = photos[current_photo]
  rectfill(0, 0, 127, 127, 13)
  print("screenshot "..photo.index, 32, 60, 7)
  
  rectfill(0, 120, 127, 127, 9)  -- orange bar
  print("photo_"..photo.index..".png", 4, 122, 7)
  print("⬅️➡️", 110, 122, 7)
end

function take_screenshot()
  extcmd("screen")
  local new_photo = {
    index = #photos + 1
  }
  add(photos, new_photo)
  save_photos()
  

end

function load_photos()
  photos = {}
  for i=0,63 do
    if dget(i) != 0 then
      add(photos, {
        index = dget(i)
      })
    else
      break
    end
  end
  if #photos == 0 then
    add(photos, {index = 1})  -- always have at least one photo
  end
end

function save_photos()
  for i, photo in ipairs(photos) do
    dset(i-1, photo.index)
  end
end