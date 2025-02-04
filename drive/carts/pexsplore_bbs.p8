pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

-- copy of pexsplore.p8 but supports loading games from bbs

#include serial.p8
#include menu.p8
#include utils.p8
#include tween.lua
#include timer.p8
#include anim.p8

bg_color=129
bar_color_1=12
bar_color_2=-4

cart_dir='games'
label_dir='bbs' -- TODO: currently bbs is a symlink because I want to test p8.png loading. This should not be a symlink and instead games should have p8.png files when possible since those have more information.
loaded_carts={} -- list of all carts that can be displayed in the menu
carts={}        -- menu for pexsplore ui

-- loading animation for downloading songs
-- 0: dont show, 1: loading, 2: done
music_dl_icon_state=0


-- menu for each cartridge
cart_options=menu_new({
  {label='play',func=function()
    make_transition_tween(carts:cur())
  end},
  {label='favorite',func=function()
    sfx(3)
    local is_favorite = not carts:cur().favorite
    request_loadable('set_favorite', {carts:cur().id, is_favorite})
  end},
  {label='download',func=function()sfx(1)end},
  {label='save music',func=function()
    sfx(3)
    -- TODO check if music is already downloaded

    request_loadable('download_music', {carts:cur().id})

    -- start loading animation
    music_dl_icon_state=1
    loading_anim:start()

  end},
  {label='similar carts',func=function()sfx(1)end},
  {label='back',func=function()
    sfx(3)
    cart_tween_up()
    cart_tween_state = 1
  end},
})

-- load label into slot into memory
function load_label(cart, slot)
  if cart == nil then return end

  -- load cartridge art of current cartridge into memory
  label_name=tostring(cart.filename) .. '.64.p8'
  reload(slot*0x1000, 0x0000, 0x1000, label_dir .. '/' .. label_name)
end

-- can pass -1 to slot to skip label
-- TODO this function is duplicated a lot, should abstract it
function draw_label(x, y, w, slot)
  rectfill(x-w/2, y-w/2, x+w/2, y+w/2, 0)
  -- render a 64x64 label from memory in 'scanlines'
  if slot >= 0 then
    for j = 0, 31 do
      for i = 0, 1 do
        sspr(i*64, slot*32 + j, 64, 1, x-w/2, y-w/2+j*2+i)
      end
    end
  end
end

function draw_cart(x, y, slot)
  local w=64

  -- border
  rectfill(x-w/2-2, y-w/2-11, x+w/2+2, y+w/2+2, 5)
  -- rectfill(x-w/2-2, y+w/2+7, x+w/2-5, y+w/2+13, 5)

  -- corner
  -- line(x+w/2+1, y+w/2+6, x+w/2-4, y+w/2+11, 7)
  -- line(x+w/2+1, y+w/2+7, x+w/2-4, y+w/2+12, 7)
  -- line(x+w/2+1, y+w/2+8, x+w/2-4, y+w/2+13, 7)

  -- TODO waste of tokens
  for i=0,10 do
    line(x-w/2-2, y+w/2+3+i, x+w/2+2-max(i-3, 0), y+w/2+3+i, 5)
    if i <= 8 then
      line(x-w/2, y+w/2+3+i, x+w/2-max(i-2, 0), y+w/2+3+i, 13)
    end
  end

  -- divet
  rectfill(x-w/2, y-w/2-9, x+w/2, y-w/2-3, 13)
  -- rectfill(x-w/2, y+w/2+3, x+w/2, y+w/2+11, 13)

  -- pico8 logo
  spr(128, x-w/2+1, y-w/2-8, 5, 1)

  -- edge connector
  for i=0,9 do
    rect(x-w/2+4+5*i, y+w/2+5, x-w/2+5+5*i, y+w/2+13, 9)
    rect(x-w/2+6+5*i, y+w/2+5, x-w/2+6+5*i, y+w/2+13, 10)
  end

  -- label
  draw_label(x, y, w, slot)
end

cart_y_ease=0
cart_y_bob=0
cart_x_swipe=64
-- 1 is up, -1 is down
cart_tween_state=1

cart_tween={}
cart_swipe_tween={}
cart_bobble_tween={}

function cart_tween_bobble()
  bob_amplitude=2
  cart_bobble_tween=tween_machine:add_tween({
    func=inOutSine,
    v_start=-bob_amplitude,
    v_end=bob_amplitude,
    duration=1
  })
  cart_bobble_tween:register_step_callback(function(pos)
    cart_y_bob=pos
  end)
  cart_bobble_tween:register_finished_callback(function(tween)
    tween.v_start=tween.v_end 
    tween.v_end=-tween.v_end
    tween:restart()
  end)
  cart_bobble_tween:restart()
