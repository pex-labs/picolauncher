pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- cherry bomb
-- by lazy devs

function _init()
 --this will clear the screen
 cls(0)
 
 cartdata("cherrybomb")
 highscore=dget(0)
 
 version="v1"
 
 startscreen()
 blinkt=1
 t=0
 lockout=0
 
 shake=0
 flash=0

 debug=""
 
 peekerx=64
 
 -- logo ani --
	fadetable={{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},{1,1,129,129,129,129,129,129,129,129,0,0,0,0,0},{2,2,2,130,130,130,130,130,128,128,128,128,128,0,0},{3,3,3,131,131,131,131,129,129,129,129,129,0,0,0},{4,4,132,132,132,132,132,132,130,128,128,128,128,0,0},{5,5,133,133,133,133,130,130,128,128,128,128,128,0,0},{6,6,134,13,13,13,141,5,5,5,133,130,128,128,0},{7,6,6,6,134,134,134,134,5,5,5,133,130,128,0},{8,8,136,136,136,136,132,132,132,130,128,128,128,128,0},{9,9,9,4,4,4,4,132,132,132,128,128,128,128,0},{10,10,138,138,138,4,4,4,132,132,133,128,128,128,0},{11,139,139,139,139,3,3,3,3,129,129,129,0,0,0},{12,12,12,140,140,140,140,131,131,131,1,129,129,129,0},{13,13,141,141,5,5,5,133,133,130,129,129,128,128,0},{14,14,14,134,134,141,141,2,2,133,130,130,128,128,0},{15,143,143,134,134,134,134,5,5,5,133,133,128,128,0}}

 cls(12)
 spr(10,40,34,6,5)
 cprint("a lazy devs game", 64,80,7)
 cprint("by krystian majewski", 64,86,7)
 
 fadeperc=1
 
 repeat
  dofade()
  fadeperc-=0.07
  flip()
 until( fadeperc<=0 )
 
 fadeperc=0
 dofade()
 for i=0,30 do
  flip()
 end
 
 repeat
  dofade()
  fadeperc+=0.07
  flip()
 until( fadeperc>=1 )
 fadeperc=0
 cls()
 dofade()
 for i=0,10 do
  flip()
 end
 
end

function dofade()
 fadeperc=min(fadeperc,1)
 for c=0,15 do
  pal(c,fadetable[c+1][flr(fadeperc*16+1)],1)
 end
end

function _update() 
 t+=1
 
 blinkt+=1
 
 if mode=="game" then
  update_game()
 elseif mode=="start" then
  update_start()
 elseif mode=="wavetext" then
  update_wavetext()
 elseif mode=="over" then
  update_over()
 elseif mode=="win" then
  update_win()
 end
 
end

function _draw()
 doshake()
 
 if mode=="game" then
  draw_game()
 elseif mode=="start" then
  draw_start()
 elseif mode=="wavetext" then
  draw_wavetext()
 elseif mode=="over" then
  draw_over()
 elseif mode=="win" then
  draw_win()
 end
 
 camera()
 print(debug,2,9,7)

end

function startscreen()
 makestars()
 mode="start"
 music(7)
end

function startgame()
 t=0
 wave=0
 lastwave=9
 nextwave()
 
 ship=makespr()
 ship.x=60
 ship.y=90
 ship.sx=0
 ship.sy=0
 ship.spr=2
   
 flamespr=5
 
 bultimer=0
 
 muzzle=0
 
 score=0
 cher=0
 
 lives=4
 invul=0
 
 attacfreq=60
 firefreq=20
 nextfire=0
 
 makestars()
  
 buls={}
 ebuls={}
 
 enemies={}
 
 parts={}
 
 shwaves={}
 
 pickups={}
 
 floats={}
end

-->8
-- tools

function makestars()
 stars={} 
 for i=1,100 do
  local newstar={}
  newstar.x=flr(rnd(128))
  newstar.y=flr(rnd(128))
  newstar.spd=rnd(1.5)+0.5
  add(stars,newstar)
 end 
end

function starfield()
 
 for i=1,#stars do
  local mystar=stars[i]
  local scol=6
  
  if mystar.spd<1 then
   scol=1
  elseif mystar.spd<1.5 then
   scol=13
  end   
  
  pset(mystar.x,mystar.y,scol)
 end
end

function animatestars(spd)
 if spd==nil then
  spd=1
 end
 
 for i=1,#stars do
  local mystar=stars[i]
  mystar.y=mystar.y+mystar.spd*spd
  if mystar.y>128 then
   mystar.y=mystar.y-128
  end
 end

end

function blink()
 local banim={5,5,5,5,5,5,5,5,5,5,5,6,6,7,7,6,6,5}
 
 if blinkt>#banim then
  blinkt=1
 end

 return banim[blinkt]
end

function drwoutline(myspr)
 spr(myspr.spr,myspr.x+1,myspr.y,myspr.sprw,myspr.sprh)
 spr(myspr.spr,myspr.x-1,myspr.y,myspr.sprw,myspr.sprh)
 spr(myspr.spr,myspr.x,myspr.y+1,myspr.sprw,myspr.sprh)
 spr(myspr.spr,myspr.x,myspr.y-1,myspr.sprw,myspr.sprh)
end

function drwmyspr(myspr)
 local sprx=myspr.x
 local spry=myspr.y
 
 if myspr.shake>0 then
  myspr.shake-=1
  if t%4<2 then
   sprx+=1
  end
 end
 if myspr.bulmode then
  sprx-=2
  spry-=2
 end
 
 spr(myspr.spr,sprx,spry,myspr.sprw,myspr.sprh)
end

function col(a,b)
 if a.ghost or b.ghost then 
  return false
 end

 local a_left=a.x
 local a_top=a.y
 local a_right=a.x+a.colw-1
 local a_bottom=a.y+a.colh-1
 
 local b_left=b.x
 local b_top=b.y
 local b_right=b.x+b.colw-1
 local b_bottom=b.y+b.colh-1

 if a_top>b_bottom then return false end
 if b_top>a_bottom then return false end
 if a_left>b_right then return false end
 if b_left>a_right then return false end
 
 return true
end

function explode(expx,expy,isblue)
 
 local myp={}
 myp.x=expx
 myp.y=expy
 
 myp.sx=0
 myp.sy=0
 
 myp.age=0
 myp.size=10
 myp.maxage=0
 myp.blue=isblue
 
 add(parts,myp)
	  
 for i=1,30 do
	 local myp={}
	 myp.x=expx
	 myp.y=expy
	 
	 myp.sx=rnd()*6-3
	 myp.sy=rnd()*6-3
	 
	 myp.age=rnd(2)
	 myp.size=1+rnd(4)
	 myp.maxage=10+rnd(10)
	 myp.blue=isblue
	 
	 add(parts,myp)
 end
 
 for i=1,20 do
	 local myp={}
	 myp.x=expx
	 myp.y=expy
	 
	 myp.sx=(rnd()-0.5)*10
	 myp.sy=(rnd()-0.5)*10
	 
	 myp.age=rnd(2)
	 myp.size=1+rnd(4)
	 myp.maxage=10+rnd(10)
	 myp.blue=isblue
	 myp.spark=true
	 
	 add(parts,myp)
 end
 
 big_shwave(expx,expy)
 
end

function bigexplode(expx,expy)
 
 local myp={}
 myp.x=expx
 myp.y=expy
 
 myp.sx=0
 myp.sy=0
 
 myp.age=0
 myp.size=25
 myp.maxage=0
 
 add(parts,myp)
	  
 for i=1,60 do
	 local myp={}
	 myp.x=expx
	 myp.y=expy
	 
	 myp.sx=rnd()*12-6
	 myp.sy=rnd()*12-6
	 
	 myp.age=rnd(2)
	 myp.size=1+rnd(6)
	 myp.maxage=20+rnd(20)
	 
	 add(parts,myp)
 end
 
 for i=1,100 do
	 local myp={}
	 myp.x=expx
	 myp.y=expy
	 
	 myp.sx=(rnd()-0.5)*30
	 myp.sy=(rnd()-0.5)*30
	 
	 myp.age=rnd(2)
	 myp.size=1+rnd(4)
	 myp.maxage=20+rnd(20)
	 myp.spark=true
	 
	 add(parts,myp)
 end
 
 big_shwave(expx,expy)
 
end

function page_red(page)
 local col=7
 
 if page>5 then
  col=10
 end
 if page>7 then
  col=9
 end
 if page>10 then
  col=8
 end
 if page>12 then
  col=2
 end
 if page>15 then
  col=5
 end
 
 return col
end

function page_blue(page)
 local col=7
 
 if page>5 then
  col=6
 end
 if page>7 then
  col=12
 end
 if page>10 then
  col=13
 end
 if page>12 then
  col=1
 end
 if page>15 then
  col=1
 end
 
 return col
end

function smol_shwave(shx,shy,shcol)
 if shcol==nil then
  shcol=9
 end 
 local mysw={}
 mysw.x=shx
 mysw.y=shy
 mysw.r=3
 mysw.tr=6
 mysw.col=shcol
 mysw.speed=1
 add(shwaves,mysw)
end

function big_shwave(shx,shy)
 local mysw={}
 mysw.x=shx
 mysw.y=shy
 mysw.r=3
 mysw.tr=25
 mysw.col=7
 mysw.speed=3.5
 add(shwaves,mysw)
end

