pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8
#include menu.p8
#include utils.p8
#include tween.lua

-- temp, include a color for the box
categories=menu_new({
    {label='featured',c1=12,c2=0},
    {label='shooter',c1=9,c2=0},
    {label='puzzle',c1=11,c2=0},
    {label='platformer',c1=8,c2=0},
    {label='co-op',c1=14,c2=0},
    {label='arcade',c1=10,c2=0},
    {label='different menu'}
})

cam_y=0

function cam_scroll_tween(v_start, v_end)
  cam_tween=tween_machine:add_tween({
    func=outQuart,
    v_start=v_start,
    v_end=v_end,
    duration=1
  })
  cam_tween:register_step_callback(function(pos)
    cam_y=pos
  end)
  cam_tween:register_finished_callback(function(tween)
    tween:remove()
  end)
  cam_tween:restart()
end

function _init()
  categories:set_wrap(false)
  categories:add_hook(6, function(self)
    cam_scroll_tween(cam_y, 0)
  end)
  categories:add_hook(7, function(self)
    cam_scroll_tween(cam_y, 100)
  end)
end

function _update60()
  tween_machine:update()
  camera(0, cam_y) 

  if btnp(0) then

  elseif btnp(1) then

  elseif btnp(2) then
    categories:up()
  elseif btnp(3) then
    categories:down()
  elseif btnp(5) then
    serial_bbs(1, '')
  end
end

function _draw()
  cls(1)
  rectfill(0, 0, 128, 56, 12)
  -- TODO scale text
  -- https://www.lexaloffle.com/bbs/?tid=29612
  print('EXsplore', 90, 48, 7)

  -- categories section
  print('categories', 8, 60, 6)
  line(8, 68, 120, 68, 6)

  cat_x = 8
  cat_y = 72
  cat_w = 32
  cat_h = 16
  for i, item in ipairs(categories.items) do
    -- submenu only consists of 6 items
    if i > 6 then break end

    x = (i-1) % 3
    y = ((i-1)\3)
    -- print(item.label .. ' ' .. x .. ' ' .. y)
    rectfill(cat_x+x*(cat_w+8), cat_y+y*(cat_h+8), cat_x+x*(cat_w+8)+cat_w, cat_y+y*(cat_h+8)+cat_h, item.c1)
    if categories:index() == i then
      rect(cat_x+x*(cat_w+8)-1, cat_y+y*(cat_h+8)-1, cat_x+x*(cat_w+8)+cat_w+1, cat_y+y*(cat_h+8)+cat_h+1, 7)
    end
  end

  -- featured carts section
  print('featured', 8, 116, 6)
  line(8, 124, 120, 124, 6)


end
