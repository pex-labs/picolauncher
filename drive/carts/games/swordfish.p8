pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--swordfish v1.0
--by dan lambton-howard
-- 2018

--room data

function load_room_data()
rooms = {
{
ref="-20,-20,",
tiles="14,4,-1,",
spawn="0,300,150,",
ferns="0,104,3,8,8,104,2,9,32,112,2,8,40,112,1,2,49,128,2,8,56,128,3,14,91,128,2,8,104,120,4,2,112,104,4,8,121,104,6,14,128,104,6,8,135,104,5,9,142,104,4,10,149,104,3,15,156,104,2,7,218,104,2,7,225,104,3,15,232,104,4,10,239,104,5,9,246,104,6,8,",
triggers={{
parse"0,0,0,0,1,",
function()
if titles then
player.off=true
player.dir=2
if t==200 then
titles=false
next_room()
elseif t==80 then music(2)
elseif t>=30 then
change_state(player,"swim")
player.vx+=0.3
end
else
if t==10 then
music(0)
player.off=true
player.dir=3
player.vx=4
player.vy=5
end
if t==40 then player.dir=2 player.vx=1 end
if t==60 then player.off=false end
end
end
},{
parse"200,64,30,0,0,",
function()
titles=true
t=0
end
}}
},

{
ref="32,192,",
tiles="18,2,29,16,17,19,20,-1,7,0,2,3,4,28,12,-1,18,29,8,17,17,17,11,-1,",
ferns="32,224,2,9,40,224,3,9,182,312,5,9,190,312,5,8,202,312,4,9,220,312,3,9,155,384,7,9,160,384,8,8,190,384,5,9,240,384,8,9,312,56,2,8,324,56,3,9,336,56,4,8,346,56,2,8,470,224,8,8,480,224,8,9,501,232,9,8,517,232,10,9,531,232,6,9,544,232,8,10,558,224,8,9,575,224,8,10,593,232,9,7,605,232,5,10,620,232,7,7,638,232,6,7,",
spawn="0,842,342,8,172,70,8,216,232,8,396,68,"
},

{
ref="64,32,",
tiles="15,17,-1,12,17,-1,12,17,-1,27,20,-1,17,11,-1,17,15,-1,17,11,-1,",
ferns="24,272,3,7,32,280,3,11,40,456,2,7,80,464,4,7,96,480,4,7,108,480,2,11,120,488,5,7,127,488,3,3,134,488,4,11,144,496,4,3,152,520,6,11,".."144,656,3,3,152,664,3,3,160,696,5,3,224,696,6,3,232,664,4,11,240,656,5,3,",
spawn="0,192,832,8,72,172,8,82,300,8,64,378,8,148,632,8,234,646,"
},

{
tiles="3,4,5,21,-1,",
ferns="110,104,2,3,134,104,2,3,149,104,4,3,230,104,3,3,237,104,3,3,269,104,2,3,374,104,2,3,398,104,2,3,413,112,5,3,422,112,4,3,446,104,2,3,461,104,4,3,",
spawn="0,448,64,1,140,40,1,220,65,1,220,80,1,220,95,1,344,60,1,310,95,"
},

{
tiles="4,7,0,0,3,-1,",
ferns="100,104,2,3,134,96,2,3,149,96,3,3,230,96,2,3,239,104,3,3,516,112,2,3,534,112,3,3,549,112,6,3,622,104,4,3,",
spawn="0,576,64,3,176,64,3,352,6,3,352,120,1,300,64,1,436,32,1,436,96,3,500,50,3,500,78,"
},

{
ref="64,74,true,",
tiles="1,-1,",
ferns="8,112,2,3,32,120,2,3,104,120,3,3,112,112,3,3,",
spawn="0,64,64,3,20,108,3,108,108,3,108,20,3,20,20,"
},


{
ref="192,192,",
tiles="19,4,20,-1,27,21,12,-1,3,4,28,-1,",
ferns="199,232,3,9,206,232,3,9,99,224,2,15,106,224,3,15,32,184,2,9,215,104,3,9,230,104,3,15,237,104,2,9,360,224,3,15,368,208,2,15,70,352,2,9,80,352,4,9,90,352,5,15,100,352,7,9,110,360,10,9,120,360,8,9,130,360,9,15,140,360,7,9,150,360,10,9,160,360,10,9,170,352,8,9,180,352,5,9,190,352,9,9,200,352,7,9,210,360,6,9,220,360,7,9,230,360,8,9,240,360,6,15,250,360,4,9,260,360,7,9,270,360,8,9,280,336,7,9,290,336,8,9,300,336,6,15,310,344,5,9,320,336,8,9,330,336,6,15,",
spawn="0,32,320,4,95,160,4,210,32,4,350,210,3,290,295,3,310,295,8,80,320,8,64,296,8,64,344,",
},

{
ref="64,74,true,",
tiles="1,-1,",
spawn="0,64,64,4,64,20,4,28,100,4,100,100,",
ferns="8,112,5,9,32,120,6,9,104,120,4,9,112,112,3,9,16,120,5,9,51,120,3,9,77,120,3,15,84,120,5,9,",
},

{
ref="64,192,",
tiles="18,0,3,4,20,-1,7,0,16,17,12,-1,17,9,17,24,28,-1,",
ferns="164,266,5,14,196,272,6,12,220,256,5,14,260,248,7,12,120,120,3,12,502,104,4,12,509,104,3,14,604,280,4,14,480,352,6,14,488,352,5,12,502,360,5,12,",
spawn="0,454,314,5,170,64,5,200,128,5,230,196,5,368,80,5,392,20,5,416,80,5,562,178,5,576,60,5,590,228,5,486,320,"
},

{
ref="64,74,true,",
tiles="1,-1,",
ferns="24,120,2,12,34,120,1,14,74,120,4,12,94,120,3,14,104,120,2,14,",
spawn="0,64,64,5,32,96,5,96,32,8,32,32,8,96,96,",
},

{
ref="26,64,",
tiles="3,4,4,5,4,6,21,-1,",
ferns="104,104,3,13,111,104,2,5,125,104,2,13,132,104,4,5,139,104,3,5,152,104,2,13,226,104,3,5,258,104,2,13,354,104,4,5,386,104,2,5,426,104,3,13,433,104,2,5,440,104,3,13,500,104,2,13,520,104,3,13,670,40,3,5,680,40,3,13,690,40,2,13,700,40,1,5,710,40,2,13,720,40,3,13,730,40,2,5,670,112,1,13,680,112,2,13,690,112,2,5,700,112,3,13,710,112,2,13,720,112,2,5,730,112,2,13,",
spawn="0,820,64,6,246,102,6,438,102,1,472,60,6,512,102,5,656,48,5,748,48,6,692,112,6,692,40,"
},

{
ref="128,176,true,",
tiles="19,20,-1,27,28,-1,",
ferns="40,200,4,13,72,208,2,5,96,224,3,13,104,224,2,5,120,232,4,13,128,232,5,5,136,232,3,13,144,232,4,13,156,208,2,13,166,208,3,5,180,216,3,5,192,208,3,5,224,152,5,13,",
spawn="0,128,48,6,56,200,6,184,216,6,128,104,1,120,88,1,136,88,"
},

{
tiles="24,4,21,-1,",
spawn="0,320,64,7,256,56,7,256,72,",
ferns="192,96,2,8,304,112,2,9,320,104,2,8,"
},

{
ref="82,64,",
tiles="24,4,7,0,-1,17,17,18,0,-1,17,17,18,0,-1,17,17,17,15,-1,",
spawn="0,450,500,5,140,30,4,240,64,5,338,64,6,376,246,6,390,382,5,400,60,5,432,120,5,464,260,5,496,160,",
fields="194,42,3,1,80,0,true,234,88,3,1,80,0,true,408,12,1,3,0,135,true,478,66,1,4,0,82,true,448,102,1,5,0,60,true,426,412,3,2,25,20,true,",
triggers={{
{},
function()
local m=create_mine(130,74)
m.state="detonate"
end
}}
},

{
tiles="7,2,0,3,20,17,-1,25,9,9,17,11,17,-1,0,3,20,18,0,16,-1,9,17,13,17,15,17,-1,17,17,27,5,28,17,-1,",
ferns="24,96,2,8,72,96,3,8,79,96,2,2,96,96,2,14,280,128,2,8,288,136,3,2,312,136,4,8,320,144,4,8,328,144,5,14,460,96,2,8,467,96,2,8,544,440,3,8,608,440,4,2,456,584,3,8,463,584,2,8,470,584,3,14,477,584,3,8,484,584,2,2,320,584,3,8,328,592,3,14,286,480,4,8,294,480,3,8,302,480,3,2,310,480,2,8,318,480,3,8,70,400,5,8,80,384,4,14,26,384,4,8,",
spawn="0,64,300,7,240,20,6,300,136,7,425,70,4,335,89,1,564,460,1,580,460,1,596,460,11,344,392,1,297,309,1,208,343,1,116,300,1,24,332,3,348,350,3,172,289,3,60,360,7,530,336,7,660,336,7,400,570,8,468,570,8,308,470,"
},

{
tiles="24,5,5,5,20,-1,19,6,6,6,28,-1,27,5,5,5,21,-1,24,6,6,6,21,-1,",
spawn="0,576,320,3,240,62,2,343,62,2,460,62,1,480,62,6,186,168,6,314,168,6,442,168,4,240,318,2,343,318,2,460,318,1,480,318,6,170,424,6,202,424,6,298,424,6,330,424,6,426,424,6,458,424,",
ferns=""..
"384,232,4,8,392,240,5,14,400,240,4,8,408,240,3,8,416,240,3,14,424,240,3,8,432,240,3,14,440,240,3,8,448,240,3,8,456,240,3,14,464,240,3,14,472,240,3,8,480,240,4,14,488,240,4,14,496,240,5,8,504,232,5,14,256,232,6,2,264,240,4,2,272,240,4,2,280,240,3,8,288,240,3,8,296,240,3,2,304,240,3,8,312,240,3,8,320,240,3,14,328,240,3,2,336,240,3,8,344,240,3,8,352,240,6,14,360,240,4,8,368,240,5,8,376,232,5,14,128,232,3,2,136,240,4,2,144,240,4,8,152,240,3,2,160,240,3,8,168,240,3,8,176,240,3,2,184,240,3,8,192,240,3,8,200,240,3,2,208,240,3,8,216,240,3,2,224,240,4,2,232,240,4,8,240,240,5,8,248,232,6,8,",
},

{
ref="192,32,",
tiles="17,12,17,-1,17,11,17,-1,18,0,16,-1,18,0,16,-1,17,15,17,-1,",
spawn="0,192,620,4,192,128,4,202,292,7,158,388,7,230,388,4,196,464,",
fields="169,120,4,1,18,0,false,140,312,8,2,18,128,false,"
},

{
ref="32,192,",
tiles="17,18,0,0,16,-1,4,7,0,0,16,-1,17,18,0,0,3,-1,17,17,9,9,17,-1,",
fields="264,8,5,6,64,64,false,",
ferns="88,232,3,8,104,232,2,9,112,232,3,8,152,224,3,9,168,224,2,9,176,232,3,8,",
spawn="0,608,320,5,296,32,5,360,64,5,424,250,5,488,128,8,296,104,8,400,168,8,480,232,8,312,296,8,312,360,5,296,160,5,360,192,5,424,122,5,488,256,8,424,104,8,300,168,8,380,232,8,512,296,8,412,360,"
},

{
tiles="15,-1,12,-1,13,-1,12,-1,11,-1,0,-1,2,-1,29,-1,0,-1,",
spawn="0,64,1088,",
fields="50,82,2,4,38,52,true,68,108,1,4,38,52,true,50,402,2,6,38,52,true,68,428,1,6,38,52,true,",
triggers={{
parse"64,840,60,10,0,",
function() create_trap(96,882) end
},{
parse"64,928,60,10,0,",
function() create_trap(20,960) create_trap(108,930)end
}}
},

{
tiles="0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,",
spawn="0,64,875,",
inks="90,110,110,120,26,166,40,190,95,226,128,260,0,316,72,346,50,400,128,430,0,540,74,600,0,600,88,640,60,680,80,700,90,690,120,720,0,820,128,840,0,860,20,896,106,880,128,896,"
},

{
tiles="0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,0,-1,",
spawn="0,64,875,",
inks="0,100,128,132,0,200,128,256,0,320,128,352,48,352,128,452,48,452,80,500,0,500,80,664,80,564,128,600,54,664,128,732,0,732,128,780,40,780,128,854,84,854,128,896,"
},

{
ref="54,140,false,",
tiles="25,25,25,25,25,25,25,-1,0,0,0,0,0,0,0,-1,0,0,0,0,0,0,0,-1,0,0,26,26,26,26,26,-1,10,8,30,31,30,31,30,-1,",
spawn="0,120,616,",
inks="-10,192,800,384,880,176,900,560,500,172,530,404,364,440,412,460,-10,-10,20,512,96,436,140,486,214,480,264,616,-10,500,64,564,280,360,296,440,",
triggers={{
parse"0,0,0,0,1,",
function()
update_boss()
if t%150==0 or t==20 then
boss.wave=40
music(3)
for i=296,872,64 do
create_bubbles(i,436,16,14,2,4)
end
end
end
}}
},

{
ref="64,32,",
tiles="22,-1,22,-1,30,-1,23,-1,31,-1,",
spawn="0,240,128,6,-15,650,6,138,650,6,-15,512,6,138,512,",
triggers={{
{},
function()
change_state(boss,"active")
boss.hp=3
create_bubbles(arg"64,320,20,40,2,3,")
create_ink(arg"-20,320,146,340,13,true,")
boss.wave=40
music(3)
end
},{
parse"0,0,0,0,1,",
function()
update_boss()
end
}}
},

{
ref="192,704,",
tiles="17,15,17,-1,17,12,17,-1,17,12,17,-1,17,11,17,-1,18,2,16,-1,18,0,16,-1,",
spawn="0,192,32,1,190,346,1,202,442,6,78,64,6,78,128,6,78,192,6,306,64,6,306,128,6,306,192,",
fields="176,322,2,8,40,24,false,191,252,4,1,12,0,false,",
triggers={{
{},
function()
create_ink(arg"-10,768,394,768,13,")
end
},{
parse"0,0,0,0,1,",
function()
if t%2==0 then
create_explosion(rnd(328)+120,rnd(256)+512,rnd(8)+8)
create_explosion(rnd(128)+128,rnd(512),rnd(8)+8)
end
if t%flr(rnd(10)+4)==0 then sfx(14) add_shake(4) end
end
}}
},

{
ref="64,1088,",
tiles="0,-1,0,-1,15,-1,12,-1,12,-1,13,-1,12,-1,11,-1,15,-1,",
spawn="0,64,32,6,-12,640,6,140,640,",
fields="30,510,6,1,10,0,false,70,456,5,1,10,0,false,28,80,3,3,40,80,true,48,120,2,3,40,80,true,",
triggers={{
{},
function()
create_ink(arg"-10,1150,138,1152,13,")
create_trap(40,1020)
create_trap(94,1020)
end
},{
parse"0,0,0,0,1,",
function()
if t%4==0 then
create_explosion(rnd(128),rnd(512)+248,rnd(8)+8)
create_explosion(rnd(128),rnd(512)+760,rnd(8)+8)
end
if t%flr(rnd(10)+4)==0 then sfx(14) add_shake(4) end
end
},{
parse"64,388,60,45,0,",
function()
create_trap(28,214)
create_trap(100,214)
end
}}
},

{
ref="276,64,",
tiles="14,4,-1,",
spawn="0,300,150,",
ferns="0,104,3,8,8,104,2,9,32,112,2,8,40,112,1,2,49,128,2,8,56,128,3,14,91,128,2,8,104,120,4,2,112,104,4,8,121,104,6,14,128,104,6,8,135,104,5,9,142,104,4,10,149,104,3,15,156,104,2,7,218,104,2,7,225,104,3,15,232,104,4,10,239,104,5,9,246,104,6,8,",
triggers={{
{},
function()
player.off=true
end
},{
parse"0,0,0,0,1,",
function()
if titles then
player.off=true
player.dir=7
if t==80 then music(2) end
if t>=30 and t<=200 then
change_state(player,"swim")
player.vx-=0.3
player.vy-=0.3
end
else
if t==20 then
create_explosion(arg"250,64,30,")
sfx(14)
add_shake(2)
music(0)
player.dir=6
player.vx=-4
end
if t==60 then player.off=false end
end
end
},{
parse"72,64,30,0,0,",
function()
titles=true
t=0
end
}}
}

}
end

