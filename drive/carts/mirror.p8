pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8
#include menu.p8
#include utils.p8
#include tween.lua
#include timer.p8
#include anim.p8
#include ui.p8
#include vkeyboard.p8

local show_keyboard = false

function _init()
    new_loadable('vnc_join', function(resp)
        -- TODO display some visual indication
        if resp == 'ok' then
            -- success, vnc viewer launched
        elseif resp == 'failed' then
            -- failed to launch vnc viewer
        end
    end)

end

local keyboard_up_y = 78
local keyboard_down_y = 148
local keyboard = Keyboard:new(7, 0, 8, 14, keyboard_down_y, function(text)
    show_keyboard = false
    make_vkeyboard_tween(false)

    if text == "" then return end

    request_loadable('vnc_join', {text})
end)

-- TODO this is copied from settings completely
vkeyboard_tween = {}
function make_vkeyboard_tween(show_keyboard)
  local vkeyboard_target_y = 0
  if show_keyboard then
    vkeyboard_target_y = keyboard_up_y
  else
    vkeyboard_target_y = keyboard_down_y
  end
  vkeyboard_tween=tween_machine:add_tween({
    func=outQuart,
    v_start=keyboard.y,
    v_end=vkeyboard_target_y,
    duration=0.5
  })
  vkeyboard_tween:register_step_callback(function(pos)
    keyboard.y = pos
  end)
  vkeyboard_tween:register_finished_callback(function(tween)
    tween:remove()
  end)
  vkeyboard_tween:restart()
end

function _update60()
    tween_machine:update()
    if show_keyboard then
        keyboard:input()
    else
        if btnp(❎) then
            show_keyboard = true
            make_vkeyboard_tween(true)
        end
    end
end

function _draw()

    cls(1)

    local bar_color_1 = 7
    local bar_color_2 = 6

    -- draw top bar
    rectfill(0,0,127,8,bar_color_1)
    rectfill(0,8,127,9,bar_color_2)

    print("mirror", 2, 2, 0)

    -- text input field
    local input_x = 20
    local input_y = 30
    local input_w = 88
    local input_h = 12

    -- draw input box
    rectfill(input_x, input_y, input_x+input_w, input_y+input_h, 6)
    rect(input_x, input_y, input_x+input_w, input_y+input_h, 7)
    
    -- TODO make this accurately reflect what's being typed in kb later
    print("enter ip address...", input_x+4, input_y+3, 5)

    keyboard:draw()
end