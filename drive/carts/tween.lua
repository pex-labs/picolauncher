------------
-- PICO-Tween -
-- A small library of tweening/easing
-- functions for use in the PICO-8
-- fantasy console, inspired by Robert
-- Penner's easing functions.
-- Code ported from EmmanuelOga's
-- Lua port of the easing functions.
-- Adapted to work with the PICO-8's
-- math functionality.
--
-- For all easing functions:
-- 
-- t = elapsed time
-- 
-- b = begin
-- 
-- c = change == ending - beginning
-- 
-- d = duration (total time)
--
-- For visual represenations of
-- easing functions, visit this
-- website: http://easings.net/
-- @script PICO-Tween
-- @author Joeb Rogers
-- @license MIT
-- @copyright Joeb Rogers 2018

--- Definition of Pi.
pi = 3.14

--- Cos now uses radians
cos1 = cos function cos(angle) return cos1(angle/(3.1415*2)) end
--- Sin now uses radians
sin1 = sin function sin(angle) return sin1(-angle/(3.1415*2)) end

--- Implementation of asin.
-- Source converted from 
-- http://developer.download.nvidia.com/cg/asin.html
function asin(x)
  local negate = (x < 0 and 1.0 or 0.0)
  x = abs(x)
  local ret = -0.0187293
  ret *= x
  ret += 0.0742610
  ret *= x
  ret -= 0.2121144
  ret *= x
  ret += 1.5707288
  ret = 3.14159265358979*0.5 - sqrt(1.0 - x)*ret
  return ret - 2 * negate * ret
end

--- Implementation of acos.
-- Source converted from 
-- http://developer.download.nvidia.com/cg/acos.html
function acos(x)
  local negate = (x < 0 and 1.0 or 0.0)
  x = abs(x);
  local ret = -0.0187293;
  ret *= x;
  ret += 0.0742610;
  ret *= x;
  ret -= 0.2121144;
  ret *= x;
  ret += 1.5707288;
  ret *= sqrt(1.0-x);
  ret -= 2 * negate * ret;
  return negate * 3.14159265358979 + ret;
end

--- Function for calculating 
-- exponents to a higher degree
-- of accuracy than using the
-- ^ operator.
-- Function created by samhocevar.
-- Source: https://www.lexaloffle.com/bbs/?tid=27864
-- @param x Number to apply exponent to.
-- @param a Exponent to apply.
-- @return The result of the 
-- calculation.
function pow(x,a)
  if (a==0) return 1
  if (a<0) x,a=1/x,-a
  local ret,a0,xn=1,flr(a),x
  a-=a0
  while a0>=1 do
      if (a0%2>=1) ret*=xn
      xn,a0=xn*xn,shr(a0,1)
  end
  while a>0 do
      while a<1 do x,a=sqrt(x),a+a end
      ret,a=ret*x,a-1
  end
  return ret
end

function linear(t, b, c, d)
  return c * t / d + b
end

function inQuad(t, b, c, d)
  return c * pow(t / d, 2) + b
end

function outQuad(t, b, c, d)
  t = t / d
  return -c * t * (t - 2) + b
end

function inOutQuad(t, b, c, d)
  t = t / d * 2
  if (t < 1) return c / 2 * pow(t, 2) + b
  return -c / 2 * ((t - 1) * (t - 3) - 1) + b  
end

function outInQuad(t, b, c, d)
  if (t < d / 2) return outQuad(t * 2, b, c / 2, d)
  return inQuad((t * 2) - d, b + c / 2, c / 2, d)
end

function inCubic(t, b, c, d)
  return c * pow(t / d, 3) + b
end

function outCubic(t, b, c, d)
  return c * (pow(t / d - 1, 3) + 1) + b
end

function inOutCubic(t, b, c, d)
  t = t / d * 2
  if (t < 1) return c / 2 * t * t * t + b
  t = t - 2
  return c / 2 * (t * t * t + 2) + b
end

function outInCubic(t, b, c, d)
  if (t < d / 2) return outCubic(t * 2, b, c / 2, d)
  return inCubic((t * 2) - d, b + c / 2, c / 2, d)
end

function inQuart(t, b, c, d)
  return c * pow(t/d, 4) + b
end

function outQuart(t, b, c, d)
  return -c * (pow(t / d - 1, 4) - 1) + b
end

