pico-8 cartridge // http://www.pico-8.com
version 42
__lua__


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
