pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- serial interface with the underlying operating system

channel=0x805
chan_buf=0x4300
chan_buf_size=0x1000
function fetch_carts()
  -- send request
  -- use 0x4300 as a buffer for sending serial data arguments
  poke(chan_buf, 69)
  poke(chan_buf+1, 69)
  serial(channel, chan_buf, 2) 

  -- read result
  result=''
  repeat
    -- also use the argument space to receive the result
    size = serial(channel, chan_buf, chan_buf_size)
    for i=0,size do
      b = peek(chan_buf+i)
      result = result..b
    end
  until(size == 0)
  printh('result '..result)
end

function _init()
  fetch_carts()
end

