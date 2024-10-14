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

function tsize(table)
  local count = 0
  for _ in pairs(table) do count = count + 1 end
  return count
end

-- converts anything to string, even nested tables
-- https://www.lexaloffle.com/bbs/?pid=43636
function tostring(any)
    if type(any)=="function" then 
        return "function" 
    end
    if any==nil then 
        return "nil" 
    end
    if type(any)=="string" then
        return any
    end
    if type(any)=="boolean" then
        if any then return "true" end
        return "false"
    end
    if type(any)=="table" then
        local str = "{ "
        for k,v in pairs(any) do
            str=str..tostring(k).."->"..tostring(v).." "
        end
        return str.."}"
    end
    if type(any)=="number" then
        return ""..any
    end
    return "unkown" -- should never show
end

-- check if a string ends with given suffix
function ends_with(str, suffix)
  return sub(str, -#suffix) == suffix
end

-- concats all stringified elements in table with comma
function tconcat(table)
  local res = ""
  for _, v in ipairs(table) do
    res = res .. tostring(v) .. ","
  end
  return res
end