function inOutQuart(t, b, c, d)
  t = t / d * 2
  if (t < 1) return c / 2 * pow(t, 4) + b
  t = t - 2
  return -c / 2 * (pow(t, 4) - 2) + b
end

function outInQuart(t, b, c, d)
  if (t < d / 2) return outQuart(t * 2, b, c / 2, d)
  return inQuart((t * 2) - d, b + c / 2, c / 2, d)
end

function inQuint(t, b, c, d)
  return c * pow(t / d, 5) + b
end

function outQuint(t, b, c, d)
  return c * (pow(t / d - 1, 5) + 1) + b
end

function inOutQuint(t, b, c, d)
  t = t / d * 2
  if (t < 1) return c / 2 * pow(t, 5) + b
  return c / 2 * (pow(t - 2, 5) + 2) + b
end

function outInQuint(t, b, c, d)
  if (t < d / 2) return outQuint(t * 2, b, c / 2, d)
  return inQuint((t * 2) - d, b + c / 2, c / 2, d)
end

function inSine(t, b, c, d)
  return -c * cos(t / d * (pi / 2)) + c + b
end

function outSine(t, b, c, d)
  return c * sin(t / d * (pi / 2)) + b
end

function inOutSine(t, b, c, d)
  return -c / 2 * (cos(pi * t / d) - 1) + b
end

function outInSine(t, b, c, d)
  if (t < d / 2) return outSine(t * 2, b, c / 2, d)
  return inSine((t * 2) - d, b + c / 2, c / 2, d)
end

function inExpo(t, b, c, d)
  if (t == 0) return b
  return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
end

function outExpo(t, b, c, d)
  if (t == d) return b + c
  return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
end

function inOutExpo(t, b, c, d)
  if (t == 0) return b
  if (t == d) return b + c
  t = t / d * 2
  if (t < 1) return c / 2 * pow(2, 10 * (t - 1)) + b - c * 0.0005
  return c / 2 * 1.0005 * (-pow(2, -10 * (t - 1)) + 2) + b
end

function outInExpo(t, b, c, d)
  if (t < d / 2) return outExpo(t * 2, b, c / 2, d)
  return inExpo((t * 2) - d, b + c / 2, c / 2, d)
end

function inCirc(t, b, c, d)
  return (-c * (sqrt(1 - pow(t / d, 2)) - 1) + b)
end

function outCirc(t, b, c, d)
  return (c * sqrt(1 - pow(t / d - 1, 2)) + b)
end

function inOutCirc(t, b, c, d)
  t = t / d * 2
  if (t < 1) return -c / 2 * (sqrt(1 - t * t) - 1) + b
  t = t - 2
  return c / 2 * (sqrt(1 - t * t) + 1) + b
end

function outInCirc(t, b, c, d)
  if (t < d / 2) return outCirc(t * 2, b, c / 2, d)
  return inCirc((t * 2) - d, b + c / 2, c / 2, d)
end

function inElastic(t, b, c, d, a, p)
  if (t == 0) return b
  t /= d
  if (t == 1) return b + c
  p = p or d * 0.3
  local s

  if not a or a < abs(c) then
    a = c
    s = p / 4
  else
    s = p / (2 * pi) * asin(c/a)
  end

  t -= 1
  return -(a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
end

function outElastic(t, b, c, d, a, p)
  if (t == 0) return b
  t /= d
  if (t == 1) return b + c
  p = p or d * 0.3
  local s

  if not a or a < abs(c) then
    a = c
    s = p / 4
  else
    s = p / (2 * pi) * asin(c/a)
  end

  return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p) + c + b
end

function inOutElastic(t, b, c, d, a, p)
  if (t == 0) return b
  t = t / d * 2
  if (t == 2) return b + c
  p = p or d * (0.3 * 1.5)
  a = a or 0
  local s

  if not a or a < abs(c) then
    a = c
    s = p / 4
  else
    s = p / (2 * pi) * asin(c / a)
  end

  if t < 1 then
    t -= 1
    return -0.5 * (a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
  end
  t -= 1
  return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p ) * 0.5 + c + b
end

function outInElastic(t, b, c, d, a, p)
  if (t < d / 2) return outElastic(t * 2, b, c / 2, d, a, p)
  return inElastic((t * 2) - d, b + c / 2, c / 2, d, a, p)
end

