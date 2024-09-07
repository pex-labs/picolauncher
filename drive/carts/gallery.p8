pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include menu.p8
#include utils.p8
#include tween.lua

-- screenshot and recording viewer

photo_dir='screenshots' 

-- constants
local grid_cols = 3
local grid_rows = 4
local thumb_size = 32
local grid_offset_x = 12
local grid_offset_y = 20

-- state
local photos = {}
local current_photo = 1
local is_fullscreen = false

function _init()
  cartdata("screenshot_gallery_data")
  load_photos()
  make_thumbnail_freeq()
end

function _update60()
  tween_machine:update()

  if is_fullscreen then
    update_fullscreen()
  else
    update_gallery()
  end
end

function _draw()
  if is_fullscreen then
    draw_fullscreen()
  else
    draw_gallery()
  end
end

scroll_tween={}
scroll_y = 0
function make_scroll_tween(target_y)
  scroll_tween=tween_machine:add_tween({
    func=outQuart,
    v_start=scroll_y,
    v_end=target_y,
    duration=1
  })
  scroll_tween:register_step_callback(function(pos)
    scroll_y=pos
  end)
  scroll_tween:register_finished_callback(function(tween)
    tween:remove()
  end)
  scroll_tween:restart()
end

function scroll_to()
  local target_y = flr((current_photo - 1) / grid_cols) * (thumb_size + 4) - 32
  make_scroll_tween(target_y)
end

function update_gallery()
  if btnp(2) then  
    current_photo = max(1, current_photo - grid_cols)
    scroll_to()
  elseif btnp(3) then  -- down
    current_photo = min(tsize(photos), current_photo + grid_cols)
    scroll_to()
  elseif btnp(0) then  -- left
    current_photo = max(1, current_photo - 1)
    scroll_to()
  elseif btnp(1) then  -- right
    current_photo = min(tsize(photos), current_photo + 1)
    scroll_to()
  elseif btnp(5) then  -- x button
    load_full_photo()
    is_fullscreen = true
  end
end

-- draw thumbnail n at (x,y)
function draw_thumbnail(n, x, y)
  if n < 0 then return end

  for j = 0, 7 do
    for i = 0, 3 do
      sspr(i*32, n*8 + j, 32, 1, x, y+j*4+i)
    end
  end
end

function draw_gallery()
  cls(1)  -- dark blue background
   
  for i, photo in ipairs(photos) do
    local col = (i-1) % grid_cols
    local row = flr((i-1) / grid_cols)
    local x = grid_offset_x + col * (thumb_size + 4)
    local y = grid_offset_y + row * (thumb_size + 4) - scroll_y
    
    if y > -32 and y < 128 then
      -- load if thumbnail is not loaded
      if photo.slot == -1 then
        -- find free slot
        if #thumbnail_freeq > 0 then
          new_slot = deli(thumbnail_freeq, 1)
          local path = photo_dir .. "/" .. photo.path .. ".32.p8"
          reload(new_slot*0x0200, 0x0000, 0x0200, path)
          -- printh("lazy loading " .. path .. " to slot " .. new_slot)
          photo.slot = new_slot
        else
          printh("no space left in thumbnail free queue")
        end
      end

      rectfill(x, y, x+thumb_size-1, y+thumb_size-1, 0)
      draw_thumbnail(photo.slot, x, y)
      -- print(i, x+2, y+2, 7)
      
      -- highlight selected photo
      if i == current_photo then
        rect(x-1, y-1, x+thumb_size, y+thumb_size, 7)
      else
        rect(x-1, y-1, x+thumb_size, y+thumb_size, 0)
      end
    else
      -- can mark the image is unloaded
      if photo.slot != -1 then
        add(thumbnail_freeq, photo.slot)
        photo.slot = -1
      end
    end
  end

  -- draw header
  rectfill(0, 0, 128, 8, 9) 
  print("photos", 2, 2, 7)
  -- print("❎ screenshot", 75, 5, 7)
end

function update_fullscreen()
  if btnp(4) then
    is_fullscreen = false
    load_photos()
    scroll_to()
  elseif btnp(0) then  
    current_photo = max(1, current_photo - 1)
    load_full_photo()
  elseif btnp(1) then  
    current_photo = min(tsize(photos), current_photo + 1)
    load_full_photo()
  end
end

function draw_fullscreen()
  cls(0)
  sspr(0, 0, 128, 128, 0, 0)
  
  rectfill(0, 120, 127, 127, 9)  -- orange bar
  local photo_name = photos[current_photo].path .. ".p8"
  print(photo_name, 4, 121, 7)
  print("⬅️➡️", 110, 121, 7)
end

-- photos={
--   -- 0>= for loaded, -1 for unloaded
--   {path="", slot=-1}
-- }
thumbnail_freeq={}
total_slots=16
function make_thumbnail_freeq()
  thumbnail_freeq={}
  for i = 0, total_slots-1 do
    add(thumbnail_freeq, i)
  end
end

function load_photos()
  photos={} -- reset photos
  make_thumbnail_freeq() -- reset loaded thumnails
  for i, path in ipairs(ls(photo_dir)) do
    if ends_with(path, ".128.p8") then
      stripped_path = sub(path, 0, -#(".128.p8")-1)
      add(photos, {path=stripped_path, slot=-1})
    end
  end
end

function load_full_photo()
  path = photo_dir .. "/" .. photos[current_photo].path .. ".128.p8"
  reload(0x0000, 0x0000, 0x2000, path)
end