end

function cart_tween_down()
  cart_tween=tween_machine:add_tween({
    func=outQuart,
    v_start=cart_y_ease,
    v_end=90,
    duration=1
  })
  cart_tween:register_step_callback(function(pos)
    cart_y_ease=pos
  end)
  cart_tween:register_finished_callback(function(tween)
    tween:remove()
  end)
  cart_tween:restart()
end

function cart_tween_up()
  cart_tween=tween_machine:add_tween({
    func=outQuart,
    v_start=cart_y_ease,
    v_end=0,
    duration=1
  })
  cart_tween:register_step_callback(function(pos)
    cart_y_ease=pos
  end)
  cart_tween:register_finished_callback(function(tween)
    tween:remove()
    cart_tween_bobble()
  end)
  cart_tween:restart()
end

-- dir is -1 (left) or 1 (right)
function make_cart_swipe_tween(dir)
  cart_swipe_tween=tween_machine:add_tween({
    func=outQuart,
    v_start=64,
    v_end=64+dir*128,
    duration=0.25
  })
  cart_swipe_tween:register_step_callback(function(pos)
    cart_x_swipe=pos
  end)

  cart_swipe_tween:register_step_callback(function(_, frame)
    serial_load_image("bbs/"..carts:cur().filename, 0x0000, 128, 128, frame)
  end)

  cart_swipe_tween:register_finished_callback(function(tween)
    cart_x_swipe=64-1*dir*128
    tween:remove()

    -- load_label(carts:cur(), 0)
    make_cart_swipe_tween_2(dir)
  end)
  cart_swipe_tween:restart()
end

-- part 2 of tween
function make_cart_swipe_tween_2(dir)
  cart_swipe_tween=tween_machine:add_tween({
    func=outQuart,
    v_start=64-1*dir*128,
    v_end=64,
    duration=0.25
  })
  cart_swipe_tween:register_step_callback(function(pos)
    cart_x_swipe=pos
  end)
  cart_swipe_tween:register_finished_callback(function(tween)
    tween:remove()
  end)
  cart_swipe_tween:restart()
end

transition_radius=0
transition_tween={}
function make_transition_tween(cart)
  transition_tween=tween_machine:add_tween({
    func=outQuart,
    v_start=0,
    v_end=200,
    duration=1
  })
  transition_tween:register_step_callback(function(pos)
    transition_radius=pos
  end)
  transition_tween:register_finished_callback(function(tween)
    tween:remove()
    load(cart_dir .. '/' .. tostring(cart.filename) .. '.p8', 'back to games')
  end)
  transition_tween:restart()
end

menuitem = {
  cart = 0, -- a standard cartridge
  load = 1  -- a loading page
}
loaded_pages=0   -- number of pages (of 30 games) have been loaded so far
carts_per_page=30

loading_anim_timer=0 -- timer used for loading animation
loading_state=0

