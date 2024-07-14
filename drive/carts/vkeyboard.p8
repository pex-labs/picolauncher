pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

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
        sx = 2,
        sy = 1,
        shift = false,
        --if true symbol keyset if false letter keyset
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

            if self.sx==j and self.sy == i then
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
    if self.sy>#keys then

        if self.sx==3 then
            spacebar_color = self.selected_color
        elseif self.sx==2 then
            switch_color = self.selected_color
        elseif self.sx==1 then
            shift_color = self.selected_color
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
    return sub(keys[self.sy], self.sx, self.sx)

end

function Keyboard:input()
    if btnp(0) then
        if self.sx~=5 then
            self.sx = self.sx-1
            if self.sx==0 then
                self.sx=11
            end
        end
    elseif btnp(1) then
        self.sx = self.sx%11+1


    elseif btnp(2) then
        self.sy = self.sy-1
        if self.sy==0 then
            self.sy=5
        end
    elseif btnp(3) then
        self.sy = self.sy%5+1
    elseif btnp(4) then
        self.text = self.text .. self:current_char(self:current_keyset())

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