function inBack(t, b, c, d, s)
  s = s or 1.70158
  t = t / d
  return c * t * t * ((s + 1) * t - s) + b
end

function outBack(t, b, c, d, s)
  s = s or 1.70158
  t = t / d - 1
  return c * (t * t * ((s + 1) * t + s) + 1) + b
end

function inOutBack(t, b, c, d, s)
  s = s or 1.70158
  s = s * 1.525
  t = t / d * 2
  if (t < 1) return c / 2 * (t * t * ((s + 1) * t - s)) + b
  t = t - 2
  return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
end

function outInBack(t, b, c, d, s)
  if (t < d / 2) return outBack(t * 2, b, c / 2, d, s)
  return inBack((t * 2) - d, b + c / 2, c / 2, d, s)
end

function outBounce(t, b, c, d)
  t = t / d
  if t < 1 / 2.75 then
    return c * (7.5625 * t * t) + b
  elseif t < 2 / 2.75 then
    t = t - (1.5 / 2.75)
    return c * (7.5625 * t * t + 0.75) + b
  elseif t < 2.5 / 2.75 then
    t = t - (2.25 / 2.75)
    return c * (7.5625 * t * t + 0.9375) + b
  end
  t = t - (2.625 / 2.75)
  return c * (7.5625 * t * t + 0.984375) + b
end

function inBounce(t, b, c, d)
  return c - outBounce(d - t, 0, c, d) + b
end

function inOutBounce(t, b, c, d)
  if (t < d / 2) return inBounce(t * 2, 0, c, d) * 0.5 + b
  return outBounce(t * 2 - d, 0, c, d) * 0.5 + c * .5 + b
end

function outInBounce(t, b, c, d)
  if (t < d / 2) return outBounce(t * 2, b, c / 2, d)
  return inBounce((t * 2) - d, b + c / 2, c / 2, d)
end

------------
-- PICO-TweenMachine -
-- An additional small extension
-- library for PICO-Tween that
-- acts as a wrapper, powering
-- all tween related functionality
-- internally, rather than having
-- large chunks of tweening 
-- cluttering the codebase.
--
-- @script PICO-TweenMachine
-- @author Joeb Rogers
-- @license MIT
-- @copyright Joeb Rogers 2018

--- A table storing various utility
-- functions used by the ECS.
utilities = {}

--- Assigns the contents of a table to another.
-- Copy over the keys and values from source 
-- tables to a target. Assign only shallow copies
-- to the target table. For a deep copy, use
-- deep_assign instead.
-- @param target The table to be copied to.
-- @param source Either a table to copy from,
-- or an array storing multiple source tables.
-- @param multiple Specifies whether source contains
-- more than one table.
-- @return The target table with overwritten and 
-- appended values.
function utilities.assign(target, source, multiple)
  multiple = multiple or false
  if multiple == true then
    for count = 1, #source do
      target = utilities.assign(target, source[count])
    end
    return target
  else
    for k, v in pairs(source) do
      target[k] = v;
    end
  end
  return target;
end

--- Deep assigns the contents of a table to another.
-- Copy over the keys and values from source 
-- tables to a target. Will recurse through child
-- tables to copy over their keys/values as well.
-- @param target The table to be copied to.
-- @param source Either a table to copy from,
-- or an array storing multiple source tables.
-- @param multipleSource Specifies whether source
-- contains more than one table.
-- @param exclude Either a string or an array of
-- string containing keys to exclude from copying.
-- @param multipleExclude Specifies whether exclude
-- contains more than one string.
-- @return The target table with overwritten and 
-- appended values.
function utilities.deep_assign(target, source, multipleSource, exclude, multipleExclude)
    multipleSource = multipleSource or false
    exclude = exclude or nil
    multipleExclude = multipleExclude or false

    if multipleSource then
        for count = 1, #source do
            target = utilities.deep_assign(target, source[count], false, exclude, multipleExclude)
        end
        return target
    else
        for k, v in pairs(source) do
            local match = false
            if multipleExclude then
                for count = 1, #exclude do
                    if (k == exclude[count]) match = true
                end
            elseif exclude then
                if (k == exclude) match = true
            end
            if not match then
                if type(v) == "table" then
                    target[k] = utilities.deep_assign({}, v, false, exclude, multipleExclude)
                else
                    target[k] = v;
                end
            end
        end
    end
    return target;
end

