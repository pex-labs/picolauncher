pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

function tcontains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

