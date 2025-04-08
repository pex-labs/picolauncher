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
local show_visualizer = false -- Toggle for showing visualizer or album art

-- Music events, code from https://www.lexaloffle.com/bbs/?pid=51460
music_events = {
  wave = {-1, -1, -1, -1},
  pitch = {-1, -1, -1, -1},
  volume = {0, 0, 0, 0},
  notevol = {0, 0, 0, 0},
  effect = {0, 0, 0, 0},
  pattern = {-1, -1, -1, -1},
  row = {-1, -1, -1, -1},
  speed = {0, 0, 0, 0},
  last = 0,
  notestr = {"c ","c#","d ","d#","e ","f ","f#","g ","g#","a ","a#","b "}
}

local bars = {0, 0, 0, 0}
local bar_colors = {8, 9, 12, 14}
-- local note_particles = {}
local wave_intensity = {0, 0, 0, 0}

function _init()
  load_label()
  load_song()

  init_title_bar(11)
  
  -- note_particles = {}
end

function music_events:update()
  local t = time()
  local d = t - self.last
  self.last = t
  
  for i=1, 4 do
    self:update_channel(i)
    
    if self.effect[i] == 5 then
      local voldec = 128 * self.notevol[i] * d / (self.speed[i] + 1)
      self.volume[i] = max(self.volume[i] - voldec, 0)
    end
    
    if self.notevol[i] == 0 then
      self.wave[i] = -1
      self.pitch[i] = -1
    end
    
    -- smooth decay
    bars[i] = max(bars[i] - 0.125, self.volume[i])
  end
end

function music_events:update_channel(i)
  local speed = 0
  local wave = -1
  local pitch = -1
  local volume = 0
  local fx = 0
  local pattern = stat(15 + i)
  local row = -1
  
  if pattern >= 0 then
    row = stat(19 + i)
    if pattern == self.pattern[i] and row == self.row[i] then
      return
    end
    
    -- data  from memory
    local notedat = peek4(0x31fe + pattern * 68 + 2 * row)
    speed = peek(0x3241 + pattern * 68)
    wave = band(shr(notedat, 6), 0x07)
    pitch = band(notedat, 0x3f)
    volume = band(shr(notedat, 9), 0x07)
    fx = band(shr(notedat, 12), 0x07)
    
    if pitch != self.pitch[i] and pitch > 0 then
      local bin = pitch % 12 + 1
      
      if show_visualizer then
        -- add_note_particles(i, pitch, volume)
      end
      
      -- wave intensity, idk if I like this, too noisy 
      wave_intensity[i] = volume
    end
  end
  
  self.speed[i] = speed
  self.wave[i] = wave
  self.pitch[i] = pitch
  self.volume[i] = volume
  self.notevol[i] = volume
  self.effect[i] = fx
  self.pattern[i] = pattern
  self.row[i] = row
end

function music_events:getnote(i)
  if self.pitch[i] == -1 then
    return ""
  end
  return self.notestr[self.pitch[i] % 12 + 1] .. flr(self.pitch[i] / 12 + 1)
end

function add_note_particles(channel, pitch, volume)
  local x = 20 + (channel - 1) * 28
  local y = 100
  local note_color = bar_colors[channel]
  
  for i=1, 2 + flr(rnd(2)) do
    add(note_particles, {
      x = x + rnd(10) - 5,
      y = y - volume * 5 - rnd(10),
      vx = (rnd() - 0.5) * 1.5,
      vy = -1 - rnd(2),
      life = 15 + rnd(10),
      color = note_color,
      size = 1 + volume / 3
    })
  end
end

function update_particles()
  local i = 1
  while i <= #note_particles do
    local p = note_particles[i]
    p.x += p.vx
    p.y += p.vy
    p.vy += 0.2  -- gravity
    p.life -= 1
    
    if p.life <= 0 then
      deli(note_particles, i)
    else
      i += 1
    end
  end
  
  for i=1,4 do
    wave_intensity[i] = max(0, wave_intensity[i] * 0.95)
  end
end