--- The main wrapper object
-- of the library. 
-- Stores all curent instances
-- of tween objects and drives
-- them.
tween_machine = {
    instances = {}
}

--- Calls update() on all current
-- tween instances.
function tween_machine:update()
    for t in all(self.instances) do
        t:update()
    end
end

--- Adds a created tween instance to
-- the table. The passed in object only
-- needs to define the fields it needs 
-- to change, the rest will be defaulted
-- to the base tween object.
-- For example: 
-- tween_machine:add_tween({
-- func = linear,
-- v_start = 10,
-- v_end = 5
-- })
-- @param instance The tween object to add 
-- to the machine.
-- @return Returns the tween object.
function tween_machine:add_tween(instance)
    local this = 
    {
        func = nil,
        v_start = 0,
        v_end = 1,
        value = 0,
        start_time = 0,
        duration = 0,
        elapsed = 0,
        frame = 0,
        finished = false,
    
        --- Callbacks
        -- Will pass through value
        -- as argument.
        step_callbacks = {},
        -- Will pass through tween
        -- object as argument.
        finished_callbacks = {}
    }
    utilities.deep_assign(this, instance)
    setmetatable(this, __tween)
    add(self.instances, this)
    this:init()
    return this
end

--- The base table for all tween
-- objects.
-- @field func The easing function
-- to use for this tween.
-- @field v_start The starting value
-- for the tween.
-- @field v_end The end value of the 
-- tween.
-- @field value The value between
-- v_start and v_end representing
-- the current tween progress.
-- @field start_time The time at which 
-- the tween was started, set in init()
-- via the time() function.
-- @field duration The duration of time
-- the tween should last for.
-- @field elapsed The amount of time
-- elapsed since the tween was started.
-- @field finished A bool for whether 
-- or not the tween has finished 
-- running.
-- @field step_callbacks A table of 
-- registered callback functions.
-- Called in update() after a new 
-- value has been set.
-- Will call all registered functions
-- with value as the argument.
-- @field finished_callbacks A table
-- of registered callback functions.
-- Called at the end of update()
-- after the tween has been marked
-- as finished.
-- Will call all registered functions
-- with self as the argument.
__tween = {}
__tween.__index = __tween

--- Registers the passed in function
-- as a step callback, to be called
-- in update() after a new value has
-- been set.
-- @param func The function to be 
-- called every step.
function __tween:register_step_callback(func)
    add(self.step_callbacks, func)
end

--- Registers the passed in function
-- as a finished callback, to be 
-- called at the end of update()
-- after the tween has been marked
-- as finished.
-- @param func The function to be 
-- called when finished.
function __tween:register_finished_callback(func)
    add(self.finished_callbacks, func)
end

--- Sets the tween's necessary
-- fields prior to being 
-- ran.
-- Called automatically when
-- added to the wrapper object
-- or when restarted.
function __tween:init()
    self.start_time = time()
    self.value = self.v_start
end

--- Restarts the tween's 
-- necessary fields in order to be
-- ran again.
function __tween:restart()
    self:init()
    self.elapsed = 0
    self.frame = 0
    self.finished = false
end

--- Updates the tween object.
-- Gets the current value for the 
-- tween from the set function and
-- will pass it through all the 
-- registered step callbacks.
-- Will set the tween as finished
-- when the elapsed time passes
-- the duration and will pass 
-- the tween object to all 
-- registered finished callback
-- functions.
-- @return Will return early if
-- the tween is finished or no
-- easing function has been set.
function __tween:update()
    if (self.finished or self.func == nil) return

    self.elapsed = time() - self.start_time
    self.frame += 1 -- frame just increments by 1 each frame.
    if (self.elapsed > self.duration) self.elapsed = self.duration
    self.value = self.func(
        self.elapsed, 
        self.v_start, 
        self.v_end - self.v_start,
        self.duration
    )

    if #self.step_callbacks > 0 then
        for v in all(self.step_callbacks) do
            v(self.value, self.frame)
        end
    end

    local progress = self.elapsed / self.duration
    if (progress >= 1) then 
        self.finished = true
        if #self.finished_callbacks > 0 then
            for v in all(self.finished_callbacks) do
                v(self)
            end
        end
    end
end

--- Removes the tween from the 
-- wrapper object.
function __tween:remove()
    del(tween_machine.instances, self)
end
