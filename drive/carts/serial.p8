pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- serial interface with the underlying operating system

stdin=0x806
stdout=0x807

chan_buf=0x4300
chan_buf_size=0x1000

-- read init message (host os provides some information)
-- see https://github.com/nlordell/p8-controller for discussion on caveats with serial read and write
function serial_hello()
  serial_readline()
end

-- read from input file until a newline is reached
-- TODO this can be refactored into a coroutine?
function serial_readline()
  result=''
  got_newline=false
  while true do
    -- also use the argument space to receive the result
    size = serial(stdin, chan_buf, chan_buf_size)
    if (size == 0) then break end
    printh('size: ' .. size)
    for i=0,size do
      b = peek(chan_buf+i)
      printh('byte: '..b)
      if b == 0x0a then
        got_newline=true
        break
      end 
      result = result..b
    end
  end
  if not got_newline then
    printh('warning: newline was not received')
  end
  printh('result '..result)
  return result
end

function serial_fetch_carts()
  -- send request
  -- use 0x4300 as a buffer for sending serial data arguments
  poke(chan_buf, 69)
  poke(chan_buf+1, 69)
  serial(stdout, chan_buf, 2) 

end

function _init()
  serial_hello()
  -- serial_fetch_carts()
end

function _update()
end

function _draw()
  cls(0)
end