-->8
--game loop

function _init()

load_room_data()

room=1
godmode = false

wtrfrc = 0.94

gt,gm,deathcounter,freeze,fade=0,0,0,0,0

camx,camy,shkx,shky = 0,0,0,0

fades={
0b1111111111111111.1,
0b0111111111011111.1,
0b0101111101011111.1,
0b0101101101011110.1,
0b0101101001011010.1,
0b0001101001001010.1,
0b0000101000001010.1,
0b0000001000001000.1
}

boss = {
x=52,
y=592,
hp=3,
animt=0,
state="dead",
wave=0,
box = new_box(arg"48,576,80,608,")
}

load_room(room)
end

function _update()
t+=1
if t>=30000 then t=0 end
if room>1 and room <#rooms then
gt+=1
if gt==1800 then gt=0 gm+=1 end
end
if freeze >0 then freeze -= 1 return end
if fade>0 then return end

update_shake()
update_player(player)
update_objects(objects)
update_hazards(hazards)
update_particles()
update_exit()

if (player.invinci<=0 and not godmode) or player.state=="attack" then
coll_objs()
check_hazard_colls(hazards)
end
coll_exit()


update_camera()

for enemy in all(objects) do
if enemy.name!="pearl" and enemy.name!="clam" then
detectwalls(enemy)
end
end

update_triggers(triggers)
end


function _draw()

if fade>0 then
if fade<=#fades and fadein==false then
fillp(fades[fade])
rectfill(0,0,cmaxx,cmaxy,1)
fade+=1
fillp()
return
else
fadein=true
end
end

cls()

camera(camx,camy)

draw_background()
draw_foreground()
draw_exit()
draw_particles()
draw_hazards(hazards)
draw_objects(objects)
draw_player(player)
draw_fx(fx)

if boss.state!="dead" then draw_boss() end

if room>1 and room<#rooms then
draw_hud()
else
draw_titles()
end

camera()

if fadein  then
fade-=1
if fade>0 then
fillp(fades[fade])
rectfill(0,0,cmaxx,cmaxy,1)
fillp()
else
fade=0
fadein=false
end
end
end



function update_camera()
local xoff,yoff,pd = 0,0,player.dir
if pd >= 1 and pd <=3 then xoff = 12 end
if pd >= 5 and pd <=7 then xoff = -12 end
if pd <=1 or pd ==7 then yoff = -12 end
if pd >= 3 and pd <=5 then yoff = 12 end
local xpoint = max(0,player.x-64+(player.vx*14)+xoff)
local ypoint = max(0,player.y-64+(player.vy*14)+yoff)
camx += (xpoint-camx)*0.1
camy += (ypoint-camy)*0.1
if camx>cmaxx-127 then camx=cmaxx-127 end
if camy>cmaxy-127 then camy=cmaxy-127 end
camx +=shkx
camy +=shky
end


function draw_background()
rectfill(0,0,cmaxx,cmaxy,1)
end


function draw_foreground()
local mapx,mapy = 0,0
pal(10,0)
for i in all(roomtiles) do
if i == -1 then
mapx=0
mapy+=128
else
map((i%8)*16,flr(i/8)*16,mapx,mapy,16,16,0x1)
mapx+=128
end
end
pal()
end

function update_objects(objects)
for enemy in all(objects) do
enemy.update(enemy)
end
end

function update_hazards(hazards)
for p in all(hazards) do
p.update(p)
end
end

function check_hazard_colls(hazards)
for p in all(hazards) do
p.coll(p)
end
end

function draw_hazards(hazards)
for p in all(hazards) do
p.draw(p)
end
end



function create_trigger(ref,exec)
local t ={
x=ref[1] or 0,
y=ref[2] or 0,
prox=ref[3] or 1,
t=ref[4] or 0,
active=ref[5] or 1,
exec=exec
}
add(triggers,t)
end

function update_triggers(triggers)
for trig in all(triggers) do
local kill=false
if trig.prox>0 then
kill=true
if dist(player.x,player.y,trig.x,trig.y)<=trig.prox then
trig.active=1
end
end

if trig.active==1 then
if trig.t>0 then
trig.t-=1
else
trig.t = 0
trig.exec()
if kill then del(triggers,trig) end
end
end
end
end

function update_shake()
if abs(shkx)+abs(shky)<0.5 then
shkx,shky=0,0
else
shkx*=-0.5-rnd(0.2)
shky*=-0.5-rnd(0.2)
end
end

function draw_objects(objects)
for enemy in all(objects) do
enemy.draw(enemy)
end
end

function draw_hud()
for i=106,122,8 do
circ(camx+i-shkx,camy+6-shky,3.5,0)
end
local cx=106
local col=ternary(t<30 and t%4==0,7,8)
for i=1,player.hp do
circfill(camx+cx-shkx,camy+6-shky,2.5,col)
pset(camx+cx-1-shkx,camy+4-shky,7)
cx+=8
end

boldprint(timer(),camx+2-shkx,camy+121-shky)
end

function draw_titles()
if player.y>=60 and t>=60 and room==1 then
boldprint("⬅️➡️⬆️⬇️: move",32,40)
boldprint("❎/🅾️ (hold): attack",20,50)
end
if titles and t>=80 then
if room==1 then
boldprint("s w o r d f i s h",155,60)
else
local tstars, dstars = 1,1
if gm <15 then
tstars = 2
if gm<10 then
tstars = 3
end
end
if deathcounter <11 then
dstars=2
if deathcounter <6 then
dstars=3
end
end

rect(arg"28,27,96,96,")
boldprint("congratulations",33,32,10)
boldprint("time: "..timer(),43,42)

for i=1,3 do
local sx = 40+(i*10)
if i>tstars then
print("★",sx,52,6)
else
boldprint("★",sx,52,10)
end
end

boldprint("deaths: "..deathcounter,45,62)

for i=1,3 do
local sx = 40+(i*10)
if i>dstars then
print("★",sx,72,6)
else
boldprint("★",sx,72,10)
end
end

boldprint("thanks for",43,82)
boldprint("playing!",48,89)
end
end
end

function draw_fx(fxs)
for fx in all(fx) do
fx.draw(fx)
end
end

function next_room()
room+=1
load_room(room)
end


function load_room(rm)
t=0

objects={}
fx={}
particles={}
triggers={}
hazards={}

local r=rooms[rm]

local roomref={64,64,false}
if r.ref then roomref=parse(r.ref) end

local px = roomref[1]
local py = roomref[2]
player = create_player(px,py)
camx=max(0,px-54)
camy=max(0,py-64)

roomtiles=parse(r.tiles)
roomrows = 0
for i in all(roomtiles) do
if i == -1 then
roomrows+=1
end
end

