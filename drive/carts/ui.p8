pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- common ui functions
function init_title_bar(bg_color, alt_color)
  if alt_color == nil then
    pal(bg_color, 128+bg_color, 2) -- use the dark version
  else
    pal(bg_color, alt_color, 2) -- specify an override
  end
  poke(0x5f5f, 0x10)
  poke(0x5f71, 0x01) -- make line 8 alternate color
end

function draw_title_bar(text, bg_color, text_color, align_left, icon, icon_color)
  rectfill(0, 0, 128, 8, bg_color)
  
  -- default to align left
  if align_left == nil then
    align_left = true
  end

  local x = 4
  if align_left and icon ~= nil then
    -- add some padding for the icon
    x += #icon*4 + 4
  elseif not align_left then
    x = 128 - (#text+1)*4 
  end

  -- currentely icons can only be text
  if icon ~= nil then
    print(icon, 2, 2, icon_color)
  end

  print(text, x, 2, text_color)
end
