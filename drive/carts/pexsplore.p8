pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8
#include menu.p8
#include utils.p8

bg_color=129
bar_color_1=12
bar_color_2=-4

cart_dir='carts'
label_dir='labels'
carts=menu_new(ls(cart_dir))
labels=ls(label_dir)

function load_label()
    -- load cartridge art of current cartridge into memory
    if tcontains(labels, carts:cur()) then
        reload(0x0000, 0x0000, 0x4000, label_dir .. '/' .. carts:cur())
    end
end

function _init()
  -- setup dual palette
  --poke(0x5f5f,0x10)
  --for i=0,15 do pal(i,i+128,2) end
  ----memset(0x5f78,0xff,8)

  serial_hello()
  load_label()
end

function _update()
  if btnp(2) then
    carts:up()
    load_label()
  end
  if btnp(3) then
    carts:down()
    load_label()
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

  -- top bar
  rectfill(0, 0, 128, 8, bar_color_1)
  print("★", 2, 2, 10)
  print("featured", 12, 2, 6)

  for i, cart in ipairs(carts.items) do
    is_sel=carts.select+1 == i
    if is_sel then w=60 else w=50 end
    draw_menuitem(w, 10+15*i, cart, is_sel)
  end
  print(carts.select)

  -- draw the cartridge
  rect(64-32/2-1, 64-32/2-1, 64+32/2+1, 64+32/2+1, 6)
  rectfill(64-32/2, 64-32/2, 64+32/2, 64+32/2, 0)
  sspr(0, 0, 32, 32, 64-32/2, 64-32/2)


  --for i=0,#carts do
  --end
end
