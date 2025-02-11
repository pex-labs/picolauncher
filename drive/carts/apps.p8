pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8
#include menu.p8
#include utils.p8
#include tween.lua
#include ui.p8

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

  init_title_bar(8)
end

function _update()
  if btnp(2) then
    exe_menu:up()
  elseif btnp(3) then
    exe_menu:down()
  elseif btnp(4) then
    os_back()
  elseif btnp(5) then
    exe_menu:cur().cmd()
  end
end

function _draw()
  cls(bg_color)
  
  print("external apps", 10, 14, 6)
  line(10, 22, 118, 22, 6)
  -- draw menu items
  x_offset=12
  y_offset=20
  for i, menuitem in ipairs(exe_menu.items) do
    is_sel=exe_menu:index() == i
    if is_sel then
      c = 7
      x_shift=-2
    else
      c = 6
      x_shift=0
    end
    print(menuitem.name, x_offset+x_shift, y_offset+i*7, c)
  end

  -- draw top bar
  draw_title_bar('my apps', 8, 7, true, '웃', 7)
end
