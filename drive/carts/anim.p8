pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- TODO no way to remove animations
local anims={}
local STOPPED=-1

function anim_new(name, frames, speed, loop)
  local anim= {
    name=name,
    frames=frames,
    speed=speed, -- number of ticks before the frame changes, technically lower speed means faster :P
    loop=loop,
    _cur_frame=0,
    _counter=STOPPED, -- -1 means stopped

    start=function(self)
      self._cur_frame = 0
      self._counter = 0
    end,

    stop=function(self)
      self._counter = STOPPED
    end,

    step=function(self)
      -- tick the counter
      self._counter += 1
      if self._counter > speed then
        self._counter = 0
        self._cur_frame += 1
        if self._cur_frame >= #self.frames then
          if self.loop then
            self:start()
          else
            -- TODO: kinda bad
            -- go back one to keep the current frame at the last frame
            self._cur_frame = max(0,#self.frames-1)
            self:stop()
          end
        end
      end
    end,

    get_frame=function(self)
      return self.frames[self._cur_frame+1]
    end
  }
  anims[name]=anim
  return anim
end


function update_anim()
  for _, anim in pairs(anims) do
    if anim._counter >= 0 then
      anim:step()
    end
  end
end
