pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8


-- library
function tcontains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

-- draws a filled convex polygon
-- v is an array of vertices
-- {x1, y1, x2, y2} etc
function render_poly(v,col)
 col=col or 5

 -- initialize scan extents
 -- with ludicrous values
 local x1,x2={},{}
 for y=0,127 do
  x1[y],x2[y]=128,-1
 end
 local y1,y2=128,-1

 -- scan convert each pair
 -- of vertices
 for i=1, #v/2 do
  local next=i+1
  if (next>#v/2) next=1

  -- alias verts from array
  local vx1=flr(v[i*2-1])
  local vy1=flr(v[i*2])
  local vx2=flr(v[next*2-1])
  local vy2=flr(v[next*2])

  if vy1>vy2 then
   -- swap verts
   local tempx,tempy=vx1,vy1
   vx1,vy1=vx2,vy2
   vx2,vy2=tempx,tempy
  end 

  -- skip horizontal edges and
  -- offscreen polys
  if vy1~=vy2 and vy1<128 and
   vy2>=0 then

   -- clip edge to screen bounds
   if vy1<0 then
    vx1=(0-vy1)*(vx2-vx1)/(vy2-vy1)+vx1
    vy1=0
   end
   if vy2>127 then
    vx2=(127-vy1)*(vx2-vx1)/(vy2-vy1)+vx1
    vy2=127
   end

   -- iterate horizontal scans
   for y=vy1,vy2 do
    if (y<y1) y1=y
    if (y>y2) y2=y

    -- calculate the x coord for
    -- this y coord using math!
    x=(y-vy1)*(vx2-vx1)/(vy2-vy1)+vx1

    if (x<x1[y]) x1[y]=x
    if (x>x2[y]) x2[y]=x
   end 
  end
 end

 -- render scans
 for y=y1,y2 do
  local sx1=flr(max(0,x1[y]))
  local sx2=flr(min(127,x2[y]))

  local c=col*16+col
  local ofs1=flr((sx1+1)/2)
  local ofs2=flr((sx2+1)/2)
  memset(0x6000+(y*64)+ofs1,c,ofs2-ofs1)
  pset(sx1,y,c)
  pset(sx2,y,c)
 end 
end

-- application code
cart_dir='carts'
label_dir='labels'

select=0
carts=ls(cart_dir)
labels=ls(label_dir)

function _init()
    serial_hello()
    load_label()
end

function cur_cart()
    return carts[select+1]
end

function load_label()
    -- load cartridge art of current cartridge into memory
    if tcontains(labels, cur_cart()) then
        reload(0x0000, 0x0000, 0x4000, label_dir .. '/' .. cur_cart())
    end
end

function _update()
    if btnp(0) then
        select=(select-1)%(#carts)
        load_label()
    end
    if btnp(1) then
        select=(select+1)%(#carts)
        load_label()
    end
    if btnp(5) then
        load(cart_dir .. '/' .. cur_cart(), 'back to pexsplore')
    end
end

function _draw()
    cls(1)
    color(0)
    sspr(0, 0, 128, 128, 0, 0)
    render_poly({2, 64, 8, 58, 8, 71}, 10)
    render_poly({126, 64, 120, 58, 120, 71}, 10)

    -- w = 50
    -- h = 8
    -- rectfill(64-w, 100-h, 64+w, 100+h, 6)
    -- print(cur_cart(), 64-#cur_cart()*2, 100, 0)

    -- for i, filename in ipairs(carts) do
    --     c=6
    --     if select+1 == i then
    --         c=7
    --     end
    --     color(c)
    --     print(i .. ': ' .. filename)
    -- end
end

-- use serial to fetch (downscaled) labels
-- they can be kept in extra memory region
-- when they need to be rendered can be quickly swapped over to spritesheet
function _load_label(labelname)
      
end

__label__
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffff777777777777777777777777777777777777777777777777777777777777777777ff777777777777777777ffffffffffffffffffff
ffffffffffffffffffffff777777777777777777777777777777777777777777777777777777777777777777ff777777777777777777ffffffffffffffffffff
ffffffffffffffffffffff77hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77ff77hhhhhhhhhhhhhh77ffffffffffffffffffff
ffffffffffffffffffffff77hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77ff77hhhhhhhhhhhhhh77ffffffffffffffffffff
ffffffffffffffffffffff77hhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahhaaaaaaaaaahh777777hhaaaaaaaaaahh77ffffffffffffffffffff
ffffffffffffffffffffff77hhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahhaaaaaaaaaahh777777hhaaaaaaaaaahh77ffffffffffffffffffff
ffffffffffffffffffffff77hhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahhaaaaaaaaaahhhhhhhhhhaaaaaaaaaahh77ffffffffffffffffffff
ffffffffffffffffffffff77hhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahhaaaaaaaaaahhhhhhhhhhaaaaaaaaaahh77ffffffffffffffffffff
ffffffffffffffffffffff77hhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahh77ffffffffffffffffffff
ffffffffffffffffffffff77hhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahh77ffffffffffffffffffff
ffffffffffffffffffffff77hhaaaaaahhaaaaaahhhhhhaaaaaahhhhhhaaaaaahhaaaaaahhaaaaaahhaaaaaahhaaaaaahhhhhhhhhh77ffffffffffffffffffff
ffffffffffffffffffffff77hhaaaaaahhaaaaaahhhhhhaaaaaahhhhhhaaaaaahhaaaaaahhaaaaaahhaaaaaahhaaaaaahhhhhhhhhh77ffffffffffffffffffff
ffffffffffffffffffffff77hhaaaaaaaaaaaaaahhhhhhaaaaaahhhhhhaaaaaaaaaaaaaahhaaaaaahhaaaaaahhaaaaaaaaaaaaaahh77ffffffffffffffffffff
ffffffffffffffffffffff77hhaaaaaaaaaaaaaahhhhhhaaaaaahhhhhhaaaaaaaaaaaaaahhaaaaaahhaaaaaahhaaaaaaaaaaaaaahh77efffffffffffffffffff
ffffffffffffffffffffff77hhaaaaaaaaaahhhhhhhhhhaaaaaahhhhhhaaaaaaaaaahhhhhhaaaaaahhaaaaaahhaaaaaaaaaaaaaahh77eeeeefffffffffffffff
ffffffffffffffffffffff77hhaaaaaaaaaahhhhhhhhhhaaaaaahhhhhhaaaaaaaaaahhhhhhaaaaaahhaaaaaahhaaaaaaaaaaaaaahh77eeeeeeefffffffffffff
ffffffffffffffffffffff77hhaaaaaaaaaaaaaahh77hhaaaaaahh77hhaaaaaaaaaaaaaahhaaaaaahhaaaaaahhaaaaaaaaaaaaaahh77eeeeeeeeefffffffffff
ffffffffffffffffffffff77hhaaaaaaaaaaaaaahh77hhaaaaaahh77hhaaaaaaaaaaaaaahhaaaaaahhaaaaaahhaaaaaaaaaaaaaahh77eeeeeeeeeeefffffffff
ffffffffffffffffffffff77hhaaaaaahhaaaaaahhhhhhaaaaaahhhhhhaaaaaahhaaaaaahhaaaaaahhaaaaaahhhhhhhhhhaaaaaahh77eeeeeeeeeeeeffffffff
fffffffffffffffffffffe77hhaaaaaahhaaaaaahhhhhhaaaaaahhhhhhaaaaaahhaaaaaahhaaaaaahhaaaaaahhhhhhhhhhaaaaaahh77eeeeeeeeeeeeefffffff
ffffffffffffffffffffee77hhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahhaaaaaahhaaaaaahhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahh77eeeeeeeeeeeeeeffffff
fffffffffffffffffffeee77hhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahhaaaaaahhaaaaaahhaaaaaaaaaaaaaahhaaaaaaaaaaaaaahh77eeeeeeeeeeeeeeefffff
ffffffffffffffffffeeee77hhaaaaaaaaaaaaaahhaaaaaahhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhaaaaaahhaaaaaaaaaahhhhhh77eeeeeeeeeeeeeeeeffff
fffffffffffffffffeeeee77hhaaaaaaaaaaaaaahhaaaaaahhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhaaaaaahhaaaaaaaaaahhhhhh77eeeeeeeeeeeeeeeeefff
fffffffffffffffffeeeee77hhaaaaaaaaaaaaaahhaaaaaahh77hh77hh777777hh777777hh77hh77hhaaaaaahhaaaaaaaaaahhhhhh77eeeeeeeeeeeeeeeeeeff
ffffffffffffffffeeeeee77hhaaaaaaaaaaaaaahhaaaaaahh77hh77hh777777hh777777hh77hh77hhaaaaaahhaaaaaaaaaahhhhhh77eeeeeeeeeeeeeeeeeeff
ffffffffffffffffeeeeee77hhhhhhhhhhhhhhhhhhhhhhhhhh77hh77hhhh77hhhhhh77hhhh77hh77hhhhhhhhhhhhhhhhhhhhhhhhhh77eeeeeeeeeeeeeeeeeeef
ffffffffffffffffeeeeee77hhhhhhhhhhhhhhhhhhhhhhhhhh77hh77hhhh77hhhhhh77hhhh77hh77hhhhhhhhhhhhhhhhhhhhhhhhhh77eeeeeeeeeeeeeeeeeeef
fffffffffffffffeeeeeee77hhhhhhhhhhhhhhhhhhhhhhhhhh77hh77hhhh77hhhhhh77hhhh777777hhhhhhhhhhhhhhhhhhhhhh777777eeeeeeeeeeeeeeeeeeee
fffffffffffffffeeeeee477hhhhhhhhhhhhhhhhhhhhhhhhhh77hh77hhhh77hhhhhh77hhhh777777hhhhhhhhhhhhhhhhhhhhhh777777eeeeeeeeeeeeeeeeeeee
fffffffffffffffeeeeee477hhhhhhhhhhhhhhhhhhhhhhhhhh777777hhhh77hhhhhh77hhhh77hh77hhhhhhhhhhhhhhhhhhhhhh77eeeeeeeeeeeeeeeeeeeeeeee
fffffffffffffffeeeee4477hhhhhhhhhhhhhhhhhhhhhhhhhh777777hhhh77hhhhhh77hhhh77hh77hhhhhhhhhhhhhhhhhhhhhh77eeeeeeeeeeeeeeeeeeeeeeee
fffffffffffffffeeeee4477777777777777hhhhhhhhhhhhhh777777hh777777hhhh77hhhh77hh77hh77hhhhhhhhhhhhhh777777eeeeeeeeeeeeeeeeeeeeeeee
fffffffffffffffeeee44477777777777777hhhhhhhhhhhhhh777777hh777777hhhh77hhhh77hh77hh77hhhhhhhhhhhhhh777777eeeeeeeeeeeeeeeeeeeeeee4
fffffffffffffffeeee44444444444777777hh6666666666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77hh6666666666hh77eeeeeeeeeeeeeeeeeeeeeeeeee44
ffffeeeeeeeffffeeee44444444444777777hh6666666666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77hh6666666666hh77eeeeeeeeeeeeeeeeeeeeeeeee444
feeeeeeeeeeeeeffeee4444444444477hhhhhh6666666666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6666666666hh77eeeeeee2222eeeeeeeeeeeeee444
eeeeeeeeeeeeeeeeeee4444444444477hhhhhh6666666666hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6666666666hh77eeeeee222222eeeeeeeeeeee4444
eeeeeeeeeeeeeeeeeee4444444444477hh66666666666666hh666666hh666666hh66666666666666hh66666666666666hh77eeeee22222222eeeeeeeeeee4444
eeeeeeeeeeeeeeeeeeee444444444477hh66666666666666hh666666hh666666hh66666666666666hh66666666666666hh77eeee2222222222eeeeeeeeee4444
eeeeeeeeeeeeeeeeeeee444444444477hh666666hhhhhhhhhh666666hh666666hh666666hh666666hh666666hhhhhhhhhh77eeee2222222222eeeeeeeeee4444
eeeeeeeeeeeeeeeeeeeee44444444477hh666666hhhhhhhhhh666666hh666666hh666666hh666666hh666666hhhhhhhhhh77eeee2222222222eeeeeeeeeee444
eeeeeeeeeeeeeeeeeeeee44444444477hh666666hhhhhhhhhh666666hh666666hh666666hh666666hh66666666666666hh77eeee2222222222eeeeeeeeeee444
eeeeeeeeeeeeeeeeeeeeee4444444477hh666666hhhhhhhhhh666666hh666666hh666666hh666666hh66666666666666hh77eeeee22222222eeeeeeeeeeeee44
eeeeeeeeeeeeehhhheeeeee444444477hh666666hhhhhhhhhh666666hh666666hh666666hh666666hh66666666666666hh77eeeeee222222eeeeeeeeeeeeeee4
eeeeeeeeeeehhhhhhhheeeeee4444477hh666666hhhhhhhhhh666666hh666666hh666666hh666666hh66666666666666hh77444eeee2222eeeeeeeeeeeeeeeee
eeeeeeeeeehhhhhhhhhheeeeeee44477hh666666hh666666hh666666hh666666hh666666hh666666hh66666666666666hh77444444eeeeeeeeeeeeeeeeeeeeee
eeeeeeeeehhhhhhhhhhhheeeeeeeee77hh666666hh666666hh666666hh666666hh666666hh666666hh66666666666666hh774444444eeeeeeeeeeeeeeeeeeeee
2222eeeeehhhhhhhhhhhheeeeeeeee77hh666666hh666666hh666666hh666666hh666666hh666666hhhhhhhhhh666666hh77444444444eeeeeeeeeeeeeeeeeee
22222222hhhhhhhhhhhhhheeeeeeee77hh666666hh666666hh666666hh666666hh666666hh666666hhhhhhhhhh666666hh774444444444eeeeeeeeeeeeeeeeee
22222222hhhhhhhhhhhhhheeeeeeee77hh66666666666666hh66666666666666hh666666hh666666hh66666666666666hh7744444444444eeeeeeeeeeeeeeeee
22222222hhhhhhhhhhhhhheeeeeeee77hh66666666666666hh66666666666666hh666666hh666666hh66666666666666hh7744444444444eeehhhheeeeeeeeee
22222222hhhhhhhhhhhhhheeeeeeee77hh66666666666666hhhhhh6666666666hh666666hh666666hh6666666666hhhhhh77244444444444hhhhhhhheeeeeeee
222222222hhhhhhhhhhhheeeeeeeee77hh66666666666666hhhhhh6666666666hh666666hh666666hh6666666666hhhhhh7722244444444hhhhhhhhhheeeeeee
222222222hhhhhhhhhhhheeeeeeeee77hh66666666666666hhhhhh6666666666hh666666hh666666hh6666666666hhhhhh772222444444hhhhhhhhhhhheeeeee
2222222222hhhhhhhhhheeeeeeeeee77hh66666666666666hhhhhh6666666666hh666666hh666666hh6666666666hhhhhh772222444444hhhhhhhhhhhh4eeeee
22222222222hhhhhhhh44eeeeeeeee77hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77222224444hhhhhhhhhhhhhh44eee
2222222222222hhhh22244eeeeeeee77hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77222224444hhhhhhhhhhhhhh4444e
2222222222222222222244eeeeeeee77hhhhhhhhhhhhhhhhhh77hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh777777222222444hhhhhhhhhhhhhh44444
22222222222222222222244eeeeeee77hhhhhhhhhhhhhhhhhh77hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh777777222222444hhhhhhhhhhhhhh44444
22222222222222222222224eeeeeee77hhhhhhhhhhhhhhhhhh77hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7722222222224444hhhhhhhhhhhh444444
222222222222222222222224eeeeee77hhhhhhhhhhhhhhhhhh77hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7722222222224444hhhhhhhhhhhh444444
222222222222222222222224eee444777777777777777777777777777777777777777777777777777777777777777777222222222444444hhhhhhhhhh4444444
222222222222222222222222e444447777777777777777777777777777777777777777777777777777777777777777772222222224444444hhhhhhhh44444444
222222222222222222222222444444222222222222224444444444422222222222222222222444444444444444222222222222224444444444hhhh4444444444
22222222222222222222222224442222222222222222224444442222222222222222222222244444444444444422222222222222444444444444444444444444
222222hhhhhhhhh22222222224422222222222222222222444422222222222222222222222444444444444444442222222222224444444444444444444444444
22hhhhhhhhhhhhhhhhh2222222222222222222222222222244222222222222hhhhhhhhh222444444444444444444422222222444444444444444444444444444
hhhhhhhhhhhhhhhhhhhhh22222222222222222222222222222222222222hhhhhhhhhhhhhhh444444444444444444444222244444444444444444444444222222
hhhhhhhhhhhhhhhhhhhhhhh2222222222222222222222222222222222hhhhhhhhhhhhhhhhhhh4444444444444444444444444444444444444444444222222222
hhhhhhhhhhhhhhhhhhhhhhhhh222222222222222222222222222222hhhhhhhhhhhhhhhhhhhhhhh44444444444444444444444444444444444444422222222222
hhhhhhhhhhhhhhhhhhhhhhhhhh2222222222222222222222222222hhhhhhhhhhhhhhhhhhhhhhhhh4444444444444444444444444444444444444222222222222
hhhhhhhhhhhhhhhhhhhhhhhhhhh22222222222222222222222222hhhhhhhhhhhhhhhhhhhhhhhhhhh444444444444444444444444444444444422222222222222
hhhhhhhhhhhhhhhhhhhhhhhhhhhh22222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh44444444444444444444222222222222222
hhhhhhhhhhhhhhhhhhhhhhhhhhhhh2222222h22222222222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh2244444444h44444444444444444442222222222222222
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhh222222h2hhhhhhhh222222222hhhhhhhhhhhhhhhhhhh22222222hhhhhhhhh4h44444444hhhhhh444422222222222222222
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh22222h2hhhhhhhh222222222hhhhhhhhhhhhhhhhhhh22222222hhh2ee2hh4h444444hhhhhhhhhh4422222222222222222
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh2222h2hh5dd5hh222222222hhhhhhhhhhhh28882hh22222222hheeeee2h4h4444hhhhhhhhhhhhhh22222222222222222
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh2222h2h7dddd5h222533522hhhhhhhhhhh2888882h222222h0h2eeeffeh4h444hhhhhhhhhhhhhhhh2222222222222222
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh222h2557d22dh22333339ahhhhhhhhhhh8228888h92222h00heehef0eh4h44hhhhhhhhhhhhhhhhhh222222222222222
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh222h2h57d8825253333aaahhhhhhhhhhh2678866haa92009aheehee7eh4h44hhhhhhhhhhhhhhhhhh222222222222222
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh22h2hhd8h88d233339aa2hhhhhhhhhhh6772666haaaaa0cche2h27f7h4h4hhhhhhhhhhhhhhhhhhhh22222222222222
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh22h2hhd8h88d23003a442hhh242hhhhh77066hhh9aaa0chcheehhfffh4h4hhhhhhhhhhhhhhhhhhhh22222222222222
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh2h2h5dd88ddh30h39444h994442hhhh7605666h99aa0chchee2h00fh4hhhhhhhhhhhhhhhhhhhhhhh2222222222222
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh2h253ddddd5h53333994ha94h422hhh6000666he9909acch2ee000hh4hhhhhhhhhhhhhhhhhhhhhhh2222222222222
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh2hh33d3dddhh25333339hha742222hh6h00668h8e00aaa7hhee00hhh2hhhhhhhhhhhhhhhhhhhhhhh222222hhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh3233d35hh22333332hh6777222hhhh28888h28077777hh2ee2hhh2hhhhhhhhhhhhhhhhhhhhhhh222hhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh2223333hh22533372hhh67776hhhh288882h25777777hehhee2hhhhhhhhhhhhhhhhhhhhhhhhhh2hhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh22222322h26557744h4hhehehhhh9288828h27777777heeh2eehhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh62626226hd66d5544h24ehhehhhaa8889a8h05777777hee2hee2hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh66666266h66666dd5hh224e42hhcca88caah00057777heeeh2eehhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh55555555h44444444h55555555h22222222h44444444h55555528hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh55555555h44444444h55555555h22222222hcd444444h55552888hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh55677655h44446776h555eee55h222222h0hcccd4444h55528888hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh57777775h44467777h5efffff2h22222000h7cccd444h55d888e7hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhd677766dh447777ddh2fffff22h222h0000hc77ccd44h55667777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhddd77dddh44777d06h22ff2205h2h000000h70dchhh4h56677777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh90077009h44677606h5028e005h49994000h700c0hhhh5h0aa777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh7909a097h44497766h5f8888feh2hh09990h777cc044hd0a22a70hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh77799777h4499aa77hf828828fh2222a000hh7777644h67a2hha0hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh6799a977h499a7777hf2e22e2fh2222a9h0hhh777644h679hh997hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh07h9ah67h49a47777hfffeeffeh22227aa9hch777444h67899977hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh0600a0h7h44447777h5feeeff5h2222777ahcch76444h77888877hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh0h009006h444d7777h5feeee25h22267777hcd7h4444h77e88877hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh000000h0hd6666777h552eee25h22267777hd7764444h77788e77hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh00000h0h66666677h555eeee2h22277777h77744444h77777777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh00h0000h66666666h5552eeeeh22277777h77644444h77777777hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh

