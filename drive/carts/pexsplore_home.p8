pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8
#include utils.p8
#include timer.p8
#include menu.p8
#include vkeyboard.p8
#include tween.lua
#include ui.p8

local show_keyboard = false
local keyboard_up_y = 78
local keyboard_down_y = 148
local keyboard = Keyboard:new(7, 0, 8, 14, keyboard_down_y, function(text)
  show_keyboard = false
  make_vkeyboard_tween(false)

  -- no-op if empty string
  if text == "" then return end

  -- search bbs
  pexsplore_search(text)
end)

-- tweens for keyboard (TODO this is copied from settings.p8)
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


-- launch pexsplore with given games category
function pexsplore_category(category)
  return function()
    os_load('pexsplore_bbs.p8', '', category)
  end
end

function pexsplore_search(search_str)
  -- search has a concatenated 'search:' prefix
  os_load('pexsplore_bbs.p8', '', 'search:' .. search_str)
end

-- TODO should move each category into some sort of enum that can be shared with pesplore_bbs.p8
categories=menu_new({
    {label='search',cmd=function()end},
    {label='featured',c1=12,c2=0,icon=1,cmd=pexsplore_category('featured')},
    {label='platformer',c1=9,c2=0,icon=2,cmd=pexsplore_category('platformer')},
    {label='new',c1=11,c2=0,icon=3,cmd=pexsplore_category('new')},
    {label='arcade',c1=8,c2=0,icon=4,cmd=pexsplore_category('arcade')},
    {label='action',c1=14,c2=0,icon=5,cmd=pexsplore_category('action')},
    {label='puzzle',c1=10,c2=0,icon=6,cmd=pexsplore_category('puzzle')},
    {label='favorites',c1=10,c2=0,icon=7,cmd=pexsplore_category('favorites')},
    -- {label='different menu',cmd=function()end},
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
  -- disable scrolling for now
  -- categories:add_hook(6, function(self)
  --   cam_scroll_tween(cam_y, 0)
  -- end)
  -- categories:add_hook(7, function(self)
  --   cam_scroll_tween(cam_y, 100)
  -- end)

  -- graphics
  init_title_bar(12)
end

function _update60()
  if show_keyboard then
    keyboard:input()
  else
    menu_update()
  end
  tween_machine:update()
end

function menu_update()
  camera(0, cam_y) 

  if btnp(0) then
    sfx(0)
    categories:up()
  elseif btnp(1) then
    sfx(0)
    categories:down()
  end

  if categories:index() == 1 then
    if btnp(2) then
      sfx(0)
      categories:up()
    elseif btnp(3) then
      sfx(0)
      categories:down()
    elseif btnp(5) then
      -- open onscreen kb
      show_keyboard=true
      make_vkeyboard_tween(true)
    end
  elseif 2 <= categories:index() and categories:index() <= 8 then
    local menu1_w = 3
    local menu1_h = 3
    local cur_index = categories:index()
    if btnp(2) then
      sfx(0)
      categories:set_index(cur_index-menu1_w)
    elseif btnp(3) then
      sfx(0)
      categories:set_index(cur_index+menu1_w)
    end
  end

  if btnp(4) then
    os_back()
  elseif btnp(5) then
    sfx(2)
    categories:cur().cmd()
  end
end

function _draw()
  cls(1)
  -- TODO scale text
  -- https://www.lexaloffle.com/bbs/?tid=29612
  draw_title_bar('PEXsplore', 12, 7, false)

  -- categories section
  print('categories', 8, 30, 6)
  line(8, 36, 120, 36, 6)

  -- draw search bar
  search_x = 8
  search_y = 15
  search_h = 10
  local search_c = 6
  if categories:index() == 1 then
    search_c = 7
  end
  line(search_x+1, search_y, 128-search_x-1, search_y, search_c)
  line(search_x+1, search_y+search_h, 128-search_x-1, search_y+search_h, search_c)
  rectfill(search_x, search_y+1, search_x+2, search_y+search_h-1, search_c)
  rectfill(128-search_x-3, search_y+1, 128-search_x, search_y+search_h-1, search_c)
  -- TODO replace with point?
  line(search_x+3, search_y+1, search_x+3, search_y+1, search_c)
  line(128-search_x-4, search_y+1, 128-search_x-4, search_y+1, search_c)
  line(search_x+3, search_y+search_h-1, search_x+3, search_y+search_h-1, search_c)
  line(128-search_x-4, search_y+search_h-1, 128-search_x-4, search_y+search_h-1, search_c)
  print("search", search_x+6, search_y+3, search_c)

  -- draw categories menu
  cat_x = 8
  cat_y = 40
  cat_w = 32
  cat_h = 16
  cat_pad_x = 8
  cat_pad_y = 12
  for i, item in ipairs(categories.items) do
    if 2 <= i and i <= 8 then
      rel_i = i-1

      x = (rel_i-1) % 3
      y = ((rel_i-1)\3)
      -- print(item.label .. ' ' .. x .. ' ' .. y)
      if categories:index() == i then
        c1=7
        press_offset=2
      else
        c1=5
        press_offset=0
      end
      rectfill(cat_x+x*(cat_w+cat_pad_x), cat_y+y*(cat_h+cat_pad_y)+cat_h+1, cat_x+x*(cat_w+cat_pad_x)+cat_w, cat_y+y*(cat_h+cat_pad_y)+cat_h+2, 0)
      sspr(((item.icon-1)*32)%128, flr((item.icon-1)/4)*16, 32, 16, cat_x+x*(cat_w+cat_pad_x), cat_y+y*(cat_h+cat_pad_y)+press_offset)
      rect(cat_x+x*(cat_w+cat_pad_x), cat_y+y*(cat_h+cat_pad_y)-1+press_offset, cat_x+x*(cat_w+cat_pad_x)+cat_w, cat_y+y*(cat_h+cat_pad_y)+cat_h+press_offset, c1)
      -- category name
      print(item.label, cat_x+x*(cat_w+cat_pad_x)+cat_w/2-#(item.label)*2+1, cat_y+y*(cat_h+cat_pad_y)+cat_h+4, c1)
    end
  end

  -- featured carts section
  -- print('featured', 8, 116, 6)
  -- line(8, 124, 120, 124, 6)

  keyboard:draw()


end
__gfx__
cccccccccccccccccccccccccccccccc99999999999999999999999999999999bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88888888888888888888888888888888
cccccccccccccccccccccccccccccccc99999999999999999999999999999999bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88888888888888888888888888888888
cccccccccccccc0000cccccccccccccc99999999999999900990900999999999bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88888888888888888888888888888888
cccccccccccccc0aa0cccccccccccccc9999999999999990300b0b0999999999bbbbbbbb000000bbbb000000bbbbbbbb88888888000008888888880088888888
cccccccccccc000aa000cccccccccccc999999999999999903b3309999999999bbbbbbbb033330bbbb033330bbbbbbbb88888888066608888888806608888888
cccccccccccc0aaaaaa0cccccccccccc99999999999999902888820999999999bbbbbbbb0333300000033330bbbbbbbb88888888066608888888066660888888
cccccccc00000aaaaaa00000cccccccc99999999999999908988880999999999bbbbbbbb0333333003333330bbbbbbbb88888000066600008888056650888888
cccccccc0aaaaaaaaaaaaaa0cccccccc99999999999999908888980999999999bbbbbbbb0333333003333330bbbbbbbb88888066666666608888805508888888
cccccccc0aaaaaaaaaaaaaa0cccccccc99999999999999908898880999999999bbbbbbbb0000333003333000bbbbbbbb88888066666666608880080088888888
cccccccc000aaaaaaaaaa000cccccccc99999999999999902888820999999999bbbbbbbbbbb03330033330bbbbbbbbbb88888055566655508806608888888888
cccccccccc0aaaaaaaaaa0cccccccccc99999999999999990288209999999999bbbbbbbbbbb00003300000bbbbbbbbbb88888000066600008066660888888888
cccccccccc0aa000000aa0cccccccccc99999999900000000000000999999999bbbbbbbbbbbb00033000bbbbbbbbbbbb88888888066608888056650888888888
cccccccccc0aa0cccc0aa0cccccccccc99999999077777777777777099999999bbbbbbbbbbbbb003300bbbbbbbbbbbbb88888888055508888805508888888888
cccccccccc0000cccc0000cccccccccc99999990777cccccccccc77709999999bbbbbbbbbbbbbb0330bbbbbbbbbbbbbb88888888000008888880088888888888
cccccccccccccccccccccccccccccccc9999999077cc77cccccccc7709999999bbbbbbbbbbbbbb0000bbbbbbbbbbbbbb88888888888888888888888888888888
cccccccccccccccccccccccccccccccc999999907ccc77cccc7cccc709999999bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb88888888888888888888888888888888
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa6666666666666666666666666666666600000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaaaaaaaaaaa0000000aaaaaaaaaaaaa6666666666666666666666666666666600000000000000000000000000000000
eeeeeeeeeee00eeeeeee00eeeeeeeeeeaaaaaaaaaaaa0888880aaaaaaaaaaaaa6666666666600006600006666666666600000000000000000000000000000000
eeeeeeeeeee0600eee0060eeeeeeeeeeaaaaaaaaaaaa088888000aaaaaaaaaaa6666666666008800008800666666666600000000000000000000000000000000
eeeeeeeeeeee0650e0560eeeeeeeeeeeaaaaaaaaaaa0000888880aaaaaaaaaaa6666666660088880088880066666666600000000000000000000000000000000
eeeeeeeeeeee056505650eeeeeeeeeeeaaaaaaaaaaa0ee0888880aaaaaaaaaaa6666666660888888887788066666666600000000000000000000000000000000
eeeeeeeeeeeee0565650eeeeeeeeeeeeaaaaaaaaaaa0ee00000000aaaaaaaaaa6666666660888888888788066666666600000000000000000000000000000000
eeeeeeeeeeeeee05650eeeeeeeeeeeeeaaaaaaaaaaa0eeee0cccc0aaaaaaaaaa6666666660888888888788066666666600000000000000000000000000000000
eeeeeeeeeeee005656500eeeeeeeeeeeaaaaaaaaaaa0eeee0cccc0aaaaaaaaaa6666666660088888888880066666666600000000000000000000000000000000
eeeeeeeeeee05565056550eeeeeeeeeeaaaaaaaaa0000000000cc0aaaaaaaaaa6666666666008888888800666666666600000000000000000000000000000000
eeeeeeeeeee05650e05650eeeeeeeeeeaaaaaaaaa0999999990cc0aaaaaaaaaa6666666666600888888006666666666600000000000000000000000000000000
eeeeeeeeee055550e055550eeeeeeeeeaaaaaaaaa0999999990cc0aaaaaaaaaa6666666666660088880066666666666600000000000000000000000000000000
eeeeeeeeee05500eee00550eeeeeeeeeaaaaaaaaa0000000000cc0aaaaaaaaaa6666666666666008800666666666666600000000000000000000000000000000
eeeeeeeeeee00eeeeeee00eeeeeeeeeeaaaaaaaaaaaaaaaaaa0000aaaaaaaaaa6666666666666600006666666666666600000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa6666666666666660066666666666666600000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa6666666666666666666666666666666600000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006666666666666666000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006666666666666666000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006666666666666666000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006666666666666666000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006666666666666666000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006666666666666666000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006666666666666666000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006666666666666666000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
__sfx__
000300000d7500d7500d7500840008400084000c4000c4000c4000b40012400074000a40008400034000630000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002705026050260502605022100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001275012750187501875000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
