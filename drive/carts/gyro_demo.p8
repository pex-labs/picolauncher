pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8
#include timer.p8
#include utils.p8

charx = 64
chary = 64

pitch = 0
roll = 0
i = 0
requests = 0
function _init()
  new_loadable('gyro_read', function(resp)
    printh('resp '..resp)

    local parts=split(resp, ',', true)
    pitch = parts[1]
    roll = parts[2]

    requests = requests + 1
  end, 1)
end

local threshold = 300
local speed = 5
function _update()
  -- periodically request for the gyro data
  i += 1 
  if i > 10 then
    i = 0
    request_loadable('gyro_read', {})
  end

  if pitch < -threshold then
    charx -= speed
  elseif pitch > threshold then
    charx += speed
  end

  if roll < -threshold then
    chary -= speed
  elseif roll > threshold then
    chary += speed
  end

  -- limit ball position
  charx = max(0, min(128, charx))
  chary = max(0, min(128, chary))

  update_loadables()
end

function _draw()
  cls(7)
  -- print(tostring(pitch)..' '..tostring(roll))
  -- print(tostring(requests))
  circfill(charx, chary, 5, 0)  
end
