-- scale a pico8 label to a given size

local filename = arg[1]
local size = arg[2]
if (not filename) or (not size) then
    print('usage: p8scale [filename] [size]')
    os.exit(1)
end
size = tonumber(size)

local file = io.open(filename, 'r')
if not file then
    print('failed to open file for reading')
end

while true do
    local line = file:read('*l')
    if not line then
        print('no label section was found')
        os.exit(1)
    end

    if line == '__label__' then
        break
    end
end

-- label section has 128 lines
label={}
for i=1,128 do
    local line = file:read('*l')
    --print(line)
    table.insert(label, line)
end

-- print cart headers
print('pico-8 cartridge // http://www.pico-8.com')
print('version 42')
print('__label__')

scaled={}
for j=1,128,128/size do
    scaled_row=''
    for i=1,128,128/size do
        scaled_row = scaled_row..string.sub(label[j], i, i)
    end
    if #scaled_row < 128 then
        scaled_row = scaled_row .. string.rep('0', 128-#scaled_row)
    end
    print(scaled_row)
    table.insert(scaled, scaled_row)
end


file:close()

