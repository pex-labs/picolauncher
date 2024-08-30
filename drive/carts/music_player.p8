pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- constants
local view_list = 1
local view_player = 2
local visualizer_bar = 1
local visualizer_wave = 2
local visualizer_cover = 3

-- state
local current_view = view_list
local songs = {
  {title="song a", duration=192, cover=0},
  {title="song b", duration=74, cover=2},
  {title="song c", duration=121, cover=4},
  {title="song d", duration=59, cover=6},
  {title="song e", duration=103, cover=8}
}
local selected_song = 1
local is_playing = false
local play_time = 0
local visualizer_type = visualizer_cover

function _init()
end


function _update()
  if current_view == view_list then
    update_list()
  else
    update_player()
  end
end

function _draw()
  cls(1) -- dark blue background
  if current_view == view_list then
    draw_list()
  else
    draw_player()
  end
end

function update_list()
  if btnp(2) then -- up
    selected_song = max(1, selected_song - 1)
  elseif btnp(3) then -- down
    selected_song = min(#songs, selected_song + 1)
  elseif btnp(4) then -- o button
    current_view = view_player
    is_playing = true
    play_time = 0
  end
end

function draw_list()
  -- header
  rectfill(0, 0, 128, 16, 11) -- green header
  print("tunes", 4, 5, 7)
  
  -- song list
  for i, song in ipairs(songs) do
    local y = 20 + (i-1) * 12
    local color = (i == selected_song) and 7 or 6
    rectfill(4, y, 124, y+10, 13)
    print(song.title, 8, y+2, color)
    print(time_to_string(song.duration), 100, y+2, color)
  end
end



function update_player()
  local song = songs[selected_song]
  
  if btnp(5) then -- x button
    current_view = view_list
  elseif btnp(4) then -- o button
    if is_playing then
      is_playing = false
    else
      is_playing = true
    end
  elseif btnp(0) then -- left
    play_time = max(0, play_time - 5)
  elseif btnp(1) then -- right
    play_time = min(song.duration, play_time + 5)
  elseif btnp(2) then -- up (previous song)
    selected_song = max(1, selected_song - 1)
    play_time = 0
  elseif btnp(3) then -- down (next song)
    selected_song = min(#songs, selected_song + 1)
    play_time = 0
  end
  
  if is_playing then
    play_time = min(song.duration, play_time + 1)
    if play_time == song.duration then
      selected_song = min(#songs, selected_song + 1)
      play_time = 0
    end
  elseif btnp(6) then -- use btnp(6) for changing visualizer when paused
    visualizer_type = (visualizer_type % 3) + 1
  end
end



function draw_player()
  local song = songs[selected_song]
  
  -- header
  rectfill(0, 0, 128, 16, 11) -- green header
  print("♪ tunes", 4, 5, 7)
  print(time_to_string(play_time) .. "/" .. time_to_string(song.duration), 70, 5, 7)
  
  -- song info
  print(song.title, 4, 20, 7)
  
  -- progress bar
  local progress = play_time / song.duration
  rect(4, 40, 124, 46, 7)
  rectfill(4, 40, 4 + 120 * progress, 46, 7)
  
  -- controls
  draw_control_icon(11, 50, 1) -- rewind
  draw_control_icon(35, 50, 2) -- previous
  draw_control_icon(60, 50, is_playing and 4 or 3) -- play/pause
  draw_control_icon(85, 50, 5) -- next
  draw_control_icon(110, 50, 6) -- forward
  
  -- visualizer / cover art
  if visualizer_type == visualizer_bar then
    draw_bar_visualizer()
  elseif visualizer_type == visualizer_wave then
    draw_wave_visualizer()
  else
    draw_cover_art(32, 60, song.color, 64)
  end
  
  if not is_playing then
    print("paused", 56, 80, 6)
  end
   -- instructions
  print("❎: back", 4, 120, 6)
  if not is_playing then
    print("🅾️: change view", 60, 120, 6)
  end
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

function draw_bar_visualizer()
  for i=0,31 do
    local height = 10 + rnd(30)
    rectfill(i*4, 100-height, i*4+2, 100, 12)
  end
end

function draw_cover_art(x, y, color, size)
  rectfill(x, y, x+size-1, y+size-1, color)
  for i=0,size/2 do
    line(x+i, y+i, x+size-1-i, y+i, 7)
    line(x+i, y+size-1-i, x+size-1-i, y+size-1-i, 7)
  end
end


function draw_wave_visualizer()
  for i=0,127 do
    local y = 100 + sin(i/20 + time()/2) * 10
    line(i, y, i, 100, 12)
  end
end

function time_to_string(t)
  return (t\60) .. ":" .. ((t%60)<10 and "0" or "") .. (t%60)
end