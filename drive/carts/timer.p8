pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- credits: https://www.lexaloffle.com/bbs/?tid=3202

local timers = {}
local last_time = nil

function init_timers ()
  last_time = time()
end

function add_timer (name,
    length, step_fn, end_fn,
    start_paused)
  local timer = {
    length=length,
    elapsed=0,
    active=not start_paused,
    step_fn=step_fn,
    end_fn=end_fn
  }
  timers[name] = timer
  return timer
end

function update_timers ()
  local t = time()
  local dt = t - last_time
  last_time = t
  for name,timer in pairs(timers) do
    if timer.active then
      timer.elapsed += dt
      local elapsed = timer.elapsed
      local length = timer.length
      if elapsed < length then
        if timer.step_fn then
          timer.step_fn(dt,elapsed,length,timer)
        end  
      else
        if timer.end_fn then
          timer.end_fn(dt,elapsed,length,timer)
        end
        timer.active = false
      end
    end
  end
end

function pause_timer (name)
  local timer = timers[name]
  if (timer) timer.active = false
end

function resume_timer (name)
  local timer = timers[name]
  if (timer) timer.active = true
end

function restart_timer (name, start_paused)
  local timer = timers[name]
  if (not timer) return
  timer.elapsed = 0
  timer.active = not start_paused
end

local loadable_table = {}

-- name is the function to call
-- callback_fn is called when the response is received
function new_loadable(name, callback_fn, poll_duration)
    local loadable = {
        name=name,
        callback_fn=callback_fn,
        poll_duration=poll_duration,
        requested=false,
        last_poll=0,
    }
    loadable_table[name] = loadable

    return loadable
end

function request_loadable(name, args)
    local loadable = loadable_table[name]
    if loadable == nil then return end
    if args == nil then args = {} end
    serial_writeline(name..':'..tconcat(args))
    loadable.requested = true
end

function status_loadable(name)
  local loadable = loadable_table[name]
  if loadable == nil then return false end
  return loadable.requested
end

function update_loadables()
    curtime = time()
    for name, loadable in pairs(loadable_table) do
        if loadable.requested == true then
            if curtime - loadable.last_poll > loadable.poll_duration then
                local resp=serial_readline()
                if #resp > 0 and resp ~= nil then
                    loadable.requested = false
                    loadable.callback_fn(resp)
                end
                loadable.last_poll = curtime
            end
        end
    end
end