function _init()
  games_category=stat(6)
  -- fallback incase of invalid category
  if games_category == nil or games_category == '' then
    printh('invalid games category')
    games_category='featured'
  end
  -- special flag to disable pagination for local only categories (like local and favourites)
  is_local = (games_category == 'local' or games_category == 'favorites')

  carts=build_new_cart_menu({})
  
  -- loadables
  new_loadable('bbs', function(resp)
    printh('bbs_load response '..tostring(resp))
    local split_carts=split(resp, ',', false)
    for k, v in pairs(split_carts) do
      split_carts[k]=table_from_string(v)

      -- parse into bool
      if split_carts[k].favorite == 'true' then
        split_carts[k].favorite = true
      else
        split_carts[k].favorite = false
      end
    end
    local old_index = carts:index()
    carts=build_new_cart_menu(split_carts)
    carts:set_index(old_index) -- set the correct position of the menu
    load_label(carts:cur(), 0)
  end, 1) 

  new_loadable('set_favorite', function(resp)
    local split_resp=split(resp, ',', true)
    local cart_id=split_resp[1]
    local is_favorite=tobool(split_resp[2])
    printh('response from set_favorite '..tostring(cart_id)..' '..tostring(is_favorite))

    -- TODO probably not safe to use cur_cart, since it could have changed
    carts:cur().favorite = is_favorite

    printh('favorite is now '..tostring(carts:cur().favorite))

    -- play relevant animation
    if is_favorite then
      favorite_anim:start()
    else
      unfavorite_anim:start()
    end

  end, 0.1)

  new_loadable('download_music', function(resp)
    printh('response from download_music '..resp)

    music_dl_icon_state=2
    check_anim:start()
  end, 1)

  cart_tween_bobble()

  -- create animation
  unfavorite_anim=anim_new(
    'unfavorite',
    {
      -- TODO can make this waste less tokens
      {0, 123, 5, 5},
      {6, 123, 5, 5},
      {12, 123, 5, 5},
      {18, 123, 5, 5},
      {24, 123, 5, 5},
      {30, 123, 5, 5},
    },
    3,
    false
  )

  -- TODO hack to scrub to last frame
  unfavorite_anim:start()

  favorite_anim=anim_new(
    'favorite',
    {
      {30, 123, 5, 5},
      {0, 117, 5, 5},
      {6, 117, 5, 5},
      {12, 117, 5, 5},
      {18, 117, 5, 5},
      {24, 117, 5, 5},
      {30, 117, 5, 5},
      {36, 117, 5, 5},
      {30, 117, 5, 5},
      {36, 117, 5, 5},
      {30, 117, 5, 5},
      {36, 117, 5, 5},
      {30, 117, 5, 5},
    },
    3,
    false
  )

  loading_anim=anim_new(
    'loading',
    {
      {0, 111, 5, 5},
      {6, 111, 5, 5},
      {12, 111, 5, 5},
    },
    7,
    true
  )
  loading_anim:start()

  check_anim=anim_new(
    'check',
    {
      {18, 111, 5, 5},
      {24, 111, 5, 5},
      {30, 111, 5, 5},
      {36, 111, 5, 5},
    },
    3,
    false
  )

  favorite_anim:start()

  -- automatically make first query
  loaded_pages = loaded_pages+1
  request_loadable('bbs', {loaded_pages, games_category})
end

function _update60()
  tween_machine:update()
  update_anim()

  if cart_tween_state > 0 then
    if btnp(0) then
      if carts:index() == 1 then
        sfx(1)
      else
        sfx(0)
        carts:up()
        make_cart_swipe_tween(1)
      end
    elseif btnp(1) then
      if carts:index() == carts:len() then
        sfx(1)
      else
        sfx(0)
        carts:down()
        make_cart_swipe_tween(-1)
      end
    elseif btnp(4) then
      os_back()
    elseif btnp(5) then
      if carts:cur().menuitem == menuitem.load then

        -- only ask for new page if previous page has been loaded
        if status_loadable('bbs') == false then
          -- request load from bbs
          loaded_pages=loaded_pages+1
          printh('requesting page from bbs '..loaded_pages)
          request_loadable('bbs', {loaded_pages, games_category})
        end

      else
        sfx(2)
        cart_bobble_tween:remove()
        cart_tween_down()
        cart_tween_state = -1
      end
    end
  else
    if btnp(2) then
      sfx(0)
      cart_options:up()
    elseif btnp(3) then
      sfx(0)
      cart_options:down()
    elseif btnp(4) then
      sfx(3)
      cart_bobble_tween:remove()
      cart_tween_up()
      cart_tween_state = 1
    elseif btnp(5) then
      cart_options:cur().func()
    end
  end

  -- query for response from bbs load
  if status_loadable('bbs') then
    -- update loading animation
    curtime=time()
    if curtime-loading_anim_timer > 1 then
      loading_anim_timer=curtime
      loading_state=(loading_state+1)%4
    end
  end

  update_loadables()
end

function build_new_cart_menu(resp)
  -- TODO can this be done all at once?
  for _, item in ipairs(resp) do
    add(loaded_carts, item)
    printh('loaded '..tostring(item))
  end

  -- create a new menu after loading carts
  -- TODO very dumb that we are making a new copy of the menu items
  new_menuitems = {}
  for _, item in ipairs(loaded_carts) do
    item.menuitem = menuitem.cart
    add(new_menuitems, item)
  end
    
  -- TODO would like to disable this option for local categories, but also need to make sure we don't have an empty menu
  add(new_menuitems, {menuitem=menuitem.load})

  local new_carts=menu_new(new_menuitems)
  new_carts:set_wrap(false)
  return new_carts
end