roomcols = (#roomtiles-roomrows)/roomrows

cmaxx = roomcols*128-1
cmaxy = roomrows*128-1

spawnlist(r.spawn)

if roomref[3] then
exit.state="closed"
exit.combat=true
end

for t in all(r.triggers) do
create_trigger(t[1],t[2])
end

if r.fields!=nil then
local f = parse(r.fields)
for i=1,#f,7 do
create_field(f[i],f[i+1],f[i+2],f[i+3],f[i+4],f[i+5],f[i+6])
end
end

if r.inks!=nil then
local inks = parse(r.inks)
for i=1,#inks,4 do
create_ink(inks[i],inks[i+1],inks[i+2],inks[i+3])
end
end

if r.ferns!=nil then
local fs = parse(r.ferns)
for i=1,#fs,4 do
create_fern(fs[i],fs[i+1],fs[i+2],fs[i+3])
end
end

fade=1

end


-->8
--player--

function create_player(x,y)
local p=new_object(x,y,"player")
p.dir=2
p.hp=3
p.charge=0
p.invinci=0
p.cooldown=0
p.flash=0
p.bigbox=false
p.tpspd = 3

p.spr_info={
idle = {
up = parse"7,38,7,39,",
diagu = parse"32,36,32,34,",
diagd = parse"40,42,40,44,",
right=parse"16,18,16,20,",
dt=0.3
},
swim = {
up = parse"38,39,",
diagu = parse"36,34,",
diagd = parse"42,44,",
right=parse"18,20,",
dt=0.05
},
charge = {
up = {38},
diagu = {32},
diagd = {42},
right={18},
dt=0.2
},
attack = {
up = {15},
diagu = {11},
diagd = {11},
right={13},
dt=0.2
},
hurt = {
hurt = {46},
dt=0.2
},
dead = {
hurt = {46},
dt=0.2
}
}
p.abs_box=function(att)
local b,mx,my,pb = 5,0,0,p.bigbox and att
if att and p.state=="attack" then
b=ternary(pb,14,8)
end

if p.dir== 0 or p.dir==4 then
mx=1
if pb then
my=5
end
elseif p.dir==2 or p.dir==6 then
my=1
if pb then
mx=5
end
elseif pb then
mx,my=5,5
end

return new_box(p.x-b+mx,p.y-b+my,p.x+b-mx,p.y+b-my)
end

return p
end


function update_player(p)
p.animt+=0.01

local state = p.state

if state=="dead" then
p.vy+=0.04
apply_friction(p,wtrfrc)
if abs(p.animt/0.01)%2==0 then p.flash = 0.1 end
if p.animt>=1 then load_room(room) end

else

if p.invinci>0 then
p.invinci -= 1
else p.invinci = 0
end
local bl,br,bu,bd,bx,bz
if not player.off then
if btn"0" then bl=true end
if btn"1" then br=true end
if btn"2" then bu=true end
if btn"3" then bd=true end
if btn"4" then bz=true end
if btn"5" then bx=true end
end
if state=="hurt" then
if p.cooldown > 0 then
bl,br,bu,bd = false, false, false, false
else
p.invinci = 60
change_state(p,"idle")
end
end
if p.cooldown > 0 then
p.cooldown-=0.1
bz,bx = false,false
else
p.cooldown=0
end
if state=="charge"and not(bz or bx) then
if p.charge>=1 then
sfx(4)
create_bubbles(p.x,p.y,rnd(4)+p.charge,4,1,p.charge+1)
if p.charge>=3 then p.bigbox=true end
change_state(p,"attack")
else
change_state(p,'idle')
end
end
state = p.state
if state=="attack" then
if p.charge > 0 then
local d = p.dir
local attackspd=8
if d==0 or d==1 or d==7 then p.vy-=attackspd end
if d>=1 and d<=3 then p.vx+=attackspd end
if d>=3 and d<=5 then p.vy+=attackspd end
if d>=5 then p.vx-=attackspd end
p.charge-=0.15
apply_accel(p,p.tpspd+(flr(p.charge)*1.5))
if abs(p.animt/0.01)%2==0 then	p.flash = 0.1 end
add_shake(0.3)
else
p.charge = 0
p.cooldown = 2
if player.invinci<3 then player.invinci=15 end
p.bigbox = false
change_state(p,'idle')
end
else
if (state=="charge" and t%3==0) or state!="charge" then --only check direction every three frames if charging( to make aiming less fiddly)
setdirection(p,bl,br,bu,bd)
end
if (bl or br or bu or bd) and not(bz or bx) then
local placc=0.5
change_state(p,"swim")
if bl then p.vx-=placc end
if br then p.vx+=placc end
if bu then p.vy-=placc end
if bd then p.vy+=placc end
apply_accel(p,p.tpspd)
else
if (bz or bx) and not (p.cooldown >0) then
change_state(p,"charge")
if p.animt>=0.8 then
p.charge = 0
sfx(5)
add_shake(3)
p.cooldown = 2
change_state(p,'idle')
elseif p.animt>=0.27 and p.charge <3 then
p.charge=3
sfx(3)
elseif p.animt>=0.15 and p.charge <2 then
p.flash=0.2
p.charge=2
sfx(2)
elseif p.animt>=0.03 and p.charge <1 then
p.flash=0.2
p.charge=1
sfx(1)
end
if p.charge==3 and abs(p.animt/0.01)%5==0 and p.animt<0.75 then
p.flash = 0.2
end

elseif state!='hurt' and not titles then
change_state(p,"idle")
end
end
end
end
if state=="attack" then
local xm=0.3

if p.dir%2!=0 then xm=-0.3 end
create_particle(p.x+p.vx*2.2,p.y+p.vy*2.2,p.vy*0.3,p.vx*xm,true)
create_particle(p.x+p.vx*2.2,p.y+p.vy*2.2,p.vy*-0.3,p.vx*-xm,true)
end
apply_friction(p,wtrfrc)
move(p)
if not player.off then
detectwalls(p)
end
end

function draw_player(p)
local state=p.state
local sinfo=p.spr_info[state]
local flipx,flipy,sprw,sprh,xoff,yoff,sprites = false,false,2,2,-4,-8,{}

if state=="hurt" or state=="dead" then
sprites = sinfo.hurt
else
local d = p.dir
if d==0 or d==4 then sprites = sinfo.up sprw=1 end
if d==1 or d==7 then sprites = sinfo.diagu xoff=-8 end
if d==2 or d==6 then sprites = sinfo.right sprh=1 xoff=-8 yoff=-4 end
if d==3 or d==5 then sprites = sinfo.diagd xoff=-8 end
if d==4 or ((d==3 or d==5) and state=="attack") then flipy=true end
if d>=5 then flipx=true end
end
local spri = sprites[flr(p.animt/sinfo.dt)%#sprites+1]
if (p.invinci>0 and flr(p.invinci%3)==0) then
else
local fc = 7
if state=="dead" then fc=8 end
local oc = 0
if p.flash>0 then oc = fc end
drawoutline(spri,p.x+xoff,p.y+yoff,sprw,sprh,flipx,flipy,oc)
flashobject(p,fc)
spr(spri,p.x+xoff,p.y+yoff,sprw,sprh,flipx,flipy)
end
pal()
end

function coll_objs()
for e in all(objects) do

local att=ternary(player.state=="attack" and not e.invinci,true,false)


if coll(e.abs_box(),player.abs_box(att)) then
local name = e.name
if name=="mine" then change_state(e,"detonate") sfx(9)end

if player.state=="attack" then
if e.invinci then
if player.invinci>0 then return end
if name!="clam" then bounce(e,player.vx*0.6,player.vy*0.6) end
cancel_attack()
bounce_relative(player,e,3)
else
kill_object(e)
end
elseif player.state!="hurt" then
if name!="clam" then bounce(e,player.vx,player.vy) end
if name!="mine" then
if not (name=="clam" and e.state=="idle") then
if player.invinci>0 then return end
hurt_player(player)
end
end
bounce_relative(player,e,3)
if name=="pearl" then kill_object(e) end
end
end
end
end


function hurt_player(p)
if p.state != "dead" then
p.hp-=1
create_bubbles(p.x,p.y,rnd(3)+3,8,2,4)
freeze=3
sfx(6)
add_shake(10)
if p.hp<=0 then
deathcounter+=1
change_state(p,"dead")
else
p.charge = 0
p.cooldown = 3
change_state(p,"hurt")
end
end
end

function cancel_attack()
change_state(player,"idle")
add_shake(3)
sfx(9)
player.charge = 0
player.cooldown = 2
player.flash = 0
player.bigbox=false
for i=1,rnd(4)+3 do
create_particle(player.x,player.y,rnd(3)+-2,rnd(3)+-2,true)
end
if player.invinci<3 then player.invinci=15 end
end

-->8
--objects--


function new_object(x,y,name,update,draw)
return {x=x,y=y,vx=0,vy=0,animt=0,state="idle",name=name,update=update,draw=draw}
end

function create_snapper(x,y)
local e=new_object(x,y,"snapper",update_snapper,draw_snapper)
e.dir=0
e.active=false

e.spr_info={
idle = {
up = {1,2},
diag = {3,4},
right={5,6},
dt=0.02
}
}
e.abs_box=function()
return new_box(e.x-3,e.y-3,e.x+3,e.y+3)
end
add(objects, e)
return e
end

function create_school(x,y)
for i=1,6 do
local a=rnd(1)
local d=rnd(20)
local sx=x+d*cos(a)
local sy=y+d*sin(a)
create_snapper(sx,sy)
end
end


function update_snapper(e)
e.animt+=0.01
local d = dist(e.x,e.y,player.x,player.y)
if not e.active then
if d<=120 then e.active=true end
else
local spd,buff=0.1,20
if d<=20 then buff=4 end
local l,r,u,d
if player.x-buff > e.x then e.vx +=spd r=true end
if player.x+buff < e.x then e.vx -=spd l=true end
if player.y-buff > e.y then e.vy +=spd d=true end
if player.y+buff < e.y then e.vy -=spd u=true end
apply_accel(e,1)
setdirection(e,l,r,u,d)

move(e)
end
end

function draw_snapper(e)
local sinfo,flipx,flipy,sprites,d=e.spr_info[e.state],false,false,{},e.dir

if d==0 or d==4 then sprites = sinfo.up  end
if d==1 or d==3 or d==5 or d==7 then sprites = sinfo.diag end
if d==2 or d==6 then sprites = sinfo.right end
if d>=3 and d<=5 then  flipy=true end
if d>=5 then flipx=true end

local spri = sprites[flr(e.animt/sinfo.dt)%#sprites+1]
drawoutline(spri,e.x-4,e.y-4,1,1,flipx,flipy,0,true)
end

function create_puffer(x,y)
local e=new_object(x,y,"puffer",update_puffer,draw_puffer)
e.invinci=false

e.spr_info={
idle = {
sprites = {110,111},
dt=0.02
},
puffed = {
sprites = {78},
dt=0.5
}
}
e.abs_box=function()
local size = ternary(e.state=="puffed",7,3)
return new_box(e.x-size,e.y-size,e.x+size,e.y+size)
end
add(objects, e)
return e
end


function update_puffer(e)
e.animt+=0.01
local os= is_offscreen(e,80)
if os then return end
local state = e.state
local spd = ternary(state=="puffed",0.06,0.1)

if e.animt>1.2 and state=="idle" then
change_state(e,"puffed")
e.invinci=true
if not os then sfx(23) end
end
if e.animt>0.75 and state=="puffed" then
change_state(e,"idle")
e.invinci=false
if not os then sfx(24) end
end
if dist(player.x,player.y,e.x,e.y)<48 and state=="idle" then spd *=-1 end
if player.x-8 > e.x then e.vx +=spd end
if player.x+8 < e.x then e.vx -=spd end
if player.y-8 > e.y then e.vy +=spd end
if player.y+8 < e.y then e.vy -=spd end

apply_accel(e,1)
move(e)
end

function draw_puffer(e)
local sinfo=e.spr_info[e.state]
local sprites = sinfo.sprites
local flipx,sprw,sprh,xoff,yoff = ternary(player.x>e.x,true,false),1,1,-4,-4

if e.state=="puffed" then xoff,yoff,sprw,sprh,flipx = -8,-8,2,2,not flipx  end
local spri = sprites[flr(e.animt/sinfo.dt)%#sprites+1]
drawoutline(spri,e.x+xoff,e.y+yoff,sprw,sprh,flipx,false,0,true)
end

function create_squid(x,y,shark)
local e=new_object(x,y,"squid",update_squid,draw_squid)
e.up=false
e.invinci=false
local sa,sb= 76,77
if shark then
e.name,e.up,sa,sb="shark",true,74,90
end

e.spr_info={
idle = {
sprites = {sa},
dt=0.02
},
swim = {
sprites = {sa,sb},
dt=6
}
}
e.abs_box=function()
local xa,ya=3,7
if e.name=="shark" then xa,ya=7,3 end
return new_box(e.x-xa,e.y-ya,e.x+xa,e.y+ya)
end
add(objects, e)
return e
end

function create_shark(x,y)
create_squid(x,y,true)
end

function update_squid(e)
e.animt+=1
if e.name=="squid" then
e.up=ternary(e.vy<0,true,false)
e.invinci=ternary(((player.y>e.y-3 and not e.up) or (player.y<e.y+3 and e.up)),true,false)

else
e.up=ternary(e.vx<=0,true,false)
end

if e.state=='idle' then
apply_friction(e,wtrfrc)
if e.animt>30 then change_state(e,'swim') end
else
if e.animt>120 then change_state(e,'idle') end
if e.name=="squid" then
e.vy+=ternary(e.up,-0.1,0.1)
else
e.vx+=ternary(e.up,-0.1,0.1)
end
apply_accel(e,1.5)
end
move(e)
end

function draw_squid(e)
local sinfo = e.spr_info[e.state]
local sprites = sinfo.sprites
local spri = sprites[flr(e.animt/sinfo.dt)%#sprites+1]
local flipy,flipx,xa,ya,sx,sy = false,false,3,7,1,2
if e.name=="squid" then
flipy=ternary(e.up,false,true)
else
flipx=ternary(e.up,true,false)
xa,ya,sx,sy=7,3,2,1
end
drawoutline(spri,e.x-xa,e.y-ya,sx,sy,flipx,flipy,0,true)
end

function create_spikey(x,y,mine)
local e=new_object(x,y,"spikey",update_spikey,draw_spikey)
e.spri=22
e.bob=true
e.flash=0
e.invinci=true

e.seed = flr(rnd(30))
e.abs_box=function()
return new_box(e.x-3,e.y-3,e.x+3,e.y+3)
end
if mine then e.name = "mine" e.spri=10 end
add(objects, e)
return e
end

function create_mine(x,y)
return create_spikey(x,y,true)
end

function create_field(x,y,cols,rows,xspace,yspace,mine)
local ypos = y
for i=1,cols do
for i=1,rows do
create_spikey(x,ypos,mine)
ypos+=yspace
end
x+=xspace
ypos=y
end
end

function create_trap(x,y)
local m = create_mine(x,y)
m.state="detonate"
create_field(x-10,y-10,2,2,20,20)
create_bubbles(x,y,14,15,2,4)
end

function update_spikey(e)
e.vy+=ternary(e.bob,0.01,-0.01)

if (t+e.seed)%30==0 then e.bob = not e.bob end

if e.state=="detonate" then
e.animt+=1
if e.animt>=60 then
create_explosion(e.x,e.y,15)
create_bubbles(e.x,e.y,10,15,2,4)
add_shake(8)
sfx(14)
local pdist = dist(player.x,player.y,e.x,e.y)
if pdist<=30 and player.state != "hurt" and player.invinci==0 then
hurt_player(player)
bounce_relative(player,e,9-pdist/4)
end
for o in all(objects) do
local odist = dist(o.x,o.y,e.x,e.y)
if odist<=30 then
if o.name == "mine" or o.name == "spikey" then
bounce_relative(o,e,9-odist/4)
if o.name =="mine" then change_state(o,"detonate") end
else
kill_object(o)
end
end
end

del(objects,e)
elseif e.animt>=40 and e.animt%2==0 then
e.flash =0.1
elseif e.animt>=0 and e.animt%10==0 then
e.flash =0.2
end
end
apply_friction(e,wtrfrc)
move(e)
end

function draw_spikey(e)
drawoutline(e.spri,e.x-4,e.y-4,1,1)
flashobject(e,7)
spr(e.spri,e.x-4,e.y-4,1,1)
pal()
end


function create_clam(x,y)
local e =new_object(x,y,"clam",update_clam,draw_clam)
e.flipx=false
e.wob=true
e.invinci=true
e.shakesound=false

e.abs_box=function()

local box = new_box(e.x-7,e.y-3,e.x+7,e.y+3)
if e.state=="open" then box.y1-=4 box.y2+=4 end
return box
end
add(objects,e)
return e
end

function update_clam(e)
e.animt+=1
if is_offscreen(e,60) then return end
if e.state=="idle" then
e.flipx=ternary(player.x>e.x,true,false)
if e.animt >=60 then
if not e.shakesound and not is_offscreen(e) then sfx(15) e.shakesound=true end
if t%2==0 then
if e.wob then
e.x+=2
else
e.x-=2
end
e.wob=not e.wob
end
end
if e.animt >=80 then
change_state(e,"open")
e.shakesound=false
e.invinci=false
end
end

if e.state=="open" then
if e.animt==1 then
local vx = (player.x-e.x)/dist(player.x,player.y,e.x,e.y)
local vy = (player.y-e.y)/dist(player.x,player.y,e.x,e.y)
create_bubbles(e.x,e.y-3,rnd(3)+2,4,1,3)
create_pearl(e.x,e.y-2,vx*2,vy*1.6)
sfx(16)
end
if e.animt>=120 then
change_state(e,"idle")
e.invinci=true
end
end
end

function draw_clam(e)
local spri,yoff,h=29,-7,1

if e.state=="open" then
spri,yoff,h=8,-15,2
end
drawoutline(spri,e.x-8,e.y+yoff,2,h,e.flipx,false,0,true)
end

function create_pearl(x,y,vx,vy)
local e=new_object(x,y,"pearl",update_pearl,draw_pearl)
e.vx=vx
e.vy=vy

e.abs_box=function()
return new_box(e.x-2,e.y-2,e.x+2,e.y+2)
end

add(objects,e)
return e
end

function update_pearl(e)
if e.x<-20 or e.x>roomcols*140 or e.y<-20 or e.y>roomrows*140 then
del(objects,e)
end
move(e)
end

function draw_pearl(e)
drawoutline(26,e.x-2,e.y-2,1,1,false,false,0,true)
end

function create_exit(x,y)
local e={
x=x,
y=y,
name='exit',
state='open',
combat=false,
abs_box=new_box(x-4,y-4,x+4,y+4)
}
exit = e
return e
end

function update_exit()
if exit.combat==true and exit.state=="closed" then
local no = 0
for i in all(objects) do
if i.name=="mine" or i.name=="spikey" or i.name=="pearl" then
no+=1
end
end
if #objects-no <= 0 then
exit.state="open"
music(5)
create_bubbles(exit.x,exit.y,10,6,2,4)
end
end
if t%60==0 then create_bubbles(exit.x,exit.y,rnd(1)+1,2,1,2) end
end

function coll_exit()
if coll(exit.abs_box,player.abs_box()) then
if exit.state=="open" and player.state!="dead" then
sfx(29)
next_room()
end
end
end

function draw_exit()
local ca,cb=0,0
if exit.state=="closed" then ca,cb= 13,2 end
pal(8,0)
pal(9,ca)
pal(10,cb)
spr(108,exit.x-8,exit.y-8,2,2)
pal()
end

function create_ink(x1,y1,x2,y2,uprate,both)
e = {
box=new_box(x1,y1,x2,y2),
uprate=uprate or 0,
both=both or false,
name="ink",
update=update_ink,
coll=coll_ink,
draw=draw_ink
}
e.uprate*=0.1
add(hazards,e)
return e
end

function update_ink(e)
local box=e.box
box.y1-=e.uprate
if e.both then box.y2-=e.uprate end
if box.y2<0 then del(hazards,e) end

local cbox =new_box(camx-20,camy-20,camx+148,camy+148)

if coll(box,cbox) then
if t%3==0 then
local x1,y1,x2,y2=box.x1,box.y1,box.x2,box.y2
local tblen,rllen,off = x2-x1,y2-y1,10
for i=1, flr((tblen+64)/64) do
create_particle(flr(rnd(tblen)+x1),y1+off,0,(rnd(0.2)+0.2+e.uprate)*-1)
create_particle(flr(rnd(tblen)+x1),y2-off,0,rnd(0.2)+0.2-(e.uprate*0.9))
end
for i=1, flr((rllen+64)/64) do
create_particle(x2-off,flr(rnd(rllen)+y1),rnd(0.2)+0.2,0)
create_particle(x1+off,flr(rnd(rllen)+y1),(rnd(0.2)+0.2)*-1,0)
end
end
end
end

function coll_ink(e)
local box = e.box
local ps = player.state
if coll(box,player.abs_box()) and ps!="attack" and ps!="hurt" and ps!="dead" then
local centre = {}
centre.x = box.x1+box.x2/2
centre.y = box.y1+box.y2/2
hurt_player(player)
bounce_relative(player,centre,2)
end
end

function draw_ink(e)
local b = e.box
palt(0,false)
rectfill(b.x1,b.y1,b.x2,b.y2,0)
pal()
end


function update_boss()
boss.animt+=1
if boss.wave>0 then boss.wave-=1 player.vy-=0.4 add_shake(1)end
if boss.state=="active" then
if coll(player.abs_box(),boss.box) then
if player.state=="attack" then
cancel_attack()
sfx(21)
boss.hp-=1
add_shake(4)
if boss.hp<=0 then
sfx(22)
change_state(boss,"dying")
for i in all(objects) do
kill_object(i)
end
end
end
bounce_relative(player,boss,2)
end
if t%150==0 then
create_bubbles(arg"64,640,20,40,2,3,")
create_ink(arg"-20,640,146,660,13,true,")
boss.wave=40
music(3)
end
elseif boss.state=="dying" then
if t%2==0 then
create_explosion(rnd(80)+20,rnd(128)+512,rnd(8)+8)
end
if t%flr(rnd(10)+4)==0 then sfx(14) add_shake(4) end
if boss.animt>=150 and player.state!="dead"then change_state(boss,"dead") next_room() end
end
end

function draw_boss()
drawoutline(arg"69,48,576,4,4,false,false,0,true,")
if boss.hp<3 then
spr(arg"73,69,596,")
if boss.hp<2 then
spr(arg"73,52,596,1,1,false,true,")
spr(arg"73,66,580,1,1,true,")
if boss.hp<1 then
spr(arg"73,56,581,1,1,true,true,")
spr(arg"73,62,588,1,1,")
end
end
end
end

-->8
--object utils

function spawnlist(l)
local ol = parse(l)
for i=1,#ol,3 do
local t,x,y=ol[i],ol[i+1],ol[i+2]
spawntype(t,x,y)
end
end

function spawntype(type,x,y)
if type==3 then
create_snapper(x,y)
elseif type==4 then
create_puffer(x,y)
elseif type==5 then
create_squid(x,y)
elseif type==1 then
create_spikey(x,y)
elseif type==2 then
create_mine(x,y)
elseif type==0 then
create_exit(x,y)
elseif type==6 then
create_clam(x,y)
elseif type==7 then
create_school(x,y)
elseif type==8 then
create_shark(x,y)
end
end

function coll(a,b)
return not (a.x1>b.x2 or a.y1>b.y2 or a.x2<b.x1 or a.y2<b.y1)
end

function move(o)
o.x+=o.vx
o.y+=o.vy
end

function kill_object(e)
add_shake(5)
create_explosion(e.x,e.y,5)
create_bubbles(e.x,e.y,rnd(2)+2,4,1,3)
for i=1,flr(rnd(4)+3) do
create_particle(e.x,e.y,rnd(3)+-2,rnd(3)+-2,true)
end
sfx(7)
del(objects,e)
freeze=2
end


function apply_friction(o,fric)
o.vx*=fric
o.vy*=fric
end

function bounce(o,bx,by)
if bx then o.vx = bx end
if by then o.vy = by end
end

function bounce_relative(p,o,str)
local rdist = dist(p.x,p.y,o.x,o.y)
local bouncex = (p.x-o.x)/rdist
local bouncey = (p.y-o.y)/rdist
bouncex*=str
bouncey*=str
bounce(p,bouncex,bouncey)
end

function change_state(o,state)
if o.state != state then
o.state = state
o.animt = 0
end
end

function apply_accel(o,tpspd)
local l=dist(o.vx,o.vy)
local rl=min(l,tpspd)
o.vx=o.vx/l*rl
o.vy=o.vy/l*rl
end

function issolid(x, y)
local tile,col,row = gettile(x,y)
if tile then
ox = (x-(col*128))/8
oy = (y-(row*128))/8
offsetx = (tile%8)*16
offsety = flr(tile/8)*16
val=mget(ox+offsetx, oy+offsety)
return fget(val, 1)
end
end

function detectwalls(o)
local hb = o.abs_box()
local x1,x2,y1,y2,xc,yc=hb.x1,hb.x2,hb.y1,hb.y2,0,0
local adjust = 0.1

for i=y1,y2 do
if x1-1<0 or issolid(x1-1,i) then
o.x+=adjust
xc+=1
end
if x2+1>cmaxx or issolid(x2+1,i) then
o.x-=adjust
xc+=1
end
end

for i=x1,x2 do
if y1-1<0 or issolid(i,y1-1) then
o.y+=adjust
yc+=1
end
if y2+1>cmaxy or issolid(i,y2+1) then
o.y-=adjust
yc+=1
end
end

if xc>0 and xc>=yc then bounce(o,o.vx*-0.8,nil) end
if yc>0 and yc>=xc then bounce(o,nil,o.vy*-0.8) end

if (xc>0 or yc>0) and o.name=="player" and o.state=="attack" then
if (player.dir==2 or player.dir==6) and yc>xc then
else
cancel_attack()
end
end
end

function setdirection(o,bl,br,bu,bd)
if bu and not(bl or br or bd) then o.dir = 0 end
if br and not(bu or bl or bd) then o.dir = 2 end
if bd and not(bl or bu or br) then o.dir = 4 end
if bl and not(bd or br or bu) then o.dir = 6 end
if (bu and br) and not(bl or bd) then o.dir = 1 end
if (br and bd) and not(bl or bu) then o.dir = 3 end
if (bd and bl) and not(br or bu) then o.dir = 5 end
if (bl and bu) and not(br or bd) then o.dir = 7 end
end

function add_shake(p)
local a=rnd(1)
shkx+=p*cos(a)
shky+=p*sin(a)
end

function is_offscreen(o,buffer)
local buf = buffer or 0

if o.x<camx-buf or o.x>camx+127+buf or o.y<camy-buf or o.y>camy+127+buf then return true end
end

-->8
--effects--


function create_explosion(x,y,r)
local e={
x=x,
y=y,
r=r,
p=0,
draw=draw_explosion,
}
add(fx,e)
end

function draw_explosion(s)
if s.p<2 then
circfill(s.x,s.y,s.r,0)
elseif s.p<4 then
circfill(s.x,s.y,s.r,7)

if s.p<3 and s.r>4 then
for i=0,2 do
local x=s.x+rnd(2.2*s.r)-1.1*s.r
local y=s.y+rnd(2.2*s.r)-1.1*s.r
local r=0.25*s.r+rnd(0.5*s.r)
create_explosion(x,y,r)
end
end
elseif s.p<5 then
circ(s.x,s.y,s.r,7)

del(fx,s)
return
end

s.p+=1
end

function create_bubbles(x,y,num,spread,minsize,maxsize)
for i=1,num do
local a=rnd(1)
local b={
x=x+spread*cos(a),
y=y+spread*sin(a),
r=rnd(maxsize-minsize)+minsize,
draw=draw_bubble
}
add(fx,b)
end
end

function draw_bubble(b)
circ(b.x+0.5,b.y+0.5,b.r,13)
circfill(b.x+0.5-b.r*0.4,b.y+0.5-b.r*0.4,b.r*0.2,6)
b.y-=b.r*0.6
if(b.y<0)then del(fx,b) end
end

function create_fern(x,y,len,col)
f={x=x,y=y,len=len,col=col,flipx=false,draw=draw_fern}
f.bub=flr(rnd(1080)+720)
add(fx,f)
end

function draw_fern(f)
if t%50==0 then f.flipx=not f.flipx end
if flr(t+1080)%f.bub==0 then create_bubbles(f.x+3,f.y,1,1,1,2) end
pal(8,f.col)
for i=1,f.len do
if i==f.len then
spr(105,f.x,f.y-i*8,1,1,f.flipx)
else
spr(121,f.x,f.y-i*8,1,1,f.flipx)
end
end
pal()
end


function flashobject(o,c)
if o.flash > 0 then
o.flash-=0.1
for i=0,15 do
pal(i,c)
end
else
o.flash = 0
end
end

function drawoutline(n,x,y,w,h,flip_x,flip_y,c,main)
for i=1,15 do
pal(i,c)
end

for xx=-1,1 do
for yy=-1,1 do
spr(n,x+xx,y+yy,w,h,flip_x,flip_y)
end
end
pal()
if main then spr(n,x,y,w,h,flip_x,flip_y) end
end

function boldprint(str,x,y,col)
c=col or 7
for xx=-1,1 do
for yy=-1,1 do
print(str,x+xx,y+yy,0)
end
end
print(str,x,y,c)
end

function create_particle(x,y,vx,vy,pp)
p = {
x=x,
y=y,
vx=vx,
vy=vy,
cols={0,0,2},
size=10,
age=0,
maxage=30
}
if pp then
p.size=1
p.maxage=15
p.cols={7,7,7,6,6,12}
p.pp=true
end
add(particles,p)
end

function update_particles()
for p in all(particles) do
p.age+=1
if p.age==p.maxage or is_offscreen(p,30) then del(particles,p) end
local ci = 1+flr((p.age/p.maxage)*#p.cols)
p.col = p.cols[ci]
if p.age/p.maxage > 0.6 then p.fill = fades[4] end
if p.age/p.maxage > 0.8 then
p.fill = fades[2]
if not p.pp then
p.size=14
end
end

move(p)
end
end

function draw_particles()
for p in all(particles) do
if p.fill then fillp(p.fill) end
circfill(p.x,p.y,p.size,p.col)
fillp()
end
end

-->8
--utilities--

function parse(string)
local data = {}
local d = ""
for i=1,#string do
local s = sub(string,i,i)
if s != "," then
d=d..s
else
if d=="true" then
d=true
elseif d=="false" then
d=false
else
d=flr(d)
end
add(data,d)
d=""
end
end
return data
end

function arg(str)
return unpack(parse(str))
end

function unpack(t,i)
i=i or 1
if t[i]!=nil then
return t[i],unpack(t,i+1)
end
end

function ternary(c,a,b)
if c then return a else return b end
end

function gettile(x,y)
local col = flr(x/128)
local row = flr(y/128)
local tile = roomtiles[(roomcols*row)+row+col+1]
return tile,col, row
end

function dist(xa,ya,xb,yb)
if xb then xa=xb-xa ya=yb-ya end
local d = max(abs(xa),abs(ya))
local n = min(abs(xa),abs(ya)) / d
return sqrt(n*n +1)*d
end

function new_box(x1,y1,x2,y2)
return {x1=x1,y1=y1,x2=x2,y2=y2}
end

function timer()
local min,sec=gm,flr(gt/30)
if min<10 then
min="0"..min
end
if sec<10 then
sec="0"..sec
end
return min..":"..sec
end

__gfx__
000000000088e0000088e000000008e8000008e8000e0000000e0000000c0000000000000001d000002222000000000000000000000000677777000000060000
0000000000178e0000178e000008718800087188e008e0000008e000000c000000000000001dd50002e2222000000000000076700d6666666666770000676000
00700700007788e0007788e00e8877820e8877828882871ee882871e000c000000000000001dd5002e26d222000000000777776000dddddd6666676007777700
0007700002888880028888800082888200888882288887788888877800cc600000000000001d5dd0226e8d220000000076667770000000000006777607676700
000770002888822028282820ee8888200088282088888882288888820c71600000000000001dd5d022d88521000000776666670000dddddd6666676076666670
007007000088220000882200882882000888822000228820802882200c77c60000000000001ddddd222d5211000007666d0667000d6666666666770076606670
000000000088800000888000082820000288200000022200000222000cccc600000000000001dd5d0222211000000666d0d66700000000677777000076606670
00000000088280000088280000800000002800000000000000000000dccccc60000000000001ddd5001111000000666d0d667000000000000000000076606670
00000006600000000060000660000000000000066000000060000006d0cccc00000000000001dd5d0f77000000066dd0d6670000000000000000000076d0d670
66000000cc66000000c60000cc66000000000000cc660000060e206000ccc000000000ffee001dddf77760000006d00d666700000000000dd555000066d0d660
0c6066ccc77cc0000c6c666cc77cc000000066ccc77cc0000062260000dcc0000002efeeeee211d57777600000dd000d6670000000d5dd555ddd5d0006d0d600
0cccccccc71cccccccccccccc71ccccc666cccccc71ccccc0e22222000ddc000d12222eeee2221d07776d00000d000d660000000d11d5dddddddd1d006d0d600
0cc0dddcccccc0000000dddcccccc0000cc0dddcccccc00002222110000c0000ddd11111111111d0066d000000000d6600000000ddd1111111111dd006d0d600
dd00000ddcc000000000000ddcc00000ddd0000ddcc0000000d21d0000cc600000dddddddddddd00000000000000dd000000000000dddddddddddd0006d0d600
00000000d000000000000000d00000000d000000d00000000d0110d00cddd60000000d5d5d5d500000000000000000000000000000000d5d5d5d50000d000d00
000000000000000000000000000000000000000000000000d000000d0d000c000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000c0000000c00000006000000000000000000000000000000000000000000000000000000000000
00000000000000c000000000000000c000000000000000c0000c0000000c000000006000000000000060006000000000000000000000000000000000000000c0
0000000000000c000000000000000c000000000000000c00000c0000000c0000000cc0000000000000cc0c600000000006660000000000000000000006000c00
000000000000c000000000000000c000000000000000c00000cc600000cc6000c0ccc00060000000000dcc006000000000ccc00060000000000000066cccc000
00000006cccc000000000006cccc000000000006cccc00000c7160000c7160000dddc660060000000000cc6006000000000cc660060000000000006c17cc0000
0000006cc71c00000000006cc71c00000000006cc71c00000c77c6000c77c6000000dccccc0000000000dccccc00000000cddccccc00000006006ccc77cc0000
00006cccc77c000000006cccc77c000000006cccc77c00000cccc6000cccc60000000ccccc60000000000ccccc6000000dd00ccccc6000000c60ccccccc00000
00060ccccccd000000060ccccccd000000060ccccccd0000dccccc60dccccc6000000dcdccc6000000000dcdccc6000000000dcdccc600000dc6cccccd000000
00000ccdccd0000000000ccdccd0000000000ccdccd00000d0cccc00d0cccc00000000dccccc0000000000dccccc0000000000dccccc000000dcddddd0000000
0000cccccd0000000000cccccd0000000660cccccd00000000ccc00000ccc000000000dcc77c0000000000dcc77c0000000000dcc77c000000dcccd000000000
00006ddd0000000000006ddd0000000000c6cddd0000000000dcc00000dcc0000000000dc71c00000000000dc71c00000000000dc71c000000cccc0000000600
066ccd00000000000006cd0000000000000ccd000000000000ddc00000ddc00000000000dccc000000000000dccc000000000000dccc0000000dccc66000cc00
60ccc00000000000006cc0000000000000ccd00000000000000c0000000c0000000000000000c000000000000000c000000000000000c0000000dcccc66cc000
000cd0000000000000ddd000000000000dd000000000000000cc0000000cc0000000000000000c000000000000000c000000000000000c0000000ddccccc0000
0000d000000000000d000d00000000000000000000000000ccdd0000000dcc6000000000000000c000000000000000c000000000000000c00000000ddddc0000
000d00000000000000000000000000000000000000000000000c0000000dd00000000000000000000000000000000000000000000000000000000000000d0000
ffffffff0333333333333333333333303333333300000000000066666666000000000000000070009900009900000000000f4000000f40000000000400000000
fff8fff83353533553533535535353333355333300000000066600000000666000000000000070000990000990000000000f400000044000000400f4ff040000
fff88f8e35e5e35ee5e53e5e35e5255335ee53550000000660000000000000066000000000000700009999999997700000044000000f400000004fff4f4f0000
fff888ef5efff5effefe5fef5ef2e2235effe5ee0000006d0000777700000000060000000000700000999999999719990049940000f944000004ffff4ffff000
8888888fefffffffffffefffeffeeee5effffeff000006d000777777000000000d60000000770000009ff9999999999900f9940000f94400044fffffffffff00
ee888888fffffffffffffffffffeeee2ffffffff00006dd0777700000000000000d600007700700009900ffff99fff9000f9940000f4940000fff77fffff7100
fffe8eeefffffffffffffffffffeeeeeffffffff00065dd7777000000000000000dd600000000700990000fff99fff0000f94400004994000ffff17fffff77f0
ffff8ffffffffffffffffffffffeeeeeffffffff0065057770000000000000000dd556000000000000000000990000000f94994004f994400f44fffffffffff0
fff33fffeeeeeeeeddd55555eee22222ff4444ff00600777d000000000000000dd5006001a1a1a1a09000099000000000f4999400f99944004ffffffffffff44
fff31fffeeeeeeeed1111112eee22222f49ff94f06007775dd0000000000000dd5000060a1a1a1a10090000990000000049999400f994940044ffff4ffff4ff0
ff3333ffffffffffddd55552fffeeeee4fe44fe4060077005dd00000000000dd500000601a1a1a1a009999999997700044499444f4449944004fff4ffffff400
f3b3331feeeeeeee51111112eee222224949f4940600770005dddd0022000dd500000060a1a1a1a10099999999971999f7794774f779977400444ffff4ffff40
f333311feeeeeeee5dd55552eee222224f4f4fe46007700000dd2222222ddd50000000061a1a1a1a009ff99999999999f7144174f7144174000444ffff4ff000
e333311feeeeeeee51111112eee222224949e94e60077000005225222222dd0000000006a1a1a1a100900fff99ffff900488884004888840000044444ff40000
fe3111eeeeeeeeee5dd55552eee222224fe444ef600770000022222222222500000000061a1a1a1a090000ff99ffff0000808800080808000000004444000000
ffeeeeeeffffffff52222222fffeeeeef44eeeff60077000022222222222220000000006a1a1a1a1000000099000000008080080080080800000000000000000
fffffffffffffffffffffffffffeeeeeffffffff60000000022222222222210000000006000000001111111a11111111000000dddd00000000004f0000004f00
fffffffffffffffffffffffffffeeeeeffffffff6000000002228822228821000002000600088000111111a1a11111110000dd5555550000000fff40000fff40
fff9fffffffffffffffffffffffeeeeeffffffff600000000022288228821100002000560088880011111a1a1a111111000d555225555000f0f17f1700f17f17
fffffffffffffffffffffffffffeeeeeffffffff60000000021222222221120022100056008488001111a1a1a1a1111100d55229a22555004ff77f77fff77f77
ffffffffeffffffffffffffffffeeee2ffffff9f0600002221001222211112222000006000848800111a1a1a1a1a11110d552a89a8925550ffffffff4fffffff
ffffffff2efffffffffffffffffeee22f9ffffff06000210000006ddd5100010000005600848800011a1a1a1a1a1a1110d529a89a89a25500044fff4f04ffff4
ffffffff02eeeeeeeeeeeeeeeeeee220ffffffff06000200000006ddd500000000005560084880001a1a1a1a1a1a1a11d5529a89a89a2552000fff40000f4f40
ffffffff002222222222222222222200ffffffff006020000000008e280000000000560000848800a1a1a1a1a1a1a1a1d5289a89a89a8d520000440000004400
5d555522fffffffffffeeeeefffffffffffeeeee006000000000080e2800000000055600008488001a1a1a1a1a1a1a1ad5289a89a89a8d52555555555d555522
5d555522eeeeeeeeeee22222fffffffffffeeeee0006000000000e8200800000005560000008488011a1a1a1a1a1a1a1d5589a89a89a8522dddddddd5d555522
5d555522eeeeeeeeeee22222fffffffffffeeeee0000600000000028e80000000556000000084880111a1a1a1a1a1a11055d9a89a89ad520555555555d555522
5d555522fffffffffffeeeeefffffffffffeeeee000006000000008028e0000055600000008488001111a1a1a1a1a1110255da89a89d5220555555555d51d522
5d555522fffffffffffeeeeefffffffffffeeeee000000600000e802e00e0055560000000084880011111a1a1a1a111100255dd9add52200555555555d5d5522
5d555522eeeeeeeeeee22222fffffffffffeeeee00000006600e082e000555566000000008488000111111a1a1a111110002555dd5522000555555555d555522
5d555522fffffffffffeeeeefffffffffffeeeee0000000006660082e805666000000000084880001111111a1a1111110000255555220000222222225d555522
5d555522fffffffffffeeeeefffffffffffeeeee000000000000666666660000000000000084880011111111a11111110000002222000000222222225d555522
16262626262626262626262637373737373737373737373737373737373737373737373737373737373737373737374737373737373737373737373737373737
3737373737373737373737373737373737374637373746063737373737043737070000a7b7000000000000a7b700000707000700000000000000000000070007
a7959595951646373737373737373737373737373737373737373737373737373737373737373737373737373746374706370646063737063737370637373737
37373737370637373737373737373737262626262626463737374637373737370700000000000000000000000000000707a607a6a6a6a6a6a6a6a6a6a607a607
00a79595959537063737063737063737373737063737063737373737374637373746373737373737373737373737064737374604463706463737262626262626
262626262626262646373737063737373695959595b6162626263706373746370700000000000000000000000000000707b707b7b7b7b7b7b7b7b7b7b707b707
000000b7a79546373746370637373737373737373737373737463737370637373737373737374637373737460637374737370646370637373706263695959595
95959595951626262606373737373737959595959595b6162626262626373737070000a6b6000000000000a6b60000070700f700000000000000000000070007
00000000009517171717171717171717171717171717171717171717171717171717171717171717171717171717172717171717171717171727959595959595
9595959595959595951717171717171795959595959595b600000017171717170795959595959595959595959595950707000700000000000000000000070007
0000000000a715151515151515151515151515151515151515151515151515151515151515151515151515151515153515151515151515151535959595959595
959595959595959595151515151515159595a795959595950000a61515151515f70000a7b7000000000000a7b700000707e7e725b6b6b6b6b6b6b6b625e7e707
00000000000017171717171717171717171717171717171717171717171717171717171717171717171717171717172717171717171717171727959595959595
9595959595959595951717171717171795b6959595959595b6959517171717170700000000000000000000000000000707a7a707a7a7a7a7a7a7a7a707a7a707
0000000000a646063737064637373704373737373737064637373737373737373737463737374637064637374637063637370626262626262636959595959595
95959595959595959516262606370637959595959595959595959516262606370700000000000000000000000000000707000007000000000000000007000007
00000000a69515151515151515151515151515151515151515151515151515151515151515151515151515151515350015151535959595959595959595959595
95959595959595959595959515151515959595959595959595959595951515150700000000000000000000000000000707000007000000000000000007000007
0000a695959506370637373737373737373737373737370637373737373737373737372626262626262626262626360037463747959595959595959595959595
959595959595959595959595163746379595959595959595959595959537370607000000000000a6b6000000000000f707a6b607b6a6b6a6b6a6b6a6f7a6b607
00009595951424373746373737373737373737373737370637373706373746373737373746373737460637373747b7003737374795959595b70000a695959595
95959595b795a795b7a79595953737379595959595959595959595951424373725e7e725959595959595959525e7e72507b7a707a7b7a7b7a7b7a7b707b7a707
00a695b7951717171717171717171717171717171717171717171717171717171717171717171717171717171727000017171727959595950000a69595959595
9595b700a695b600a6b6a7b7001717179595959595959595959595951717171707000000000000a7b700000000000007f7e7e7e72500000000000025e7e7e707
009595a695063737373737373737373737373737063737373737373737373737373737373737373737063737464700003737373695959595b695959595959595
95b7a695959595959595b6a6953737379595b7a79595959595959595374637370700000000000000000000000000000707000000070000000000000700000007
00959595144424373737374637373737373737370637373737370637373737374637373737063737373737370447000046374795959595959595959595951424
44349595959595959595959595464637442434b6a795959514242424064506370700000000000000000000000000000707a6a6a607a6a6a6b6b6b607b6b6b607
a6951424243737373737373737373706370637373737373737373737373737373737373737373737370637373747b60006464795959595959595959595143737
0637349595959595959595959506373746372424442424440646370637460637070000a6b6000000000000a6b600000707a7a7a707a7a7a7b7b7b707b7b7b707
142406463737373737373737463737373746370646373737063746463746370637373737373737373737373737244434373747959595b7959595959595374606
4637479595959595959595959537373737373737374637373706373737373737f795959595959595959595959595950707000000070000000000000700000007
37373737373737373737373737373737373737373737373737373737063737370000000000000000000000000000000037374795959595959595959595063737
4506479595959595959595959537373700000000000000000000000000000000072500a7b7000000000000a7b7002507e7e7e7e7e725b6b6a6a625e7e7e7e7e7
06370637373706373737063737463737373737373737373737374637373737370000000000000000000000000000000037374795959595959595959595163706
46373695959595959595959595370637000000000000000000000000000000000707000000000000000000000000070707070707e7079595959507e707070707
373737373737463737373706370637263737373737373737373737373737373700000000000000000000000000000000370647959595959595959595b7001626
2636959595959595959595959537373700000000000000000000000000000000070700000000000000000000000007070707f707e7259595959525e707f70707
46063737262626262626262626263695373737063747373737473737370637370000000000000000000000000000000046062434959595959595959500000095
959595959595959595959514243746060000000000000000000000000000000007070000000000a6b60000000000070707070725959595959595959525070707
171717171727b7a695959595959595951717171717271717172717171717171700000000000000000000000000000000171717279595959595a695b70000a695
95959595959595959595951717171717000000000000000000000000000000000707959595959595959595959595070707072595959595b7a79595959525f707
15151515353695959595959595959595151515151535151515351515151515150000002525250000000000252525000015151535959595959595b70000959595
959595b700a69595959595151515151500000000000000000000000000000000f7070000000000a7b700000000000707f70795b79595950000959595a7950707
17171717279595959595959595959595171717171727172717271717171717170000002525250000000000252525000017171727959595b700000000a6959595
9595b70000959595b795951717171717000000000000000000000000000000000707000000000000000000000000070707079595b7959500009595a795950707
37373737369595959595959595959595373737063747374737473737373737370000002525250000000000252525000037463724349595000000a69595959595
959500a69595959500000037370637370000000000142444244444243400000007e72500000025e7e72500000025e7070725959595b795000095a79595952507
1515153595959595959595b7959595951515151515351535153515151515151500000007070700000000000707070000151515153595b7000095959595959595
95959595959595b7000000151515151500000000000637374637370647000000070007a6b600079595f700a6b6070007079595959595b70000a79595959595f7
373737242434959595959595959595953706262606473747374726263737373700000007070700000000000707070000373706462424444434a7959595959595
9595959595b7000000000037064637370000000000171717171717172700000007950795959525e7e7259595950795070795b700000000000000000000a79507
37374637242444442444349595959595064795b746470647374795b7370637370000000707072444340000070707340037374606373737372424243495959595
95959514443400001444443737373737000000000016262626262626360000000700f7a7b7000000000000a7b70700070795b600000000000000000000a69507
17171717171717171717279595959595172795001727172717279500171717170000140707070646242444070707063417171717171717171717172795959595
9595951717271434171717171717171700000000000000a7959595950000000007000700000000000000000000f70007079595959595b60000a6959595959507
373737373737373737373724442434953747950006471636464795003737063714444607f7074637063706070707460637373737373706373737373724443495
9595953706470647370646370437373700000000000000000000a7b70000000007000700000000000000000000070007f725959595b695070795a69595952507
373737373737064637373737373737243747b700163600000647b700162637373725e725e725e7254625e725e725e72537373737374637460637373737064624
444424243747373737373737373737370000000000000000000000000000000007000700000000a6b600000000f7000707079595b6959507079595a695950707
3737063737370646063706373737370637470000000000001636000000003746460746064637370706f706374637460737373737373706370637373737063737
06373737373737373737373737373737000000000000000000000000000000000795079595959595959595959507950707f725b69595252525259595a625f707
373737373737373737373737373737372636000000000000000000000000162625e7e7e7e7e7e7e7e7e7e7e7e7e7e7e737373737373737373737373737373737
373737373737373737373737373737370000000000000000000000000000000007000700000000a7b700000000070007070707e7e7e7e7e7e7e7e7e7e7070707
__label__
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffff9fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffff9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff4444ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffff49ff94fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fff9fffffffffffffffffffffff9fffffffffffffff9ffffffffffff4fe44fe4fffffffffff9ffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffff4949f494ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffff4f4f4fe4ffffffffffffffffffffff9fffffffffffffffffffffffffffffff9fffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffff4949e94efffffffffffffffff9fffffffffffffffffffffffffffffff9ffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffff4fe444efffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffff44eeeffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9fffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9ffffffffffffffffffffffffffffff
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeffffffffffffffffffffffffffffffffffffffffeeeeeeee
22222222222222222222222222222222222222222222222222222222222222222222222222222222ffffffffffffffffffffffffffffffffffffffff22222222
10101010101010101010101010101010101010101010101010101010101010101010101010101010fffffffffffffffffffffffffffffffffffeeeee10101010
01010101010101010101010101010101010101010101010101010101010101010101010101010101fffffffffffffffffffffffffffffffffffeeeee01010101
10101010101010101010101010101010101010101010101010101010101010101010101010101010fffffffffffffffffffffffffffffffffffeeeee10101010
01010101010101010101010101010101010101010101010101010101010101010101010101010101fffffffffffffffffffffffffffffffffffeeeee01010101
10101010101010101010101010101010101010101010101010101010101010101010101010101010effffffffffffffffffffffffffffffffffeeee210101010
010101010101010101010101010101010101010101010101010101010101010101010101010101012efffffffffffffffffffffffffffffffffeee2201010101
1010101010101010101010101010101010101010101010101010101010101010101010101010101012eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee22110101010
01010101010101010101010101010101010101010101010101010101010101010101010101010101112222222222222222222222222222222222221101010101
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101011101010101010101
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010111110101010101010
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101111111010101010101
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101011111111101010101010
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010111111111110101010101
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101111111111111010101010
01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101011111111111111101010101
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101111111010101010
01088101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101011111110108810101
10888810101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101111101088881010
01884801010101010101010101000001010000010100000101000001010000010100000101000001010000010100000101010101010101011111010188480101
10884810101010101010101010007700100707001000770010077700100770001007770010077700100077001007070010101010101010101110101088481010
01088481010101010101010101070001010707010107070101070701010707010107000101007001010700010107070101010101010101011101010108848101
10188480101010101010101010077700100707001007070010077000100707001007701010107010100777001007770010101010101010101010101018848010
01884801010101010101010101000701010777010107070101070701010707010107000101007001010007010107070101010101010101010101010188480101
10884810101010101010101010077000100777001007700010070700100777001007001010077700100770001007070010101010101010101010101088481010
08848101019901010101010101000001010000010100000101000001010000010100010101000001010000010100000101010101010101010199010884810101
18848010199990101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101999901884801010
01884801099491010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010994910188480101
10884810199490101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101994901088481010
01088481019949010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010199490108848101
10188480109949101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101099491018848010
01884801099491010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010994910188480101
10884810199490101010101010101010101010101010101010101010101010101010101011111111111111111111111110101010101010101994901088481010
08848101994901010aa1010101010101010101010101010101010101010101010101010111111111111111111111111101010101010aa1019949010884810101
1884801099491010aaaa10101010101010101010101010101010101010101010101010111111111111111111111111111010101010aaaa109949101884801010
0188480109949101aa4a01010101010101010101010101010101010101010101010101111111111111111111111111110101010101aa4a010994910188480101
1088481019949010aa4a10101010101010101010101010101010101010101010101011111111111111111111111111111010101010aa4a101994901088481010
01088481019949010aa4a10101010101010101010101010101010101010101010101111111111111111111111111111101010101010aa4a10199490108848101
10188480109949101aa4a01010101010101010101010101010101010101010101011111111111111111111111111111110101010101aa4a01099491018848010
0188480109949101aa4a01010101010101010101010101010101010101010101011111111111111111111111111111110101010101aa4a010994910188480101
1088481019949010aa4a10101010101010101010101010101010101010101010111111111111111111111111111111101010101010aa4a101994901088481010
088481019949010aa4a10101ff01010101010101010101010101010101010101111111111111111111111111111111010101ff010aa4a1019949010884810101
188480109949101aa4a0101ffff010101010101010101010101010101010101011111111111111111111111111111010101ffff01aa4a0109949101884801010
0188480109949101aa4a010ff4f101010101010101010101010101010101010111111111111111111111111111110101010ff4f101aa4a010994910188480101
1088481019949010aa4a101ff4f010101010101010101010101010101010101011111111111111111111111111101010101ff4f010aa4a101994901088481010
01088481019949010aa4a101ff4f010101010101010101010101010101010101111111111111111111111111110101010101ff4f010aa4a10199490108848101
10188480109949101aa4a010ff4f101010101010101010101010101010101010111111111111111111111111101010101010ff4f101aa4a01099491018848010
0188480109949101aa4a010ff4f101010101010101010101010101010101010111111111111111111111111101010101010ff4f101aa4a010994910188480101
1088481019949010aa4a101ff4f010101010101010101010101010101010101011111111111111111111111110101010101ff4f010aa4a101994901088481010
088481019949010aa4a101ff4f010107710101010101010101010101010101011111111111111111111111110101077101ff4f010aa4a1019949010884810101
188480109949101aa4a010ff4f101077771010101010101010101010101010111111111111111111111111111010777710ff4f101aa4a0109949101884801010
0188480109949101aa4a010ff4f101774701010101010101010101010101011111111111111111111111111101017747010ff4f101aa4a010994910188480101
1088481019949010aa4a101ff4f010774710101010101010101010101010111111111111111111111111111110107747101ff4f010aa4a101994901088481010
01088481019949010aa4a101ff4f010774710101010101010101010101011111111111111111111111111111010107747101ff4f010aa4a10199490108848101
10188480109949101aa4a010ff4f101774701010101010101010101010111111111111111111111111111111101017747010ff4f101aa4a01099491018848010
0188480109949101aa4a010ff4f101774701010101010101010101010111111111111111111111111111111101017747010ff4f101aa4a010994910188480101
1088481019949010aa4a101ff4f010774710101013333333333333333333333333333333333333311111111010107747101ff4f010aa4a101994901088481010
088481019949010aa4a101ff4f010774710101013353533553533535535335355353353553535333111111010107747101ff4f010aa4a1019949010884810101
188480109949101aa4a010ff4f1017747010101035e5e35ee5e53e5ee5e53e5ee5e53e5e35e52553111110101017747010ff4f101aa4a0109949101884801010
0188480109949101aa4a010ff4f10177470101015efff5effefe5feffefe5feffefe5fef5ef2e2231111010101017747010ff4f101aa4a010994910188480101
1088481019949010aa4a101ff4f0107747101010efffffffffffefffffffefffffffefffeffeeee51110101010107747101ff4f010aa4a101994901088481010
01088481019949010aa4a101ff4f010774710101fffffffffffffffffffffffffffffffffffeeee211010101010107747101ff4f010aa4a10199490108848101
10188480109949101aa4a010ff4f101774701010fffffffffffffffffffffffffffffffffffeeeee10101010101017747010ff4f101aa4a01099491018848010
0188480109949101aa4a010ff4f1017747010101fffffffffffffffffffffffffffffffffffeeeee0101010101017747010ff4f101aa4a010994910188480101
3333333333333333333333333333333333333333ffffffffffffffffffffffff3333333333333333333333333333333333333333333333333333333333333333
3355333353533535535335353355333333553333ffffffffffffffffffffffff5353353553533535535335353355333333553333535335355353353533553333
35ee5355e5e53e5ee5e53e5e35ee535535ee5355ffffffffffffffffffffffffe5e53e5ee5e53e5ee5e53e5e35ee535535ee5355e5e53e5ee5e53e5e35ee5355
5effe5eefefe5feffefe5fef5effe5ee5effe5eefffffffffffffffffffffffffefe5feffefe5feffefe5fef5effe5ee5effe5eefefe5feffefe5fef5effe5ee
effffeffffffefffffffefffeffffeffeffffeffffffff9fffffffffffffffffffffefffffffefffffffefffeffffeffeffffeffffffefffffffefffeffffeff
fffffffffffffffffffffffffffffffffffffffff9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffff9fffffffffffffffffffffffffffffffffffffff9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9ffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffff9fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9fffffffff
fffffffffffffffffffffffffffffffff9fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9ffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003030303030000000000000000000000030303030300000000010000000000000303030303000000000001010000000003030303030000000000010100000303
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000073606262626262626262626262627360000000000000000000000000000000006162626273647373737373737373737373736473737373737373737373737373737373737373737374717171726073737373736073737373737364607373737373736473736073736064737373626263
00000000000000000000000000000000646300007a597b007a597b7a59596173000000000000000000000000000000007a597b0073607362627364737373737360737360736073547360647373736473737373736473737374736073747360736262626262626262626262626262627373737373647373626262626263595959
0000000000000000000000000000000074596b0000596b000059000059597b730000000000000000000000000000000000596b006162635959616262626262626262626262626262626273736473736262626262626262626351515153616262635959595959595959595959595959616262626262626262635959595959597b
000000000000000000000000000000007459596b005959006a596b0059590064000000000000000000000000000000000059596b5900597b7a59595959595959595959595959595959596162626263595959596b6b6a5959597171717259595959595959595959595959595959595959595959595959595959596a59597b0000
00000000000000000000000000000000727a595900595900597a590059596b7100000041424300000000000000000000007a59597b0059000059596b6a5959595959595959595959595959595959595959595959595959595971717172595959595959595959595959595959595959596b7a597b7a595959595959597b000000
0000000000000000000000000000000053007a596b597b00590059007a5959510000006162636b00000000000000000000007a590000596b6a5959595959595959595959595959595959595959595959595959595959595959616262635959595959594144424444424244437a5959595959590000007a59597b7a596b000000
000000000000000000000000000000007200005959596a59596b590000007a71000000007a595900000000000000000000006a59006a59595959595959595959595959595959595959595959597b7a59595959595959595959595959595959595959597373736064737373740059595959597b006a6b00595900005959000000
00000000000000000000000000000000746b007a595959595959590000006a7300000000007a59596b0000414443000000005959005959597b6b597b0000595959595959595959595959595959596a5959595959595959595959595959595959595959717171717171717172006a595959596b6a59595959596b005959000000
0000000000000000000000000000000072596b005959595959597b00006a5951000000000000595959006a7171720000006a597b00597a595959590000005959595959595959595959595959595959595959595959595959595959595959595959597b6054607373736473746a595959595959597a5959595959595959000000
00000000000000000000000000000000747a596b59597a5959596b006a597b7300000000000059595959596162630000007a596b007a595959597b00006a595959595959595959597b00000059595959595959597b595959594142444359595959596b51515151515151515359595959597b7a595959007a7b00006a596b0000
0000000000000000000000000000000074007a59597b007a7b7a59007a5900600000000000007a59595959597b000000000059590000597a595900000059595959595959595959590000006a5959595959597b00007a595959736073745959595959596162626262626262635959595959006a5959596b000000007a59590000
000000000000000000000000000000007200007a5900006a6b005900005900710000000000006a5959597b0000000000006a7b7a6b0059005959006a59595959595959595959597b00000059595959595959004143005959595151515359595959595959595959595959595959595959595959595959595959596b6a59596b00
0000000000000000000000000000000074000000590000597b0059000059007300000000414443597b00000000000000005900005900596b4142444243595959595959595941424242436a5959595959597b006074007a595971717172595959595959595959595959595959595959594142424242435959414244444243596b
000000000000000000000000000000007400000059006a590000590000596b73000000006162637b00000000000000006a596b6a596b4142444242444444424244424244446473734242424444424244444242424242424242424242424242424359595959595959595959595959594142424244444242424242424244624359
000000000000000000000000000000007443006a596b597b006a596b6a594173000000000000000000000000000000004142424444427340736473737373607373736073737373607373737373737373737373737373737373737373737373734242424244424244424244444442446073737364737350736064444444424243
0000000000000000000000000000000060744142444442444442444242447373000000000000000000000000000000007373736073736073736073737373647373737373647373737373737373606473737373737373737373737373737373737373737373647373736073737373737373737360737373737373737373736074
00000000000041444242444242444244414244430000000000004142444442424442444244424244444242430000000073737459595959595959595959737373736474595959595959595959597373737364745959595959595959595964737300000000000000000000007474747373424359596b000000000000006a595941
0000000041444273736473736073606073734244424444430000736073646473737373737360647373736474000000007373424359595959597b59595973737373607459595959595959595959647360737374595959595959595959597360730000000000000000000000637474607373745959595959595959595959595964
000000414242737373737364546073737373607364734244444442736040607373737373736050647373424243000000736460745959595959006a5959736473737342435959595959595959596050647360745959590000007a59595973647300000000000000000000007a637473737342435959597b000000007a59594160
0041426473737373737373606473737373737373737373737360737373606073737373737373737373607360424243007373606359595959590059595961736073736042437a59595959595959736073626263595959004144424244444273730000000000000000000000005972717273734243590000006a59595959416060
00717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171720071717259597b0059595959595959717171717171726b6a595959595959717171717259595959007171717171717171710000000000000000000000005963737471717172596b006a5959595959717171
0051515151515151515151515151515151515151515151515151515151515151515151515151515151515151515153005151535959597b6a5959595959595151515151515359595959595959595151515153595959596b5151515151515151510000000000000000000000007a59647451515153595959597a59595959515151
007171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717200717172595959595959595959595971717171717172595959597b595959717171717259595959597171717171717171710000000000000000000000000059616371717172595959000059595959717171
00616262626262626273737360607373737373737360737373647373737373736073737373737373646062626262630064644243595959007a7b7a595941737373607373745959597b007a5959616273607459595959596174746262626273730000000000000000000000006a59596b737342424359596b00007a5941736073
007a51515151515151515151515151515151515151515151515151515151515151515151515151515151515153597b0051515153597b596b000000595951515151515151535959590000000059595951515359595959595963635959595151510000000000000000000000007a5959595151515153595959596b005951515151
000073737373737373737373737360737373737373736073737364646073737373737373737373737373737374596b0073737374596a59596b006a595960736073736062635959590000000059595960734243595959595959595959596173730000000000000000000000006a59597b73737364745959595959595960607373
00007373737364737373737373737373737373737373737373737373737373737373737373737373736064737459590073646263597a5959595959597b6173546073737459595959596b006a5959417373407459595959595959595959597373000000000000000000000000595959007373647363597b005959595961737360
006a717171717171717171717171717171717171717171717171717171717171717171717171717171717171727a5900717172595900000000000000005971717171717259597b00007a595959597171717172595959595959595959595971710000000000000000000000007a59596b7171717259596b595959595959717171
0041737373737373737364737373737373737373737373737373737373737373737373737373737373737342444359007360745959596b00000000006a59616473737374595900000000597a59417373737342424444444243595959594142730000000000000000000000007a6a59597373737459597b7a7a59595959737373
41424242424242737373737373407373737373737373737373737373737373737373737373737373737373737374596b736463596a59595959595959597b59737360606359596b000000596b00736073737362626262746263595959597373734243000000000000000000005959414473607363595900006a59595959736073
7360737364737364737373737373737373737373647373737373647373737373737373736473737373737373734244434074595959597b00007a59595959597373647459595959596b00595959606473737374595974635959595959597373735153000041436b004144436a595960406064745959596a595959595959647364
7373737360737373737373737373737373737373737373737373737373736073737373737373737373737373737364746263597b0000000000000000007a5961737374595959595959595959597373737373745959635959595959595973737373746b6a60745959647374595941737373737459595959595959595959736073
__sfx__
0114000005611086210c6210c6210c6210c6210b6310b6310c6310e6410f6411264115641186511b6611b6511c6611a671186711567113671106610e6510b6510964108631076210662105611036110261101611
010400000a0510c0510f0511105100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400000e05110051120511305100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400001305115051170511905120553285030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01040000225531e5531a55316553135530f5530d55303500015001b0001800016000120000f0000d0000800006000000000000000000000000000000000000000000000000000000000000000000000000000000
010600000a0500a050010500105000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002945312053314532055327053366570000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002245122451264512645121654226512065521100000002110021100000000000021100211000000021100211000000000000000000000000000000000000000000000000000000000000000000000000
011000000161101611016110361105611046110161101611026110461105611046110361102621016310162101621016210161101611016110161102611036210662105621046210362103621046110161101611
010100000505305053050530405304053040530205302053020530005300053000530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000114301143011440114401145011460114601146011470114701147011470114701146011460114500c4600c4600c4700c4700c4700c4700c4600c4500c4500c4500c4500c4400c4400c4400c4300c430
01100000212222122221222212322123221242212422125221252212522125221252212422124221232212321c2621c2521c2521c2521c2421c2421c2321c2221c2221c2221c2221c2121c2121c2121c2021c202
011000001814118151181511815124151241512414124131181611815118151181511815118151181511814113161131511315113151131511315113141131411313113131131311312113121131211311113111
01100000281122811228122281222813228132281422814228152281522816228162281612815228152281522815228152281522815228142281322812228112281122811228112281121c1121c1121c1121c112
01040000291531c1530e1530015000050000500005000050001030010300103001030010300103001030010300103001030010300103001030010300103001030000000000000000000000000000000000000000
010800001103504535110350453511035045351103504535110350453511035045350c00500005000050000500005000050000500005000050000500005000050000500005000050000500000000000000000000
0104000013530297531c5101a51010510105100050000501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050000500
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300000c7230c7230c7230c7230c7230c7330c7430c7530c7630c7630c7530c7430c7330c7230c7230c7330c7330c7430c7530c7630c7630c7530c7430c7330c7230c7330c7330c7430c7430c7330c7230c723
000300001173311743117531176311763117531175311743117431173311743117431175311753117531175311753117631176311763117531174311743117331173311733117431174311743117531176311753
0103000002023030230402307023080330b0330b03308023070130802309023080230603306043080530a0630b0630c0630b05309043070330603305033040230402305033070430703306023060230601306003
010500003664327345336513634533651336512462124611246111861118615000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0105000032355346513b355376513465135345356413b641346413b631393353b631396313762132325326213b621346113631518611186111861118611186111861118611186111861118611186111861118611
010500000c521105311f5412355124533245000050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100501005010000000000
0105000024531235311f5411c55118543000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00001144011450114601146011460114601146011450114401144011430114301142011410114101141000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00001c2221c2221c2221c2221c2321c2321c2421c2521d2721d2621d2521d2421d2321d2221d2121d21200000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00001814118151181511815121151211512114121131111511115111141111311112111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00002811228112281222812228132281422814228152291522915229142291322912229112291122911200000000000000000000000000000000000000000000000000000000000000000000000000000000
010600001d0341d0711d0711d015000001d0141d0151800000000180001d0141d0151d0001800018000180001d0001d0001800000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000c0533f415000003c6150c0533f3153c615000000c0533f415000003c6150c0533f4153c615000000c0533f3153f3153c6150c0533f4153c615000000c053000003f3153c6150c0533f4153c61500000
011000000c0533f200000003c6150c0533f2003c615000000c0533f200000003c6150c0533f2003c615000000c0533f2003f2003c6150c0533f2003c615000000c053000003f2003c6150c0533f2003c61500000
011000000c05329454264453c6150c0532f3453c6152b3520c05328352294523c6150c0533f2003c615000000c0533f200293503c6150c053283503c615293500c05329440263553c6150c053000003c61500000
011000000014000020001100010000140000200011000100001400002000110001000014000020001100010000140000200011000100001400002000110001000014000020001100010000140000200011000100
011000000414004020041100410004140040200411004100041400402004110041000414004020041100410004140040200411004100041400402004110041000414004020041100410004140040200411004100
011000000714007020071100710007140070200711007100071400702007110071000714007020071100710007140070200711007100071400702007110071000714007020071100710007140070200711007100
011000000514005020051100510005140050200511005100051400502005110051000514005020051100510005140050200511005100051400502005110051000514005020051100510005140050200511005100
011000000914009020091100910009140090200911009100091400902009110091000914009020091100910009140090200911009100091400902009110091000914009020091100910009140090200911009100
011000000214002020021100210002140020200211002100021400202002110021000214002020021100210002140020200211002100021400202002110021000214002020021100210002140020200211002100
__music__
00 00424344
02 08424344
04 0a0b0c0d
00 12134344
04 13144344
04 191a1b1c
00 41424344
00 41424344
01 22234344
00 22244344
00 22254344
00 22254344
00 22264344
00 22274344
00 22254344
02 22284344

