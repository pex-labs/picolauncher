pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8
#include menu.p8
#include utils.p8
#include tween.lua

bg_color=129
bar_color_1=12
bar_color_2=-4

cart_dir='carts'
label_dir='labels'
carts={}
labels={}

-- menu for each cartridge
cart_options=menu_new({
  {label='play',func=function()
    load(cart_dir .. '/' .. carts:cur(), 'back to pexsplore')
  end},
  {label='favourite',func=function()end},
  {label='download',func=function()end},
  {label='save music',func=function()end},
  {label='similar carts',func=function()end},
  {label='back',func=function()
    cart_tween_up()
    cart_tween_state = 1
  end},
})

function load_label()
  -- load cartridge art of current cartridge into memory
  if tcontains(labels, carts:cur()) then
    reload(0x0000, 0x0000, 0x1000, label_dir .. '/' .. carts:cur())
  end
end

function draw_label(x, y)
  local w=64

  -- border
  rectfill(x-w/2-2, y-w/2-11, x+w/2+2, y+w/2+2, 5)
  -- rectfill(x-w/2-2, y+w/2+7, x+w/2-5, y+w/2+13, 5)

  -- corner
  -- line(x+w/2+1, y+w/2+6, x+w/2-4, y+w/2+11, 7)
  -- line(x+w/2+1, y+w/2+7, x+w/2-4, y+w/2+12, 7)
  -- line(x+w/2+1, y+w/2+8, x+w/2-4, y+w/2+13, 7)

  -- TODO waste of tokens
  for i=0,10 do
    line(x-w/2-2, y+w/2+3+i, x+w/2+2-max(i-3, 0), y+w/2+3+i, 5)
    if i <= 8 then
      line(x-w/2, y+w/2+3+i, x+w/2-max(i-2, 0), y+w/2+3+i, 13)
    end
  end

  -- divet
  rectfill(x-w/2, y-w/2-9, x+w/2, y-w/2-3, 13)
  -- rectfill(x-w/2, y+w/2+3, x+w/2, y+w/2+11, 13)

  -- pico8 logo
  spr(128, x-w/2+1, y-w/2-8, 5, 1)

  -- edge connector
  for i=0,9 do
    rect(x-w/2+4+5*i, y+w/2+5, x-w/2+5+5*i, y+w/2+13, 9)
    rect(x-w/2+6+5*i, y+w/2+5, x-w/2+6+5*i, y+w/2+13, 10)
  end

  -- label
  rectfill(x-w/2, y-w/2, x+w/2, y+w/2, 0)
  sspr(0, 0, w, w, x-w/2, y-w/2)
end

cart_y_ease=0
-- 1 is up, -1 is down
cart_tween_state=1

cart_tween={}
cart_bobble_tween={}

function cart_tween_bobble()
  bob_amplitude=2
  cart_bobble_tween=tween_machine:add_tween({
    func=inOutSine,
    v_start=-bob_amplitude,
    v_end=bob_amplitude,
    duration=1
  })
  cart_bobble_tween:register_step_callback(function(pos)
    cart_y_ease=pos
  end)
  cart_bobble_tween:register_finished_callback(function(tween)
    tween.v_start=tween.v_end 
    tween.v_end=-tween.v_end
    tween:restart()
  end)
  cart_bobble_tween:restart()
end

function cart_tween_down()
  cart_tween=tween_machine:add_tween({
    func=outQuart,
    v_start=0,
    v_end=90,
    duration=1
  })
  cart_tween:register_step_callback(function(pos)
    cart_y_ease=pos
  end)
  cart_tween:register_finished_callback(function(tween)
    tween:remove()
  end)
  cart_tween:restart()
end

function cart_tween_up()
  cart_tween=tween_machine:add_tween({
    func=outQuart,
    v_start=90,
    v_end=0,
    duration=1
  })
  cart_tween:register_step_callback(function(pos)
    cart_y_ease=pos
  end)
  cart_tween:register_finished_callback(function(tween)
    tween:remove()
    cart_tween_bobble()
  end)
  cart_tween:restart()
end

function _init()
  -- setup dual palette
  --poke(0x5f5f,0x10)
  --for i=0,15 do pal(i,i+128,2) end
  ----memset(0x5f78,0xff,8)

  serial_hello()

  carts=menu_new(serial_ls(cart_dir))
  labels=ls(label_dir)

  cart_tween_bobble()

  load_label()
end

function _update60()
  tween_machine:update()

  if cart_tween_state > 0 then
    if btnp(2) then
      carts:up()
      load_label()
    elseif btnp(3) then
      carts:down()
      load_label()
    elseif btnp(5) then
      -- load(cart_dir .. '/' .. carts:cur(), 'back to pexsplore')
      cart_bobble_tween:remove()
      cart_tween_down()
      cart_tween_state = -1
    end
  else
    if btnp(2) then
      cart_options:up()
    elseif btnp(3) then
      cart_options:down()
    elseif btnp(4) then
      cart_tween_up()
      cart_tween_state = 1
    elseif btnp(5) then
      cart_options:cur().func()
    end
  end
end

function draw_menuitem(w, y, text, sel)
  if sel then c=7 else c=6 end
  local h=12
  rectfill(0, y, w, y+h, 13)
  line(0, y-1, w, y-1, c)
  line(w+1, y, w+1, y+h-1, c)
  line(0, y+h, w, y+h, c)
  print(text, w-#text*4-3, y+4, c)
end

function _draw()
  cls(bg_color)

  -- draw the cartridge
  label_x=90
  --draw_label(label_x, 64.5+2*sin(0.5*time()))
  draw_label(label_x, 64.5+cart_y_ease)
  str="❎view"
  print(str, label_x-#str*2, 117+cart_y_ease, 7)

  print(carts:cur(), 70, -(#cart_options.items*7)-23+cart_y_ease, 14)
  line_y=-(#cart_options.items*7)-17+cart_y_ease
  line(70, line_y, 128, line_y, 6)
  for i, menuitem in ipairs(cart_options.items) do
    is_sel=cart_options.select+1 == i
    if is_sel then
      c=7
      x_off=0
    else
      c=6
      x_off=2
    end
    print(menuitem.label, 70+x_off, -(#cart_options.items*7)-20+i*7+cart_y_ease, c)
  end

  -- selection menu
  for i, cart in ipairs(carts.items) do
    is_sel=carts.select+1 == i
    if is_sel then w=60 else w=50 end
    draw_menuitem(w, 10+15*i, cart, is_sel)
  end
  -- print(carts.select)

  -- top bar
  rectfill(0, 0, 128, 8, bar_color_1)
  print("★", 2, 2, 10)
  print("featured", 12, 2, 7)


  --for i=0,#carts do
  --end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00800007777077770077700777700000777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
097f0077077007700770007707700000700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a777e077777007700770007707707707777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b7d0077000007700770007707700007700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c00077000077770777707777000007777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
