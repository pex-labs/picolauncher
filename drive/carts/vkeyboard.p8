pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

Keyboard = {}
Keyboard.__index = Keyboard

local WIDTH=100
local HEIGHT=50

function Keyboard:new(key_color, border_color, selected_color, x, y, confirm_fn)

    local obj = {
        -- include text field at top
        show_textfield = true,
        -- useful for password fields
        redact_textfield = false,
        -- textfield colors
        textfield_border_color = 0,
        textfield_color = 6,
        x = x,
        y = y,
        confirm_fn=confirm_fn,
        text="",
        key_color = key_color,
        border_color = border_color,
        selected_color = selected_color,
        key_width = flr(WIDTH/12),
        key_height = flr(HEIGHT/5),
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
--invert case
function Keyboard:corrected_text()
    local inverted_text = ""

    for i = 1, #self.text do
        local char = sub(self.text, i, i)
        local ascii = ord(char)

        if ascii >= 97 and ascii <= 122 then
            -- Lowercase to uppercase
            inverted_text = inverted_text .. chr(ascii - 32)
        elseif ascii >= 65 and ascii <= 90 then
            -- Uppercase to lowercase
            inverted_text = inverted_text .. chr(ascii + 32)
        else
            -- Non-alphabet characters remain the same
            inverted_text = inverted_text .. char
        end
    end

    return inverted_text
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
    print('^', shift_x0+self.key_width/2, shift_y0+self.key_height/4)
    -- spr(1,shift_x0+self.key_width/2,shift_y0)
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
    local backspace_y1 = backspace_y0+self.key_height*2
    local backspace_x1 = backspace_x0+self.key_width
    rectfill(backspace_x0,backspace_y0,backspace_x1,backspace_y1,backspace_color)
    rect(backspace_x0,backspace_y0,backspace_x1,backspace_y1,self.border_color)
    print('◀', backspace_x0+self.key_width/2-2, backspace_y0+4)

    local return_x0 = self.x+self.key_width*11
    local return_y0 = self.y+ self.key_height*2
    local return_y1 = return_y0+self.key_height*4
    local return_x1 = return_x0+self.key_width
    rectfill(return_x0,return_y0,return_x1,return_y1,return_color)
    rect(return_x0,return_y0,return_x1,return_y1,self.border_color)
    print('▶', return_x0+self.key_width/2-2, return_y0+4)

    -- draw textfield if enabled
    if self.show_textfield then
        local textfield_x0 = self.x
        local textfield_y0 = self.y - self.key_height
        local textfield_x1 = textfield_x0 + 12 * self.key_width
        local textfield_y1 = textfield_y0 + self.key_height
        rectfill(textfield_x0, textfield_y0, textfield_x1, textfield_y1, self.textfield_color)
        rect(textfield_x0, textfield_y0, textfield_x1, textfield_y1, self.textfield_border_color)
        if self.redact_textfield then
            -- print(string.rep("*", #self.text), textfield_x0 + 2, textfield_y0 + 2, self.border_color)
        else
            print(self.text, textfield_x0 + 2, textfield_y0 + 2, self.border_color)
        end
    end
end

function Keyboard:current_keyset()
    if self.switch then
        return self.symbols_keyset
    elseif self.shift then
        return self.lowercase_keyset
    end
    return self.uppercase_keyset
end

function Keyboard:current_char(keys)
    -- printh('curchar '..tostring(self.kx)..','..tostring(self.ky))
    return sub(keys[self.ky], self.kx, self.kx)
end

function Keyboard:input()
    -- TODO a lot of this code is garbage
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
                self.ry=2
            end
        else
            self.ky = self.ky-1
            if self.ky==0 then
                self.ky=5
                if self.kx<=2 then
                    self.bx=1
                elseif self.kx<=4 then
                    self.bx=2
                else
                    self.bx=3
                end
            end
        end
    elseif btnp(3) then
        if self.kx>11 then
            self.ry = self.ry+1
            if self.ry==3 then
                self.ry=1
            end
        else
            self.ky = self.ky%5+1
            if self.ky==5 then
                if self.kx<=2 then
                    self.bx=1
                elseif self.kx<=4 then
                    self.bx=2
                else
                    self.bx=3
                end
            end
        end
    elseif btnp(4) then
        -- back, exit menu and clear text
        self.text=""
        self.confirm_fn(self:corrected_text())
    elseif btnp(5) then
        -- TODO make this less stupid
        if self.kx>11 then
            if self.ry==1 then
                -- backspace
                if #self.text > 0 then
                    self.text = sub(self.text, 1, #self.text - 1)
                end
            elseif self.ry==2 then
                -- return
                self.confirm_fn(self:corrected_text())
                self.text=""
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

--local keyboard = Keyboard:new(7, 0, 8, (128-100)/2, 78, 100, 50)
--function _update()
    --keyboard:input()
--end

--function _draw()
    --cls()
    --keyboard:draw()
    --print(keyboard.text, 60,90,8)
--end

----TODO can't use gfx since we are using vkeyboard as a library
--__gfx__
--00000000777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
--00000000777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
--00000000777007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
--00000000770000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
--00000000700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
--00000000700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
--00000000777007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
--00000000777007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
