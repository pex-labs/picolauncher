pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8
#include menu.p8
#include tween.lua

-- TODO should make this menu scroll too
app_menu=menu_new({
  {label='pexsplore', icon=1, func=function()load('pexsplore_home.p8', 'back to menu')end},
  {label='apps', icon=6, func=function()load('apps.p8', 'back to menu')end},
  {label='photos', icon=2, func=function()load('gallery.p8', 'back to menu')end},
  {label='tunes', icon=3, func=function()load('tunes.p8', 'back to menu')end},
  {label='settings', icon=4, func=function()load('settings.p8', 'back to menu')end},
  -- TODO: only quits to prompt if not in exported binary
  {label='power off', icon=5, func=function()serial_shutdown()end},
})

function _init()
  app_cursor_y = target_app_cursor_y()
end

function wait(a) for i = 1,a do flip() end end

transition_radius=0
transition_tween={}
function make_transition_tween()
  transition_tween=tween_machine:add_tween({
    func=outQuart,
    v_start=0,
    v_end=200,
    duration=1
  })
  transition_tween:register_step_callback(function(pos)
    transition_radius=pos
  end)
  transition_tween:register_finished_callback(function(tween)
    tween:remove()
  end)
  transition_tween:restart()
end


queued_fn=nil
queued_fn_time=0
function _update60()
  tween_machine:update()

  if btnp(2) then
    app_menu:up()
    sfx(0)
    make_app_cursor_tween(target_app_cursor_y())
  elseif btnp(3) then
    app_menu:down()
    sfx(0)
    make_app_cursor_tween(target_app_cursor_y())
  elseif btnp(5) then
    -- sfx(1)
    queued_fn=app_menu:index()
    queued_fn_time=time()
    make_transition_tween()
  end
end

-- compute the desired location of the app cursor
function target_app_cursor_y()
  return 16 + 20*(app_menu:index()-1) - 1
end

-- x and y are top left corner
function draw_wifi_icon(x, y)
  -- TODO: different wifi level indicator
  -- TODO: make this actually do something
  col=7
  line(x, y+3, x, y+4, 7)
  line(x+2, y+2, x+2, y+4, 7)
  line(x+4, y+1, x+4, y+4, 7)
  line(x+6, y, x+6, y+4, 7)
end

function draw_bat_icon(x, y)
  -- TODO: accurately reflect battery level
  col=7
  bat_level=3
  rect(x, y, x+9, y+4, 7)
  rectfill(x+1, y+1, x+1+bat_level, y+3, 7)
  line(x+10, y+1, x+10, y+3, 7)
end

app_cursor_tween={}
app_cursor_y=0
function make_app_cursor_tween(new_y)
  app_cursor_tween=tween_machine:add_tween({
    func=outQuart,
    v_start=app_cursor_y,
    v_end=new_y,
    duration=0.25
  })
  app_cursor_tween:register_step_callback(function(pos)
    app_cursor_y=pos
  end)
  app_cursor_tween:register_finished_callback(function(tween)
    tween:remove()
  end)
  app_cursor_tween:restart()
end

function _draw()
  cls(1)

  -- top bar
  print(stat(93)..":"..stat(94), 7, 4, 7)
  draw_wifi_icon(83, 4)
  draw_bat_icon(94, 4)
  print('42%', 108, 4, 7)

  -- draw menu items
  for i, menuitem in ipairs(app_menu.items) do

    x_offset = 28
    y_offset = 16+20*(i-1)
    sspr(16*(menuitem.icon-1), 0, 16, 18, x_offset, y_offset)

    print(menuitem.label, x_offset+20, y_offset+7, 5)

    is_sel=app_menu:index() == i
    if is_sel then
      print(menuitem.label, x_offset+20, y_offset+6, 7)
    else
      print(menuitem.label, x_offset+20, y_offset+6, 6)
    end

  end

  -- draw app cursor
  cursor_x = x_offset-1
  cursor_y = app_cursor_y
  rect(cursor_x, cursor_y, cursor_x+17, cursor_y+19, 7)

  if queued_fn != nil then
    circfill(28+8, 16+8+20*(queued_fn-1), transition_radius, 0)
    if time()-queued_fn_time > 0.5 then
      app_menu.items[queued_fn].func()
    end
  end
end

__gfx__
cccccccccccccccc9999999999999999bbbbbbbbbbbbbbbbeeeeeeeeeeeeeeeedddddddddddddddd888888888888888800000000000000000000000000000000
cccccccccccccccc9999999999999999bbbbbbbbbbbbbbbbeeeeeeeeeeeeeeeeddddddd00ddddddd888888888888888800000000000000000000000000000000
cccccccccccccccc9999999999999999bbbbbbb1111111bbeeeeeeeeeeeeeeeeddddddd00ddddddd887777788777778800000000000000000000000000000000
cccccccaaccccccc9999999999999999bbbbbbb1111111bbeeeeeddeeeeeeeeedddd00d00d00dddd887888788788878800000000000000000000000000000000
cccccccaaccccccc9999000000999999bbbbbbb11bbbbbbbeeeeeddeeeeeeeeeddd000d00d000ddd887888788788878800000000000000000000000000000000
cccccaaaaaaccccc9999000000999999bbbbbbb11bbbbbbbeeeeeddddddddeeedd000dd00dd000dd887888788788878800000000000000000000000000000000
cccccaaaaaaccccc9900005500000099bbbbbbb11bbbbbbbeeeeeddddddddeeedd00ddd00ddd00dd887777788777778800000000000000000000000000000000
caaaaaaaaaaaaaac9900005500000099bbbbbbb11bbbbbbbeeeeeddeeddeeeeedd00ddd00ddd00dd888888888888888800000000000000000000000000000000
caaaaaaaaaaaaaac990055cc55005599bbb111111bbbbbbbeeeeeddeeddeeeeedd00ddd00ddd00dd888888888888888800000000000000000000000000000000
cccaaaaaaaaaaccc990055cc55005599bbb111111bbbbbbbeeeddddddddeeeeedd00dddddddd00dd887777788777778800000000000000000000000000000000
cccaaaaaaaaaaccc9900005500005599bbb111111bbbbbbbeeeddddddddeeeeedd000dddddd000dd887888788788878800000000000000000000000000000000
cccaaccccccaaccc9900005500005599bbb111111bbbbbbbeeeeeeeeeddeeeeeddd000dddd000ddd887888788788878800000000000000000000000000000000
cccaaccccccaaccc9999999999999999bbb111111bbbbbbbeeeeeeeeeddeeeeedddd00000000dddd887888788788878800000000000000000000000000000000
cccccccccccccccc9999999999999999bbbbbbbbbbbbbbbbeeeeeeeeeeeeeeeeddddd000000ddddd887777788777778800000000000000000000000000000000
cccccccccccccccc9999999999999999bbbbbbbbbbbbbbbbeeeeeeeeeeeeeeeedddddddddddddddd888888888888888800000000000000000000000000000000
cccccccccccccccc9999999999999999bbbbbbbbbbbbbbbbeeeeeeeeeeeeeeeedddddddddddddddd888888888888888800000000000000000000000000000000
dddddddddddddddd4444444444444444333333333333333322222222222222225555555555555555222222222222222200000000000000000000000000000000
dddddddddddddddd4444444444444444333333333333333322222222222222225555555555555555222222222222222200000000000000000000000000000000
__sfx__
000300000d7500d7500d7500840008400084000c4000c4000c4000b40012400074000a40008400034000630000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002705026050260502605022100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
