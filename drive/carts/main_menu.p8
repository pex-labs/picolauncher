pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8
#include menu.p8
#include tween.lua

-- TODO should make this menu scroll too
app_menu=menu_new({
  --{label='games', icon=6, func=function()os_load('pexsplore_bbs.p8', '', 'local')end},
  {label='pexsplore', icon=1, func=function()os_load('pexsplore_home.p8')end},
  -- {label='files', icon=7, func=function()os_load('pexsplore_bbs.p8', '', 'local')end}, -- load local games only
  -- {label='apps', icon=6, func=function()os_load('apps.p8')end},
  {label='photos', icon=2, func=function()os_load('gallery.p8')end},
  {label='tunes', icon=3, func=function()os_load('tunes.p8')end},
  {label='settings', icon=4, func=function()os_load('settings.p8')end},
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
    sfx(2)
    queued_fn=app_menu:index()
    queued_fn_time=time()
    make_transition_tween()
  end
end

-- compute the desired location of the app cursor
function target_app_cursor_y()
  return 20*(app_menu:index()-1) - 1
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
  local hour = tostr(stat(93))
  if #hour < 2 then 
    hour = "0"..hour
  end
  local minute = tostr(stat(94))
  if #minute < 2 then 
    minute = "0"..minute
  end

  print(hour..":"..minute, 7, 4, 7)
  draw_wifi_icon(83, 4)
  draw_bat_icon(94, 4)
  print('42%', 108, 4, 7)

  -- draw logo
  pal(7, 0)
  pal(12, 0)
  sspr(0, 18, 110, 14, 64-110/2, 28-app_cursor_y+1)
  pal()
  sspr(0, 18, 110, 14, 64-110/2, 28-app_cursor_y)
  local str="BY PEX LABS"
  print(str, 64-#str*2, 44-app_cursor_y, 6)

  -- draw menu items
  for i, menuitem in ipairs(app_menu.items) do

    x_offset = 34
    y_offset = 64+20*(i-1)
    sspr(16*(menuitem.icon-1), 0, 16, 18, x_offset, y_offset-app_cursor_y)

    print(menuitem.label, x_offset+20, y_offset+7-app_cursor_y, 5)

    is_sel=app_menu:index() == i
    if is_sel then c=7 else c=6 end
    print(menuitem.label, x_offset+20, y_offset+6-app_cursor_y, c)

  end

  -- draw app cursor
  cursor_x = x_offset-1
  cursor_y = 64
  rect(cursor_x, cursor_y, cursor_x+17, cursor_y+19, 7)

  if queued_fn != nil then
    circfill(40, 64, transition_radius, 0)
    if time()-queued_fn_time > 0.5 then
      app_menu.items[queued_fn].func()
    end
  end
end

__gfx__
cccccccccccccccc9999999999999999bbbbbbbbbbbbbbbbeeeeeeeeeeeeeeeedddddddddddddddd888888888888888866666666666666660000000000000000
cccccccccccccccc9999999999999999bbbbbbbbbbbbbbbbeeeeeeeeeeeeeeeeddddddd00ddddddd888888888888888866666666666666660000000000000000
cccccccccccccccc9999999999999999bbbbbbb1111111bbeeeeeeeeeeeeeeeeddddddd00ddddddd887777788777778866666666666666660000000000000000
cccccccaaccccccc9999999999999999bbbbbbb1111111bbeeeeeddeeeeeeeeedddd00d00d00dddd887888788788878866666666666666660000000000000000
cccccccaaccccccc9999000000999999bbbbbbb11bbbbbbbeeeeeddeeeeeeeeeddd000d00d000ddd8878887887888788666666699777c9660000000000000000
cccccaaaaaaccccc9999000000999999bbbbbbb11bbbbbbbeeeeeddddddddeeedd000dd00dd000dd887888788788878866999999999999660000000000000000
cccccaaaaaaccccc9900005500000099bbbbbbb11bbbbbbbeeeeeddddddddeeedd00ddd00ddd00dd887777788777778866999999999999660000000000000000
caaaaaaaaaaaaaac9900005500000099bbbbbbb11bbbbbbbeeeeeddeeddeeeeedd00ddd00ddd00dd888888888888888866999999999999660000000000000000
caaaaaaaaaaaaaac990055cc55005599bbb111111bbbbbbbeeeeeddeeddeeeeedd00ddd00ddd00dd888888888888888866999999999999660000000000000000
cccaaaaaaaaaaccc990055cc55005599bbb111111bbbbbbbeeeddddddddeeeeedd00dddddddd00dd887777788777778866999999999999660000000000000000
cccaaaaaaaaaaccc9900005500005599bbb111111bbbbbbbeeeddddddddeeeeedd000dddddd000dd887888788788878866999999999999660000000000000000
cccaaccccccaaccc9900005500005599bbb111111bbbbbbbeeeeeeeeeddeeeeeddd000dddd000ddd887888788788878866999999999999660000000000000000
cccaaccccccaaccc9999999999999999bbb111111bbbbbbbeeeeeeeeeddeeeeedddd00000000dddd887888788788878866666666666666660000000000000000
cccccccccccccccc9999999999999999bbbbbbbbbbbbbbbbeeeeeeeeeeeeeeeeddddd000000ddddd887777788777778866666666666666660000000000000000
cccccccccccccccc9999999999999999bbbbbbbbbbbbbbbbeeeeeeeeeeeeeeeedddddddddddddddd888888888888888866666666666666660000000000000000
cccccccccccccccc9999999999999999bbbbbbbbbbbbbbbbeeeeeeeeeeeeeeeedddddddddddddddd888888888888888866666666666666660000000000000000
dddddddddddddddd44444444444444443333333333333333222222222222222255555555555555552222222222222222dddddddddddddddd0000000000000000
dddddddddddddddd44444444444444443333333333333333222222222222222255555555555555552222222222222222dddddddddddddddd0000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777770077777777000077777700007777777700cc000000cccccc00cc00cc00cccc000000cccc00cc00cc00cccccc00cccccc0000000000000000000000
00777777770077777777000077777700007777777700cc000000cccccc00cc00cc00cccc000000cccc00cc00cc00cccccc00cccccc0000000000000000000000
77770077770000777700007777000000777700777700cc000000cc00cc00cc00cc00cc00cc00cc000000cc00cc00cc000000cc00cc0000000000000000000000
77770077770000777700007777000000777700777700cc000000cc00cc00cc00cc00cc00cc00cc000000cc00cc00cc000000cc00cc0000000000000000000000
77777777770000777700007777000000777700777700cc000000cccccc00cc00cc00cc00cc00cc000000cccccc00cccc0000cccc000000000000000000000000
77777777770000777700007777000000777700777700cc000000cccccc00cc00cc00cc00cc00cc000000cccccc00cccc0000cccc000000000000000000000000
77770000000000777700007777000000777700777700cc000000cc00cc00cc00cc00cc00cc00cc000000cc00cc00cc000000cc00cc0000000000000000000000
77770000000000777700007777000000777700777700cc000000cc00cc00cc00cc00cc00cc00cc000000cc00cc00cc000000cc00cc0000000000000000000000
77770000000077777777007777777700777777770000cccccc00cc00cc0000cccc00cc00cc0000cccc00cc00cc00cccccc00cc00cc0000000000000000000000
77770000000077777777007777777700777777770000cccccc00cc00cc0000cccc00cc00cc0000cccc00cc00cc00cccccc00cc00cc0000000000000000000000
__sfx__
000300000d7500d7500d7500840008400084000c4000c4000c4000b40012400074000a40008400034000630000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002705026050260502605022100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001275012750187501875000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
