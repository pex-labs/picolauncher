pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- screenshot and recording viewer

#include serial.p8

screenshot_dir='screenshots'
screenshots={}
select=0
-- TODO handle no files in screenshot dir
function _init()
  serial_hello()
  screenshots=serial_ls('screenshots')
  for sh in all(screenshots) do
    printh(sh)
  end
end


function _update()
  if btnp(0) then
    select=(select-1)%(#screenshots)
    import(screenshot_dir..'/'..screenshots[select+1])
  end
  if btnp(1) then
    select=(select+1)%(#screenshots)
    import(screenshot_dir..'/'..screenshots[select+1])
  end
end

function _draw()
  cls(1)
  sspr(0, 0, 128, 128, 0, 0)
  rectfill(0, 120, 128, 128, 8)
  print(screenshots[select+1], 4, 121, 6)
end
