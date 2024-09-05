pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include menu.p8

app_menu=menu_new({
  {label='my games', icon=1, func=function()load('pexsplore.p8', 'back to menu')end},
  {label='photos', icon=2, func=function()load('gallery.p8', 'back to menu')end},
  {label='tunes', icon=2, func=function()load('music_player.p8', 'back to menu')end},
  {label='settings', icon=2, func=function()load('pexsplore_settings.p8', 'back to menu')end},
  {label='power off', icon=2, func=function()end},
})

function _init()
end

function _update()
  if btnp(2) then
    app_menu:up()
  elseif btnp(3) then
    app_menu:down()
  elseif btnp(5) then
    app_menu:cur().func()
  end
end

function _draw()
  cls(1)

  for i, menuitem in ipairs(app_menu.items) do

    print(menuitem.label, 60, 41+8*i, 5)

    is_sel=app_menu:index() == i
    if is_sel then
      print(menuitem.label, 60, 40+8*i, 7)
    else
      print(menuitem.label, 60, 40+8*i, 6)
    end
  end
end
