pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

#include serial.p8
#include menu.p8
#include utils.p8
#include tween.lua

function _init()
  serial_hello()
end

function _update()

end

-- temp, include a color for the box
categories={
    {label='featured',c1=12,c2=0},
    {label='shooter',c1=9,c2=0},
    {label='puzzle',c1=11,c2=0},
    {label='platformer',c1=8,c2=0},
    {label='co-op',c1=14,c2=0},
    {label='arcade',c1=10,c2=0},
}

function _draw()
    cls(1)
    rectfill(0, 0, 128, 56, 12)
    -- TODO scale text
    -- https://www.lexaloffle.com/bbs/?tid=29612
    print('EXsplore', 90, 48, 7)

    -- categories section
    print('categories', 8, 60, 6)
    line(8, 68, 120, 68, 6)

    cat_x = 8
    cat_y = 72
    cat_w = 32
    cat_h = 16
    for i, item in ipairs(categories) do
        x = (i-1) % 3
        y = ((i-1)\3)
        -- print(item.label .. ' ' .. x .. ' ' .. y)
        rectfill(cat_x+x*(cat_w+8), cat_y+y*(cat_h+8), cat_x+x*(cat_w+8)+cat_w, cat_y+y*(cat_h+8)+cat_h, item.c1)
    end
end
