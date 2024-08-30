pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- screenshot and recording viewer

#include serial.p8

-- constants
local grid_cols = 3
local grid_rows = 4
local thumb_size = 36
local grid_offset_x = 6
local grid_offset_y = 20

-- state
local photos = {}
local current_photo = 1
local is_fullscreen = false
local scroll_y = 0

function _init()
  -- simulate loading photos
  for i=1,18 do
    add(photos, {
      thumb = i,  -- this would be the sprite number for the thumbnail
      has_play_icon = (i % 3 == 2)  -- add play icon to every third photo
    })
  end
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
  if btnp(2) then  -- up
    current_photo = max(1, current_photo - grid_cols)
  elseif btnp(3) then  -- down
    current_photo = min(#photos, current_photo + grid_cols)
  elseif btnp(0) then  -- left
    current_photo = max(1, current_photo - 1)
  elseif btnp(1) then  -- right
    current_photo = min(#photos, current_photo + 1)
  elseif btnp(4) then  -- o button
    is_fullscreen = true
  end
  
  -- update scroll
  local target_y = flr((current_photo - 1) / grid_cols) * (thumb_size + 4) - 32
  scroll_y = scroll_y + (target_y - scroll_y) / 4
end

function draw_gallery()
  -- draw header
  rectfill(0, 0, 128, 16, 9)  -- orange header
  print("photos", 4, 5, 7)
  
  -- draw thumbnails
  for i, photo in ipairs(photos) do
    local col = (i-1) % grid_cols
    local row = flr((i-1) / grid_cols)
    local x = grid_offset_x + col * (thumb_size + 4)
    local y = grid_offset_y + row * (thumb_size + 4) - scroll_y
    
    if y > 16 and y < 128 then
      -- draw thumbnail (placeholder)
      rectfill(x, y, x+thumb_size-1, y+thumb_size-1, 13)
      
      -- draw play icon if applicable
      if photo.has_play_icon then
        draw_play_icon(x + thumb_size/2, y + thumb_size/2)
      end
      
      -- highlight selected photo
      if i == current_photo then
        rect(x-1, y-1, x+thumb_size, y+thumb_size, 7)
      end
    end
  end
end

function draw_play_icon(x, y)
  -- draw a simple triangle as play icon
  line(x-3, y-3, x-3, y+3, 7)
  line(x-3, y-3, x+4, y, 7)
  line(x-3, y+3, x+4, y, 7)
end

function update_fullscreen()
  if btnp(5) then  -- x button to return to gallery
    is_fullscreen = false
  elseif btnp(0) then  -- left
    current_photo = max(1, current_photo - 1)
  elseif btnp(1) then  -- right
    current_photo = min(#photos, current_photo + 1)
  end
end

function draw_fullscreen()
  rectfill(0, 0, 127, 127, 13)
  
  rectfill(0, 120, 127, 127, 9)  -- orange bar
  print("photo_"..current_photo..".png", 4, 122, 7)
  
  print("⬅️➡️", 110, 122, 7)
end