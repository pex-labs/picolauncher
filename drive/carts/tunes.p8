pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8
#include utils.p8
#include menu.p8
#include tween.lua
#include ui.p8

song_dir='music'
label_dir='labels'

local song_menu=menu_new(ls(song_dir))

function _init()
  load_label()
  load_song()

  -- graphics
  init_title_bar(11)
end

-- load song art of current song into memory
function load_label()
  song_name=tostring(song_menu:cur())
  -- replace .p8 with .64.p8
  if ends_with(song_name, ".p8") then
    stripped_path = sub(song_name, 0, -#(".p8")-1)
    reload(0x0000, 0x0000, 0x1000, label_dir .. '/' .. stripped_path .. '.64.p8')
  end
end

-- load sfx and music section
function load_song()
  song_name=tostring(song_menu:cur())
  reload(0x3100, 0x3100, 0x0200, song_dir .. '/' .. song_name)
  reload(0x3200, 0x3200, 0x1100, song_dir .. '/' .. song_name)
end

function draw_label(x, y, w)
  rectfill(x-w/2, y-w/2, x+w/2, y+w/2, 0)
  for j = 0, 31 do
    for i = 0, 1 do
      sspr(i*64, j, 64, 1, x-w/2, y-w/2+j*2+i)
    end
  end
end

-- TODO: this function is kinda lmao, just use spritesheets instead
function draw_control_icon(x, y, icon)
  -- draw 8x8 control icons
  if icon == 1 then -- rewind
    line(x+6, y+2, x+6, y+6, 7)
    line(x+5, y+3, x+5, y+5, 7)
    line(x+4, y+4, x+4, y+4, 7)
    line(x+2, y+2, x+2, y+6, 7)
    line(x+1, y+3, x+1, y+5, 7)
    line(x, y+4, x, y+4, 7)
  elseif icon == 2 then -- previous
    line(x+6, y+2, x+6, y+6, 7)
    line(x+5, y+3, x+5, y+5, 7)
    line(x+4, y+4, x+4, y+4, 7)
    line(x+2, y+2, x+2, y+6, 7)
  elseif icon == 3 then -- play
    line(x+2, y+2, x+2, y+6, 7)
    line(x+3, y+3, x+3, y+5, 7)
    line(x+4, y+4, x+4, y+4, 7)
  elseif icon == 4 then -- pause
    rect(x+1, y+2, x+3, y+6, 7)
    rect(x+5, y+2, x+7, y+6, 7)
  elseif icon == 5 then -- next
    line(x+2, y+2, x+2, y+6, 7)
    line(x+3, y+3, x+3, y+5, 7)
    line(x+4, y+4, x+4, y+4, 7)
    line(x+6, y+2, x+6, y+6, 7)
  elseif icon == 6 then -- forward
    line(x+2, y+2, x+2, y+6, 7)
    line(x+3, y+3, x+3, y+5, 7)
    line(x+4, y+4, x+4, y+4, 7)
    line(x+6, y+2, x+6, y+6, 7)
    line(x+7, y+3, x+7, y+5, 7)
    line(x+8, y+4, x+8, y+4, 7)
  end
end

play_state=false
shuffle=false
function play_song()
  play_state = true
  music(0)
end

function stop_song()
  play_state = false
  music(-1)
end

function on_song_change()
  cur_play_state = play_state
  stop_song()
  load_label()
  load_song()

  -- start new song if previously playing
  if cur_play_state then
    play_song()
  end
end

function _update60()
  tween_machine:update()

  if btnp(0) then -- prev song
    -- TODO add stack to support shuffled songs?
    song_menu:up()
    on_song_change()
  elseif btnp(1) then -- next song
    if shuffle then
      -- TODO currently allows same song to be played again
      song_menu:set_index(flr(rnd(#song_menu.items))+1)
    else
      song_menu:down()
    end
    on_song_change()
  -- elseif btnp(4) then -- shuffle
  --  shuffle = not shuffle
  elseif btnp(4) then
    os_back()
  elseif btnp(5) then -- pause/play
    play_state = not play_state
    if play_state then
      play_song()
    else
      stop_song()
    end
  end

  -- detect when the current song ends
  if play_state then
    
    if stat(54) == -1 then
      song_menu:down()
      on_song_change()
    end
  end
end

function _draw()
  cls(1) -- dark blue background
  
  -- header
  draw_title_bar('tunes', 11, 0, true, '♪', 0)

  print(song_menu:cur(), 64-#(song_menu:cur())*2, 20, 12)
  print(song_menu:cur(), 64-#(song_menu:cur())*2, 19, 7)

  local x=64
  local y=64
  local w=64
  rectfill(x-w/2, y-w/2, x+w/2, y+w/2, 0)
  draw_label(x, y, w)

  draw_control_icon(64-16, 100, 2)
  if play_state then
    draw_control_icon(64-4, 100, 4)
  else
    draw_control_icon(64-4, 100, 3)
  end
  draw_control_icon(64+8, 100, 5)

  -- draw help text
  print('❎pause/play', 3, 120, 6)

  -- if shuffle then
  --   shuffle_text='on'
  -- else
  --   shuffle_text='off'
  -- end
  -- print('🅾️shuffle ' .. shuffle_text, 74, 120, 6)
end
