pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

list_enemies = {}
list_villagers = {}
list_people = {}
list_drawstuff = {}
list_objects = {}
list_parts_back = {}
list_parts_front = {}
list_parts_blood = {}
list_steps = {}
list_heads = {}

function frnd(n)
	return flr(rnd(n))
end

function frnda(n, o)
	local addval = o or 1
	return frnd(n)+addval
end

function randc(chance)
	local c = chance or 50
	if frnd(100) < c then
		return true
	end
	return false
end

function wrap(value, min, max)
	if value < min then
		return max
	elseif value > max then
		return min
	else
		return value
	end
end

function table_clear(t)
	local count = #t
	for i=0, count do t[i]=nil end
end

function copy_screen_to_mem()
	-- half the map/lower sprite memory area
	memcpy(0x1800, 0x6000, 0x0800)
	-- almost all general use memory
	memcpy(0x4300, 0x6800, 0x1800)
end

function paste_screen_from_mem()
	memcpy(0x6000, 0x1800, 0x0800)
	memcpy(0x6800, 0x4300, 0x1800)
end

function printc_o(str, y, col, outcol, x) -- print a centered string with a black outline
	for i=-1,1 do
	 	for j=-1,1 do
	   	printc(str, y+j, outcol or 2, (x or 64)+i)
	 	end
	end
	printc(str, y, col, (x or 64))
end