function smol_spark(sx,sy)
 --for i=1,2 do
 local myp={}
 myp.x=sx
 myp.y=sy
 
 myp.sx=(rnd()-0.5)*8
 myp.sy=(rnd()-1)*3
 
 myp.age=rnd(2)
 myp.size=1+rnd(4)
 myp.maxage=10+rnd(10)
 myp.blue=isblue
 myp.spark=true
 
 add(parts,myp)
 --end
end

function makespr()
 local myspr={}
 myspr.x=0
 myspr.y=0
 myspr.sx=0
 myspr.sy=0
 
 myspr.flash=0
 myspr.shake=0
 
 myspr.aniframe=1
 myspr.spr=0
 myspr.sprw=1
 myspr.sprh=1
 myspr.colw=8
 myspr.colh=8
 
 return myspr
end

function doshake()

 local shakex=rnd(shake)-(shake/2)
 local shakey=rnd(shake)-(shake/2)
 
 camera(shakex,shakey)
 
 if shake>10 then
  shake*=0.9
 else
  shake-=1
  if shake<1 then
   shake=0
  end
 end
end

function popfloat(fltxt,flx,fly)
 local fl={}
 fl.x=flx
 fl.y=fly
 fl.txt=fltxt
 fl.age=0
 add(floats,fl)
end

