pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

function menu_new(items)
  return {
    items=items,
    select=0,
    up=function(self)
      self.select = (self.select-1)%(#self.items)
    end,
    down=function(self)
      self.select = (self.select+1)%(#self.items)
    end,
    cur=function(self)
      return self.items[self.select+1]
    end
  }
end