function printc(str, y, col, x)
	print(str, (x or 64)-#str*2, y, col or 7)
end


function printsprite(str, y, color)
	pal(7, color)
	for i=1, #str do

		local letter, whichalpha = sub(str,i,i), -1
		for j in all(g_alphabet_sprites) do
			whichalpha += 1
			if letter == j then
				spr(131 + flr(whichalpha/9)*16 + whichalpha % 9, 64-(#str*8)/2 + (i-1)*8, y)
				break
			end
		end
	end
	pal()
end

function set_outline()
	pal(2, g_color_outline)
end

function m_textfloat(x,y, text, col_main, col_sec)
	add(list_parts_front,
	{
		x=x,
		y=y,
		text=text,
		col_main=col_main or 7,
		col_sec=col_sec or 5,
		dur=30,
		dur_orig=30,

		draw=function(self)
			local color = self.col_main
			if self.dur < self.dur_orig/3 then
				color = self.col_sec
			end
			printc_o(self.text, self.y, color, g_color_outline, self.x)
		end,

		update=function(self)
			self.dur-=1
			if self.dur == 0 then
				del(list_parts_front, self)
			else
				self.y -= .3
			end
		end,
	})
end

function a_set_invuln_flash(self)
	if self.invuln_frames > 0 and self.invuln_frames % 5 < 3 then
		for i=1,15 do
			pal(i, 2)
		end
		return true
	end
	return false
end

function is_near_objs(obj1, obj2, range)
	if abs(obj1.x-obj2.x) <= range and abs(obj1.y-obj2.y) <= range then
		return true
	end
	return false
end

function int_cols(e1, e2, buffer)
	if e1.just_spawned or e2.just_spawned then
		return false
	end
	local buffer = buffer or 0
	local x1, y1, w1, h1, x2, y2, w2, h2 =
				e1.x-e1.col_w/2-buffer,
				e1.y-e1.col_h/2-buffer,
			 	e1.col_w+buffer*2,
			 	e1.col_h+buffer*2,
				e2.x-e2.col_w/2-buffer,
				e2.y-e2.col_h/2-buffer,
				e2.col_w+buffer*2,
				e2.col_h+buffer*2
	if x1+w1<x2 or x2+w2<x1 or y1+h1<y2 or y2+h2<y1 then
    return false
	else
  	return true
	end
end

function m_part_blood(part_details, duration)
	part_details[6] = duration or frnda(10, 50)
	m_part_angle(part_details, .65, 8, g_color_blood_burn)
end

function m_part_angle(part_details, frict, color, color_sec, layer)

	local p =
	{
		size=part_details[1]-1,
		x=part_details[2],
		y=part_details[3],
		angle=part_details[4],
		speed_move=part_details[5],
		duration=part_details[6],
		frict=frict,
		color=color,
		color_sec=color_sec or color,
		layer=layer or 0,

		time=0,

		draw=function(self)
			local color, s2 = self.color, self.size/2
			if self.time > self.duration *.75 then
				color = self.color_sec
			end
			if self.size == 0 then
				pset(self.x, self.y, color)
			else
				rectfill(self.x-s2, self.y-s2, self.x+s2, self.y+s2, color)
			end
		end,

		update=function(self)
			if self.time > self.duration then
				if self.layer == 1 then
					del(list_parts_back, self)
				elseif self.layer == 2 then
					del(list_parts_front, self)
				else
					del(list_parts_blood, self)
				end

				return
			end
			if self.speed_move > .1 then
				a_move_angle(self)
				self.speed_move *= self.frict
			end
			self.time += 1
		end,
	}
	if layer == 1 then
		add(list_parts_back, p)
	elseif layer == 2 then
		add(list_parts_front, p)
	else
		add(list_parts_blood, p)
	end
	return p
end

function m_part_sprite(frame, x,y, dy, col, col_sec, duration, flipx, is_front)

	local p =
	{
		x=x,
		y=y,
		frame=frame,
		col=col,
		col_sec=col_sec or col,
		duration=duration,
		flipx=flipx or false,
		is_front=is_front or false,

		time=0,
		dx=0,
		dy=dy,
		ddy=0,

		draw=function(self)
			if self.time < self.duration *.75 then
				pal(7,self.col)
			else
				pal(7,self.col_sec)
			end
			spr(self.frame, self.x-4, self.y-4, 1, 1, self.flipx)
			pal()
		end,

		update=function(self)
			self:update_base()
		end,

		update_base=function(self)
			if self.time > self.duration then
				if self.is_front then
					del(list_parts_front, self)
				else
					del(list_parts_back, self)
				end
				return
			end
			self.x += self.dx
			self.y += self.dy
			self.dy += self.ddy
			self.time += 1
		end,
	}
	if is_front then
		add(list_parts_front, p)
	else
		add(list_parts_back, p)
	end
	return p
end

function m_part_bomb_spark(x, y)
	local color, color_second = 10, 9
	if randc() then
		color, color_second = 7, 10
	end
	local p = m_part_sprite(103, x, y, -.2-rnd(.5), color, color_second, 10+rnd(5), false, true)
	p.ddy = .1
	local dx = rnd(.5)
	if randc() then
		dx = 0 - dx
	end
	p.dx = dx
end

function m_part_circle(x,y, size, duration, color, color_sec, layer)

	local p = m_part_angle({size, x, y, 0, 0, duration}, 0, color, color_sec, layer)
	p.draw=function(self)
		local color = self.color
		if self.time > self.duration * .75 then
			color = self.color_sec
		end
		circfill(self.x, self.y, self.size, color)
	end
end

function m_part_bloodsplash(x,y,angle)

	for i=0,36 do
		local size, xoff, yoff, angleoff,dur=1, rnd(4), rnd(4), rnd(.2), rnd(8)
		if i > 30 then
			dur=rnd(1)
			size=2
		elseif i > 15 then
			dur=rnd(4)
		end
		m_part_blood({size, x-2+xoff, y-2+yoff, angle-.1+angleoff, dur})
	end

end

function m_part_impact(entity,size)
	m_part_circle(entity.x, entity.y, size or 7, 4, 10, 9, 1)
end

function handle_slash_recovery(speed)
	local dir = rnd(.125)
	if randc() then
		dir = 0-dir
	end

	p1.slash_angle, p1.slash_speed, p1.slash_time, p1.slash_has_impacted =
	abs(p1.slash_angle+.5+dir)%1, speed or 0, 5, true
	a_anim_set(p1, "attack")
end

function handle_slash_entity_impact(target)

	cam:shake(.1, 3)
  game_pause(2, 0)
	if not target.is_furniture then
		m_part_bloodsplash(target.x, target.y, p1.slash_angle)
	end

	m_part_impact(target, 10)
	handle_slash_recovery()
end

function score_add(entity, score)
	if score > 0 then
		sfx(min(26+flr(score/1), 31))
	else
		sfx(32)
	end

  g_score_level += score

  local score_color, score_color_sec = 10, 9
  if score >= 4 then
    score_color, score_color_sec = 7, 9
  elseif score >= 2 then
    score_color, score_color_sec = 11, 3
	elseif score < 0 then
		score_color, score_color_sec = 8, 13
  end
	if score != 0 then
  	m_textfloat(entity.x, entity.y-8, ""..score*10, score_color, score_color_sec)
	end
end

function attempt_deflect_target(target)

	local reverse_angle = abs(target.angle+.5)%1

	if abs(p1.slash_angle - reverse_angle) < .25 then

		sfx(8)
		m_part_circle(target.x, target.y, 6, 10, 7, 5, 1)

		target.is_flying, target.is_flying_impactable, target.windup_time_rem, target.attack_time_rem, target.fly_speed =
		true, false, 0, 0, 2

		local t_dir = rnd(.125)
		if randc() then
			t_dir = 0 - t_dir
		end
		target.angle= abs(p1.slash_angle+t_dir)%1
		--target:emotion_add()

		-- todo - combine this with handle-impact version into a single function

		handle_slash_recovery(2)
		return true
	end
	return false
end

function combo(entity, target)
	entity.was_counted_for_combo = true

	sfx(frnda(2, 21))
	handle_impact_death(entity, target)

	if not entity.is_furniture then
		m_part_bloodsplash(target.x, target.y, entity.angle)
	end

	target:handle_impact(entity)
	target.fly_speed, target.angle = entity.fly_speed, entity.angle%1

	if entity.is_heavy or entity.is_armored then
		target.score_multiplier = entity.score_multiplier
		fly_reset(entity)
		entity.invuln_frames = 15
		if entity.is_armored then
			attack_reset(entity)
		end
	else
		target.score_multiplier = entity.score_multiplier + 1
	end
end

function slash_target(target)

	sfx(25)
	target.fly_speed, target.angle = 3, p1.slash_angle
	target:handle_impact()
	handle_slash_entity_impact(target)
	a_anim_set(p1, "attack")
end

function a_anim_update(entity, anim_set, tick_multiplier)
	if tick_multiplier == nil then
		tick_multiplier = 1
	end
	entity.animtick-=1 * tick_multiplier
	if entity.animtick<=0 then
		entity.curframe+=1
		local a=anim_set[entity.curanim]

		entity.animtick=a.ticks
		if entity.curframe>#a.frames then
			entity.curframe=1
		end
	end
end

function a_anim_set(entity, anim)
	if(anim==entity.curanim)return

	entity.animtick, entity.curanim, entity.curframe = character_anims[anim].ticks, anim, 1
end

function a_doflipx(entity)
	local angle = entity.angle
	if angle == .25 or angle == .75 then
		return
	elseif angle > .25 and angle < .75 then
		entity.flipx = true
	else
		entity.flipx = false
	end
end

function constrain_to_screen(obj)
	return constrain_to_borders(obj, g_level_screen_buffer+4, g_level_screen_buffer+4, 124-g_level_screen_buffer, 124-g_level_screen_buffer)
end

function constrain_to_borders(obj, bor_x1, bor_y1, bor_x2, bor_y2)

	local was_constrained, x, y = false, obj.x, obj.y
	if x < bor_x1 then
		x, was_constrained = bor_x1, true
	elseif x > bor_x2 then
		x, was_constrained = bor_x2, true
	end
	if y < bor_y1 then
		y, was_constrained = bor_y1, true
	elseif y > bor_y2 then
		y, was_constrained = bor_y2, true
	end
	obj.x, obj.y = x, y
	return was_constrained
end

function game_pause(duration)
	game_pause_timer = duration
end

function handle_impact_death(entity, target)
	if not entity.is_furniture and not entity.is_armored then
		split_entity(entity, (entity.angle+.5)%1)
		m_part_bloodsplash(target.x, target.y, entity.angle)
		if target.is_heavy then
			if not target.is_bloody then
				target.sprite += 16
				target.is_bloody = true
			end
		end
	end
	m_part_impact(entity)
	cam:shake(.5*entity.fly_speed,10)
  game_pause(2)

	if entity.is_villager then
		level_end_villager_died(false)
	end
	if not entity.is_heavy and not entity.is_armored then
  	del_from_people(entity)
		score_add(entity, entity.score * entity.score_multiplier)
	end
end

function fly_reset(entity)
	entity.fly_speed, entity.is_flying, entity.is_flying_impactable, entity.angle, entity.score_multiplier =
	0, false, false, get_dir_to_player(entity), 1
end

function attack_reset(entity)
	entity.attack_time_rem, entity.recovery_time_rem, entity.time_between_attacks_rem =
	0, entity.recovery_time, entity.time_between_attacks+entity.recovery_time
end

function a_attack(entity)

	entity.attack_time_rem -= 1
	a_move_angle(entity, 4)
	if constrain_to_screen(entity) then
		sfx(20)
		attack_reset(entity)
	end

	if entity.attack_time_rem <= 0 then
		attack_reset(entity)
	end
end

function a_fly(entity)
	a_move_angle(entity, entity.fly_speed)
	entity.fly_speed *= .95

	local was_reset = false

  if entity.fly_speed <= .1 then
		fly_reset(entity)
		was_reset = true
  end

	if constrain_to_screen(entity) then
		entity.angle, entity.fly_speed = get_rebound_angle_speed(entity.angle, entity.fly_speed)
		m_part_impact(entity)
		entity.is_flying_impactable = false
		sfx(23)
	end

	if not was_reset and entity.is_flying_impactable then
		for a in all(list_people) do
		--	if not a.is_flying then
				if entity != a and a.invuln_frames == 0 and int_cols(entity, a, 2) then
					if entity.fly_speed > .5 then
						combo(entity,a)
						break
					end
				end
		--	end
		end
	end
end

function a_move_angle(entity, speed)
	if not speed then
		speed = entity.speed_move
	end

	entity.angle = abs(entity.angle)%1
	a_doflipx(entity)

	entity.x += cos(entity.angle) * speed
	entity.y += sin(entity.angle) * speed
end

character_anims =
{
	["stand"]=
	{
		ticks=10000,
		hframes={1},
		frames={14},
	},
	["move"]=
	{
		ticks=6,
		hframes={1,1,1,1},
		frames={12,13,14,15},
	},
	["run"]= -- this is a hack because only villagers run
	{
		ticks=7,
		hframes={17,18,17,18},
		frames={12,13,14,15},
	},
	["windup"]=
	{
		ticks=10000,
		hframes={17},
		frames={45},
	},
	["attack"]=
	{
		ticks=10000,
		hframes={33},
		frames={46},
	},
	["fly"]=
	{
		ticks=10000,
		hframes={49},
		frames={47},
	},
}


function get_direction_to_turn(cur_angle, desired_angle)
	local angle_delta = desired_angle-cur_angle

	local turn_result = 0
	if -.5 < angle_delta and angle_delta <= .5 then
		turn_result = angle_delta
	elseif angle_delta > .5 then
		turn_result = angle_delta - 1
	elseif angle_delta <= -.5 then
		turn_result = angle_delta + 1
	end

	if turn_result < 0 then
		return 1
	else
		return -1
	end
end

function get_rebound_angle_speed(angle, speed)
	local dir = -.125
	if randc() then
		dir = .125
	end
	return (angle+.5+dir)%1, speed * .5
end

function get_angle_from_input()
	if p1.recovery_time_rem > 0 then
		return 0
	end
	local ml, mr, mu, md, angle = btn(0), btn(1), btn(2), btn(3), -1
	if ml then
		if md then
			angle = .625
		elseif mu then
			angle = .375
		else
			angle = .5
		end
	elseif mr then
		if md then
			angle = .875
		elseif mu then
			angle = .125
		else
			angle = 0
		end
	elseif md then
		angle = .75
	elseif mu then
		angle = .25
	end
	return angle
end

-- reduction : remove col_w, col_h and just have one square col. remove col_off. remove c+o in offset, just do -4 global

function m_player(setx, sety)

	local p=
	{
		name = "",
		pcolor=7,
		scolor=6,
		is_player = true,
		x=setx,
		y=sety,
		angle=0,
		speed_move=0,
		speed_move_max=1.25,
		col_w=6,
		col_h=6,
		col_off=0,

		curanim="move",
		curframe=1,
		animtick=0,
		flipx=true,
		head_shift=0,
		body_shift=0,

    hp_cur=2,
		is_dead=false,

    recovery_time_rem = 0,
		ready_time = 150,
    invuln_frames = 0,
		is_slashing = false,


		init=function(self)
		end,

    damage=function(self, source, do_kill)
      if self.invuln_frames > 0 and not do_kill then
        return false
      end

			local blood_angle = atan2(self.x - source.x, self.y - source.y)
			m_part_bloodsplash(self.x, self.y, blood_angle)
      game_pause(5)
      cam:shake(3, 20)

			g_player_damaged_time, self.invuln_frames = 10, 60

			self.hp_cur -= 1
      if self.hp_cur <= 0 or g_difficulty > 4 or do_kill then
				self.is_dead, self.head_shift = true, 0
				split_entity(self, (blood_angle+.5)%1)
				sfx(10)
        level_end_player_died(source.is_static)
      else
				sfx(frnda(2))
			end

      return true
    end,


		slash=function(self)
			if not self.is_slashing then

				sfx(frnda(3,4))
				a_anim_set(self, "windup")
				self.slash_has_impacted,
				self.is_slashing,
				self.slash_time,
				self.slash_speed,
				self.slash_angle,
				self.speed_move,
				self.ready_time =
				false,
				true,
				5,
				6,
				self.angle,
				0,
				45
			end
		end,

		update=function(self)
			if self.is_dead then
				return
			end

			if self.ready_time > 0 then
				self.ready_time -= 1
				if self.ready_time == 0 then
					sfx(7)
				end
			end

			check_for_footsteps(self)

			-- blood drip from damage

			local blood_rate = 0
			if self.hp_cur < 2 then
				blood_rate = 2
			end
			if blood_rate > 0 then
				if g_ticks % blood_rate == 0 then
					local size = 1
					if randc(10) then
						size = 2
					end
					m_part_blood({size, self.x-2, self.y-2, rnd(1), rnd(1), frnda(3,10)})
				end
			end

			if self.invuln_frames > 0 then
				self.invuln_frames -= 1
			end

			if self.recovery_time_rem > 0 then
				self.recovery_time_rem -= 1
				--a_anim_set(self, "stand")
				return
			end

			if btnp(4) then
				if self.ready_time == 0 then
					self:slash()
				end
			end

			if self.is_slashing then

				self.slash_time -= 1
				m_part_sprite(49, self.x, self.y, 0, 12, 1, 10, self.flipx, false)

				self.x += cos(self.slash_angle) * self.slash_speed
				self.y += sin(self.slash_angle) * self.slash_speed

				if constrain_to_screen(self) then
					sfx(23)
					self.slash_angle, self.slash_speed = get_rebound_angle_speed(self.slash_angle, self.slash_speed)

					m_part_impact(self)
				end

				if self.slash_time == 0 then
					self.is_slashing, self.recovery_time_rem = false, 10
					a_anim_set(self, "attack")
				end
			else
				local input_angle = get_angle_from_input()

				if input_angle >= 0 then
					--[[
					if (input_angle+.5)%1 == self.angle then
						self.speed_move = 0
					end
					--]]
					self.angle, self.speed_move  = input_angle, self.speed_move_max
					a_move_angle(self)
					a_anim_set(self, "move")
				else
					self.speed_move = 0
					a_anim_set(self, "stand")
				end

				if constrain_to_screen(self) then
					self.speed_move = 0
				end
			end

			a_anim_update(self, character_anims)
		end,

		draw=function(self)
			if self.is_dead then
				return
			end
			if self.ready_time == 0 and (self.curanim == "move" or self.curanim == "stand") then
				self.body_shift, self.head_shift = 16, 16
			else
				self.body_shift, self.head_shift = 0, 0
			end
			draw_character(self)
		end,
	}

	p:init()
	add(list_drawstuff, p)
	return p
end

emotion_anims =
{
	["upset"]=
	{
		ticks=7,
		frames={70,71},
	},
	["angry"]=
	{
		ticks=7,
		frames={72,73,70,74},
	},
}

function m_emotion(entity, emotion)
	local e =
	{
		owner=entity,
		curanim=emotion,
		curframe=1,
		animtick=0,
		color=g_color_interface,

		update=function(self)
			a_anim_update(self, emotion_anims)
		end,

		draw=function(self)
			local frame, c_o = emotion_anims[self.curanim].frames[self.curframe], -4
			pal(7, self.color)

			spr(frame,
				self.owner.x+c_o,
				self.owner.y+c_o-10,
				1,1, false)
			pal()
		end,
	}
	entity.emotion = e
end

--]]

function get_flipx_from_angle(angle)
	if angle > .25 and angle <= .75 then
		return true
	end
	return false
end

function get_dir_to_player(entity)
	return (atan2(entity.x - p1.x, entity.y - p1.y)+.5)%1
end

function get_yboboffset(self)

	if self.curanim == "move" then
		if self.curframe % 2 == 0 then
			return -1
		end
	end
	return 0
end

function m_step(x,y)
	local s =
	{
		x=x-frnda(4,2),
		y=y,
	}
	add(list_steps, s)
end

function check_for_footsteps(self)
	-- do snow stuff
	if g_season == 3 and not g_level_indoor then
		if randc(50) then
			m_step(self.x, self.y)
		end
	end
end

function draw_character(self)

	local yboboffset = get_yboboffset(self)

	if not a_set_invuln_flash(self) then
		pal(6,self.scolor)
		pal(7,self.pcolor)
	end

	local flip_offset = -1
	if self.flipx then
		flip_offset = 1
	end
	set_outline()
	spr(character_anims[self.curanim].hframes[self.curframe]+self.head_shift,
		self.x-4,
		self.y-7+yboboffset,
		1,1,
		self.flipx)
	spr(character_anims[self.curanim].frames[self.curframe]+self.body_shift,
		self.x-4+flip_offset,
		self.y+1+yboboffset,
		1,1,
		self.flipx)
	pal()
end

function split_entity(entity, angle)
	m_bodypart(entity, 42, entity.pcolor, (angle+.300+rnd(.325))%1)
	m_bodypart(entity, 56+entity.head_shift, entity.scolor, abs(angle-.300-rnd(.325))%1)
end

function rndbool()
	return frnd(2) == 0
end

function m_bodypart(entity, sprite, replace_color, angle)
	local h=
	{
		x=entity.x,
		y=entity.y,
		replace_color = replace_color,
		angle=angle,
		sprite=sprite,
		speed_move=.5+rnd(.5),

		flip_x=rndbool(),

		decay_time=frnda(25,25),

		update=function(self)


			-- if we roll to a stop, start counting down cleanup
			if self.speed_move < .1 then
				self.decay_time -= 1
				if self.decay_time < 0 then
					del(list_heads, self)
					del(list_drawstuff, self)
					return
				end
			else
				if g_ticks % 6 == 0 then
					local size = 1
					if randc(33) then
						size = 2
					end
						m_part_blood({size, self.x, self.y, 0, .25+rnd(.5)})
				end
			end

			a_move_angle(self)

			self.speed_move *= .95

			if constrain_to_screen(self) then
				self.angle, self.speed_move = get_rebound_angle_speed(self.angle, self.speed_move)
			end
		end,

		draw=function(self)

			local c_o = -4

			set_outline()
			pal(6, self.replace_color)

			spr(self.sprite,
				self.x+c_o,
				self.y+1+c_o,
				1,1,
				self.flip_x)
			pal()
		end,
	}
	add(list_heads, h)
	add(list_drawstuff, h)
	return h
end

function m_object(x, y, spritelist, is_deadly)
	local o =
	{
		x=x,
		y=y,
		col_w=4,
		col_h=2,
		spritelist=spritelist,
		sprite=1,
		is_static=true,
		is_deadly=is_deadly,

		update=function(self)
		end,

		dealt_damage=function(self)
			self.sprite = 2
		end,

		draw=function(self)
			set_outline()
			pal(14, 8)
			pal(1, g_color_detail)
			spr(self.spritelist[self.sprite], x-4, y-4)
			pal()
		end,
	}
	add(list_objects, o)
	add(list_drawstuff, o)
	return o
end

function m_food(setx, sety)
	local o = m_object(setx, sety, {99, 99}, false)
	o.col_h, o.col_w, o.eat =
	6, 6,
	function(self)
		p1.hp_cur = 2
		m_part_sprite(106, self.x, self.y, -.1, g_color_outline, g_color_outline, 15, false, true)
		score_add(self, 5)
		del(list_objects, self)
		del(list_drawstuff, self)
	end
end

function add_to_people(entity)

	if entity.is_villager then
		add(list_villagers, entity)
	else
		add(list_enemies, entity)
	end

	add(list_people, entity)
	add(list_drawstuff, entity)
end

function del_from_people(entity)
	if entity.is_villager then
		del(list_villagers, entity)
	elseif not entity.is_furniture then
		del(list_enemies, entity)
	end
	del(list_people, entity)
	del(list_drawstuff, entity)
	if #list_enemies == 0 and g_level_enemies_count == 0 then
		level_end_win()
	end
end

function a_alert_checkforwindup(entity)
	if is_level_active() and entity.windup_time_rem == 0 and is_near_objs(entity, p1, entity.alert_distance) then
		entity.windup_time_rem, entity.desired_angle =
		entity.windup_time-entity.emotion_count*3, get_dir_to_player(entity)

		entity.flipx = get_flipx_from_angle(entity.desired_angle)
		a_anim_set(entity, "windup")
		return true
	else
		return false
	end
end

function a_deviate(entity, time)
	if randc(10) then
		entity.deviation_time = frnda(time, time)
	end
end

function a_random_turn(entity)
	local angle_adjust = .25
	if randc() then
		angle_adjust = 0-angle_adjust
	end

	entity.angle_desired = abs(entity.angle_desired+angle_adjust)%1
end

function m_enemy_villager(setx, sety)
	local e = m_enemy(setx, sety, true)
  e.head_shift, e.body_shift, e.pcolor, e.scolor, e.score =
	6, 16, 11, 4, -10

	e.kill_class=function(self, source)
		if source == p1 then
			level_end_villager_died(true)
		else
			level_end_villager_died(false)
		end
		return false
	end

	e.touch_class=function(self)
		score_add(self, 0-self.score-2.5*self.emotion_count)
		del_from_people(self)
		return true
	end

	e.move=function(self)
		a_deviate(self, 5)
		a_random_turn(self)
	end

	e.draw_class=function(self)
	end

	return e
end

function nearest_angle(angle)
	if angle>.825 or angle < .125 then
		angle = 0
	elseif angle < .375 then
		angle = .25
	elseif angle < .625 then
		angle = .5
	else
		angle = .75
	end
	return angle
end

function m_arrow(x, y, angle)
	local a =
	{
		x=x,
		y=y,
		col_w=4,
		col_h=4,
		angle=angle,
		speed_move=3,
		is_static=false,
		is_deadly=true,
		sprite=40,
		flipx=false,

		draw=function(self)
			set_outline()
			spr(self.sprite, self.x-4, self.y-4, 1, 1, self.flipx)
			pal()
		end,

		update=function(self)
			a_move_angle(self)
			if constrain_to_screen(self) then
				self:dealt_damage()
			end
		end,

		dealt_damage=function(self)
			del(list_objects, self)
			del(list_drawstuff, self)
		end,
	}
	if angle == .25 or angle ==.75 then
		a.sprite = 41
	end

	add(list_objects, a)
	add(list_drawstuff, a)
end

function m_enemy_archer(setx, sety)
	local e = m_enemy(setx, sety)
	e.head_shift, e.pcolor, e.scolor, e.alert_distance, e.windup_time, e.time_between_attacks, e.attack_time, e.attack_is_shot = 4, 14, 13, 60, 30, 60, 30, true

	e.move=function(self)
		a_deviate(self, 10)
		if is_level_active() then
			self.angle_desired = get_dir_to_player(self)
		end
	end

	e.alert_class=function(self)
		if abs(self.x - p1.x) < 5 or abs(self.y - p1.y) < 5 then
			if a_alert_checkforwindup(self) then
				self.desired_angle = nearest_angle(self.desired_angle)
				sfx(24)
				return true
			else
				return false
			end
		end
	end

	e.fire_arrow=function(self)
		sfx(17)
		m_arrow(self.x, self.y, self.desired_angle)
	end

	e.draw_class=function(self)
		if self.windup_time_rem > 0 then
			set_outline()
			local arrow_sprite, doflipy = 40, false
			if self.desired_angle == .75 then
				arrow_sprite, doflipy = 41, true
			elseif self.desired_angle == .25 then
				arrow_sprite = 41
			end
			spr(arrow_sprite, self.x-4, self.y-4, 1, 1, self.flipx, doflipy)
			pal()
		end
	end
end

function m_enemy_wander(setx, sety)
	local e = m_enemy(setx, sety)

	e.head_shift, e.pcolor = 1, 9

	e.move=function(self)
		a_deviate(self, 15)
		a_random_turn(self)
	end

	e.alert_class=function(self)
		return a_alert_checkforwindup(self)
	end

	return e
end

function m_enemy_bomber(setx, sety)
	local e = m_enemy(setx, sety)

 	e.pcolor, e.scolor, e.head_shift, e.is_fuse_lit, e.is_bomber =
	8, 4, 3, false, true

	e.touch_class=function(self)
		self:explode(nil, true)
		return true
	end

	e.update_class=function(self)
		if not self.is_fuse_lit and is_near_objs(self, p1, 25) then
			self.is_fuse_lit, self.fuse_timer, self.emotion_count, self.speed_move = true, 500, 1, self.speed_move_orig*2
			sfx(35)
		end
		if self.is_fuse_lit then
			self.fuse_timer -= 1
			if self.fuse_timer <= 0 then
				self:explode(self, true)
			end
			if g_ticks % 4 == 0 then
				m_part_bomb_spark(self.x, self.y-10)
			end
		end
		return true
	end

	e.move=function(self)

		a_deviate(self, 10)
		if is_level_active() then
			self.angle_desired = get_dir_to_player(self)
		end
	end

	e.explode=function(self, source, no_score)
		if source != nil and source != p1 and not source.is_heavy then
			self.score_multiplier = source.score_multiplier + 1
		end

		if not self.was_counted_for_combo then
			self.was_counted_for_combo = true
			sfx(frnda(2,33))
			m_part_circle(self.x, self.y, 20, 6, 10, 8, 2)

			for i=-6, 6, 2 do
				for j=-6, 6, 2 do
					if randc(75) then
						local size = frnda(2)

						m_part_blood({size, self.x+i, self.y+j, 	atan2(self.x - (self.x+i), self.y - (self.y+j)), rnd(2)})
					end
				end
			end
			split_entity(self, rnd(1))
			cam:shake(3, 10)
			game_pause(2)

			if not no_score then
				score_add(self, self.score * self.score_multiplier)
			end
		end

		for a in all(list_people) do
			if a != self and a != source then
				if not a.was_counted_for_combo and not a.just_spawned and not a.is_armored then
					if is_near_objs(self, a, 20) then
						if source != nil and not source.is_heavy then
							source.score_multiplier += 1
						end
						if not a.is_furniture then
							if a.is_bomber then
								a:kill(self, no_score)
							elseif not a.is_heavy then
								a:kill(self, true)
							end
						end
						-- only for people that didn't explode
						if not a.was_counted_for_combo and not a.is_heavy then
							self.score_multiplier += 1
							a.was_counted_for_combo = true
							if not no_score then
								score_add(a, a.score * self.score_multiplier)
							end
						end

					end
				end
			end
		end
		if is_near_objs(self, p1, 20) then
			p1:damage(self)
		end

		del_from_people(self)

	end

	e.handle_impact_class=function(self, source)
		self:explode(source)
		return true
	end

	e.kill_class=function(self, source, no_score)
		self:explode(source, no_score)
		return true
	end

	e.draw_class=function(self)
		local x_off = -5
		if self.flipx then
			x_off = -3
		end
		set_outline()
		spr(20, self.x+x_off, self.y-12+get_yboboffset(self), 1, 1, self.flipx)
		pal()
	end

	return e
end

function m_enemy_boss(setx, sety)
	local e = m_enemy_seeker(setx, sety)
	e.is_armored, e.head_shift, e.pcolor, e.scolor, e.speed_move_orig = true, 5, 13, 6, .5
	e:init()
end

function m_enemy_seeker(setx, sety)

	local e = m_enemy(setx, sety)

	e.head_shift = 2
	e.move=function(self)
		a_deviate(self, 10)

		if is_level_active() then
			self.angle_desired = get_dir_to_player(self)
		end
	end

	e.alert_class=function(self)
		return a_alert_checkforwindup(self)
	end

	return e
end

function m_enemy_furniture(setx, sety, sprite, is_heavy)
	local e = m_enemy(setx, sety)

	e.update_class=function(self)
		if self.is_flying then
			check_for_footsteps(self)
			a_fly(self)
		  end
		return false
	end

	e.kill_class=function(self)
	  del_from_people(self)
		return true
	end

	e.touch_class=function(self)
		return true
	end

	e.sprite, e.is_furniture, e.is_heavy = sprite, true, is_heavy or false

	del(list_enemies, e)
	return e
end

function m_enemy(setx, sety, is_villager)
	local e=
	{
		x=setx,
		y=sety,
		pcolor=10,
		scolor=7,
		is_villager = is_villager or false,

		angle=0,
		angle_desired=0,
		alert_distance=15,
		speed_turn=.01,
		speed_move_orig=.25+rnd(.1),
		speed_move=0,

		windup_time=25,
		windup_time_rem=0,
		deviation_time=0,

		col_w=6,
		col_h=6,
		col_off=0,

		curanim="move",
		curframe=1,
		animtick=0,
		flipx=true,

		head_shift=0,
		body_shift=0,

		emotion=nil,
		emotion_count=0,
		emotion_timer=0,

		fly_speed=0,
		is_flying=false,

		attack_time=7,
		attack_time_rem=0,
		recovery_time=20,
		recovery_time_rem=0,
		time_between_attacks=0,
		time_between_attacks_rem=0,

		just_spawned=true,

    invuln_frames=0,
		wander_time=0,
		wander_dir=frnd(7),

    score=1,
    score_multiplier=1,
		was_counted_for_combo=false,

		init=function(self)
			if is_level_active() then
				self.invuln_frames, self.speed_move, self.angle = 30, self.speed_move_orig, (atan2(self.x - p1.x, self.y - p1.y)+.5)%1
				constrain_to_screen(self)
			end
		end,

		move=function(self)
		end,

		attack_target=function(self)
			if self.attack_is_shot then
				self:fire_arrow()
				attack_reset(self)
				return
			end

			self.attack_time_rem, self.angle = self.attack_time, self.desired_angle
			a_anim_set(self, "attack")
			sfx(frnda(3,18))
		end,

		handle_impact_class=function(self)
			return false
		end,

		handle_impact=function(self, source)
			if not self:handle_impact_class(source) then
				self.is_flying, self.is_flying_impactable, self.windup_time_rem, self.attack_time_rem = true, true, 0, 0
				a_anim_set(self, "fly")
				self:emotion_add()
				m_part_impact(self)
			end
		end,

		kill_class=function(self)
			return false
		end,

		kill=function(self, source, no_score, angle, override)
			if not override then
				if self:kill_class(source, no_score) then
					return
				end
			end

			local source_angle = angle or atan2(source.x - self.x, source.y - self.y)

			m_part_bloodsplash(self.x, self.y, source_angle)

			split_entity(self, source_angle)

			if not no_score then
				score_add(self, self.score)
			end
			del_from_people(self)
		end,

		alert_class=function(self)
			return false
		end,

		touch_class=function(self)
			return false
		end,

		update_class=function(self)
			return true
		end,

		update=function(self)
			if self.invuln_frames > 0 then
				self.invuln_frames -= 1
			else
				self.just_spawned = false
			end
			if self.just_spawned then
				return
			end

			if not self:update_class() then
				self.just_spawned = false
				return
			end

			check_for_footsteps(self)
			if self.is_flying then
				a_fly(self)
			elseif self.attack_time_rem > 0 then
				a_attack(self)

			elseif self.windup_time_rem > 0 then
				self.windup_time_rem -= 1
				if self.windup_time_rem <= 0 then
					self:attack_target()
				end
			elseif self.recovery_time_rem > 0 then
				self.recovery_time_rem -= 1
			elseif self.time_between_attacks_rem == 0 and self:alert_class() then
			else
				if self.time_between_attacks_rem  > 0 then
					self.time_between_attacks_rem -= 1
				end
				if self.deviation_time > 0 then
					self.deviation_time -= 1
				else
					self:move()

					if abs(self.angle - self.angle_desired) < .05 then
						self.angle_desired=self.angle
					end

					if self.angle != self.angle_desired then
						self.angle = (self.angle + self.speed_turn*get_direction_to_turn(self.angle_desired, self.angle))
					end
				end
					a_move_angle(self)
					local anim = "move"
					if self.is_villager and self.emotion_count > 0 then
						anim = "run"
					end
					a_anim_set(self, anim)
				if constrain_to_screen(self) then
					self.angle = (self.angle+.25)%1
				end
			end
			self:emotion_update()

			a_anim_update(self, character_anims, self.emotion_count+1)
		end,

		draw_class=function(self)
		end,

		draw=function(self)
			if not self.is_furniture then
				draw_character(self)
				self:draw_class()
				if self.emotion and not self.is_flying then
					self.emotion:draw()
				end
			else
				set_outline()
				spr(self.sprite, self.x-4, self.y-4)
				pal()
			end
		end,

		emotion_update=function(self)
			if self.emotion then
				self.emotion:update()
			end
			if self.emotion_timer > 0 then
				self.emotion_timer -= 1
				if self.emotion_timer == 0 then
					self.emotion_count -= 1
					self:emotion_set_from_count()
					if self.emotion_count > 0 then
						self.emotion_timer = 360
					end
				end
			end
		end,

		emotion_set_from_count=function(self)
			if self.emotion_count == 3 then
				m_emotion(self, "angry")
			elseif self.emotion_count >= 1 then
				m_emotion(self, "upset")
			else
				self.emotion = nil
			end
			self.speed_move = self.speed_move_orig + .2*self.emotion_count

		end,

		emotion_add=function(self)
			self.emotion_count, self.emotion_timer = min(3, self.emotion_count+1), 360
			self:emotion_set_from_count()
		end,
	}

	e:init()

	add_to_people(e)
	return e
end

function get_gen_coords()
	local gen_x, gen_y, whichside = frnd(128), frnd(128), frnd(4)
	if whichside == 0 then
		gen_x = 4
	elseif whichside == 1 then
		gen_x = 124
	elseif whichside == 2 then
		gen_y = 4
	else
		gen_y = 124
	end
	return gen_x, gen_y
end

function m_enemy_random()

	local enemy_type = g_enemy_weights[frnda(#g_enemy_weights)]

	if enemy_type == 5 then
		if not g_spawned_boss then
			m_enemy_boss(get_gen_coords())
			g_spawned_boss = true
		else
			return
		end
	elseif enemy_type == 1 then
		m_enemy_wander(get_gen_coords())
	elseif enemy_type == 2 then
		m_enemy_seeker(get_gen_coords())
	elseif enemy_type == 3 then
		m_enemy_archer(get_gen_coords())
	else
		m_enemy_bomber(get_gen_coords())
	end
		g_level_enemies_count -= 1
end

function set_cam_pos(pos)
	if pos+8<64 then
		pos+=min(64-(pos+8),4)
	end
	if pos-8>64 then
		pos+=min(64-(pos-8),4)
	end
	return pos
end

function m_cam()
	camera()
	local c=
	{
		pos_x = 64,
		pos_y = 64,

		shake_remaining=0,
		shake_force=0,

		update=function(self)
			self.shake_remaining, self.pos_y, self.pos_x = max(0,self.shake_remaining-1), mid(64, set_cam_pos(self.pos_y), 960), mid(64, set_cam_pos(self.pos_x), 960)
			camera(self:cam_pos())
		end,

		cam_pos=function(self)
			local shk_x, shk_y, force = 0, 0, self.shake_force

			if self.shake_remaining>0 then
				shk_x, shk_y = rnd(force)-force/2, rnd(force)-force/2
			end
			return self.pos_x-64+shk_x,shk_y
		end,

		shake=function(self, force, duration)
			self.shake_force, self.shake_remaining = force, duration
		end
	}

	return c
end

function save_score()
	if g_score_total >= g_high_scores[g_difficulty][1] then
		g_high_scores[g_difficulty][1], g_high_scores[g_difficulty][2] = g_score_total, g_year
	end
	local index = 1
	for i=1, 8 do
		for j=1,2 do
			dset(index, g_high_scores[i][j])
			index += 1
		end
	end
end

function level_end()
	p1.ready_time, g_game_state, g_transition_time = 300, 6, 150
	g_score_total += g_score_level
end

function level_end_win()
	if p1.hp_cur > 1 then
		score_add(p1, 25)
	end
	g_game_transition_to_state = 7
	sfx(13)
  level_end()
end

function level_end_bad()
	g_game_transition_to_state = 8
	sfx(12)
	level_end()
	save_score()
end

function level_end_villager_died(killed_by_player)
	if g_difficulty < 7 then
		return
	end
	g_level_end_reason = "let a villager die"
	if killed_by_player then
		g_level_end_reason = "killed a villager"
	end
	level_end_bad()
end

function level_end_player_died(killed_by_obstacle)
  g_level_end_reason = "slain in combat"
	if killed_by_obstacle then
		g_level_end_reason = "stumbled into death"
	end
	level_end_bad()
end

function m_splat(x, y, size_base, size_var)
	local s =
	{
		x=x,
		y=y,
		size=frnda(size_var, size_base),

		draw=function(self, color)
			if color == 0 then
				circfill(self.x, self.y, self.size+1, color)
			else
				circfill(self.x, self.y, self.size, color)
			end
		end,
	}
	return s
end

function m_transition_splatter()
	local t =
	{
		list_splats={},

		init=function(self)
			local wipe_position = 0
			while wipe_position < 128 do

				wipe_position += 10

				add(self.list_splats, m_splat(wipe_position+2-rnd(4), 48-frnd(6), 10, 8))
				add(self.list_splats, m_splat(wipe_position+2-rnd(4), frnda(6, 80), 10, 8))

				if randc() then
					add(self.list_splats, m_splat(wipe_position+4-rnd(8), 30-frnd(15), 2, 5))
				end

				if randc() then
					add(self.list_splats, m_splat(wipe_position+4-rnd(8), frnda(15,98), 2, 5))
				end
			end
		end,

		draw=function(self)
			rectfill(0, 41, 128, 87, 0)

			for s in all(self.list_splats) do
				s:draw(0)
			end
			rectfill(0, 42, 128, 86, 8)

			for s in all(self.list_splats) do
				s:draw(8)
			end

		end,
	}
	t:init()
	return t
end

function is_level_active()
	if g_game_state == 5 or g_game_state == 6 then
		return true
	end

	return false
end

function update_weather()
	---[[
	if g_weather_part_rate == 0 then
		return
	end
	if g_ticks % g_weather_part_rate == 0 then

		local part_sprite, part_color, double_rate = g_weather_sprite, g_weather_color, 0

		if g_season == 0 then
			double_rate = 1
		elseif g_season == 3 then
			part_sprite += frnd(2)
			if not g_level_night then
				part_color += frnd(2)
			end
		end

		for i=0,double_rate do
			local p = m_part_sprite(part_sprite, frnd(256)-128, -8, g_weather_fall_rate, part_color, part_color, 300, false, true)
			if g_season == 0 then
				p.dx,	p.splash_loc = .3+rnd(.1), frnda(128, 16)
				p.update=function(self)
					if self.y >= self.splash_loc then
						for i=0,1 do
							local s = m_part_sprite(103, self.x, self.y, -rnd(1), 12, 12, 5, false, true)
							s.ddy, s.dx = .1, rnd(.5)
							if randc(50) then
								s.dx = -rnd(.5)
							end
						end
						del(list_parts_front, self)
					end
					self:update_base()
				end
			else
				p.update=function(self)
					if self.y > 128 then
						del(list_parts_front, self)
						return
					end
					if randc(25) then
						local wshift = g_weather_wind_shift
						if randc(50) then
							wshift = -g_weather_wind_shift
						end
						self.dx += wshift
					end
					self.dx = mid(-1, self.dx, 1)
					self:update_base()
				end
			end
		end
	end
	--]]
end

function _update60()
	g_ticks += 1
	--[[
	if stat(9) < stat(8) then
	--	printh("dropped frame "..g_ticks)
	end
--]]
	cam:update()
	local fu = function(i) i:update() end

	if g_game_state == 6 then
		g_transition_time -= 1
		if g_transition_time <= 0 then
			cam:shake(3, 20)
			g_game_state = g_game_transition_to_state
			sfx(9)
		end
		if g_ticks % 2 == 0 then
			return
		end
	end

	if g_game_state == 4 then
		g_transition_time -= 1
		if g_transition_time <= 0 then
			g_game_state = 5
		end
	end

	foreach(list_parts_blood, fu)
	foreach(list_parts_back, fu)
	foreach(list_parts_front, fu)

	if g_game_state > 3 and g_game_state < 9 then
		if game_pause_timer > 0 then
			game_pause_timer -= 1
			return
		end

		update_weather()
		if g_player_damaged_time > 0 then
			g_player_damaged_time -= 1
		end
		if g_game_state > 4 then
			if g_ticks % 25 == 0 and (#list_enemies + #list_villagers) < g_level_people_screen_max then
				if randc(85) and g_level_enemies_count > 0 then
				 	m_enemy_random()
				else
					if g_level_villagers_count > 0 then
						g_level_villagers_count -= 1
						m_enemy_villager(get_gen_coords())
					elseif g_level_enemies_count > 0 then
						m_enemy_random()
					end
				end
			end
		end

		p1:update()

		foreach(list_heads, fu)
		for e in all(list_people) do
	    e:update()
			-- only allow damage and impacts if we're in the game proper (not in transition)
			if g_game_state == 5 then
				if int_cols(p1, e, 2) then
					if p1.is_slashing and not p1.slash_has_impacted then
						if e.is_villager or (not e.is_furniture and #list_enemies == 1 and g_level_enemies_count == 0) then
							m_part_impact(e)
							e:kill(p1, false, p1.slash_angle, not e.is_villager)
						else
							if e.attack_time_rem > 0 then
								if not attempt_deflect_target(e) then
									slash_target(e)
								end
							else
								slash_target(e)
							end
						end
						break
					end
					if not p1.is_slashing and not e.is_flying and int_cols(p1, e) then
						if not e:touch_class() then -- if an enemy a class doesn't handle touch uniquely, do damage when touching
							if e.attack_time_rem > 0 or g_difficulty > 2 then
								p1:damage(e)
							end
						end
			    end
				end

				if e.attack_time_rem > 0 then
					for v in all(list_villagers) do
						if not v.is_flying and int_cols(e, v) then
							v:kill(e, false, e.angle)
						end
					end
				end
				if e.is_flying then
					foreach(list_objects, function(o)
						if o.is_deadly and o.is_static and not e.is_heavy and not e.is_armored and int_cols(e, o, 2) then
							handle_impact_death(e, o)
							sfx(25)
							if not e.is_furniture then
								o:dealt_damage()
							end
						end
					end)
				end
			end
	  end

		if g_game_state == 5 then
			if is_timed_mode() then
				g_rushmode_ticks -= 1
				if g_rushmode_ticks % 60 == 0 and g_rushmode_ticks < 420 then
					sfx(16)
				end
				if g_rushmode_ticks < 60 then
					p1:damage(p1, true)
					g_level_end_reason = "ran out of time"
					level_end_bad()
					return
				end
			end
			foreach(list_objects, function(o)
				o:update()
				if int_cols(o, p1) then
					if o.is_deadly then
						p1:damage(o)
						o:dealt_damage()
					else
						o:eat()
					end
				end
			end)
		end
	end
	--[[
	if g_game_state == 5 then
		if btnp(5) then
			transition_level()
		end
	end
	--]]
	if g_game_state > 6 then
		if g_ticks % 5 == 0 then
			local p = m_part_sprite(86, frnda(118,10), 46+frnd(36), 0, 7, 13, frnda(5,10), false, false)
			p.dx = -1
		end
		if btnp(4) then
			if g_game_state == 7 then
				transition_level()
			else
				reset_game()
			end
		end
	elseif g_game_state == 0 then
		if btnp(4) then
			sfx(0)
			sfx(11)
			g_game_state = 4
--[[
			for i=1,23 do
				transition_level()
			end
			--]]
			reset_level()
		end
		if btnp(0) then
			g_difficulty -= 1
		elseif btnp(1) then
			g_difficulty += 1
		end
		g_difficulty = wrap(g_difficulty, 1, 8)
	end
	if btnp(5) then
		if g_game_state < 4 then
			sfx(0)
			reset_level()
			if g_game_state == 1 then
				m_food(68,68)
				m_enemy_villager(60, 68)
			elseif g_game_state == 0 then
				p1 = m_player(64,39)
				m_enemy_wander(33, 83)
				m_enemy_seeker(43, 83)
				m_enemy_archer(53, 83)
				m_enemy_bomber(63, 83)
				m_enemy_boss(73, 83)
				m_object(83, 83, {160,161}, true)
				m_object(93, 83, {176,177}, true)

				m_enemy_villager(64, 109)
			end
			g_game_state = wrap(g_game_state+1, 0, 3)
		end
	end
end

function level_create()
	p1 = m_player(64,64)
	reload(0x2000, 0x2000, 0x1000) -- reload original map data

	local color_choice, block_sel_x, block_sel_y = g_season, frnd(2), 0

	if g_year ~= g_year_endgame then
		if g_year ~= 1 then
			if randc(25) then
				g_level_indoor, block_sel_y =
				true, 1
			end

			if randc(25) then
				g_level_night = true
			end

			if not g_level_indoor then
				if randc(25) then
					g_weather_sprite,
					g_weather_color,
					g_weather_part_rate,
					g_weather_wind_shift,
					g_weather_fall_rate =
					g_weather_seasondata[g_season*5+1],
					g_weather_seasondata[g_season*5+2],
					g_weather_seasondata[g_season*5+3],
					g_weather_seasondata[g_season*5+4],
					g_weather_seasondata[g_season*5+5]

					if g_level_night and g_season ~= 0 then
						g_weather_color = 1
					end
				end
			end
		end
	else
		block_sel_x = 2
	end

	if block_sel_y == 0 then
		g_level_people_screen_max, g_level_screen_buffer = 7+1*g_year, 0
	end

	if g_level_indoor then
		color_choice = 6
	end
	if g_level_night then
		color_choice = 4
		if g_level_indoor then
			color_choice = 5
		end
	end

	local colors_string = "03,11,05,00,07,02,11,09,10,05,00,07,04,04,04,09,05,00,07,02,10,07,06,05,00,05,06,00,00,01,05,00,07,02,12,00,01,04,00,07,02,07,00,02,09,00,07,01,07"
		--                                       |                    |                    |                    |                    |                    |                    |
		--									spring							 summer								fall								 winter								night								 indoor dark					indoor light
	--										color_ground, color_detail, color_wall, color_outline, color_interface, color_blood_burn, color_title_text

	local cl, offset = split(colors_string), color_choice*7

	g_color_ground, g_color_detail, g_color_wall, g_color_outline, g_color_interface, g_color_blood_burn, g_color_title_text =
	cl[1+offset], cl[2+offset], cl[3+offset], cl[4+offset], cl[5+offset], cl[6+offset], cl[7+offset]

	local replace_weights, has_placed_food = split("65,81,97,160,176,999"), false
	for y=0, 15 do
		for x=0, 15 do
			local tile, swapped_tile = mget(x+block_sel_x*16, y+block_sel_y*16), false
			if tile == 160 then
				if randc() or g_year == g_year_endgame then
					local coord_x, coord_y, chosen = x*8+4, y*8+4, replace_weights[frnda(#replace_weights)]
					-- start with basic spike, then possible add to get the other type
					if chosen > 998 or g_year == g_year_endgame then
						if has_placed_food then
							del(replace_weights, 999)
						end
						has_placed_food = true
						m_food(coord_x, coord_y)
					elseif chosen > 97 then
						m_object(coord_x, coord_y, {chosen, chosen+1}, true)
					else
						if g_level_indoor then
							chosen -= 1
						end
						m_enemy_furniture(coord_x, coord_y, chosen, chosen > 81)
					end
				end
				swapped_tile = true
			end
			if swapped_tile then
				if g_level_indoor then
					mset(x, y, 144)
				else
					mset(x, y, 0)
				end
			else
				mset(x, y, tile)
			end
		end
	end
end

function transition_level()

	g_season += 1
	if g_season > 3 then
		g_season = 0
		g_year += 1

		if g_year == 7 then
			add(g_enemy_weights, 5)
		end

		for i=1, 4 do
			if g_year+1 >= i then
				add(g_enemy_weights, i)
			end
		end
	end

	reset_level()
	if g_year == g_year_endgame then
		g_game_state = 9
		sfx(15)
		p1.y = 108
		m_enemy_villager(36, 24)
		m_enemy_villager(92, 24)
		m_enemy_villager(52, 108)
		m_enemy_villager(76, 108)
		g_score_total += 1000
		g_level_end_reason = "returned home"
		save_score()
	else
		sfx(11)
		g_game_state = 4
	end
end

function reset_level()
	cam=m_cam()
	table_clear(list_parts_back)
	table_clear(list_parts_front)
	table_clear(list_parts_blood)
	table_clear(list_heads)
	table_clear(list_enemies)
	table_clear(list_villagers)
	table_clear(list_people)
	table_clear(list_drawstuff)
	table_clear(list_objects)
	table_clear(list_steps)

	g_spawned_boss, g_rushmode_ticks,
	g_ticks, g_transition_to_state, g_transition_time,
	g_player_damaged_time, g_level_screen_buffer,
	g_level_villagers_count, g_level_enemies_count, g_level_people_screen_max,
	g_score_level,
	game_pause_timer,
	g_level_indoor, g_level_night,
	g_weather_sprite, g_weather_color, g_weather_part_rate, g_weather_wind_shift, g_weather_fall_rate =
	false, 1200+60*g_year,
	0, 0, 150,
	0, 16,
	3+flr(.5*g_year), 7+3*g_year, 4+1*g_year,
	0,
	0,
	false, false,
	0, 0, 0, 0, 0

	if g_game_state > 3 then
		level_create()
	end

	cls(g_color_ground)
	pal(1, g_color_detail)
	pal(2, 0)
	pal(5, g_color_wall)
	map(0,0,0,0,16,16)
	pal()
	copy_screen_to_mem()

	transition_splatter = m_transition_splatter()
end

function reset_game()
  -- initialized variables, but change during game
	g_game_state, g_level_end_reason,
	g_year, g_season,
	g_score_total,
	g_level_screen_buffer, g_ticks,
	g_enemy_weights =
	0, "defeated the vandals",
	1, 0,
	0,
	16, 0,
	split("1,1,1,2,2,2,2")

	reset_level()

  cam:shake(3, 20)
	sfx(9)
end


function _init()
	cartdata("tmirobot_bunbunsamurai_4")
	g_alphabet_sprites,
	g_season_names,
	g_weather_seasondata,
	g_difficulty_strings,
	g_difficulty_descs,
	g_year_endgame,
	g_difficulty =
	split("a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,0,1,2,3,4,5,6,7,8,9", ",", false),
	split("spring,summer,fall,winter,140,142,172,174"),
	split("119,12,1,0,3,121,14,6,.05,.5,123,9,6,.05,.5,121,6,1,.1,1"),
	split("easy,easy,norm,norm,hard,hard,hell,hell"),
	split("enemy strikes deal damage,s,enemy touches deal damage,s,hero dies from a single hit,s,villager death ends the game,s"),
	10,
	3

	local index = 1
	g_high_scores = {}
	for i=1,8 do
		g_high_scores[i] = {}
		for j=1,2 do
			g_high_scores[i][j] = dget(index)
			index += 1
		end
	end
	reset_game()
end

-- arrange all items in a list by their y value, (used for drawing them in layered order on the screen)
function sort_by_y(t) --insertion sort, ascending y
  for n=2,#t do
    local i=n
    while i>1 and t[i].y<t[i-1].y do
      t[i],t[i-1]=t[i-1],t[i]
      i-=1
    end
  end
end

function is_timed_mode()
	return g_difficulty % 2 == 0
end

function _draw()

	if g_game_state > 3 and g_game_state < 10 then
		paste_screen_from_mem ()

		for a in all(list_parts_blood) do
			if a.time == a.duration then
				a:draw()
			end
		end

		-- draw snow steps
		for a in all (list_steps) do
			pal(7, g_color_detail)
			spr(87+frnd(2), a.x, a.y)
			pal()
			del(list_steps, a)
		end

		copy_screen_to_mem()

		if g_player_damaged_time > 0 then
			cls(8)
		end
		if g_game_state == 9 then
			rectfill(0,40,128,88,12)
		end

		local fd = function(i) i:draw() end

		-- sort the list of obstacles and actors by their y coordinate so we can then draw them in "screen order" for correct overlapping
		sort_by_y(list_drawstuff)
		foreach(list_parts_blood, fd)
		foreach(list_parts_back, fd)
		foreach(list_drawstuff, fd)
		foreach(list_parts_front, fd)

		if g_game_state == 4 then
			local season_sprite = g_season_names[5+g_season]
			if g_level_night then
				season_sprite = 101
			end
			spr(season_sprite, 56, 26, 2, 2)
			spr(season_sprite, 56, 84, 2, 2)
			printsprite(g_season_names[g_season+1], 48, g_color_title_text)
			printsprite("year "..g_year, 70, g_color_title_text)
		end
		if is_level_active() and is_timed_mode() then
			printc_o(""..flr(g_rushmode_ticks/60), 3, 7, g_color_outline)
		end

	else
		cls(0)
	end

	rect(0,0,127,127,1)

	if g_game_state > 0 and g_game_state < 4 then
		if g_game_state == 1 then
			print("the \fchero\fd, weary of fighting in\n     endless wars, wanders\n the countryside, seeking the\n village he once called home.\n\n\n\n  on his journey, he finds a\n   nation overrun by filthy\n    \fcbandits\fd, vulgar \fcronin\fd,\n    and dangerous \fchazards\fd.\n\n\n\nwherever he roams, he protects\n    the \fcweak\fd and \fchelpless\fd.",4,6,13)
		elseif g_game_state == 2 then
			print("  press \fc\142 \fdto strike enemies,\n   killing them if they are\n knocked into another \fcobject\fd.\n\n build \fccombo chains\fd of impacts\n       for more \fcprestige\fd.\n\n  save \fcvillagers\fd or eat \fcfood\fd\n       to gain \fcprestige\fd.\n\n\n\n    food also heals \fcwounds\fd.\n\n    finish a season at full\n    health in order to earn\n        \fcbonus prestige\fd.",4,6,13)
		elseif g_game_state == 3 then
			printc("difficulty levels", 6, 7)
			---[[
			for i=1,8,2 do
				local i24, scorestring = i*12, ""
				printc(g_difficulty_strings[i], 6+i24, 9)
				printc(g_difficulty_descs[i], 14+i24, 12)

				for j=0,1 do
					local endyear, yearstr = g_high_scores[i+j][2], "home"
					if endyear ~= g_year_endgame then
						yearstr = "year "..endyear
					end
					scorestring = scorestring..""..(g_high_scores[i+j][1]*10).." "..yearstr
					if j == 0 then
						scorestring = scorestring.." - "
					end
				end
				printc(scorestring, 22+i24, 13)
			end
			--]]
		end
		printc("\151 next", 117, 7, 62)
		for i in all(list_drawstuff) do
			i:draw()
		end
		return
	end

	if g_game_state > 6 then
		if g_game_state < 9 then
			transition_splatter:draw()
		end
		printc_o("year "..g_year.." | "..g_season_names[g_season+1].." | "..g_difficulty_strings[g_difficulty], 54, 9)
		printc_o(g_level_end_reason, 46, 10)
	 	printc_o("prestige: "..(g_score_total*10).."", 62, 9)
		if g_score_total >= g_high_scores[g_difficulty][1] then
			printc_o("(new record)", 70, 10)
		end
		printc_o("press \142 to continue", 78, 7, 2, 62)
	elseif g_game_state == 0 then
		transition_splatter:draw()
		printsprite("bun bun", 44, 7)
		printc("s a m u r a i", 54, 10)
		printc("v1.3a", 61, 2)
		line(10, 70, 118, 70, 2)
		printc_o("\142 play | \139 "..g_difficulty_strings[g_difficulty].." \145 | \151 info", 76, 7, 2, 56)
		if is_timed_mode() then
			printc_o("(rush mode)", 84, 7)
		end
	end
end
__gfx__
00000000000000000000000000000000000000000000000000200200000000000000000000000000000000000000000026677772266777722667777226677772
00000000002020000000000000000000000000000220220002822820000000000000000000000000000000000000000002272720022277200227227202222272
00700700024242000020200000000000022022002dd2dd20028dd820002020000000000000000000000000000000000000020200000022000002002000000020
00077000024242000242420002222200244244202dd2dd2002dddd20026262000000000000000000000000000000000000000000000000000000000000000000
0007700028888820299999202aaaaa20288888202eeeee20021a1ad2026262000000000000000000000000000000000000000000000000000000000000000000
00700700024c4c2002484820025c5c20024a4a2002dadad202ddddd2026666200000000000000000000000000000000000000000000000000000000000000000
00000000027777200299992002aa99200288844202eeedd202dddd20026b6b200000000000000000000000000000000000000000000000000000000000000000
000000002266720022669200226652002288822022eee2200266dd20026666200000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000200000000000000222220000000000000000000000000000000000000000000277772002777720027777200277772
00000000002222200022222000222220002620000220220002666662000000000000000000000000000000000000000000272720000277200027227200022272
00000000026666620266666202666662000272002dd2dd20028dd8d2002020000020200000000000000000000000000000020200000022000002002000000020
0000000002427272024292920222a2a2002555202dd2dd2002dddd20026262000262620000000000000000000000000000000000000000000000000000000000
0000000028888820299999202aaaaa20025555522eeeee20021a1ad2026262000262620000000000000000000000000000000000000000000000000000000000
00000000024c4c2002484820025c5c200255555202dadad202ddddd202666620026b6b2000000000000000000000000000000000000000000000000000000000
00000000027777200299992002aa99200255555202eeedd202dddd20266b6b620266162000000000000000000000000000000000000000000000000000000000
00000000027772200299920002aaa2000025552022eee22002dddd20026616202666166200000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000200200000000000000000000002000000000000000000000000000002777720277666202776672
00000000002020000000000000000000000000000220220002822820000000000000000000027200002222000000000000000000027222722722272000227220
00000000024242000020200000000000000000002dd2dd20028dd820000000000200000000027200026686200000000000000000002000200200020000002000
00000000024242000242420002222200000000002dd2dd2002dddd20000000002822222000027200002668200000000000000000000000000000000000000000
0000000028888820299999202aaaaa20000000002eeeee20021a1ad2000000000277777200027200002688200000000000000000000000000000000000000000
00000000024c4c2002484820025c5c200000000002dadad202ddddd2000000002822222000027200026668200000000000000000000000000000000000000000
00000000027777200299992002aa99200000000002eeedd202dddd20000000000200000000282820002222000000000000000000000000000000000000000000
00000000027772200299922002aaa2200000000022eee22002dddd20000000000000000000020200000000000000000000000000000000000000000000000000
0000000000ddddd00000000000000000000000000000000000200200000000000020200000000000000000000000000002202200002002000020200002777772
0000000000007070000000000000000000000000022022000282282000000000024242000020200000000000022022002dd2dd20028228200262620000272220
00000000077777000020200000000000000000002dd2dd20028dd82000202000024242000242420002222200244244202dd2dd20028dd8200262620000020000
00000000007a7a000242420002222200000000002dd2dd2002dddd200262620028888820299999202aaaaa20288888202eeeee2002dddd200266662000000000
0000000000777700299999202aaaaa20000000002eeeee20021a1ad202626200024c4c2002484820025c5c20024a4a2002dadad2021a1ad2026b6b2000000000
000000000077700002484820025c5c200000000002dadad202ddddd2026b6b20027777200299992002aa99200288844202eeedd202ddddd20266162000000000
00000000077777000299992002aa99200000000002eeedd202dddd20026616200022220000222200002222000022222000222220002222200022220000000000
00000000000007000299966202aaa6620000000022eee22002ddd662266616620000000000000000000000000000000000000000000000000000000000000000
00022000002222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00244200024444200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02444420029444420000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000
02544520294444420000000000000000000000000000000000070000000700000070700000777000007770000000000000000000000000222000000000000000
02455420244444420000000000000000000000000000000000070000000700000777770007007000077777000000000000000000000002555200000000000000
02422420254444520000000000000000000000000000000000070000000000000070700007077000070707000000000000000000000002555200000000000000
02422420255555520000000000000000000000000000000000000000000700000777770007000000077777000000000000000000000002555200000000000000
00200200022222200000000000000000000000000000000000070000000000000070700000777000007070000000000000000000000002555200000000000000
00022000000000000000200000002000000000000000000000000000000000000000000000000000000000000000000000000000000025545520000000000000
002cc200022222200022420000224200000000000000000000000000000000000000000000000000000000000000000000000000000255444552000000000000
02c22c202444444202944920023bb320000000000000000000000000000000000007700000000000000000000000000000000000002554444455200000000000
2cdccdc2255a55522949949223b33b32000000000000000007770070000700000007700000000000000000000000000000000000025544444445520000000000
2ccddcc2244a44422949949223b33b32000000000000000000000000000000000000000000000000000000000000000000000000255444444444552000000000
2dccccd2244444422949949223b33b32000000000000000000000000000000000000000000000000000000000000000000000002554444444444455200000000
02dddd202444444202944920023bb320000000000000000000000000000000000000000000000000000000000000000000000025555555555555555520000000
00222200022222200022220000222200000000000000000000000000000000000000000000000000000000000000000000002255444444444444444552200000
0000000000222200022222200000200000000000000007aaaaa00000000000000000000000770700007707000000000000225555555555555555555555522000
0222222002dddd202fefefe200224200000000000007aaaaaaaaa000000000000000000007887870078878700000000002555555555555555555555555555200
2dddddd2026dddd22ffffff2023b3b2000000000007aaaa9aaaaaa00000000000007000078e8888778e888870000000000222252222222222222222252222000
255a555226ddddd22333333223b3b3b20000000007aaaa999aaaaaa0000000000076700078e8888778e888870000000000000252222222222222222252000000
2ddaddd22dddddd22333333223b3b3b20000000007aaaaa9aa99aaa0000700000007000078888887788888870000000000000252555555555555555252000000
2dddddd225dddd522333333223b3b3b2000000007aaaaaaaa9999aaa000000000000000007888870078888700000000000000252599599959995995252000000
2dddddd22555555202222220023b3b20000000007aaaaaaaa9999aaa000000000000000000788700007887000000000000000252599599959995995252000000
02222220022222200000000000222200000000007aa9aaaaaa99aaaa000000000000000000077000000770000000000000000252599599959995995252000000
00000000002222000000000002222220000000007a999aaaaaaaaaaa000000000000000000000000000000000000000000002252599599959995995252200000
0222222002888820000000002fefefe2000000007aa9aaaaaaaaaaaa000000000000000000000000000000000000000000025555555555555555555555520000
2888d8820268dd82000000002ffffff2000000007aaaaaaaaaaaaaaa000000000007000000070000000000000000700000022222222222222222222222220000
255a585226d8ddd200000000277777720000000007aaaaaaaaaaaaa0000700000071700000777000000000000007700000000000000000000000000000000000
28daddd22dddd8d200000000233333320000000007aaaaaa99aaaaa0000700000007000000070000000700000007000000000000000000000000000000000000
2dddd8d225dddd52000000002333333200000000007aaaaa99aaaa00000000000000000000000000000000000000000000000000000000000000000000000000
2dddddd2255555520000000002222220000000000007aaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000
0222222002222220000000000000000000000000000007aaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000
5555555555050505555555550777777007777770007777700777770007777770077777700777777007700770077777700000000eee0000000000a00aa00a0000
555555555050505550505050077777700777777007777770077007700777777007777770077777700770077007777770000000eeeee000000000aaaaaaaa0000
55555555550505050505050507700770077007700770000007700770077000000770000007700000077007700007700000000eeeeeee00000a0aaaaaaaaaa0a0
55555555505050555050505007777770077777000770000007700770077777000777770007707770077777700007700000088eeeeeee880000aaaaaaaaaaaa00
555555555505050505050505077007700777777007700000077007700770000007700000077000700770077000077000000888eeeee8880000aaaa9999aaaa00
55555555505050555050505007700770077007700770000007700770077000000770000007777770077007700007700000ee88e222e88ee0aaaaa999999aaaaa
5555555555050505050505050770077007777770077777700770077007777770077000000777777007700770077777700eeeee82128eeeee0aaa99999999aaa0
5555555550505055555555550770077007777770007777700777770007777770077000000777777007700770077777700eeeee22122eeeeeaaaa99999999aaaa
0010000000000000000000000777777007700770077000000777777707777770077777700777777007777770077777700eeeee22122eeeeeaaaa99999999aaaa
11111111000000000000000007777770077007700770000007777777077777700777777007777770077777700777777000eeee82128eeee00aaa99999999aaa0
000001000000000000000000000770000777777007700000077070770770077007700770077000700770077007700770000e88e222e88e00aaaaa999999aaaaa
111111110000010000000000000770000777700007700000077070770770077007700770077777700770077007777770000888eeeee8880000aaaa9999aaaa00
00100000001010000010000000077000077777700770000007707077077007700770077007700000077007700777770000088eeeeeee880000aaaaaaaaaaaa00
111111110010101000101000077770000770077007700000077070770770077007777770077000000777777007707770000000eeeee000000a0aaaaaaaaaa0a0
0000010000000000000000000777700007700770077777700770707707700770077777700770000007777707077007700000000eee0000000000aaaaaaaa0000
11111111000000000000000007777000077007700777777007700077077007700777777007700000007777770770077000000000000000000000a00aa00a0000
00000000000000000010000007777770077777700770077007700770077000770770077007700770077777700777777000000000000040000000000c00000000
0000000000000000111dd11107777770077777700770077007700770077070770770077007700770077777700777777000000000000440000000000c00000000
000020000000200000d00d000770000000077000077007700770077007707077007777000770077000000770077007700000000044494000000000ccc0000000
002272200022e2201d5dd5d10777777000077000077007700770077007707077000770000777777000007770077007700000004499994000000c000c000c0000
0272627202e2e2e20dd55dd007777770000770000770077007700770077070770077770000777700000777000770077000000499999940000000cc0c0cc00000
02626262026262621dddddd100000770000770000770077007700770077070770770077000077000007770000770077000004999999940000000ccccccc00000
012121210121212100dddd00077777700007700007777770007777000770707707700770000770000777777007777770000049999999400000c00c0c0c000c00
0000000000000000111111110777777000077000077777700007700007777777077007700007700007777770077777700004999949994000cccccccccccccccc
000222000002220000000000007770000777777007777770077007700777777007700000077777700777777007777770004999949999400000c00c0c0c000c00
00266620002e66200000000007777000077777700777777007700770077777700770000007777770077777700777777000499994999940000000ccccccc00000
0026662000266e200000000007777000000007700000077007700770077000000770000000000770077007700770077000499949999400000000cc0c0cc00000
0276767202e676e2000000000007700007777770007777700777777007777770077777700000077007777770077777700049949999940000000c000c000c0000
0026662000266e20000000000007700007777770007777700777777007777770077777700000077007700770077777700049499999400000000000ccc0000000
0276767202767ee20000000000077000077000000000077000000770000007700770077000000770077007700000077000049999440000000000000c00000000
00266620002666200000000007777770077777700777777000000770077777700777777000000770077777700000077000044444000000000000000c00000000
01211121012111210000000007777770077777700777777000000770077777700777777000000770077777700000077000000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333300000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333300000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333300000000000000000000000000000000
33333333333333000333333333333333333333333333330003333333333333333333333333333300033333333333333300000000000000222000000000000000
33333333333330555033333333333333333333333333305550333333333333333333333333333055503333333333333300000000000002555200000000000000
33333333333330555033333333333333333333333333305550333333333333333333333333333055503333333333333300000000000002555200000000000000
33333333333330555033333333333333333333333333305550333333333333333333333333333055503333333333333300000000000002555200000000000000
33333333333330555033333333333333333333333333305550333333333333333333333333333055503333333333333300000000000002555200000000000000
33333333333305545503333333333333333333333333055455033333333333333333333333330554550333333333333300000000000025545520000000000000
33333333333055444550333333333333333333333330554445503333333333333333333333305544455033333333333300000000000255444552000000000000
33333333330554444455033333333333333333333305544444550333333333333333333333055444445503333333333300000000002554444455200000000000
33333333305544444445503333333333333330000000000000000000003333333333333330554444444550333333333300000000025544444445520000000000
33333333055444444444550333333333333305555555555555555555550333333333333305544444444455033333333300000000255444444444552000000000
33333330554444444444455033333333333330000000000000000000003333333333333055444444444445503333333300000002554444444444455200000000
33333305555555555555555503333333333333055555555555555555033333333333330555555555555555550333333300000025555555555555555520000000
33330055444444444444444550033333333330554444444444444445503333333333305544444444444444455033333300002255444444444444444552200000
33005555555555555555555555500333330000000000000000000000000003333300000000000000000000000000033300225555555555555555555555522000
30555555555555555555555555555033305555555555555555555555555550333055555555555555555555555555503302555555555555555555555555555200
33000050000000000000000050000333330000500000000000000000500003333300005000000000000000005000033300222252222222222222222252222000
33333050000000000000000050333333333330500000000000000000503333333333305000000000000000005033333300000252222222222222222252000000
33333050555555555555555050333333333330505555555555555550503333333333305055555555555555505033333300000252555555555555555252000000
33333050599599959995995050333333333330505995999599959950503333333333305059959995999599505033333300000252599599959995995252000000
33333050599599959995995050333333333330505995999599959950503333333333305059959995999599505033333300000252599599959995995252000000
33333050599599959995995050333333333330505995999599959950503333333333305059959995999599505033333300000252599599959995995252000000
33330050599599959995995050033333333300505995999599959950500333333333005059959995999599505003333300002252599599959995995252200000
33305555555555555555555555503333333055555555555555555555555033333330555555555555555555555550333300025555555555555555555555520000
33300000000000000000000000003333333000000000000000000000000033333330000000000000000000000000333300022222222222222222222222220000
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333300000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333300000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333300000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333300000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333300000000000000000000000000000000
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000088800000000000000000888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000000888880000000000000008888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000000008888888000000000000088888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008
10000000008888888000000000000088888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088
10000000008888888000000000000088888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088
10000000000888880000000000000008888800000000000000000000088800000000000000000000000000000000000000000000000000000000000000000088
10000000000088800000000000000000888000000000000000000008888888000000000000000000000000000000000000000000000000000000000000000088
10000000000000000000000000000000000000000000000000000008888888000000000000000000000000000000000000000000000000000000000000000088
10000000000000000000000000000000000000000000000000000088888888800000000000000000000000000000000000000000000000000000000000000008
10000000000000000000000000000000000000000000000000000088888888800000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000088888888800000000000000000000000000000000000000000000000000000000000000000
10000000000000000000000000000000000000000000000000000008888888000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000008888888000000000000000000008888888000000000000000000000000000088800000000000000000000000000000000001
10000000000000000000000008888888888888000000000000000008888888880000000000000000000000000888880000000000000000000000000000000001
10000000000000000000000888888888888888880000000000000888888888888800000000000000000000000888880088888888800000000000000000000001
10000000000000000000008888888888888888888000000000088888888888888888000000000000000000000888888888888888888000000000000000000001
10000008888888000000888888888888888888888880000008888888888888888888880000000000000000000088888888888888888880000000000000000001
10008888888888888008888888888888888888888888000088888888888888888888888880000888888800000088888888888888888888800000000000000000
10888888888888888888888888888888888888888888000888888888888888888888888888888888888888088888888888888888888888880000000000000888
08888888888888888888888888888888888888888888808888888888888888888888888888888888888888888888888888888888888888888000000000888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888800000088888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888887777778877887788777777888888888877777788778877887777778888888888888888888888888888888888888
88888888888888888888888888888888888887777778877887788777777888888888877777788778877887777778888888888888888888888888888888888888
88888888888888888888888888888888888887788778877887788778877888888888877887788778877887788778888888888888888888888888888888888888
88888888888888888888888888888888888887777788877887788778877888888888877777888778877887788778888888888888888888888888888888888888
88888888888888888888888888888888888887777778877887788778877888888888877777788778877887788778888888888888888888888888888888888888
88888888888888888888888888888888888887788778877887788778877888888888877887788778877887788778888888888888888888888888888888888888
88888888888888888888888888888888888887777778877777788778877888888888877777788777777887788778888888888888888888888888888888888888
88888888888888888888888888888888888887777778877777788778877888888888877777788777777887788778888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
888888888888888888888888888888888888888aa88888aaa88888aaa88888a8a88888aaa88888aaa88888aaa888888888888888888888888888888888888888
88888888888888888888888888888888888888a8888888a8a88888aaa88888a8a88888a8a88888a8a888888a8888888888888888888888888888888888888888
88888888888888888888888888888888888888aaa88888aaa88888a8a88888a8a88888aa888888aaa888888a8888888888888888888888888888888888888888
8888888888888888888888888888888888888888a88888a8a88888a8a88888a8a88888a8a88888a8a888888a8888888888888888888888888888888888888888
88888888888888888888888888888888888888aa888888a8a88888a8a888888aa88888a8a88888a8a88888aaa888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888828282288888822282228888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888828288288888888282828888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888828288288888882282228888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888822288288888888282828888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888882882228828822282828888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888882222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88882222222888822222228222222222888822288888222222288882222822222222222288882222222888882228888822222228888222222222222222228888
88822777772288827772728277727272888827288882277777228882772227727772777288822777772288882728888227777722888277727722777227728888
88827722277288827272728272727272888827288882777227728882727272727272777288827722777288882728888277272772888227227272722272728888
88827727277288827772728277727772888827288882772227728882727272727722727288827722277288882728888277727772888827227272772272728888
88827722277288827222722272722272888827288882777227728882727272727272727288827722777288882728888277272772888227227272722272728888
88822777772288827282777272727772888827288882277777228882727277227272727288822777772288882728888227777722888277727272728277228888
88882222222888822282222222222222888822288888222222288882222222222222222288882222222888882228888822222228888222222222228222288888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888880008888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888880000088888880000000000888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888800000000000000000000000088888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888000000000000000000000000000888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888880000000000000000000000000000000888888888888888888888888888888
08888888888888888888888888888888888888800888888888888888888888888000000000000000000000000000000000000000000888888888888888888888
00888888888888888888888888888888888880000088888888888888888888000000000000000000000000000000000000000000000000088888888888888888
10008888888888888888888880888888888800000000088888880000000000000000000000000008888800000000000000000000000000008888888888888888
10000008888888000000888880000088888880000000000000000000000000000008888800000088888880000000000000000000000000000088888888888888
10000000000000000000888880000088888880000000000000000000000000000088888880000888888888000000000000000888000000000000088888880888
10000000000000000000088800000088888880000000000000000000000000000888888888008888888888800000000000008888800000000000000888000888
10000000000000000000000000000008888800000000000000000000000000008888888888808888888888800000000000008888800000000000088888888888
10000000000000000000000000000000888000000000000000000000000000088888888888888888888888800000000000008888800000000000088888888888
10000000000000000000000000000000000000000000000000000000000000088888888888888888888888800000000000000888000000000000888888888888
10000000000000000000000000000000000000000000000000000000000000088888888888888888888888800000000000000000000000000000888888888888
10000000000000000000000000000000000000000000000000000000000000088888888888880888888888000000000000000000000000000000888888888888
10000000000000000000000000000000000000000000000000000000000000088888888888880088888880000000888000000000000000000000088888880008
10000000000000000000000000000000000000000000000000000000000000008888888888800008888800000008888800000000000000000000088888880000
10000000000000000000000000000000000000000000000000000000000000000888888888000000000000000008888800000000000000000000000888000001
10000000000000000000000000000000000000000000000000000000000000000088888880000000000000000008888800000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000008888800000000000000000000888000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000001d0100380000000000000000000000ffffffffff0000000000000000000000ffffffffff0000000000000000000000ffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
00000000000000000000009100000000000000000000000000000092000000000000000000000000000000000000004c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00a0000000000000000000000000a00000a0000000000000000000000000a000000000000000004d4e000092000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000920000000000000000000000000000009100000000000000000000000000000000005c5d5e5f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000a0009200006c6d6e6f00000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000a0000000000000a000920000000000000000000000000000009100000000000000007c7d7e7f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000910000000000000000000000000000009200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000009200000000000000a0000000000000000000009200000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00a0000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000009200000000000000000000000000000000000000000000000000920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000009200000000000000000000000000000000000000000092000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000a0000000000000a0000000000000000000000000000000000000000000924c4d4e4f000000004c4d4e4f91000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000910000000000000000000000000000009100000000000000000000000000005c5d5e5f000000005c5d5e5f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000910000000000000000000000000000009100000000006c6d6e6f000000006c6d6e6f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00a00000000000a0000000000000a00000a00000000000a0000000000000a00000007c7d7e7f000000007c7d7e7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000920000000000000000000000000000009200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8080808080808080808080808080808080808080808080808080808080808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8080828282828282828282828282808080808282828282828282828282828080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8081a090909090909090909090a0818080819090909090909090909090908180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8081909090909090909090909090818080819090909090909090909090908180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8081909090909090909090909090818080819090909090909090909090908180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8081909090a090909090a0909090818080819090a0909090a0909090a0908180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8081909090909090909090909090818080819090909090909090909090908180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8081909090909090909090909090818080819090909090909090909090908180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8081909090909090909090909090818080819090909090909090909090908180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8081909090909090909090909090818080819090909090909090909090908180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8081909090a090909090a0909090818080819090a0909090a0909090a0908180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8081909090909090909090909090818080819090909090909090909090908180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8081909090909090909090909090818080819090909090909090909090908180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8081a090909090909090909090a0818080819090909090909090909090908180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8080828282828282828282828282808080808282828282828282828282828080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8080808080808080808080808080808080808080808080808080808080808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0101000008550085501d5501d55000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
00000000332502815015250201501a2501a15015250111500a2500215004250031500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000342502b1501f15014250252501825013250121500e2500625007150072500925000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002765027250190502b6502a65024250180502365020450150501d6501a15019150120501765015650131500c0500f6500e2500c0500b6500a1500b0500965007250040500215013450094500265003650
000000002263024630276302b63032630376303b6301013014130181301d13021130251302a1302e1303410038100000000000000000000000000000000000000000000000000000000000000000000000000000
000000002363026630296302d6303163036630386301e1302113025130271302a1303013033130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01000000226302363026630296302d63032630386301a1301f13022130271302d1302f13000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001d550215502455025550215501b55016550125500d55007550085500b550145501f550255501b50000500005000050000500005000050000500005000050000500005000050000500005000050000500
000100003d150340501c0500b0501205017050170503f7002d1002b0702c17033170381703c1703f1703f07027700287002a7002b700007000070000700007000070000700007000070000700007000070000700
000100000d6500e650106500d1501365015150171501b1501e65021150241502a650116501165010150116501a6501165011650166500e1500f150116501a650116500f150151500060000600006000060000600
010200002f6702e670106701c57023550275502b5102e51031550305502f5502c55029550215501a550185501a55022000290002b0002e0003300037000000000200002000020000200002000020000200002000
3f1600000f335123351433516335193351b335123350f3351e3351b3350f265002000f26500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f1600001b335193351633514335123350f3350d3350f335123350f3350f265000050f26500005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e1600001b335193351633514335123350f3350d3350f335163350f3350f265033050f26500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3e1600000f3150f31512315123150f3150f3150d3150d3150f3150f315123151231514315143150e3150e3150f3150f31512315123150f3150f3150d3150d3150f3150f31514315143150d3150d3150231502315
3e1400001f2211f2211f2211f221222212222122221222211f2211f22122221222211b2211b2211b2211b221162211622116221162211b2211b2211b2211b2211b2211b2211b2211b2211b2211b2211b2211b221
000600001b0501b050010000100001000020000100001000020000400005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
680200002f650180502f65021050210501e0501d050170500f0500a05008050060500605003050020500205002000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001b1201c1201f1202012024120241202612028120281200010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000000001312016120191201c1201d120211202212025120271200010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00000000131201512017120191201d1201f1202312026120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000002c6502b65024650206501d6501965018650186500f3501035012350143001630000600346003460033600336003260032600326000060000600006000060000600006000060000600006000060000600
000000002965024650216501d6501a6501d6501b65019650186501760016600146001260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000105700d5700c5700a5700957008570085700a5700d5700f57000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d05111050170501c0501f0502305006500085010b5000e5000e500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000100000705007050090500a05006350053501545017450167501675019750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000002865026650236501f6501b65016650146500735009350093500c3500d3500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000002965026650236501d6501b650186501665010350113501135015350173500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000002765024650216501e6501b65018650166501a3501a3501b3501d3501f3500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000002765024650216501f6501e6501b6501965020350203502235024350273500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000002565022650206501c6501a6501965018650233502435026350283502b3500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000027650246501f6501c6501a65019650176502a3502c3502f35030350333500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000002f650266501e6501b65017650156501b3500c3500a3500a3500a3500a3502d35009350093500040001400014000000000000000000000000000000000000000000000000000000000000000000000000
00030000166501965007250286502865025650062501a6501b6501a650072501b6501c6500b650056500165008600026000160000600006000060000600006000060000600006000060000600006000060000600
000300002d6502d650072501765015650156500c250216501f6501f65007250226501d650136500d6500165008600026000160000600006000060000600006000060000600006000060000600006000060000600
000200002a650170502a6500d6500d6500f6501165013650116500e6500b6500c6500c6500d6500e6500f6500c6500b6500c6500c6500a6500765006650056500465003650026500165001650016500165001650
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
02 0e404040
00 0e000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000

