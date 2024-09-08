pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8

-- pex labs splash screen

-- particle system
particles = {}
for i=1,50 do
 add(particles, {
  x=rnd(128),
  y=rnd(128),
  dx=rnd(2)-1,
  dy=rnd(2)-1,
  c=rnd({7,12,13,14})
 })
end

-- logos
pex = [[
 ____  ____  _  _
(  _ \(  __)( \/ )
 ) __/ ) _)  )  ( 
(__)  (____)(_/\_)
]]

labs = [[
    __     __    
   / /__ _/ /  ___
  / / _ `/ _ \(_-<
 /_/\_,_/_.__/___/
]]

function _init()
  t = 0
  pex_y = -32 
  labs_y = 128  
  fade = 0
  start_time=time()

  serial_hello()
end

function _update()
 t += 1
 
 -- update particles
 for p in all(particles) do
  p.x += p.dx
  p.y += p.dy
  if (p.x < 0 or p.x > 128) p.dx *= -1
  if (p.y < 0 or p.y > 128) p.dy *= -1
 end
 
 if t < 60 then
  pex_y = min(pex_y + 2, 24)  -- Move to y=32
 end
 
 if t >= 30 and t < 90 then
  labs_y = max(labs_y - 2, 56)  -- Move to y=62
 end
 
 if t < 30 then
  fade = min(fade + 0.05, 1)
 end

 if time()-start_time > 3 then
   load('main_menu.p8')
 end
end

function _draw()
 cls(0)
 
 -- draw particles
 for p in all(particles) do
  pset(p.x, p.y, p.c)
 end
 
 local pex_lines = split(pex, "\n")
 for i, line in ipairs(pex_lines) do
  local y = pex_y + i*8
  local x = 64 - #line*2  -- Center horizontally
  print(line, x, y, 7)  -- Print in white
 end
 
 -- draw  labs
 local labs_lines = split(labs, "\n")
 for i, line in ipairs(labs_lines) do
  local y = labs_y + i*8
  local x = 64 - #line*2  -- Center horizontally
  print(line, x, y, 12)  -- Print in light blue
 end
 
 for i=0,15 do
  for j=0,15 do
   if rnd() > fade then
    rectfill(i*8,j*8,i*8+7,j*8+7,0)
   end
  end
 end
end
