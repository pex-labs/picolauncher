pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- table string library
function table_from_string(str)
  local tab, is_key = {}, true
  local key,val,is_on_key
  local function reset()
    key,val,is_on_key = '','',true
  end
  reset()
  local i, len = 1, #str
  while i <= len do
    local char = sub(str, i, i)
    -- token separator
    if char == '\31' then
      if is_on_key then
        is_on_key = false
      else
        tab[tonum(key) or key] = val
        reset()
      end
    -- subtable start
    elseif char == '\29' then
      local j,c = i,''
      -- checking for subtable end character
      while (c ~= '\30') do
        j = j + 1
        c = sub(str, j, j)
      end
      tab[tonum(key) or key] = table_from_string(sub(str,i+1,j-1))
      reset()
      i = j
    else
      if is_on_key then
        key = key..char
      else
        val = val..char
      end
    end
    i = i + 1
  end
  return tab
end

-- serial interface with the underlying operating system

stdin=0x806
stdout=0x807

chan_buf=0x4300
chan_buf_size=0x1000

-- read init message (host os provides some information)
-- see https://github.com/nlordell/p8-controller for discussion on caveats with serial read and write
function serial_hello()
  serial_readline()
  serial_writeline('hello:')
  printh('got hello message')
end

function serial_ls(dir)
  serial_writeline('ls:'..dir)
  files=serial_readline()
  split_files=split(files, ',', false)
  for k, v in pairs(split_files) do
    split_files[k]=table_from_string(v)
  end
  return split_files
end

function serial_debug(msg)
  serial_writeline('debug:'..msg)
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
    -- printh('size: ' .. size)
    for i=0,size do
      b = peek(chan_buf+i)
      -- printh('byte: '..b)
      if b == 0x0a then
        got_newline=true
        break
      end 
      result = result..chr(b)
    end
  end
  if not got_newline then
    printh('warning: newline was not received')
  end
  printh('result '..result)
  return result
end

function serial_writeline(buf)
  -- TODO check length of buf to avoid overfloe
  -- TODO not super efficient
  printh('output len '..#buf .. ' content ' .. buf)
  for i=1,#buf do
    b = ord(sub(buf, i, i))
    -- printh('copy: '..b)
    poke(chan_buf + i - 1, b)
  end
  -- write a newline character
  poke(chan_buf+#buf, ord('\n'))

  -- TODO currently this means that newlines are not allowed in messages
  serial(stdout, chan_buf, #buf+1)
  flip()
end

function serial_fetch_carts()
  -- send request
  -- use 0x4300 as a buffer for sending serial data arguments
  poke(chan_buf, 69)
  poke(chan_buf+1, 69)
  serial(stdout, chan_buf, 2) 
end

-- carts={}
-- function _init()
--   cls(0)
--   serial_hello()
--   -- serial_fetch_carts()
--   print('done')
--   carts=serial_ls()
-- end
-- 
-- function _update()
--   if btnp(4) then
--     serial_writeline("spawn:picocad")
--   end
-- end
-- 
-- function _draw()
--   cls(1)
--   for cart in all(carts) do
--     print(cart)
--   end
-- end
