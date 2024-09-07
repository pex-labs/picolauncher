pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

function menu_new(items)
  return {
    items=items,
    select=0,
    wrap=true,
    hooks={},

    len=function(self)
      return #self.items
    end,

    -- get index of up item in menu
    up_index=function(self)
      if self.wrap then
        return (self.select-1)%(#self.items)
      else
        return max(self.select-1, 0)
      end
    end,

    down_index=function(self)
      if self.wrap then
        return (self.select+1)%(#self.items)
      else
        -- TODO may be weird if #items = 0
        return min(self.select+1, #self.items-1)
      end
    end,

    peek_up=function(self)
      return self.items[self:up_index()]
    end,

    peek_down=function(self)
      return self.items[self:down_index()]
    end,

    -- go up in the menu
    up=function(self)
      _select=self.select
      self.select=self:up_index()
      if _select != self.select then self:_check_hooks() end
    end,

    -- go down in the menu
    down=function(self)
      _select=self.select
      self.select=self:down_index()
      if _select != self.select then self:_check_hooks() end
    end,

    cur=function(self)
      return self.items[self:index()]
    end,

    index=function(self)
      return self.select+1
    end,

    set_index=function(self, index)
      self.select=mid(1, index, #self.items)-1
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
