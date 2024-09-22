pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8
#include menu.p8
#include utils.p8
#include tween.lua

bg_color=129
bar_color_1=8

function _init()
end

function _update()
  if btn(5) then
    serial_ls_exe()
  end
end

function _draw()
  cls(bg_color)
  
  -- draw menu items


  -- draw top bar
  rectfill(0, 0, 128, 8, bar_color_1)
  print("웃 ", 2, 2, 7)
  print("my apps", 12, 2, 7)
end