function draw_menuitem(w, y, text, sel)
  if sel then c=7 else c=6 end
  local h=12
  rectfill(0, y, w, y+h, 13)
  line(0, y-1, w, y-1, c)
  line(w+1, y, w+1, y+h-1, c)
  line(0, y+h, w, y+h, c)
  print(text, w-#text*4-3, y+4, c)
end

function _draw()
  cls(bg_color)

  draw_carts_menu()

  -- top bar
  rectfill(0, 0, 128, 8, bar_color_1)
  print("★", 2, 2, 10)
  print('pexsplore>'..games_category, 12, 2, 7)

  -- transition
  circfill(64, 128, transition_radius, 0)
end

function draw_carts_menu()
  -- draw the cartridge
  if carts:cur().menuitem == menuitem.load then
    if status_loadable('bbs') then
      local str="loading"
      for i=1,loading_state do
        str=str..'.'
      end
      print(str, cart_x_swipe-#str*2, 64, 7)
    else
      local str="❎ load more carts"
      print(str, cart_x_swipe-#str*2, 64, 7) 
    end 
  else
    draw_cart(cart_x_swipe, 64.5+cart_y_ease+cart_y_bob, 0)
    local str="❎view"
    print(str, 64-#str*2, 117+cart_y_ease+cart_y_bob, 7)
  end

  if cart_tween_state > 0 then
    if carts:index() > 1 then
      print("⬅️", 3, 64, 7)
    end
    if carts:index() < carts:len()then
      print("➡️", 118, 64, 7)
    end
  end

  -- draw menu
  menu_x=36
  menu_y=-10
  print(tostring(carts:cur().title), menu_x, -(#cart_options.items*7)+menu_y-10+cart_y_ease, 14)
  print('by ' .. tostring(carts:cur().author), menu_x, -(#cart_options.items*7)+menu_y-3+cart_y_ease, 15)
  line_y=-(#cart_options.items*7)+menu_y+3+cart_y_ease
  line(menu_x, line_y, 88, line_y, 6)
  for i, menuitem in ipairs(cart_options.items) do
    is_sel=cart_options:index() == i
    if is_sel then
      c=7
      x_off=0
    else
      c=6
      x_off=2
    end

    if menuitem.label == "favorite" then
      -- special case for favorite
      local frame=nil
      if carts:cur().favorite then
        frame = favorite_anim:get_frame()
        c=8
      else
        frame = unfavorite_anim:get_frame()
        c=6
      end

      print(menuitem.label, menu_x+x_off, -(#cart_options.items*7)+menu_y+i*7+cart_y_ease, c)

      -- draw favorite icon
      sspr(frame[1], frame[2], frame[3], frame[4], menu_x+x_off+#menuitem.label*4, -(#cart_options.items*7)+menu_y+i*7+cart_y_ease)
    elseif menuitem.label == 'save music' then

      -- draw favorite icon
      if music_dl_icon_state == 1 then
        frame = loading_anim:get_frame()
        sspr(frame[1], frame[2], frame[3], frame[4], menu_x+x_off+#menuitem.label*4, -(#cart_options.items*7)+menu_y+i*7+cart_y_ease)
      elseif music_dl_icon_state == 2 then
        frame = check_anim:get_frame()
        sspr(frame[1], frame[2], frame[3], frame[4], menu_x+x_off+#menuitem.label*4, -(#cart_options.items*7)+menu_y+i*7+cart_y_ease)
      end

      print(menuitem.label, menu_x+x_off, -(#cart_options.items*7)+menu_y+i*7+cart_y_ease, c)
    else
      print(menuitem.label, menu_x+x_off, -(#cart_options.items*7)+menu_y+i*7+cart_y_ease, c)
    end
  end

end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00800007777077770077700777700000777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
097f0077077007700770007707700000700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a777e077777007700770007707707707777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b7d0077000007700770007707700007700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00c00077000077770777707777000007777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00670007060006700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000006000700000600000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
600060000000700070000000000000000000000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000070700060600000b00000b00000b0b000b0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0760000607000076000000000b00000b00000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55088055088055088055088088088088088077077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555055558055558085558085858088888077777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555055558055558085558085558088888077777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05550005550005580008580008580008880007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00500000500000800000800000800000800000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88088055055055055055055055055055055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888085888085855055555055555055555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888088888088858085558055555055555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08880008880008880005880005550005550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00800000800000800000800000800000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000200000d7500d7500d7000840008400084000c4000c4000c4000b40012400074000a40008400034000630000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600000432004320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000015500655008550095500a5500b5500c5500d5500e5500f5501155012550135501455017550195501c5501f550235002450022500215001f5001e5001d5001b500195001650014500145001250011500
000100001a5501a5501855017550155501255012550105500d5500a55007550055500555004550035500155000550000000000000000000000000000000000000000000000000000000000000000000000000000
