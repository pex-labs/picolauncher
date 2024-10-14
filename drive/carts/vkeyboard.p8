pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include utils.p8

Keyboard = {}
Keyboard.__index = Keyboard

function Keyboard:new(key_color, border_color, selected_color, x,y,width,height)

    local obj = {
        x = x,
        y = y,
        text="",
        key_color = key_color,
        border_color = border_color,
        selected_color = selected_color,
        key_width = flr(width/12),
        key_height = flr(height/5),
        -- position on keyboard
        kx = 2,
        ky = 1,
        -- position on bottom row
        bx = 1,
        -- position on right column
        ry = 1,
        shift = false,
        -- if true symbol keyset if false letter keyset
        switch = false,
        switch_text = {[true] = "ABC", [false] = "#+="},
        uppercase_keyset = {
            "1234567890@",
            "QWERTYUIOP+",
            "ASDFGHJKL_:",
            "ZXCVBNM,.-/",
        },

        lowercase_keyset = {
            "1234567890@",
            "qwertyuiop+",
            "asdfghjkl_:",
            "zxcvbnm,.-/"
        },

        symbols_keyset = {
            "1234567890-",
            "!@#$%^&*()_",
            "~`=\\+{}|[] ",
            "<>;:\"',.?/ "
        }
    }
    setmetatable(obj, self)
    return obj
end

function Keyboard:draw()
    local keys = self:current_keyset()
    for i = 1, #keys do
        for j = 1, #keys[i] do
            local x0 = self.x + (j - 1) * self.key_width
            local y0 = self.y + (i - 1) * self.key_height
            local x1 = x0 + self.key_width
            local y1 = y0 + self.key_height
            local key_color = self.key_color

            if self.ky<=#keys and self.kx==j and self.ky == i then
                key_color = self.selected_color
            end

            rectfill(x0, y0, x1, y1, key_color)
            rect(x0, y0, x1, y1, self.border_color)

            local key_char = sub(keys[i], j, j)
            local text_x = x0 + (self.key_width / 2) - 2
            local text_y = y0 + (self.key_height / 2) - 2
            print(key_char, text_x, text_y, self.border_color)
        end
    end

    local spacebar_color = self.key_color
    local shift_color = self.key_color
    local switch_color = self.key_color
    local backspace_color = self.key_color
    local ok_color = self.key_color
    local return_color = self.key_color

    if self.kx>11 then
        if self.ry==1 then
            backspace_color = self.selected_color
        elseif self.ry==2 then
            return_color = self.selected_color
        else
            ok_color=self.selected_color
        end
    elseif self.ky>#keys then
        if self.bx==1 then
            shift_color = self.selected_color
        elseif self.bx==2 then
            switch_color = self.selected_color
        elseif self.bx==3 then
            spacebar_color = self.selected_color
        end
    end

    local shift_x0 = self.x
    local shift_y0 = self.y+self.key_height*4
    local shift_x1 = shift_x0+self.key_width*2
    local shift_y1 = shift_y0+self.key_height
    rectfill(shift_x0,shift_y0,shift_x1,shift_y1,shift_color)
    rect(shift_x0,shift_y0,shift_x1,shift_y1,self.border_color)
    palt(7,true)
    palt(0,false)
    spr(1,shift_x0+self.key_width/2,shift_y0)
    palt()

    local switch_x0 = self.x+self.key_width*2
    local switch_y0 = self.y+self.key_height*4
    local switch_x1 = switch_x0+self.key_width*2
    local switch_y1 = switch_y0+self.key_height
    rectfill(switch_x0,switch_y0,switch_x1,switch_y1,switch_color)
    rect(switch_x0,switch_y0,switch_x1,switch_y1,self.border_color)
    print(self.switch_text[self.switch],switch_x0+self.key_width/2,switch_y0+self.key_height/4)

    local spacebar_x0 = self.x+self.key_width*4
    local spacebar_y0 = self.y+self.key_height*4
    local spacebar_y1 = spacebar_y0+self.key_height
    local spacebar_x1 = spacebar_x0+7*self.key_width
    rectfill(spacebar_x0,spacebar_y0,spacebar_x1,spacebar_y1,spacebar_color)
    rect(spacebar_x0,spacebar_y0,spacebar_x1,spacebar_y1,self.border_color)

    local backspace_x0 = self.x+self.key_width*11
    local backspace_y0 = self.y
    local backspace_y1 = backspace_y0+self.key_height
    local backspace_x1 = backspace_x0+self.key_width
    rectfill(backspace_x0,backspace_y0,backspace_x1,backspace_y1,backspace_color)
    rect(backspace_x0,backspace_y0,backspace_x1,backspace_y1,self.border_color)

    local return_x0 = self.x+self.key_width*11
    local return_y0 = self.y+ self.key_height
    local return_y1 = return_y0+self.key_height*2
    local return_x1 = return_x0+self.key_width
    rectfill(return_x0,return_y0,return_x1,return_y1,return_color)
    rect(return_x0,return_y0,return_x1,return_y1,self.border_color)

    local ok_x0 = self.x+self.key_width*11
    local ok_y0 = self.y+ self.key_height*3
    local ok_y1 = ok_y0+self.key_height*2
    local ok_x1 = ok_x0+self.key_width
    rectfill(ok_x0,ok_y0,ok_x1,ok_y1,ok_color)
    rect(ok_x0,ok_y0,ok_x1,ok_y1,self.border_color)
