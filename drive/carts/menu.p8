pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

function menu_new(items)
  return {
    items=items,
    select=0,
    wrap=true,
    hooks={},

    -- go up in the menu
    up=function(self)
      _select=self.select
      if self.wrap then
        self.select = (self.select-1)%(#self.items)
      else
        self.select = max(self.select-1, 0)
      end
      if _select != self.select then self:_check_hooks() end
    end,

    -- go down in the menu
    down=function(self)
      _select=self.select
      if self.wrap then
        self.select = (self.select+1)%(#self.items)
      else
        -- TODO may be weird if #items = 0
        self.select = min(self.select+1, #self.items-1)
      end
      if _select != self.select then self:_check_hooks() end
    end,

    cur=function(self)
      return self.items[self:index()]
    end,

    index=function(self)
      return self.select+1
    end,

    add_hook=function(self, index, hook)
      self.hooks[index] = hook
    end,

    set_wrap=function(self, wrap)
      self.wrap=wrap
    end,

    -- call to determine if the current entry will trigger a hook
    _check_hooks=function(self)
      hook=self.hooks[self:index()]
      if hook != nil then
        hook()
      end
    end
  }
end