function cprint(txt,x,y,c)
 print(txt,x-#txt*2,y,c)
end


-->8
--update

function update_game()
 --controls
 ship.sx=0
 ship.sy=0
 ship.spr=2
 
 if btn(0) then
  ship.sx=-2
  ship.spr=1
 end
 if btn(1) then
  ship.sx=2
  ship.spr=3
 end
 if btn(2) then
  ship.sy=-2
 end
 if btn(3) then
  ship.sy=2
 end
  
 if btnp(4) then
  if cher>0 then
   cherbomb()
   cher=0
  else
   sfx(32)
  end
 end
 
 if btn(5) then
  if bultimer<=0 then
	  local newbul=makespr()
	  newbul.x=ship.x+1
	  newbul.y=ship.y-3
	  newbul.spr=16
	  newbul.colw=6
	  newbul.sy=-4
	  newbul.dmg=1
	  add(buls,newbul)
	  
	  sfx(0)
	  muzzle=5
	  bultimer=4
  end
 end
 bultimer-=1
 
 --moving the ship
 ship.x+=ship.sx
 ship.y+=ship.sy
 
 --checking if we hit the edge
 if ship.x>120 then
  ship.x=120
 end
 if ship.x<0 then
  ship.x=0
 end
 if ship.y<0 then
  ship.y=0
 end
 if ship.y>120 then
  ship.y=120
 end
 
 --move the bullets
 for mybul in all(buls) do
  move(mybul)
  if mybul.y<-8 then
   del(buls,mybul)
  end
 end
 
 --move the ebuls
 for myebul in all(ebuls) do
  move(myebul)
  animate(myebul)
  if myebul.y>128 or myebul.x<-8 or myebul.x>128 or myebul.y<-8 then
   del(ebuls,myebul)
  end
 end 
 
 --move the pickups
 for mypick in all(pickups) do
  move(mypick)
  if mypick.y>128 then
   del(pickups,mypick)
  end
 end 
 
 --moving enemies 
 for myen in all(enemies) do
  --enemy mission
  doenemy(myen)
  
  --enemy animation
  animate(myen)
    
  --enemy leaving screen
  if myen.mission!="flyin" then 
   if myen.y>128 or myen.x<-8 or myen.x>128 then
    del(enemies,myen)
   end
  end
 end
 
 --collision enemy x bullets
 for myen in all(enemies) do
  for mybul in all(buls) do
   if col(myen,mybul) then
    del(buls,mybul)
    smol_shwave(mybul.x+4,mybul.y+4)
    smol_spark(myen.x+4,myen.y+4)
    if myen.mission!="flyin" then
     myen.hp-=mybul.dmg
    end
    sfx(3)
    if myen.boss then
     myen.flash=5
    else
     myen.flash=2
    end
    if myen.hp<=0 then
     killen(myen)
    end
   end
  end
 end
 
 --collision ebuls x bullets
 for mybul in all(buls) do
  if mybul.spr==17 then
	  for myebul in all(ebuls) do
	   if col(myebul,mybul) then
	    del(ebuls,myebul)
	    score+=5
	    smol_shwave(ebuls.x,ebuls.y,8)
	   end
	  end
  end
 end
 
 --collision ship x enemies
 if invul<=0 then
	 for myen in all(enemies) do
	  if col(myen,ship) then
    explode(ship.x+4,ship.y+4,true)
	   lives-=1
	   sfx(1)
	   shake=12
	   invul=60
    ship.x=60
    ship.y=100
    flash=3
	  end
	 end
 else
  invul-=1
 end
 
 --collision ship x ebuls
 if invul<=0 then
	 for myebul in all(ebuls) do
	  if col(myebul,ship) then
    explode(ship.x+4,ship.y+4,true)
	   lives-=1
	   shake=12
	   sfx(1)
	   invul=60
    ship.x=60
    ship.y=100
    flash=3
	  end
	 end
 end
 
 --collision pickup x ship
 for mypick in all(pickups) do
  if col(mypick,ship) then
   del(pickups,mypick)
   plogic(mypick)
  end
 end
 
 
 if lives<=0 then
  mode="over"
  lockout=t+30
  music(6)
  return
 end
 
 --picking
 picktimer()
 
 --animate flame
 flamespr=flamespr+1
 if flamespr>9 then
  flamespr=5
 end
 
 --animate mullze flash
 if muzzle>0 then
  muzzle=muzzle-1
 end
  
 if mode=="wavetext" then
  animatestars(2)
 else
  animatestars()
 end
 
 --check if wave over
 if mode=="game" and #enemies==0 then
  ebuls={}
  nextwave()
 end
 
end

function update_start()
 animatestars(0.4)
 
 if btn(4)==false and btn(5)==false then
  btnreleased=true
 end

 if btnreleased then
  if btnp(4) or btnp(5) then
   startgame()
   btnreleased=false
  end
 end
end

function update_over()
 if t<lockout then
  return
 end
 
 if btn(4)==false and btn(5)==false then
  btnreleased=true
 end

 if btnreleased then
  if btnp(4) or btnp(5) then
   if score>highscore then
    highscore=score
    dset(0,score)
   end
   startscreen()
   btnreleased=false
  end
 end
end

function update_win()
 if t<lockout then
  return
 end
 
 if btn(4)==false and btn(5)==false then
  btnreleased=true
 end

 if btnreleased then
  if btnp(4) or btnp(5) then
   if score>highscore then
    highscore=score
    dset(0,score)
   end
   startscreen()
   btnreleased=false
  end
 end
end

function update_wavetext()
 update_game()
 wavetime-=1
 if wavetime<=0 then
  mode="game"
  spawnwave()
 end
end
-->8
-- draw

function draw_game()
 if flash>0 then
  flash-=1
  cls(2)
 else
  cls(0)
 end
 
 starfield()

 if lives>0 then
	 if invul<=0 then
	  drwmyspr(ship)
	  spr(flamespr,ship.x,ship.y+8)
	 else
	  --invul state
	  if sin(t/5)<0.1 then
	   drwmyspr(ship)
	   spr(flamespr,ship.x,ship.y+8)
	  end
	 end
 end
 
 --drawing pickups
 for mypick in all(pickups) do
  local mycol=7
  if t%4<2 then
   mycol=14
  end
  for i=1,15 do
   pal(i,mycol)
  end
  drwoutline(mypick)
  pal()
  drwmyspr(mypick)
 end
 
 --drawing enemies
 for myen in all(enemies) do
  if myen.flash>0 then
   if t%4<2 then
    pal(3,8)
    pal(11,14)
   end
   myen.flash-=1
   if myen.boss then
    myen.spr=80
   else
    for i=1,15 do
     pal(i,7)
    end
   end
  end
  drwmyspr(myen)
  pal()
 end
  
 --drawing bullets
 for mybul in all(buls) do
  drwmyspr(mybul)
 end
 
 if muzzle>0 then
  circfill(ship.x+3,ship.y-2,muzzle,7)
  circfill(ship.x+4,ship.y-2,muzzle,7)
 end
 
 --drawing shwaves
 for mysw in all(shwaves) do
  circ(mysw.x,mysw.y,mysw.r,mysw.col)
  mysw.r+=mysw.speed
  if mysw.r>mysw.tr then
   del(shwaves,mysw)
  end
 end
 
 --drawing particles
 for myp in all(parts) do
  local pc=7

  if myp.blue then
   pc=page_blue(myp.age)
  else
   pc=page_red(myp.age)
  end
  
  if myp.spark then
   pset(myp.x,myp.y,7)
  else
   circfill(myp.x,myp.y,myp.size,pc)
  end
  
  myp.x+=myp.sx
  myp.y+=myp.sy
  
  myp.sx=myp.sx*0.85
  myp.sy=myp.sy*0.85
  
  myp.age+=1
  
  if myp.age>myp.maxage then
   myp.size-=0.5
   if myp.size<0 then
    del(parts,myp)
   end
  end
 end
 
 --drawing ebuls
 for myebul in all(ebuls) do
  drwmyspr(myebul)
 end
 
 --floats
 for myfl in all(floats) do
  local mycol=7
  if t%4<2 then
   mycol=8
  end
  cprint(myfl.txt,myfl.x,myfl.y,mycol)
  myfl.y-=0.5
  myfl.age+=1
  if myfl.age>60 then
   del(floats,myfl)
  end
 end
 
 print("score:"..makescore(score),40,2,12)
 
 for i=1,4 do
  if lives>=i then
   spr(37,i*9-8,1)
  else
   spr(38,i*9-8,1)
  end 
 end

 spr(48,108,1)
 print(cher,118,2,14)
 
 --print(#buls,5,5,7)
end

function makescore(val)
 if val==0 then
  return "0"
 end
 return val.."00"
end

function draw_start()
 cls(0)
 starfield()
 print(version,1,1,1)

 spr(21,peekerx,28+sin(time()/3.5)*4 )
 if sin(time()/3.5)>0.5 then
  peekerx=30+rnd(60)
 end
   
 spr(212,17,30,12,2)
 cprint("short shwave shmup",64,45,6)
 
 if highscore>0 then
  cprint("highscore:",64,63,12)
  cprint(makescore(highscore),64,69,12)
 end

 cprint("press any key to start",64,90,blink())
 
 rectfill(0,115,128,128,1)
 cprint("learn how to make this game!",64,116,12)
 cprint("bit.ly/shmupme",64,122,12)
 
end

function draw_over()
 draw_game()
 cprint("game over",64,40,8) 
 
 cprint("score:"..makescore(score),64,60,12)
 if score>highscore then
  local c=7
  if t%4<2 then
   c=10
  end
  cprint("new highscore!",64,66,c) 
 end
 
 cprint("press any key to continue",64,90,blink())
end

function draw_win()
 draw_game()
 cprint("congratulations",64,40,12)
 cprint("score:"..makescore(score),64,60,12)

 if score>highscore then
  local c=7
  if t%4<2 then
   c=10
  end
  cprint("new highscore!",64,66,c) 
 end

 cprint("press any key to continue",64,90,blink())
end

function draw_wavetext()
 draw_game()
 if wave==lastwave then
  cprint("final wave!",64,40,blink())
 else
  cprint("wave "..wave.." of "..lastwave,64,40,blink())
 end
end
-->8
-- waves and enemies

function spawnwave()
 if wave<lastwave then
  sfx(28)
 else
  music(10)
 end
 
 if wave==1 then
  --space invaders
  attacfreq=60
  firefreq=20
  placens({
   {0,1,1,1,1,1,1,1,1,0},
   {0,1,1,1,1,1,1,1,1,0},
   {0,1,1,1,1,1,1,1,1,0},
   {0,1,1,1,1,1,1,1,1,0}
  })
 elseif wave==2 then
  --red tutorial
  attacfreq=60
  firefreq=20
  placens({
   {1,1,2,2,1,1,2,2,1,1},
   {1,1,2,2,1,1,2,2,1,1},
   {1,1,2,2,2,2,2,2,1,1},
   {1,1,2,2,2,2,2,2,1,1}
  })
 elseif wave==3 then
  --wall of red
  attacfreq=50
  firefreq=20
  placens({
   {1,1,2,2,1,1,2,2,1,1},
   {1,1,2,2,2,2,2,2,1,1},
   {2,2,2,2,2,2,2,2,2,2},
   {2,2,2,2,2,2,2,2,2,2}
  })
 elseif wave==4 then
  --spin tutorial
  attacfreq=50
  firefreq=15
  placens({
   {3,3,0,1,1,1,1,0,3,3},
   {3,3,0,1,1,1,1,0,3,3},
   {3,3,0,1,1,1,1,0,3,3},
   {3,3,0,1,1,1,1,0,3,3}
  })
 elseif wave==5 then
  --chess
  attacfreq=50
  firefreq=15
  placens({
   {3,1,3,1,2,2,1,3,1,3},
   {1,3,1,2,1,1,2,1,3,1},
   {3,1,3,1,2,2,1,3,1,3},
   {1,3,1,2,1,1,2,1,3,1}
  })
 elseif wave==6 then
  --yellow tutorial
  attacfreq=40
  firefreq=10
  placens({
   {2,2,2,0,4,0,0,2,2,2},
   {2,2,0,0,0,0,0,0,2,2},
   {1,1,0,1,1,1,1,0,1,1},
   {1,1,0,1,1,1,1,0,1,1}
  })
  
 elseif wave==7 then
  --double yellow
  attacfreq=40
  firefreq=10
  placens({
   {3,3,0,1,1,1,1,0,3,3},
   {4,0,0,2,2,2,2,0,4,0},
   {0,0,0,2,1,1,2,0,0,0},
   {1,1,0,1,1,1,1,0,1,1}
  })
 elseif wave==8 then
  --hell
  attacfreq=30
  firefreq=10
  placens({
   {0,0,1,1,1,1,1,1,0,0},
   {3,3,1,1,1,1,1,1,3,3},
   {3,3,2,2,2,2,2,2,3,3},
   {3,3,2,2,2,2,2,2,3,3}
  })
 elseif wave==9 then
  --boss
  attacfreq=60
  firefreq=20
  placens({
   {0,0,0,0,5,0,0,0,0,0},
   {0,0,0,0,0,0,0,0,0,0},
   {0,0,0,0,0,0,0,0,0,0},
   {0,0,0,0,0,0,0,0,0,0}
  })
 end  
end

function placens(lvl)

 for y=1,4 do
  local myline=lvl[y]
  for x=1,10 do
   if myline[x]!=0 then
    spawnen(myline[x],x*12-6,4+y*12,x*3)
   end
  end
 end
 
end

function nextwave()
 wave+=1
 
 if wave>lastwave then
  mode="win"
  lockout=t+30
  music(4)
 else
  if wave==1 then
   music(0)
  else
   music(3)  
  end
  
  mode="wavetext"
  wavetime=80
 end

end

function spawnen(entype,enx,eny,enwait)
 local myen=makespr()
 myen.x=enx*1.25-16
 myen.y=eny-66
 
 myen.posx=enx
 myen.posy=eny
 
 myen.type=entype
 
 myen.wait=enwait

 myen.anispd=0.4
 
 myen.mission="flyin"
 
 if entype==nil or entype==1 then
  -- green alien
  myen.spr=21
  myen.hp=3
  myen.ani={21,22,23,24}
  myen.score=1
 elseif entype==2 then
  -- red flame guy
  myen.spr=148
  myen.hp=2
  myen.ani={148,149}
  myen.score=2
 elseif entype==3 then
  -- spinning ship
  myen.spr=184
  myen.hp=4
  myen.ani={184,185,186,187}
  myen.score=3
 elseif entype==4 then
  -- yellow guy
  myen.spr=208
  myen.hp=20
  myen.ani={208,210}
  myen.sprw=2
  myen.sprh=2
  myen.colw=16
  myen.colh=16
  myen.score=5
 elseif entype==5 then
  myen.hp=130
  myen.spr=84
  myen.ani={84,88,92,88}
  myen.sprw=4
  myen.sprh=3
  myen.colw=32
  myen.colh=24
  
  myen.x=48
  myen.y=-24
  myen.posx=48
  myen.posy=25
  
  myen.boss=true
 end
  
 add(enemies,myen)
end
-->8
--behavior

function doenemy(myen)
 if myen.wait>0 then
  myen.wait-=1
  return
 end
 
 --debug=myen.hp
 
 if myen.mission=="flyin" then
  --flying in
  --basic easing function
  --x+=(targetx-x)/n
  
  local dx=(myen.posx-myen.x)/7
  local dy=(myen.posy-myen.y)/7
  
  if myen.boss then
   dy=min(dy,1)
  end
  myen.x+=dx
  myen.y+=dy
  
  if abs(myen.y-myen.posy)<0.7 then
   myen.y=myen.posy
   myen.x=myen.posx
   if myen.boss then
    sfx(50)
    myen.shake=20
    myen.wait=28
    myen.mission="boss1"
    myen.phbegin=t
   else
    myen.mission="protec"
   end
  end
  
 elseif myen.mission=="protec" then
  -- staying put
 elseif myen.mission=="boss1" then
  boss1(myen)
 elseif myen.mission=="boss2" then
  boss2(myen)
 elseif myen.mission=="boss3" then
  boss3(myen)
 elseif myen.mission=="boss4" then
  boss4(myen)
 elseif myen.mission=="boss5" then
  boss5(myen)
 elseif myen.mission=="attac" then  
  -- attac
  if myen.type==1 then
   --green guy
   myen.sy=1.7
   myen.sx=sin(t/45)
   
   -- just tweaks
   if myen.x<32 then
    myen.sx+=1-(myen.x/32)
   end
   if myen.x>88 then
    myen.sx-=(myen.x-88)/32
   end
  elseif myen.type==2 then
   --red guy
   myen.sy=2.5
   myen.sx=sin(t/20)
   
   -- just tweaks
   if myen.x<32 then
    myen.sx+=1-(myen.x/32)
   end
   if myen.x>88 then
    myen.sx-=(myen.x-88)/32
   end   
   
  elseif myen.type==3 then
   --spinny ship
   if myen.sx==0 then
    --flying down
    myen.sy=2
    if ship.y<=myen.y then
     myen.sy=0
     if ship.x<myen.x then
      myen.sx=-2
     else
      myen.sx=2
     end
    end
   end
   
  elseif myen.type==4 then
   --yellow ship
   myen.sy=0.35
   if myen.y>110 then
    myen.sy=1
   else
    
    if t%25==0 then
     firespread(myen,8,1.3,rnd())
    end
   end   
  end
  
  move(myen)
 end
  
end

function picktimer()
 if mode!="game" then
  return
 end

 if t>nextfire then
  pickfire()
  nextfire=t+firefreq+rnd(firefreq)
 end
 
 if t%attacfreq==0 then
  pickattac()
 end
end

function pickattac()
 local maxnum=min(10,#enemies)
 local myindex=flr(rnd(maxnum))
 
 myindex=#enemies-myindex
 local myen=enemies[myindex]
 if myen==nil then return end
 
 if myen.mission=="protec" then
  myen.mission="attac"
  myen.anispd*=3
  myen.wait=60
  myen.shake=60
 end
end

function pickfire()
 local maxnum=min(10,#enemies)
 local myindex=flr(rnd(maxnum))
 
 for myen in all(enemies) do
  if myen.type==4 and myen.mission=="protec" then
   if rnd()<0.5 then
    firespread(myen,12,1.3,rnd())
    return
   end
  end
 end
 
 myindex=#enemies-myindex
 local myen=enemies[myindex]
 if myen==nil then return end
 
 if myen.mission=="protec" then
  if myen.type==4 then
   --yellow guy
   firespread(myen,12,1.3,rnd())
  elseif myen.type==2 then
   --red guy
   aimedfire(myen,2)
  else
   fire(myen,0,2)
  end
 end
end


function move(obj)
 obj.x+=obj.sx
 obj.y+=obj.sy
end

function killen(myen)
 if myen.boss then
  myen.mission="boss5"
  myen.phbegin=t
  myen.ghost=true
  ebuls={}
  music(-1)
  sfx(51)
  return
 end

 del(enemies,myen)   
 sfx(2)
 

 explode(myen.x+4,myen.y+4)
 local cherchance=0.1
 local scoremult=1
 
 if myen.mission=="attac" then
  scoremult=2
  if rnd()<0.5 then
   pickattac()
  end
  cherchance=0.2
 end
 
 score+=myen.score*scoremult
 if scoremult!=1 then
  popfloat(makescore(myen.score*scoremult),myen.x+4,myen.y+4)
 end
 
 if rnd()<cherchance then
  dropickup(myen.x,myen.y)
 end
end

function dropickup(pix,piy)
 local mypick=makespr()
 mypick.x=pix
 mypick.y=piy
 mypick.sy=0.75
 mypick.spr=48
 add(pickups,mypick)
end

function plogic(mypick)
 cher+=1
 smol_shwave(mypick.x+4,mypick.y+4,14)
 if cher>=10 then
  --get a life
  if lives<4 then
   lives+=1
   sfx(31)
   cher=0
   popfloat("1up!",mypick.x+4,mypick.y+4)
  else
   --points
   score+=50
   popfloat(makescore(50),mypick.x+4,mypick.y+4)
   sfx(30)
   cher=0
  end
 else
  sfx(30)
 end
end

function animate(myen)
 myen.aniframe+=myen.anispd
 if flr(myen.aniframe) > #myen.ani then
  myen.aniframe=1
 end
 myen.spr=myen.ani[flr(myen.aniframe)]
end
-->8
--bullets

function fire(myen,ang,spd)
 local myebul=makespr()
 myebul.x=myen.x+3
 myebul.y=myen.y+6
 
 if myen.type==4 then
  myebul.x=myen.x+7
  myebul.y=myen.y+13
 elseif myen.boss then
  myebul.x=myen.x+15
  myebul.y=myen.y+23 
 end
 
 myebul.spr=32
 myebul.ani={32,33,34,33}
 myebul.anispd=0.5
 
 myebul.sx=sin(ang)*spd
 myebul.sy=cos(ang)*spd
 
 myebul.colw=2
 myebul.colh=2
 myebul.bulmode=true
 
 if myen.boss!=true then
  myen.flash=4
  sfx(29)
 else
  sfx(34)
 end
 
 add(ebuls,myebul)
 
 return myebul
end

function firespread(myen,num,spd,base)
 if base==nil then
  base=0
 end
 for i=1,num do
  fire(myen,1/num*i+base,spd)
 end
end

function aimedfire(myen,spd)
 local myebul=fire(myen,0,spd)
 
 local ang=atan2((ship.y+4)-myebul.y,(ship.x+4)-myebul.x)

 myebul.sx=sin(ang)*spd
 myebul.sy=cos(ang)*spd 
end

function cherbomb()
 local spc=0.25/(cher*2)
 
 for i=0,cher*2 do
  local ang=0.375+spc*i
  
  local newbul=makespr()
  newbul.x=ship.x
  newbul.y=ship.y-3
  newbul.spr=17
  newbul.dmg=3
  
  newbul.sx=sin(ang)*4
  newbul.sy=cos(ang)*4
 
  add(buls,newbul)
 end
 
 big_shwave(ship.x+3,ship.y+3)
 shake=5
 muzzle=5
 invul=30
 flash=3
 sfx(33)
 
end
-->8
--boss

function boss1(myen)
 -- movement
 local spd=2
 
 if myen.sx==0 or myen.x>=93 then
  myen.sx=-spd
 end
 if myen.x<=3 then
  myen.sx=spd
 end
 -- shooting
 if t%30>3 then
  if t%3==0 then
   fire(myen,0,2)
  end
 end
 
 -- transition
 if myen.phbegin+8*30<t then
  myen.mission="boss2"
  myen.phbegin=t
  myen.subphase=1
 end
 move(myen)
end

function boss2(myen)
 local spd=1.5
 
 -- movement
 if myen.subphase==1 then
  myen.sx=-spd
  if myen.x<=4 then
   myen.subphase=2
  end
 elseif myen.subphase==2 then
  myen.sx=0
  myen.sy=spd
  if myen.y>=100 then
   myen.subphase=3
  end 
 elseif myen.subphase==3 then
  myen.sx=spd
  myen.sy=0
  if myen.x>=91 then
   myen.subphase=4
  end  
 elseif myen.subphase==4 then
  myen.sx=0
  myen.sy=-spd
  if myen.y<=25 then
   -- transition
   myen.mission="boss3"
   myen.phbegin=t
   myen.sy=0
  end  
 end 
 -- shooting
 if t%15==0 then
  aimedfire(myen,spd)
 end

 move(myen)
end

function boss3(myen)
 -- movement
 local spd=0.5
 
 if myen.sx==0 or myen.x>=93 then
  myen.sx=-spd
 end
 if myen.x<=3 then
  myen.sx=spd
 end

 -- shooting
 if t%10==0 then
  firespread(myen,8,2,time()/2)
 end 
 
 -- transition
 if myen.phbegin+8*30<t then
  myen.mission="boss4"
  myen.subphase=1
  myen.phbegin=t
 end
 move(myen)
end

function boss4(myen)
 local spd=1.5
 
 -- movement
 if myen.subphase==1 then
  myen.sx=spd
  if myen.x>=91 then
   myen.subphase=2
  end
 elseif myen.subphase==2 then
  myen.sx=0
  myen.sy=spd
  if myen.y>=100 then
   myen.subphase=3
  end 
 elseif myen.subphase==3 then
  myen.sx=-spd
  myen.sy=0
  if myen.x<=4 then
   myen.subphase=4
  end  
 elseif myen.subphase==4 then
  myen.sx=0
  myen.sy=-spd
  if myen.y<=25 then
   -- transition
   myen.mission="boss1"
   myen.phbegin=t
   myen.sy=0
  end  
 end 

 -- shooting
 if t%12==0 then
  if myen.subphase==1 then
   fire(myen,0,2)
  elseif myen.subphase==2 then
   fire(myen,0.25,2)
  elseif myen.subphase==3 then
   fire(myen,0.5,2)
  elseif myen.subphase==4 then
   fire(myen,0.75,2)
  end
 end
 -- transition
 move(myen)
end

function boss5(myen)
 myen.shake=10
 myen.flash=10 
 
 if t%8==0 then
  explode(myen.x+rnd(32),myen.y+rnd(24))
  sfx(2)
  shake=2
 end

 if myen.phbegin+3*30<t then
	 if t%4==2 then
	  explode(myen.x+rnd(32),myen.y+rnd(24))
	  sfx(2)
   shake=2
	 end
 end

 if myen.phbegin+6*30<t then
  flash=3
  score+=100
  popfloat(makescore(100),myen.x+16,myen.y+6)
  bigexplode(myen.x+16,myen.y+12)
  shake=15
  enemies={}
  sfx(35)
 end
end
__gfx__
00000000000220000002200000022000000000000000000000000000000000000000000000000000ccccccccccccccccc666cccc7777766c6cccccccccccccc0
000000000028820000288200002882000000000000077000000770000007700000c77c0000077000ccccccccccccccccc777cccc7777776c776cccccccccccc0
007007000028820000288200002882000000000000c77c000007700000c77c000cccccc000c77c00cccccccc77cccccc67776cccccc677ccc77cc777ccccccc0
0007700000288e2002e88e2002e882000000000000cccc00000cc00000cccc0000cccc0000cccc00cccc6ccc77cccccc77777cccccc776ccc6777776cc6cccc0
00077000027c88202e87c8e202887c2000000000000cc000000cc000000cc00000000000000cc000ccc67ccc77cccccc77c77ccccc677ccccc77776ccc76ccc0
007007000211882028811882028811200000000000000000000cc000000000000000000000000000ccc77ccc77ccccc776c776cccc776cccccc776cccc77ccc0
00000000025582200285582002285520000000000000000000000000000000000000000000000000ccc77ccc77ccccc7766777ccc677ccccccc77ccccc77ccc0
00000000002992000029920000299200000000000000000000000000000000000000000000000000ccc77ccc77cccc67777777ccc776ccccccc77ccccc77ccc0
09999000009999000000000000000000000000000330033003300330033003300330033000000000ccc77ccc77666c777666776c7777777cccc776cccc77ccc0
9977990009aaaa9000000000000000000000000033b33b3333b33b3333b33b3333b33b3300000000ccc77ccc77777677cccc676c7777777cccc776cccc77ccc0
9a77a9009aa77aa90000000000000000000000003bbbbbb33bbbbbb33bbbbbb33bbbbbb300000000ccc77ccc7666666cccccccccccccccccccc66ccccc77ccc0
9a77a9009a7777a90000000000000000000000003b7717b33b7717b33b7717b33b7717b300000000ccc77ccccccccccccccccccccccccccccccccccccc77ccc0
9a77a9009a7777a90000000000000000000000000b7117b00b7117b00b7117b00b7117b000000000ccc77cccccccccccc66677cc77cccc666cc666cccc77ccc0
99aa99009aa77aa90000000000000000000000000037730000377300003773000037730000000000ccc77ccc777777ccc77777cc776ccc776c77777ccc77ccc0
09aa900009aaaa900000000000000000000000000303303003033030030330300303303000000000ccc77ccc7777777cc676cccc677cc677cc77667ccc77ccc0
00990000009999000000000000000000000000000300003030000003030000300330033000000000ccc676cc77ccc777c676ccccc77cc776c677cccccc77ccc0
00ee000000ee00000077000000000000000000000880088008800880000000000000000000000000ccc676cc776cc677c67777ccc77cc77cc67776ccc676ccc0
0e22e0000e88e00007cc700000000000000000008888888880088008000000000000000000000000ccc676cc776ccc77c67777ccc676676ccc67777cc676ccc0
e2e82e00e87e8e007c77c70000000000000000008888888880000008000000000000000000000000ccc677cc676cc677c676cccccc7777cccccc677cc676ccc0
e2882e00e8ee8e007c77c70000000000000000008888888880000008000000000000000000000000cccc77cc676c6776c677cccccc7777ccccccc77cc77cccc0
0e22e0000e88e00007cc700000000000000000000888888008000080000000000000000000000000cccc77cc6777777cc677776ccc677cccc776777cc77cccc0
00ee000000ee00000077000000000000000000000088880000800800000000000000000000000000cccc776cc77776ccc66666ccccc76cccc67777ccc77cccc0
00000000000000000000000000000000000000000008800000088000000000000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccc0
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccc666666666666666666666ccccccccccccc0
000bbbb0000000000000000000000000000000000000000000000000000000000000000000000000666667777777777777777777777777777777777777766660
000b0bb000000000000000000000000000000000000000000000000000000000000000000000000077777777777766677667766c6776cc776776777777777770
00b00b00000000000000000000000000000000000000000000000000000000000000000000000000c777776c6776ccc77cc67ccccc7ccc76c67cc7cc7cc77760
00b00880000000000000000000000000000000000000000000000000000000000000000000000000c77777ccc77cc7776ccc76c76c6cc67cc66cc76ccc6777c0
08808788000000000000000000000000000000000000000000000000000000000000000000000000c67777c6c67c7777cc6c76c77c6ccc7cccccc77cc67776c0
87880888000000000000000000000000000000000000000000000000000000000000000000000000cc7777cccc7cc667cccc66c6cc7cc66c7cc6c676c7777cc0
88880880000000000000000000000000000000000000000000000000000000000000000000000000ccc77ccc6c67ccc6c676c6ccc77ccc6c7c67c67cc777ccc0
08800000000000000000000000000000000000000000000000000000000000000000000000000000ccc67c67766776777777777777777777777767766776ccc0
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccc777777777777777777777777777777777777777cccc0
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc77766666ccccccccccccccccccccc66666777ccccc0
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccccccccccccccccccccccccccccccccccc0
00000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccccc7777ccccccccccc7777cccccccccccccc0
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccc67776ccccccc67776ccccccccccccccc0
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccccc677776cc67776ccccccccccccccccc0
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccccccc677777776ccccccccccccccccccc0
00000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccccccccc67776ccccccccccccccccccccc0
00000ee00000bbbbbbbb00000ee0000000000ee00000bbbbbbbb00000ee0000000000ee00000bbbbbbbb00000ee0000000000ee00000bbbbbbbb00000ee00000
ee0008e7e1bbbbbaabbbbb1e7e8000eeee0008e7e1bbbbbaabbbbb1e7e8000eeee0008e7e1bbbbbaabbbbb1e7e8000eeee0008e7e1bbbbbaabbbbb1e7e8000ee
e7e0138873bbbaa77aabbb3788310e7ee7e0138873bbbaa77aabbb3788310e7ee7e0138873bbbaa77aabbb3788310e7ee7e0138873bbbaa77aabbb3788310e7e
8e783b333bbabaa77aababb333b387e88e783b333bbabaa77aababb333b387e88e783b333bbabaa77aababb333b387e88e783b333bbabaa77aababb333b387e8
08e813bbbbbbbba77abbbbbbbb318e8008e813bbbbbbbbbaabbbbbbbbb318e8008e813bbbbbbbbbaabbbbbbbbb318e8008e813bbbbbbbbbaabbbbbbbbb318e80
088811bbbbbbbbbaabbbbbbbbb11888008881133b33bbbbbbbbbb33b3311888008881133b33bbbbbbbbbb33b3311888008881133b33bbbbbbbbbb33b33118880
0011133bbbbb33bbbb33bbbbb331110000113b11bbb3333333333bbb11b3110000113b11bbb3333333333bbb11b3110000113b11bbb3333333333bbb11b31100
00bb113bbabbb33bb33bbbabb311bb0000bb13bb13bbb333333bbb31bb31bb0000bb13bb13bbb333333bbb31bb31bb0000bb13bb13bbb333333bbb31bb31bb00
bb333113bbabbbbbbbbbbabb311333bbbb3331333333bba77abb3333331333bbbb3331333333bba77abb3333331333bbbb3331333333bba77abb3333331333bb
bbbb31333bbaa7bbbb7aabb33313bbbbb7713ee6633333bbbb3333366ee3177bb7713ee6633333bbbb3333366ee3177bb7713ee6633333bbbb3333366ee3177b
3b333313333bbb7777bbb333313333b337113eefff663333333366fffee3117337113eefff663333333366fffee3117337113eefff663333333366fffee31173
c333333bb33333bbbb33333bb333333cc3773efff77f17711111f77fffe3773cc3773efff77f17711111f77fffe3773cc3773efff77f17711111f77fffe3773c
0c3bb3b3bbb3333333333bbb3b3bb3c00c3b3eff777717711c717777ffe3b3c00c3b3eff777717711c717777ffe3b3c00c3b3eff777717711c717777ffe3b3c0
00c1bb3b33bbbb3333bbbb33b3bb1c0000c1b3ef7777711cc7177777fe3b1c0000c1b3ef7777711cc7177777fe3b1c0000c1b3ef7777711cc7177777fe3b1c00
00013bb3bb333bbbbbb333bb3bb3100000013b3eff777711117777ffe3b3100000013b3eff777711117777ffe3b3100000013b3eff777711117777ffe3b31000
0331c3bb33aaa333333aaa33bb3c13300331c3b3eef7777777777fee3b3c13300031c3b3eef7777777777fee3b3c13000031c3b3eef7777777777fee3b3c1300
3bb31c3bbb333a7777a333bbb3c13bb33bb31c3b33eee777777eee33b3c13bb303b31c3b33eee777777eee33b3c13b30003b1c3b33eee777777eee33b3c1b300
3ccc13c3bbbbb333333bbbbb3c31ccc33ccc13c3bb333eeeeee333bb3c31ccc33bcc13c3bb333eeeeee333bb3c313cb303bc13c3bb333eeeeee333bb3c31cb30
00003b3c33bbbba77abbbb33c3b3000000003b3c33bbb333333bbb33c3b300003c003b3c33bbb333333bbb33c3b300cc03c0333c33bbb333333bbb33c3330c30
0003b3ccc333bbbbbbbb333ccc3b30000003b3ccc333bba77abb333ccc3b300000003b3cc333bba77abb333cc3b3000000003b3cc333bba77abb333cc3b30000
00033c003bc33bbbbbb33cb300c3300000033c003bc33bbbbbb33cb300c33000000033c03bc33bbbbbb33cb30c33000000003bc03bc33bbbbbb33cb30cb30000
0003c0003b3c3cb22bc3c3b3000c30000003c0003b3c3cb22bc3c3b3000c300000003c003b3c3cb22bc3c3b300c30000000003c0c3bc3cb22bc3cb3c0c300000
0000000033c0cc2112cc0c33000000000000000033c0cc2112cc0c330000000000000000c330cc2112cc033c00000000000000000c30cc2112cc03c000000000
00000000cc0000c33c0000cc0000000000000000cc0000c33c0000cc00000000000000000cc000c33c000cc0000000000000000000cc00c33c00cc0000000000
00000000000000000000000000070000020000200200002002000020020000205555555555555555555555555555555502222220022222200222222002222220
000bb000000bb0000007700000077000022ff220022ff220022ff220022ff2200578875005788750d562465d0578875022e66e2222e66e2222e66e2222e66e22
0066660000666600606666066066660602ffff2002ffff2002ffff2002ffff2005624650d562465d05177150d562465d27761772277617722776177227716772
0566665065666656b566665bb566665b0077d7000077d700007d77000077d700d517715d051771500566865005177150261aa172216aa162261aa612261aa162
65637656b563765b056376500563765008577580085775800857758008577580056686500566865005d24d50056686502ee99ee22ee99ee22ee99ee22ee99ee2
b063360b006336000063360000633600080550800805508008055080080550805d5245d505d24d500505505005d24d5022299222229999222229922222299222
006336000063360000633600006336000c0000c007c007c007c00c7007c007c05005500505055050050000500505505020999902020000202099990202999920
0006600000066000000660000006600000c7c7000007c0000077cc000007c000dd0000dd0dd00dd005dddd500dd00dd022000022022002202200002202200220
00ff880000ff88000000000000000000200000020200002000000000000000003350053303500530000000000000000000000000000000000000000000000000
0888888008888880000000000000000022000022220000220000000000000000330dd033030dd030005005000350053000000000000000000000000000000000
06555560076665500000000000000000222222222222222200000000000000003b8dd8b3338dd833030dd030030dd03003e33e300e33e330033e333003e333e0
6566665576555565000000000000000028222282282222820000000000000000032dd2300b2dd2b0038dd830338dd833e33e33e333e33e333e33e333e33e333e
57655576555776550000000000000000288888822888888200000000000000003b3553b33b3553b3033dd3300b2dd2b033300333333003333330033333300333
0655766005765550000000000000000028788782287887820000000000000000333dd333333dd33303b55b303b3553b3e3e3333bbe33333ebe3e333be3e3333b
0057650000655700000000000000000028888882080000800000000000000000330550330305503003bddb30333dd3334bbbbeb44bbbebb44bbbbeb44bbbebe4
00065000000570000000000000000000080000800000000000000000000000000000000000000000003553000305503004444440044444400444444004444440
0066600000666000006660000068600000888000002222000022220000222200002222000cccccc00c0000c00000000000000000000000000000000000000000
055556000555560005585600058886000882880002eeee2002eeee2002eeee2002eeee20c0c0c0ccc000000c0000000000000000000000000000000000000000
55555560555855605588856058828860882228802ee77ee22ee77ee22eeeeee22ee77ee2c022220ccc2c2c0cc022220c00222200000000000000000000000000
55555550558885505882885088222880822222802ee77ee22ee77ee22ee77ee22ee77ee2cc2cac0cc02aa20cc0cac2ccc02aa20c000000000000000000000000
15555550155855501588855018828850882228802eeeeee22eeeeee22eeeeee22eeeeee2c02aa20cc0cac2ccc02aa20ccc2cac0c000000000000000000000000
01555500015555000158550001888500088288002222222222222222222222222222222200222200c022220ccc2c2c0cc022220c000000000000000000000000
0011100000111000001110000018100000888000202020200202020220202020020202020000000000000000c000000cc0c0c0cc000000000000000000000000
00000000000000000000000000000000000000002000200002000200002000200002000200000000000000000c0000c00cccccc0000000000000000000000000
000880000009900000089000000890000000000001111110011111100000000000d89d0000189100001891000019810000005500000050000005000000550000
706666050766665000676600006656000000000001cccc1001cccc10000000000d5115d000d515000011110000515d0000055000000550000005500000055000
1661c6610161661000666600001666000000000001cccc1001cccc1000000000d51aa15d0151a11000155100011a151005555550055555500555555005555550
7066660507666650006766000066560000000000017cc710017cc71000000000d51aa15d0d51a15000d55d00051a15d022222222222222222222222222222222
0076650000766500007665000076650000000000017cc710017cc710000000006d5005d6065005d0006dd6000d50056026060602260606022666666226060602
000750000007500000075000000750000000000001111110011111100000000066d00d60006d0d600066660006d0d60020000002206060622222222020606062
00075000000750000007500000075000000000001100001101100110000000000760067000660600000660000060660020606062222222200000000022222220
00060000000600000006000000060000000000001100001101100110000000000070070000070700000770000070700022222220000000000000000000000000
0007033000700000007d330003330333000000000022220000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d3300000d33000028833003bb3bb3000000000888882000000000000000000000000000000000000000000000000000000000000000000000000000000000
0778827000288330071ffd1000884200002882000888882000288200000000000000000000000000000000000000000000000000000000000000000000000000
071ffd10077ffd700778827008ee8e800333e33308ee8e80088ee883000000000000000000000000000000000000000000000000000000000000000000000000
00288200071882100028820008ee8e8003bb4bb308ee8e8008eeee83000000000000000000000000000000000000000000000000000000000000000000000000
07d882d00028820007d882d00888882008eeee800088420008eeee80000000000000000000000000000000000000000000000000000000000000000000000000
0028820007d882d000dffd0008888820088ee88003bb3bb3088ee880000000000000000000000000000000000000000000000000000000000000000000000000
00dffd0000dffd000000000000222200002882000333033300288200000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000077777777777777777777777777777777777777777777777777777777777777777777777777777777777777700000
00000000000000000000000000000000007777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777000
0000149aa94100000000012222100000077778888778877778878888887888887777888887788777788777778888877777788887777887777788788888777700
00019777aa921000000029aaaa920000077888888878877778878888887888888777888888778877887777778888887778888888877888777888788888877700
0d09a77a949920d00d0497777aa920d077788e778878877778878877777887788877887788878877887777778877887778877888877888777888788778877770
0619aaa9422441600619a779442941607788e7777778877778878877777887778877887778877888877777778877887788777888887888878888788778877770
07149a922249417006149a9442244160778877777778888888878888887887788877887788877888877777778888877788778888887888878888788888777770
07d249aaa9942d7006d249aa99442d60778877777778888888878888887888888777888888777788777777778888887788888888887887888788788888877770
067d22444422d760077d22244222d7707788e7777778877778878877777888887777888887777788777777778877e8878888888888788788878878877e887770
0d666224422666d00d776249942677d077788e778878877778878877777887888777887888777788777777778877788778888888877887787788788777887770
066d51499415d66001d1529749251d10077888888878877778878888887887788877887788877788777777778888888778888888877887787788788888887700
0041519749151400066151944a1516600777788887788777788788888878877788878877788877887777777788888e7777788887777887777788788888e77700
00a001944a100a0000400149a4100400007777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777000
00000049a400090000a0000000000a00000077777777777777777777777777777777777777777777777777777777777777777777777777777777777777700000
00000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
0000000000000000000000000000000000000000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000100
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000021200000000000000100000000022102000020000000002200000022212000000000000220000000000000000000000000000000000
00000000000000000000000020000000000000220000000022200000020000000002220000022220000000000000200000200000000000000000d00000000000
00000000000000000000000000000060000000220000000012200200000000000002022000021200000000200022000000000000000000000000000000000000
00000000000000000000000000000000000000020000000022202200002000000022220000000000000000002220000000000000000000000000000000000000
00000000000000000000000000000000002000020000000022200000022000000222220000000200000000002222000000000000200000000000000000000000
00000000000000000000000000000000000000020000000002220000220000000222220000005000000002022220000000000002000000000000000000000000
00000000000000000000000000000000000000020000000012001022200200000222220000002000000020d22200000000000002000000000000000000000000
00000000000000000000000000000000000000002000000022202222200220022222200000000000000220222000020000000220000002000000000000000000
00000000000000000000000000000000000000002000000002202222200222222222200000000000000200222000000000002200000022000000000000000000
00000000000000000600000000000000000000002200000002222222200222222222200000220000000202200000000002022000002222000000000000000000
00000000000000000006000000000000000000000200000002222222222222222222000002200000002000000000000020222000222222000000000000000000
00000000000000000000000000000000000000000000000000222222222222222220000202200000002000000020000222222222222222000000000000000000
00000000006000000000000000000000002000000000000000222222222222222200000022000020022020000200002222222222222222000000000000000000
00000000000000000000002000002000000000000000002000000222222222222022002222000020220000002000022222222222222220000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000077777777777777777777777777777777777777777777777777777777777777777777777777777777777777700000000000000000000
00000000000000000007777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777000000000000000000
00000000000000000077778888778877778878888887888887777888887788777788777778888877777788887777887777788788888777700000000000000000
00000000000000000077888888878877778878888887888888777888888778877887777778888887778888888877888777888788888877700000000000000000
0000000000000000077788e7788788777788788777778877888778877888788778877777788778877788778888778887778887887788777700000d0000000000
000000000000000007788e77777788777788788777778877788778877788778888777777788778877887778888878888788887887788777700000000d0000000
00000000000000000778877777778888888878888887887788877887788877888877777778888877788778888887888878888788888777770000000000000000
00000000000000000778877777778888888878888887888888777888888777788777777778888887788888888887887888788788888877770000000000000000
000000000000200007788e7777778877778878877777888887777888887777788777777778877e8878888888888788788878878877e887770000020000000000
0000000000000000077788e778878877778878877777887888777887888777788777777778877788778888888877887787788788777887770000020000000000
00000000000002000077888888878877778878888887887788877887788877788777777778888888778888888877887787788788888887700000220000000000
000000000000020000777788887788777788788888878877788878877788877887777777788888e7777788887777887777788788888e77700002220000000000
00000000000000000007777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777000022522000000000
00000000000010100000077777777777777777777777777777777777777777777777777777777777777777777777777777777777777700000012121200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000222222200010000
00000000000000000100000000000660606006606660666000000660606060606660606066600000066060606660606066600000000000002212121200000000
00000000000000000200000000006000606060606060060000006000606060606060606060000000600060606660606060600000000000022222222200000000
00000000000000000000000000006660666060606600060000006660666060606660606066000000666066606060606066600010000000121212121200000000
00000000000000000000000000000060606060606060060000000060606066606060666060000000006060606060606060000022000221222122212200000000
00000000000000000000000000006600606066006060060000006600606066606060060066600000660060606060066060000012001212121212120000000000
00030300000303000002000000000000000000000000000000000000000000000000000000000000000000000000000000000022222222200222200000000006
003bbb00003bbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012021212000212100000000000
03071b0000071b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020212221000122000000000000
bb00333b330033000000020200000000000000000000000000000000000000000000000000000000000000000000000000000002021212101210000000000000
1b0000371b0000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000001022122212220000000000000
33000003700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101212121212000000000000
0010000003000120002100000000b000b000b0000000000000000000000000000000000000000000000000000000000000000000212121212121000060033003
0000000000b002b000b0100000b000b000b000b000000000001100000000000000000000000000000011000000000000000000000212121210000000d033b33b
00000000b000b000b020b000000000000000000000011100000001000000000000000000000000101000000000000000000000000121212100000020003bbbbb
000000000000000000000000000000000000000000000000000000001111000000000000001110000000001000000000000000600032321000303002003b7717
0000000000210020012000000000111111111111110000010000000000001111111111111100000000010100001111111111100003bbb12103bbb001000b7117
000000120332133012120000000111111111111111100001011111000000000000000000000000100100000001111111111111303071b2121271b01200003773
0000012133b33b3321202120000111111111111111111000000000111111000000000000001111000000000111111111111113bbb00333b33003302100030330
000000123bbbbbb3111211100001111222225511111111100000000000001111111111111100000000001111111552e222111171b0021371b100001200030000
000000013b7717b321212000000111222222255551111111100000000000000000000000000000001111111111556eee77211103300120372100012000000000
000000001b7117b112101000000111272722666655511111111111110000000000000000000000111111111555666ee22e21110000001001300112100b000b00
033003302137732121212000000111222eee666666555511111111111111111111111111111111111555555566666222ee211100000120000021000b000b000b
33b33bb313b33131111110000001112222effffff6666555555111111111111111111111111115555556666666ffff22ee211100000011010100000000000000
bbbbbbb3b321b131212120000001112e22ffffffffff6665555555111111111111111111115555566666fffffffffffeee211100000020212100000000000000
3b7717b3121112111211130300011323efffffffffffff6666655555555555555555555555555666666ffffffffffffeeee111000000b211b000b00000000000
0b7117b12121212121213bbb00013bbbeffffffff77ffffff6661117777711111111111111111666ffff777f7f7fffffeee1110000b001b120b000b000000000
00377311111111110303071b0001171befffffffff777f7fffff1117777711111111ccc1111116fffff777777777ffffeee11100000001111000000000000000
03033031212001203bbb00333b331133efffffff777777777fff11177777711111111ccc11111ffff77777777777ffffeee11100000000212001200000000000
0300013111100010071b0000371b11eeeffffff777777777f7771117777771111111cccc77117777777777777777ffffeee11100000001111131300000303000
0001212121210021203300000370111eeefffff777777777777771117777111111111cc77711777777777777777fffffeee111000000212123bbb00003bbb000
0011111111110111101000000003111eeefff3fff37773777777711177771111111ccc777111777777777777777ffffeeee11100000011313071b0000071b000
00211121012001001120000000001111eee3fff3777377737777771111111c1c1cccc77711117777777777777f7fffeeee111020000003bbb00333b330033000
00111111011100111110000000000111eeeffffff7777777777777111111cccccccc777111177777777777f777ffffeeee11100000000171b0000371b0000000
0000210000012b110b000b00000000111eeefffffffff777777777711111cccccccc771111777777777f777ff7fffeeee1110001000001133100003700000000
00000000000b111b010b000b0100000111eeeeffffff77777777777711111ccccc111111777777777fff7777ffffeeee11303000003031111100000030000000
00000000000011210000000000000000111eeeeffffff777777777777111111111111177777777777777f77fffeeeee113bbb00003bbb0211000000000000000
000000001000111100000000000000000111eeeeffffff7f7777777777771111111777777777777777777ffffeeeee313171b0000071b1110000000000000000
000000000110211000000000000000000011eeeeeeffff9777777777777777777777777777777777777ffffeeeeee3bbb00333b330033111000000000b000b00
000b000b000001100000110000000000000111e9eeeaff9ff777777777777777777777777777777737ff3fee3ee11171b0000371b00001100000000b000b000b
0b000b000b00010000011a000000000000001aaeeeeeeeffff777777777777777777777777777737ff3fee3eee31111330000037000011110000000000000000
000000000000000000100a00a000a000a00099991eeeeeeeeff7777777777777777777777777777ffeeeeeee1111110000000000300111110010000000000000
000000000000000006009100000a0000aa99aaa99a1eee77eeaff777777777777777777777777fffee77ee111111100000000000000111100110000000000000
00000100000001100000099990000a009aaa7777aa191eaeeeeeff777777777777777777777ffeeee7eee1111110000000000000103311331100000000330033
00000130300100313a099aaaa99000069a77777777a99aeeeeeeeeee77777777777777777eeeeeeeeee1111111000b000b000b00033b33b331000000033b33b3
000003bbb00103bbba09a7777a900a099aaaa777777aaa991eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1111111000b000b000b000b03bbbbbb3000000003bbbbbb
00303071b0010071b19a777777a9009aa7777aa77777a7aa99a1eeee7ee77e77777e77ee7eeeeee111111100000000000000000003b7717b3000000003b7717b
03bbb00333b33013319a777777a909a77777777a7777a777aa91111eeeeaeeeeeeeeeeeeea11111111111000000000000033003301b7117b0000000000b7117b
0071b0000371b010019a777777a99a7777777777a7777a777a991a11a777711a1111111a111111111100000000000000033b33b3300377300033003300037730
0003300100370000009a777777a99a7777777777a7777a7779911a1aa9a97a1111111a1a9aa9a111770000000000000003bbbbbb30303303033b33b330303303
0000000000003000a119a7777a99a777777777777a777a9777aa09a7777aa91a111119a777a7a907770000000000000003b7717b3130000303bbbbbb30300003
000000000000100011119aaaa999a777771777777a777a9aa99909a7a777a7aa9aa977777a7779a0700000000000000000b7117b0001111103b7717b30000000
000000010000009011111999aaaaa777772177777a77a7a777a9a77777a77777a77a977777777a947700000000000000000377300001001000b7117b00000000
000000000000000011a1119a7777a777777227777a7a77a777a97777777777779777a7777a777957772240000000000000303303000001010103773000000000
0000000100010011a111a9a777777a7777772177aaa77797779a77777777777aa99a7a7777f99e07999922000000000000300003100011100130336300000000
0000000000001111111119a777777a7777777217a77777779a77777777a7777997177aaaa7ff490a9a4400020000000000000000010000000030000300000000
0000000000011111111119a777777aa7777772201777777aa777a777777a77a7229aa77a7ffffaa4424200020000006000010000000000000110000000000000
00000000000011111011199777777a9aa7777a210a7777aa11111aaaa9779772277777777fffaf44222020000000000000010000000000011000000000000000
0000000000011111000a119a7777a9199aaaa992011aaa1117c1c117a777402277777777ffffffa9240000000000000100000000000000110000000000000000
000000000000101100001119aaaa9119099990000015111c11111111770022f7f7777777ffffff99402200000000000000100000000000010110000001000000
0000000000000011aaa1111aa99900110000a221005111111010100110002fff7777777fffffff44000200000000000001000000000000000000000000000000
000000000000000000001a111000000aa000788211121111211221211005f4ff7f7777ffffffe444400000000000000010000000000000000000000000000000
00000000000000000000000011a000000007128821122100cc0110211005f267f7ff7ff7fffffa94400000600000000100000000000000000000000000000000
000000000000000000000001010011000a7702882122000c77c01012215514fffa7fff7ffffff999400000000200000000000001000000000000000000000000
0000000000000000000000000000000aa7a00288822011c7777c10212102244ffe7afffe7fffff44440000000000000000600000000000000000100000000000
000000000000000000000010000000a77a110288222015c7777c51022228849ffea7aff4fff4fffe622060000000000000000000000000000001000000000000
00000000000000000000000110000a777a1100228110110c77c515021288899f44e77af4fff24e44424400000000010000000000000000000000111000000000
0000000000000000011000061000a777a101128881101500cc05151022884a9f24fa7ae24fe20e90442260000000100000000000000000000000000100000000
000000000000000001000000000a777a0000228810cc01d00011c15104224494050a77a24ef40540044200000000000000000000000000000000001000000000
0000000000000000000000000aa777a0100028820c77c001010ccc01508202420f00a77a44e20022002200000000100000000000000000010001000000000000
000000000000000000000010a7777a0110112882c7777c0001c777c0108222000440a77a40402001000010000101100000000000000000000010000000000000
0000000000024442eeeeeeeee777a10110012811c7777c011cc777cc1082222001002a77a0402001000000001000000000000000000100001000000000000000
0000000000000002228888888eeeeeeeeeeeee251c77c0d0d1c777c01082020000002a77a2442000110000011010110010000000000110000100000000000000
00000000d000000000222228888888888888ee2160cc0150d10ccc0110826000000020a77a411200000000010000000000000000100100000010000000000000
0000000000000000001001122288888888888e20d1000100d500c00110222200000221a777a10000111001011110100100000000010101100001000000000000
0000000000000001001002211222122222222851111100000d100550022022211111110a777a0111100000111111001000000100000100110000000000000000
00000000000000000000012221111111112222515100000000d111001222211111111010a777a111110000110111111000000000001000000000100000000000
000000000000110000000001111111111111121111100000000110001222222eeeee0000a777a211111000010000100001000100000100001000110000000000
00000000000011000000000111111111c11111111011111111111111022221888888888eeeeea110111111111000011000011000000110001100010000000000
00000000000000000000000111111111111111111000001111111111000012228888888888888eeee10000111000110000011100000110001100000000000000
0000000000000000000000000000111111111100111000000000010000111112221122222288888888420000000111010001010d000010000000000000000000
00000000000000000000000000011111111110000110000000000000111100010010011021121122222200000011000000010000000000000000000000000000
00000000000000000000000000001111111100000000100000000000010100111111000012212101101000000000001000001010000000100000000000000000
00000000000000010000000000111111111110000000000110000000000111111111111111221111000111000000001000001111000000000000000000000000
00000000000000000000000011111111111101001000000000010000011111111111111111111001000010000000000000000110010000000000000000000000
00000000000000000000000010110111100000000000000000000000010011111111111111111110011000100000000000000000000000000000000000000000
00000000000000000000000001001101100000000000000000000001001111011111111111111100000010000000000000000000000000000100000010000000
00000000000000000000000101001010010000000000000100000000001100111111111111111000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000001000000000000000000000111111111111000000011000000000000000000000000000000000000000000000
00000000000000000000000000000000000000001000000000000000000000011111111110001000000000000000000000000000000000000000000000000000
000000000000000000000d0000000000000000000000000000000000001000011101111111110000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000001001111000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000001000100001000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000001110000001000000000000000000000010000000000000000000000000000
00000000000000000000000001000001000000000000000000000000000000000011100101000100d00000000600000000000000000000000000000000000000

__sfx__
000100003452032520305202e5202b520285202552022520205201b52018520165201352011520010200f5200c5200a5200852006520055200452003510015200052000000000000000000000000000100000000
000100002b650366402d65025650206301d6201762015620116200f6100d6100a6100761005610046100361002610026000160000600006000060000600006000000000000000000000000000000000000000000
00010000377500865032550206300d620085200862007620056100465004610026000260001600006200070000700006300060001600016200160001600016200070000700007000070000700007000070000700
000100000961025620006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
00060000010501605019050160501905001050160501905016050190601b0611b0611b061290001d000170002600001050160501905016050190500105016050190501b0611b0611b0501b0501b0401b0301b025
00060000205401d540205401d540205401d540205401d54022540225502255022550225500000000000000000000025534225302553022530255301d530255302253019531275322753027530275322753027530
000600001972020720227201b730207301973020740227401b74020740227402274022740000000000000000000001672020720257201b730257301973025740227401b740277402274027740277402774027740
011000001f5501f5501b5501d5501d550205501f5501f5501b5501a5501b5501d5501f5501f5501b5501d5501d550205501f5501b5501a5501b5501d5501f5502755027550255502355023550225502055020550
011000000f5500f5500a5500f5501b530165501b5501b550165500f5500f5500a5500f5500f5500a550055500a5500e5500f5500f550165501b5501b550165501755017550125500f5500f550125501055010550
011000001e5501c5501c550175501e5501b550205501d550225501e55023550205501c55026550265500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000017550145501455010550175500b550195500d5501b5500f5501c550105500455016550165500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090d00001b0001b0001b0001d0001b0301b0001b0201d0201e0302003020040200401e0002000020000200001b7001d7001b7001b7001b7001d700227001a7001b7001b700167001b7001b7001b7001c7001c700
050d00001f5001f0001f500215001f5301f0001f52021520225302453024530245302250024500245002450000000000000000000000000000000000000000000000000000000000000000000000000000000000
010d00002200022000220002400022030220002203024030250302703027030270302500027000270002700000000000000000000000000000000000000000000000000000000000000000000000000000000000
4d1000002b0202b0202b0202b0202b0202b0202b0202b0202b020290202b0202c0202b0202b0202b0202602026020260202702027020270202b0202b0202b0202a0302a0302a0302703027030270302003020030
4d1000002003028030280302c0302a0302a0302a0302703027030270302c0302a030290302e0302e0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00001e050000001e0501d0501b0501a0601a0621a062000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
050f00001b540070001b5401a54018540175501755217562075000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000
010c0000290502c0002a00029055290552a000270502900024000290002705024000240002400027050240002a05024000240002a0552a055240002905024000240002400029050240002a000290002405026200
510c00001431519315203251432519315203151432519325203151431519325203251431519315203251432519315203151432519325203151431519325203251431519315203251432519315203151432518325
010c00000175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750
010c0000195502c5002a50019555195552a500185502950024500295001855024500245002450018550245001b55024500245001b5551b555245001955024500245002450019550245002a500295001855026500
010c0000290502c0002a00029055290552a000270502900024000290002000024000240352504527050240002a050240002f0052d0552c0552400029050240002400024000240002400024030250422905026200
010c0000195502c5002a50019555195552a500185502950024500295002050024500145351654518550245001b550245002f5051e5551d5552450019550245002450024500245002450014530165401955026500
010c00002c05024000240002a05529055240002e050240002400029000270502400024000240002e050240003005024000240002e0552d05524000300502400024000290002905024000270002a0002900028000
510c0000143151931520325143251931520315163251932516315183151932516325183151931516325183251b3151e315183251b3251e315183151b3251e325183151b3151d325183251b3151d315183251b325
010c00000175001750017500175001750017500175001750037500375003750037500375003750037500375006750067500675006750067500675006750067500575005750057500575005750057500575005750
010c00001d55024500245001b55519555245001e550245002450029500165502450024500245001e550245001e55024500245001d5551b555245001d5502450024500295001855024500275002a5002950028500
11050000385623555233552315522f5522d5522b5522954227552265522355222552215521e5421d5421a5421854217542155421454212542105420e5420d5320b53209522075120551203512015120051200512
48020000173520f302113420932208322073200735000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
080c000013056170661c06620066220362905631036320063600632006270061f0061900617000120002a00027000000000000000000000000000000000000000000000000000000000000000000000000000000
000a0000070560c0660f07616076180661f056220472703733037330573c0673e0062b00625006200061b0061700614006110060f0060d0060c0060a006090060600606006050060500600000000000000000000
000400000744007420074200a40000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
4a0200002c6412f66130661316613766132661326612b6612866125671226611e661146611a651166510864111641056410c64105641046410264102631026310163101621006210062100611006110061100611
010100000914008150081600f160121400f1400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020400003b6702b6403b67021620376702867031670266502c6502a650276502565022650206501d6501b6501965017640166401464012640106400d6400c6300a63008620076200562004620026200162000620
010a00000c4200c4200c4200c4200c4200c4200c4200c4200f4200f4200f4200f4200f4200f4200f4200f42010420104201042010420104201042010420104201442014420144201442014420144201442014420
010a00000532105320053200532005320053200532005320083200832008320083200832008320083200832009320093200932009320093200932009320093200d3200d3200d3200d3200d3200d3200d3200d320
000a002034615296152b6161e6061c6401d6452b6152760528615296152b6151e6001c6401d6452b6152761534615296152b6161e6061c6401d6452b6152760528615356152b6151e6051c6401d6452b61527615
050a00200232002320023200232002320023200232002320023200230502325023250232002325023200232503320033200332003320033200332003320033200732007320073200732007320073200732007320
010a000002320023200232002320023200232002320023200a3200a3200a3200a3200a3200a3200a3200a32005320053200532005320053200532005320053200332003320033200332003320033200332003320
010a000009220092200922009220092200922009220092200e2200e2200e2200e2200e2200e2200e2200e2200a2200a2200a2200a2200a2200a2200a2200a2200022000220002200022001220012200122001220
010a000005220052200522005220052200522005220052200e2200e2200e2200e2200e2200e2200e2200e2200a2200a2200a2200a2200a2200a2200a2200a2200022000220002200022001220012200122001220
010a00000d2200d2200d2200d2200d2200d2200d2200d220052200522005220052200522005220052200522011220112201122011220112201122011220112200322003220032200322003220032200322003220
150a00001522015220152201522015220152201522015220152201522015220152201322013220152201522016220162201622016220162201622016220162201922019220192201922019220192201922019220
150a00001a2201a2201a2201a2201a2201a2201a2251a2251d2201d2201d2201d2201d2201d2201d2201d22019220192201922019220192201922019220192201622016220162201622016220162201622016220
150a0000192201922019220192201922019220192251922511220112201122011220112201122011220112201d2201d2201d2201d2201d2201d2201d2201d22018220192211a2211d22121221252212622126221
090a00001d2171a217212172221729217262172d2172e2171d2171a2172121722217112170e21715217162171d2171a217212172221729217262172d2172e2171d2171a2172121722217112170e2171521716217
090a000029217262172d2172e2173521732217392173a21729217262172d2172e2171d2171a2172121722217112170e21715217162171d2171a2172121722217112170e21715217162170521702217092170a217
010a00000e003296000e0031e600286151d6052b605276150e003296052b6151e600286151d6452b615276051f6501f6301f6201e6001f6251f6251f625276050e003356052b6051e605106111c6112862133631
5c030000131212513131151381711b1613b1513b1413c14116141291413913135131321312d13228132221321c13216132131321d1320e1320d1320a132091320813206122051220412203122031220312201120
5c0400000817120161181610f17108171171711017109171071710d1610f161091510715106151051410514105132041320313202132021320113201132001320113201132011320112200122001220012200122
__music__
04 04050644
00 07084749
04 090a484a
04 0b0c0d44
00 0e084344
04 0f0a4344
04 10114e44
01 12131415
00 16131417
02 18191a1b
00 24256844
01 26272844
00 26282966
00 26272a65
00 262a2b65
00 26272c44
00 26292d44
00 26272c44
00 262a2e44
00 28292f44
00 28293044
00 272b2f44
02 25243144

