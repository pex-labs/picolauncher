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
  serial(stdin, 0x4300, 1)
end

function serial_fetch_carts()
  -- send request
  -- use 0x4300 as a buffer for sending serial data arguments
  poke(chan_buf, 69)
  poke(chan_buf+1, 69)
  serial(stdout, chan_buf, 2) 

  -- read result
  --result=''
  --repeat
  --  -- also use the argument space to receive the result
  --  size = serial(stdin, chan_buf, chan_buf_size)
  --  for i=0,size do
  --    b = peek(chan_buf+i)
  --    result = result..b
  --  end
  --until(size == 0)
  --printh('result '..result)
end

function _init()
  serial_hello()
  serial_fetch_carts()
end

function _update()
end

function _draw()
  cls(0)
end