function load_label()
  song_name=tostring(song_menu:cur())
  -- replace .p8 with .64.p8 
  -- 
  if ends_with(song_name, ".p8") then
    stripped_path = sub(song_name, 0, -#(".p8")-1)
    reload(0x0000, 0x0000, 0x1000, label_dir .. '/' .. stripped_path .. '.64.p8')
  end
end

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
  
  -- Reset visualizer data
  for i=1,4 do
    bars[i] = 0
    wave_intensity[i] = 0
  end
  
  -- note_particles = {}
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
  elseif btnp(2) then -- toggle  visualizer
    show_visualizer = not show_visualizer
    -- note_particles = {} -- Clear particles 
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

  if play_state then
    if stat(54) == -1 then
      song_menu:down()
      on_song_change()
    end
  end
  
  if play_state then
    music_events:update()
    if show_visualizer then
      -- update_particles()
    end
  end
end

function _draw()
  cls(1) 
  
  draw_title_bar('tunes', 11, 0, true, '♪', 0)

  print(song_menu:cur(), 64-#(song_menu:cur())*2, 20, 12)
  print(song_menu:cur(), 64-#(song_menu:cur())*2, 19, 7)

  local x=64
  local y=64
  local w=64
  -- rectfill(x-w/2, y-w/2, x+w/2, y+w/2, 0)

  --  either the album art or the visualizer based on toggle
  if show_visualizer and play_state then
    -- Draw full visualizer in place of album art
    draw_full_visualizer()
  else
    -- Draw album art
    draw_label(x, y, w)
  end

  draw_control_icon(64-16, 100, 2)
  if play_state then
    draw_control_icon(64-4, 100, 4)
  else
    draw_control_icon(64-4, 100, 3)
  end
  draw_control_icon(64+8, 100, 5)

  -- Draw help text
  print('❎pause/play', 3, 120, 6)
  print('🅾️back', 94, 120, 6)
  print('⬆️vis', 60, 120, 6)  
end

-- Draw the full-screen visualizer (in place of album art)
function draw_full_visualizer()

  
  -- for p in all(note_particles) do
    -- if p.size <= 1 then
      -- pset(p.x, p.y, p.color)
    -- else
      -- circfill(p.x, p.y, p.size * (p.life / 25), p.color)
    -- end
  -- end
  
  for i=1, 4 do
    local bar_height = min(bars[i] * 12, 50)  -- Make taller
    local x = 39 + (i - 1) * 14
    local w = 10
    
    if bar_height > 0 then
      rectfill(
        x, 
        90 - bar_height, 
        x + w, 
        90, 
        music_events.wave[i] >= 0 and music_events.wave[i] + 8 or bar_colors[i]
      )
      
      -- drawing notes here 
      if music_events.pitch[i] >= 0 then
        print(
          music_events:getnote(i), 
          x + 1, 
          92, 
          7
        )
      end
      
      -- wave visualization
      draw_wave(i, x + w/2, 90 - bar_height - 6, wave_intensity[i])
    end
  end
  
  -- border? idk doesnt look great
  -- rect(32, 32, 96, 96, 5)
end

function draw_wave(channel, x, y, intensity)
  if intensity <= 0 then return end
  
  local pitch = music_events.pitch[channel]
  if pitch < 0 then return end
  
  local wave_type = music_events.wave[channel]
  local amp = intensity * 2.5
  
  local freq = (pitch + 10) / 40
  
  for i=0, 8 do
    local x1 = x + i - 4
    local y1, y2
    
    if wave_type == 0 then
      -- Sine wave
      y1 = y - sin(time() * freq + i/10) * amp
      y2 = y - sin(time() * freq + (i+1)/10) * amp
    elseif wave_type == 1 then
      -- Triangle wave
      local t = (time() * freq * 2 + i/10) % 1
      if t < 0.5 then
        y1 = y - (t * 4 - 1) * amp
      else
        y1 = y - (3 - t * 4) * amp
      end
      
      t = (time() * freq * 2 + (i+1)/10) % 1
      if t < 0.5 then
        y2 = y - (t * 4 - 1) * amp
      else
        y2 = y - (3 - t * 4) * amp
      end
    else
      -- Square/pulse wave
      local t = (time() * freq + i/10) % 1
      y1 = y - (t < 0.5 and amp or -amp)
      
      t = (time() * freq + (i+1)/10) % 1
      y2 = y - (t < 0.5 and amp or -amp)
    end
    
    if amp > 0.5 then
      line(x1, y1, x1 + 1, y2, bar_colors[channel])
    end
  end
end