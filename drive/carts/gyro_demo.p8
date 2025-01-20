pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8
#include timer.p8
#include utils.p8

x, y, z = 0
i = 0
requests = 0
function _init()
  new_loadable('gyro_read', function(resp)
    printh('resp '..resp)

    local parts=split(resp, ',', true)
    x = parts[1]
    y = parts[2]
    z = parts[3]

    requests = requests + 1
  end, 1)
end

function _update()
  i += 1 
  if i > 20 then
    i = 0
    request_loadable('gyro_read', {})
  end

  update_loadables()
end

function _draw()
  cls(7)
  print(tostring(x)..' '..tostring(y)..' '..tostring(z))
  print(tostring(requests))
end
