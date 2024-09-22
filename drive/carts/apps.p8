pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8
#include menu.p8
#include utils.p8
#include tween.lua

bg_color=129
bar_color_1=8

function launch_exe(path)
  return function()
    serial_spawn(path)
  end
end

function _init()
  exes=serial_ls_exe()
  for i, exe in ipairs(exes) do
    exes[i].cmd=launch_exe(exes[i].path)
  end
  add(exes, {name="pico8", author="zep", path=nil, cmd=function()serial_spawn_pico8()end}, 1)
  add(exes, {name="splore", author="zep", path=nil, cmd=function()serial_spawn_splore()end}, 2)
  exe_menu=menu_new(exes)
end

function _update()
  if btnp(2) then
    exe_menu:up()
  elseif btnp(3) then
    exe_menu:down()
  elseif btnp(5) then
    exe_menu:cur().cmd()
  end
end

function _draw()
  cls(bg_color)
  
  -- draw menu items
  x_offset=20
  y_offset=20
  for i, menuitem in ipairs(exe_menu.items) do
    is_sel=exe_menu:index() == i
    if is_sel then
      c = 7
    else
      c = 6
    end
    print(menuitem.name, x_offset, y_offset+i*7, c)
  end

  -- draw top bar
  rectfill(0, 0, 128, 8, bar_color_1)
  print("웃 ", 2, 2, 7)
  print("my apps", 12, 2, 7)
end
