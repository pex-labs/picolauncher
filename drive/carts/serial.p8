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
-- currently unused
function serial_hello()
  local hello_msg=serial_readline()
  -- we are using 'E' as the special placeholder message the os sends
  if hello_msg != 'E' then
    printh('got incorrect hello message') 
  else
    serial_writeline('hello:')
    printh('got hello message')
  end
end

-- TODO this is rly similar to serial_ls
function serial_ls_exe()
  serial_writeline('ls_exe:')
  local exes=serial_readline()
  if #exes == 0 then
    return {}
  end
  local split_exes=split(exes, ',', false)
  for k, v in pairs(split_exes) do
    split_exes[k]=table_from_string(v)
  end
  return split_exes
end

function serial_spawn(path)
  serial_writeline('spawn:'..path)
end

function serial_spawn_pico8()
  serial_writeline('spawn_pico8:')
end

-- load an image in parts through serial-in. image is loaded row-by-row.
-- image is loaded in the pico-8 4bit image format.
-- return true means the function is done at that frame and doesn't need to be called anymore.
-- load modes:
-- - "top_bot" -- load the image from the top to the bottom.
POSSIBLE_LOAD_MODES = {top_bot=true}
function serial_load_image(filename, location, scale_width, scale_height, frame, mode, bytes_per_frame)
  filename = filename..".p8.png"
  mode = POSSIBLE_LOAD_MODES[mode] and mode or "top_bot" -- load the image top to bottom.
  bytes_per_frame = bytes_per_frame or 1024 -- 1024 bytes is about 50% cpu on 60 fps.
  scale_width  = mid(1, scale_width,  128)\1 -- scale_width, scaled down images load can faster
  scale_height = mid(1, scale_height, 128)\1
  frame = max(1, frame\1) -- which frame this is. used to determine which part of the image to load.

  local buffer_len = ceil(scale_width*scale_height/2)
  if bytes_per_frame*(frame-1) >= buffer_len then
    return true
  end

  serial_writeline('load_image:'..filename..","..scale_width..","..scale_height..","..bytes_per_frame..","..frame..","..mode)
  local size = serial(stdin, location+bytes_per_frame*(frame-1), bytes_per_frame) -- TODO: make it read less for the last frame
  printh(" size "..size.." "..t())
  local size2 = serial(stdin, 0x0000, 10)
  printh(" size2 "..size2.." "..t())
  -- printh(" "..location+bytes_per_frame*(frame-1))
  -- printh(" "..bytes_per_frame)

  if bytes_per_frame*(frame-1) >= buffer_len then
    return true
  end
end

function serial_spawn_splore()
  serial_writeline('spawn_splore:')
end

-- send request for page from bbs
function serial_bbs(page, query)
  serial_writeline('bbs:'..page..','..query)
end

-- query for response from bbs
function serial_bbs_response()
  local new_carts=serial_readline()
  if #new_carts == 0 then
    return nil
  end
  printh('response from serial_bbs '..new_carts)
  local split_carts=split(new_carts, ',', false)
  for k, v in pairs(split_carts) do
    split_carts[k]=table_from_string(v)
  end
  return split_carts
end

function serial_wifi_list()
  serial_writeline('wifi_list:')
end

-- TODO this is very similar to bbs_resposne, maybe abstract this
function serial_wifi_list_response()
  local wifi_list=serial_readline()
  if #wifi_list == 0 then
    return nil
  end
  printh('response from wifi_list '..wifi_list)
  local split_wifi=split(wifi_list, ',', false)
  for k, v in pairs(split_wifi) do
    split_wifi[k]=table_from_string(v)
  end
  return split_wifi
end

function serial_debug(msg)
  serial_writeline('debug:'..msg)
end

-- read from input file until a newline is reached
-- TODO this can be refactored into a coroutine?
function serial_readline()
  local result=''
  local got_newline=false
  while true do
    -- also use the argument space to receive the result
    size = serial(stdin, chan_buf, chan_buf_size)
    if (size == 0) then return result end
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
  -- printh('output len '..#buf .. ' content ' .. buf)
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

function serial_shutdown()
  serial_writeline('shutdown:')
end

-- load a cart, use this to load carts while perserving history
function os_load(path, breadcrumb, param)
  if path == nil or #path == 0 then
    printh('WARNING: path passed to os_load was nil')
    return
  end
  if breadcrumb == nil then breadcrumb = '' end
  if param == nil then param = '' end

  serial_writeline('pushcart:'..path..','..breadcrumb..','..param)
  serial_readline() -- empty response
  load(path, breadcrumb, param)
end

-- return to the previous cart
-- no-op if previous cart doesn't exist
function os_back()
  serial_writeline('popcart:')
  local prev_cart=serial_readline()
  printh('got prevcart '..prev_cart)
  if prev_cart ~= nil or #prev_cart > 0 then
    -- split to get previous path and breadcrumb too
    parts=split(prev_cart, ',', false)
    load(parts[1], parts[2], parts[3])
  end
end

function gyro_read()
  serial_writeline('gyro_read:')
  local gyro_data=serial_readline()
  if gyro_data ~= nil or #gyro_data > 0 then
    parts=split(gyro_data, ',', true)
    return {parts[0], parts[1], parts[2]}
  end
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