end

function Keyboard:current_keyset()
    if self.switch then
        return self.symbols_keyset
    elseif self.shift then
        return self.uppercase_keyset
    end
    return self.lowercase_keyset
end

function Keyboard:current_char(keys)
    printh('curchar '..tostring(self.kx)..','..tostring(self.ky))
    return sub(keys[self.ky], self.kx, self.kx)
end

function Keyboard:input()
    if btnp(0) then
        if self.ky ~= 5 then
            self.kx = self.kx-1
            if self.kx==0 then
                self.kx=12
            end
        else
            self.bx = self.bx-1
            if self.bx==0 then
                self.bx=3
            end
        end
    elseif btnp(1) then
        if self.ky ~= 5 then
            self.kx = self.kx%12+1
        else
            self.bx = self.bx%3+1
        end
    elseif btnp(2) then
        if self.kx>11 then
            self.ry = self.ry-1
            if self.ry==0 then
                self.ry=3
            end
        else
        self.ky = self.ky-1
        if self.ky==0 then
            self.ky=5
            if self.kx<=2 then
                self.bx=1
            elseif self.kx<=4 then
                self.bx=2
            else self.bx=3
            end
        end
    end
    elseif btnp(3) then
        self.ky = self.ky%5+1
        if self.ky==5 then
            if self.kx<=2 then
                self.bx=1
            elseif self.kx<=4 then
                self.bx=2
            else self.bx=3
            end
        end
    elseif btnp(5) then

        -- TODO make this less stupid
        if self.kx>11 then
            if self.ry==1 then
                -- backspace
            elseif self.ry==2 then
                -- return
            else
                -- okay
            end
        elseif self.ky>#self:current_keyset() then
            if self.bx==1 then
                -- shift
                self.shift = not self.shift
            elseif self.bx==2 then
                -- switch
                self.switch = not self.switch
            elseif self.bx==3 then
                -- space
                self.text = self.text .. ' '
            end
        else
            -- handle normal key press
            curchar = self:current_char(self:current_keyset())
            if curchar then
                self.text = self.text .. curchar
            end
        end
    end
end

local keyboard = Keyboard:new(7, 0, 8, 0,0,100, 50)
function _update()
    keyboard:input()
end

function _draw()
    cls()
    keyboard:draw()
    print(keyboard.text, 60,90,8)
end
__gfx__
00000000777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000770000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
