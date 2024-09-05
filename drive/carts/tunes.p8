pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include utils.p8
#include menu.p8
#include tween.lua

song_dir='music'
label_dir='labels'

local song_menu=menu_new(ls(song_dir))

function _init()
  for i, song_file in ipairs(song_files) do
    printh(song_file)
  end
end

-- load song art of current song into memory
function load_label()
  song_name=tostring(song_menu:cur())
  reload(0x0000, 0x0000, 0x1000, label_dir .. '/' .. song_name)
end

-- load sfx and music section
function load_song()
  song_name=tostring(song_menu:cur())
  reload(0x3100, 0x3100, 0x0200, song_dir .. '/' .. song_name)
  reload(0x3200, 0x3200, 0x1100, song_dir .. '/' .. song_name)
end


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
    song_menu:up()
    on_song_change()
  elseif btnp(1) then -- next song
    song_menu:down()
    on_song_change()
  elseif btnp(5) then -- pause/play
    play_state = not play_state
    if play_state then
      play_song()
    else
      stop_song()
    end
  end
end

function _draw()
  cls(1) -- dark blue background
  
  -- header
  rectfill(0, 0, 128, 7, 11) -- green header
  print("♪ tunes", 4, 1, 7)

  print(song_menu:cur(), 10, 10, 7)

  local x=64
  local y=64
  local w=64
  rectfill(x-w/2, y-w/2, x+w/2, y+w/2, 0)
  sspr(0, 0, w, w, x-w/2, y-w/2)

  draw_control_icon(64-16, 100, 2)
  if play_state then
    draw_control_icon(64-4, 100, 4)
  else
    draw_control_icon(64-4, 100, 3)
  end
  draw_control_icon(64+8, 100, 5)
end
