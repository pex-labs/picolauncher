pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- mOT'S gRAND pRIX pLUS
-- bY mOT
-- tITLE aRT BY mARCO vALE

glob={
	["true"]=true,
	["false"]=false
}

function dataint(lines,props,globname)
 local d={}
 for l in all(lines) do
  local o,v={},split(l)
  for i,val in ipairs(v) do
   if val~="" then
    if(glob[val]~=nil)val=glob[val]
	   o[props[i]]=val
	  end
  end
  if o.name then
  	d[o.name]=o
  	if(globname)glob[globname.."."..o.name]=o
		end
  add(d,o)
 end
 return d
end

function data(str,globname)
 local lines=split(str,chr(10))
 local props=split(deli(lines,1))
 return dataint(lines,props,globname)
end

function datahdr(propstr,str,globname)
 return dataint(split(str,chr(10)),split(propstr),globname)
end

function sort(array,compfn)
 for i=2,#array do
  local c,j=array[i],i
  while j>1 and compfn(array[j-1],c) do
   array[j]=array[j-1]
   j-=1
  end
  array[j]=c
 end
end

-- shared animation code
-- tHIS TAB CONTAINS ALL CODE 
-- NECESSARY TO LOAD AND PLAY
-- ANIMATIONS.

-- constants
animfilever=1

-- routines

function runcoroutines(co)
	for c in all(co) do
		if costatus(c)=="dead"then
			del(co,c)
		else
			assert(coresume(c))
		end
	end
end

function lerp(a,b,f)
 return (1-f)*a+f*b
end

easefn={
 function(v) return v end,
 function(v) return  -sin(v/4) end,
 function(v) return 1-cos(v/4) end,
 function(v) return 0.5-cos(v/2)/2 end
}

function clamp(v,mn,mx)
	return min(max(v,mn),mx)
end

function sprcoords(n)
	return (n%16)*8,flr(n/16)*8
end

function tilecoords(n)
 return n%128,flr(n/128)
end

function smap(cx,cy,cw,ch,sx,sy,sw,sh,flipx,flipy)
 -- delta
 local dx,dy=cw/sw,ch/sh
 
 -- apply flip
 if flipx then
  cx+=cw
  dx=-dx
 end
 if flipy then
  cy+=ch
  dy=-dy
 end
 
 local x0,x1=sx,sx+sw
 local y0,y1=sy,sy+sh
 cx+=(ceil(x0)-x0)*dx
 cy+=(ceil(y0)-y0)*dy
 x0,y0,x1,y1=ceil(x0),ceil(y0),ceil(x1)-1,ceil(y1)-1

 -- render with tlines
 for y=y0,y1 do
  tline(x0,y,x1,y,cx,cy,dx,0)
  cy+=dy
 end
end

-- file i/o

-- stream helpers

function read2(self)
 return self:read1()|(self:read1()<<8)
end

-- memory stream

function mem_size(self)
	return self.addr-self.baseaddr
end

function mem_r1(self)
 local v=peek(self.addr)
 self.addr+=1
 return v
end

function readmemstream(addr)
	return {
		baseaddr=addr,
		addr=addr,
		size=mem_size,
		read1=mem_r1,
		read2=read2
	}
end

-- hex string stream

function fromhexchar(c)
 return ord(c)-(c>"9" and 87 or 48)
end

function str_size(self)
	return #self.str/2
end

function str_r1(self)
 local str,offs=self.strs[flr(self.offs>>10)+1],self.offs&0x3ff
 offs+=1
 local hi=fromhexchar(sub(str,offs,offs))
 offs+=1
 local lo=fromhexchar(sub(str,offs,offs))
 self.offs+=2
 return (hi<<4)|lo
end 

function readstrstream(strs)
	return {
		strs=strs,
		offs=0,
		size=str_size,
		read1=str_r1,
		read2=read2
	}
end

-- helper functions

function readstrfixed(stream,len)
	local result=""
	for i=1,len do
		result..=chr(stream:read1())
	end
	return result
end

function readstr(stream)
	local len=stream:read1()
	return readstrfixed(stream,len)
end

-- file io

function loadanims(stream)
	printh("*** loading animations ***")

	-- verify header and version
	local hdr=readstrfixed(stream,3)
	if hdr~="mas" then
		printh("'mas' header not found")
		stop()
	end
	
	local ver=stream:read1()
	if ver>animfilever then
		printh("unsupported file version: "..ver)
		stop()
	end
	
	-- load each animation
	local ct=stream:read1()
	local anims={}
	for i=1,ct do
		local typ=stream:read1()
		local anim
		if typ==1 then
			anim=loadspriteanim(stream)
		else
		 anim=loadtlanim(stream,typ)
		end
		add(anims,anim)
		anims[anim.name]=anim
	end
	
	-- convert indices into references
	for anim in all(anims) do
	 if anim.typ~="sprite" then
	  for tl in all(anim.tls) do
	   for k in all(tl.keyframes) do
	    k.anim=k.anim and anims[k.anim]
	   end
	  end
	 end
 end

	return anims
end

function loadspriteanim(stream)
	local anim=makespriteanim()
	
	-- properties
	anim.name=readstr(stream)
	anim.fps=stream:read1()/4
	anim.w=stream:read1()
	anim.h=stream:read1()
	anim.ox=stream:read1()/100
	anim.oy=stream:read1()/100
	anim.tr=stream:read1()

	-- frames
	anim.frames={}
	local ct=stream:read1()
	for i=1,ct do
		local frame={}
		frame.frame=stream:read2()
		local flags=stream:read1()
		frame.flipx=(flags&1)==1
		frame.flipy=(flags&2)==2
		add(anim.frames,frame)
	end
	
	return anim   
end

function loadtlanim(stream,typ)
 local anim=maketlanim()
 if(typ==3)anim.typ="storyboard"
 
	-- properties
	anim.name=readstr(stream)
	anim.d=stream:read2()/100
	
	-- timelines
	anim.tls={}
	local ct=stream:read1()
	for i=1,ct do
	 local keyframes={}
	 local kct=stream:read1()
	 for j=1,kct do
	 
	  -- time
	  local t=stream:read2()/100
	  local k=makekeyframe(t)
	  
	  -- content 
	  local flags=stream:read1()
	  if (flags&1)~=0 then 
	  	k.anim=stream:read1()		-- will be converted to object reference later
			end
	  if (flags&2)~=0 then
	  	k.x=stream:read2()
	  	k.y=stream:read2()
	  end
	  if (flags&4)~=0 then
	   k.xscale=stream:read2()/100
	   k.yscale=stream:read2()/100	   
	  end
	  if (flags&8)~=0 then
	   k.animt=stream:read2()/100
	   k.animspd=stream:read2()/100
	  end 
	  
	  -- state flags
	  flags=stream:read1()
	  k.flipx=(flags&1)~=0
	  k.flipy=(flags&2)~=0
	  k.visible=(flags&4)~=0
	  k.loop=(flags&8)~=0
	  k.easein=(flags&16)~=0
	  k.easeout=(flags&32)~=0
	  
	  k.tag=stream:read1()
	  
	  add(keyframes,k)
	 end
	 add(anim.tls,{keyframes=keyframes})	 
	end
	
	-- events
	anim.events.keyframes={}
	local ct=stream:read1()
	for i=1,ct do
	
  -- time
  local t=stream:read2()/100
	 local k=makeevent(t)
	 
	 -- type
	 k.typ=readstr(stream)
	 local flags=stream:read1()
	 if (flags&1)~=0 then
  	k.x=stream:read2()
  	k.y=stream:read2()	 	
  end
  if (flags&2)~=0 then
   k.n=stream:read1()
  end
  if (flags&4)~=0 then
   k.txt=readstr(stream)
  end	 
  add(anim.events.keyframes,k)
	end
	
	return anim
end

-- sprite animations

function drawanim(
		self,
		t,
		x,y,
		xscale,yscale,
		flipx,flipy,
		dt)
		
 self:dodraw(
 	t or 0,
 	x or 64,
 	y or 64,
 	xscale or 1,
 	yscale or 1,
 	flipx,
 	flipy,
 	dt or 1/(_update and 30 or 60),
 	0)
end

function spriteanim_draw(self,t,x,y,xscale,yscale,flipx,flipy)

	-- find frame
	local f=clamp(flr(t*self.fps)+1,1,#self.frames)
	local frame=self.frames[f]

	-- display width and height
	local dw,dh=self.w*8*xscale,self.h*8*yscale
	
	-- flip flags
	if(frame.flipx)flipx=not flipx
	if(frame.flipy)flipy=not flipy

	-- adjust for orgin pt
	x-=dw*(flipx and (1-self.ox) or self.ox)
	y-=dh*(flipy and (1-self.oy) or self.oy)

	-- draw
	-- as tilemap coords
	palt(0,false)
	palt(self.tr,true)
	local cx,cy=tilecoords(frame.frame)
	smap(
	 cx,cy,
	 self.w,self.h,
	 x,y,
	 dw,dh,
	 flipx,flipy)
 palt(self.tr,false)	
	palt(0,true)
end

function spriteanim_duration(self)
	return #self.frames/self.fps
end

function makespriteanim()
	return {
		typ="sprite",
		name="sprite",
		fps=10,
		w=1,h=1,
		ox=0.5,oy=0.5,
		tr=16,
		frames={
			makespriteframe(1),
		},
		duration=spriteanim_duration,
		dodraw=spriteanim_draw,
		draw=drawanim
	}
end

function makespriteframe(n)
	return {
		frame=n--,
--		flipx=false,
--		flipy=false
	}
end

-- timelined animations

function tlanim_duration(self)
	return self.d
end

keyframeswitch=split("anim,animt,animspd,tag")
keyframelerp=split("x,y,xscale,yscale")
keyframeflags=split("flipx,flipy,visible,loop")

function findrefkeyframes(tl,prop,t)
 -- find nearest frames before/after t
 -- where property is not null
 local before,after
 local beforet,aftert=-1000,1000
 for k in all(tl.keyframes) do
  if k[prop] then
   if k.t<=t and k.t>beforet then
    before,beforet=k,k.t
   end
   if k.t>t and k.t<aftert then
    after,aftert=k,k.t
   end
  end
 end
 return before,after
end

function getvirtualkeyframe(tl,t)

 -- calculate the effective 
 -- "virtual" keyframe at time t
 -- on the timeline, interpolating
 -- as necessary.
 local props={
  visible=true,
  animt=0,animspd=1,
  x=0,y=0,
  xscale=1,yscale=1,
  flipx=false,flipy=false,
  easein=false,easeout=false
 }

	-- switchover properties
 local animtt				
	for prop in all(keyframeswitch) do
	 before,after=findrefkeyframes(tl,prop,t)
	 local frame=before or after
	 if(frame)props[prop]=frame[prop]
		if prop=="animt" then
		 animtt=before and before.t
		end
	end

	-- interpolated properties
	for prop in all(keyframelerp) do
	 before,after=findrefkeyframes(tl,prop,t)
  if before and after then
   local f=(t-before.t)/(after.t-before.t)
   if prop=="x" or prop=="y" then
    local e=1
    if(after.easein)e+=1
    if(before.easeout)e+=2
    f=easefn[e](f)
   end
   props[prop]=lerp(before[prop],after[prop],f)
  else
		 local frame=before or after
		 if(frame)props[prop]=frame[prop]
		end			  
	end
	
	-- flags
	before,after=findrefkeyframes(tl,"t",t)
	local k=before or after
	if k then 
	 for prop in all(keyframeflags) do
	  props[prop]=k[prop]
	 end
	end
	
	-- calculate effective animt
	-- at time t, taking into account
	-- animation speed an looping.
	if animtt then
	 props.animt+=(t-animtt)*props.animspd
	end
	if props.loop and props.anim then
	 props.animt%=props.anim:duration()
	end
	return props
end

function tlanim_draw(self,t,x,y,xscale,yscale,flipx,flipy,dt,r)
 -- recursion limit
 r+=1
 if(r>10) return
 
 -- draw anims for each timeline
 for tl in all(self.tls) do

  -- get effective keyframe for t
		local props=getvirtualkeyframe(tl,t)
		
		-- draw child animation
		if props.visible and props.anim then
		
		 -- calculate effective position,scale and flip
		 local cx=x+props.x*xscale*(flipx and -1 or 1)
		 local cy=y+props.y*yscale*(flipy and -1 or 1)
		 local cxscale,cyscale=xscale*props.xscale,yscale*props.yscale
		 local cflipx,cflipy=flipx,flipy
   if(props.flipx)cflipx=not cflipx
   if(props.flipy)cflipy=not cflipy
   local cdt=dt and dt*props.animspd
		 
		 -- draw
		 if not anim_draw or anim_draw(props,cx,cy,cxscale,cyscale,cflipx,cflipy,cdt,r) then
			 props.anim:dodraw(props.animt,cx,cy,cxscale,cyscale,cflipx,cflipy,cdt,r)
			end
		end		
	end
	
	-- trigger events
	if dt then
	 for k in all(self.events.keyframes) do
	  if k.t>t-dt and k.t<=t and anim_events[k.typ] then
    anim_events[k.typ](k,x,y)
	  end
	 end
	end	
end

function makekeyframe(t)
	return {
		t=t,
		anim=nil,
		loop=true,
		after=false,
--		animt=nil,
--		animspd=nil,
--		x=nil,
--		y=nil,
--		xscale=nil,
--		yscale=nil,
		visible=true,
		flipx=false,
		flipy=false,
		easein=false,
		easeout=false,
		tag=0
	}
end

function makeevent(t,typ)
 return {
  t=t,
  typ=""--,
--  x=nil,
--  y=nil,
--  n=nil,
--  txt=nil
 }
end

function maketl()

 -- default keyframe
 local k=makekeyframe(0)
 k.animt,k.animspd,k.x,k.y=0,1,0,0
 
	return {
		keyframes={k}	
	}
end

function maketlanim()
	return {
		typ="tl",
		name="timeline",
		d=10,
		tls={ maketl() },
		events={ keyframes={} },
		duration=tlanim_duration,
		dodraw=tlanim_draw,
		draw=drawanim
	}
end

-- events

do 
 local afterframeco={}
	local function doafterframe(fn)
		 add(afterframeco,cocreate(fn))
 end
 
 anim_events={
  sfx=function(ev)	sfx(ev.n)         end,
  mus=function(ev) music(ev.n or -1) end,
  txt=function(ev)
   doafterframe(function()
    for i=1,ev.n or 30 do
     print(ev.txt,ev.x,ev.y)
     yield()
    end
   end)
		end,
  reltxt=function(ev,x,y)
   doafterframe(function()
    for i=1,ev.n or 30 do
     print(ev.txt,x+(ev.x or 0),y+(ev.y or 0))
     yield()
    end
   end)
		end,
		clr=function()
		 afterframeco={}
		end,

		-- schedule code to execute after the frame
		-- can use yield() to execute after multiple frames
		doafterframe=doafterframe,
  
  -- call this after the frame is rendered
		framedone=function()
		 runcoroutines(afterframeco)
		end
 }
end
-->8
-- data/constants

-- constants
type_race,type_tour,type_prac=1,2,3

-- data
tracknames=split("bRANDS hATCH,hOCKENHEIM,mONZA,sILVERSTONE,sPA fRANCORCHAMPS,sUZUKA")
racetypenames=split("sINGLE rACE,cHAMPIONSHIP,pRACTICE")
racetypeanims=split("race,tou,prac")
difnames=split("eASY,mEDIUM,hARD,eXPERT")
lapoptions=split("1,3,5,10,20")
racepts=split("15,12,10,8,6,4,2,1")
frame=0

pals=data(
[[2,3,10,11,14
131,140,2,139,3
5,5,5,5,5]])

aicarnames=split("s. hUDSON,d. vELOPER,h. pOTTER,v. iCE,p. bRAGA,m. pOWER,m. cRAB,r. bRUNT,z. lEX,d. sEEBS,b. aSTRO,s. hEINRICH,l. gARCIA,s. cAT")

aicarpals=data(
[[7,9,4
0,11,0
0,8,0
15,4,1
8,15,8
4,9,4
6,0,1
6,7,6
7,9,4
1,13,7
9,8,8
7,14,2
7,8,4
10,14,1
7,3,1]])

animdata={
"6d6173012d01046269726417010132320c044800004900004900004900000109626f6172646261636b280c0a32000c012c00000103636172280a0432640c010200000105636c6f7564280301323210019000000106636c6f756473280803320010010c000001056772616e64280e0432320c014a00000107686f72697a6f6e28100a320010018c070001046d6f747328030132320c014a020001047072697828090432320c015800000104726f6164281007323210010c04000105726f616432281007323210011c04000103736b7928101032321001380000010474657874280a053200100182020001057465787432280a050000100182020001057472656573281005326410018c01000106747265657332281005326410019c010003057374617274c201010300000b1600000000000064000400c8000917000064000400dc000924000064000400000203626731e803050100000b070000c0ff000064000c000100000b050000c0ff000064000c000100000b0f0000f0ff000064000c010100000b0f00001000000064000c000100000b0a00002400000064000c00010000046772617902020207626731616e696db80b020100000b1200000000000064000c000600000b01c2ffceff000064000c00f40106f6ffcaff64005a000c00e803060e00d5ff320032001800270507150f00bdff64005a000c00d606022200c9",
"ff0c000009024d00c9ff0800000203626732e803060100000b070000c0ff000064000c000100000b05e6ffcdff000064000d000100000b042300ddff000064000c000100000b100000f0ff000064000c010100000b1000001000000064000c000100000b0b00002400000064000c000002056269726473c800030100000b0100000000000064000c000100000b01f7fffdff0a0064000c000100000b010500faff780064000c00000205626c616e6bc800010100000a00000000000064000c0000020666616465696e1400010100000a00000000000064000c00010a000366696e00020469646c656400020100000b1e00000000000064000c0c0100000b1900001400000064000c000002046d656e75e803010100000b0d00000000000064000c1e0002087072616369646c65e803020100000b1200000000000064000c000100000b250000000064006400040000020670726163696e6400020100000b1200000000000064000c000100000b2500000000000064000400000207707261636f75746400010200000f120000000064006400000064000c00640004200320030c0000020770726163707265e803010100000b1200000000000064000c000002087261636569646c656400030100000b1200000000000064000c000100000b0300001000000064000c000100000b25000000006400640004000002067261636569",
"6e6400030100000b1200000000000064000c000200000f030000100004000400000064000c00640004640064000c000100000b2500000000000064000400000207726163656f75746400010100000b1e00000000000064000c00000207726163657072656400010100000b1200000000000064000c0000020673636f7265736400010100000b0e00000000000064000c1f00020773636f726573661400010200000b22000000000000640008000a00000c0000020973746172746d61696ee600020300000b2100000000000064000c0a6400091f00006400040bc800091e000064000c0c0300000b1900000000000064000800af0002000040000c00e60002000014001c000002057469746c656400030319000b0680ffcfff000064000c004b00020000cfff1c0000000008000328000b098000e1ff000064000c005a00020000e1ff1c000200000800021e000b081400b5ff000064000c004d00021400c5ff1c00000207746f756261636b6400020100000b1400000000000064000c000100000b020000c1ff000064000c00000207746f7569646c656400020100000b2600000000000064000c000100000b22d7ffc4ff000064000c00000205746f75696e6400020100000b2600000000000064000c000300000b23d7ffc4ff000064000800320008000096000c004b0008000064000c00000207746f756d61696ee80301",
"0100000b2700000000000064000c00000206746f756f75746400010100000b2700000000000064000400000206746f757072656400010100000b2600000000000064000c000002087472616e6c6566748c00030200000b2700000000000064002c164b00028000000018000400000b2180ff0000000064002c0a4b000200000000140b9600011e0c0c2300091f000064000c0b0100000b1900001400000064000c000002097472616e72696768748c00030200000b2100000000000064002c164b000280ff000018000400000b2b80000000000064002c0a4b000200000000140b960001270c0c23000928000064000c0b0100000b1900001400000064000c0000",
"",
"",
"",
"",
"",
"",
"",
"",
"",
"",
"",
"",
""}
-->8
-- main

function _init()
 cartdata("mot_gpp")
 
 -- load animations
 local stream=readstrstream(animdata)
 anims=loadanims(stream)
 anim_events.fin=fadein

 -- load cart data
 
 -- game state
 if dget(10)==0 then
		racetype,dif,lapoption,tracknum=1,2,2,1
	else		
	 racetype	=dget(10)
 	dif						=dget(11)
	 tracknum	=dget(12)
 	lapoption=dget(13)
 end
 
 -- tournament state
 loadtournament()

 -- update tournament stats with last race results
 if  dget(30)==1					         -- race ended 
 and dget(18)==0 				         -- not demo mode
 and racetype==type_tour then	
 	applyraceresults()
 end  
 dset(30,0)
 
 -- menu initial state
 mode,menui,menuy,demo,democtr="title",0,0,false,3150
 
 -- play start animation
 local animset=getmodeanimset(racetype)
 animsets={animset}
 transition(anims["start"],anims["idle"])
 
 -- fade in music
 music(0,5000) 
end

function _draw()
 cls()
 basepal()
 if(anim and animt)anim:draw(animt)
 if(confirmprompt)drawconfirm()
 drawfade()
end

function _update()
 frame+=1
 
 -- can't update while transitioning
 if not istransition then
  if confirmprompt then
   updateconfirm()
  elseif mode=="title" then
	 	updatemenu()
	 end
	end
 
 -- drive animation
 if animt then 
	 animt+=1/30
	 if istransition and animt>=anim:duration() then
	 
	  -- end transition
   if(doneanim)anim,animt=doneanim,0
   if(donefn)donefn() 
   doneanim,donefn=nil,nil
   istransition=false
	 end
	end	 

 -- update fade	
 updatefade()
end

function rungame(demo)

 if racetype==type_race then
 	roster=makerandomroster()
 elseif racetype==type_tour then
  roster=tour.roster
 else
  roster=nil
 end

 -- pass parameters to game
 -- stored in different data slots than used
 -- to persist values between sessions.
 -- this is so demo can invoke a random track
 -- without overwriting user's prefs.
 dset(14,racetype)
 dset(15,dif)
 dset(16,demo and 1 or lapoptions[lapoption])
 local tracki
 if racetype==type_tour then
  tracki=tour.tracks[tour.tracknum]
 else
  tracki=tracknum
	end
	dset(17,tracki)
 dset(18,demo and 1 or 0)

 -- pass roster
 if roster then
	 for i,c in ipairs(roster) do
	  dset(19+i,c)
	 end
	end
	
	-- unpack track data into high memory
	memset(0x8000,0,0x7fff)
	local data=trackdata[tracki]
	for i=1,#data do
	 poke(0x8000+i-1,ord(data,i))
	end
 
 -- run game
 load("#mot_grandprix2game")
end

animsetnames=split("pre,_in,idle,out")

function anim_draw(props,cx,cy,cxscale,cyscale,cflipx,cflipy,cdt,r)
 local tag=props.tag
 if tag==1 then 
 	pal(pals[2])
 else
  basepal()
 end
 
 if tag>=10 and tag<30 then
  local animset=animsets[tag\10]
  local name=animsetnames[tag%10+1]
  local anim=animset[name]
	 anim:dodraw(props.animt,cx,cy,cxscale,cyscale,cflipx,cflipy,cdt,r)
		return false
	elseif tag==30 then
	 camera(64-cx,-cy)
	 drawmenu()
	 camera()
	 return false
	elseif tag==31 then
	 camera(-cx,-cy)
	 drawleaderboard()
	 camera()
	 return false
 end

 return true
end

function drawconfirm()
 rectfill(0,50,128,77,3)
 rect(-1,50,128,77,7)
 cprint(confirmprompt,56,6)
 local selcol=frame%8<4 and 7 or 6
 pprint("yES",50,67,confirmx==0 and selcol or 5)
 pprint("nO", 69,67,confirmx==1 and selcol or 5)
end

function updateconfirm()
 if(btnp(⬅️))confirmx=0
 if(btnp(➡️))confirmx=1
 if btnp(❎)or btnp(🅾️) then
  confirmprompt=nil
  if confirmx==0 then
   confirmfn()
  end
  confirmfn=nil
 end
end
-->8
-- routines

function fadein()
 fadepixels={}
 for i=0,63 do
  sset(i%8,i\8,0)
  add(fadepixels,i)
 end
 fade="in"
end

function drawfade()
 if fade=="in" then
  palt(0,false) palt(1,true)
  for i=0,255 do
   spr(0,i%16*8,i\16*8)
  end
  if(#fadepixels==0)fade=nil
 end
end

function updatefade()
 if fade=="in" then
  for k=1,2 do
   local j=rnd(fadepixels)
   del(fadepixels,j)
  	sset(j%8,j\8,1)
	 end
	end
end

function pprint(txt,x,y,c)
 for ox=-1,1 do
  for oy=-1,1 do
   print(txt,x+ox,y+oy,1)
  end
 end
 print(txt,x,y,c or 6)
end

function cprint(txt,y,c)
 pprint(txt,65-#txt*2,y,c)
end

function mprint(txt,y,i)
 cprint(txt,y,menui==i and frame%8<4 and not istransition and not confirmprompt and 7 or 6)
end

function basepal()
 pal()
 pal(pals[1],1)
	poke(0x5f2e,1)
end

function transition(_anim,_doneanim,_donefn)
 anim,doneanim,donefn=_anim,_doneanim,_donefn
 animt,istransition=0,true
end 

function getmodeanimset(racetype)
 local modename=racetypeanims[racetype]
 return {
  pre=anims[modename.."pre"],
  _in=anims[modename.."in"],
  idle=anims[modename.."idle"],
  out=anims[modename.."out"]
 } 
end

function makerandomroster(t,n)
 return randomnums(14,7)
end

function randomnums(t,n)
 local allnums={}
 for i=1,t do
  add(allnums,i)
 end
 local result={}
 for i=1,n or t do
  add(result,del(allnums,rnd(allnums)))
 end
 return result
end

function sort(array,compfn)
 for i=2,#array do
  local c,j=array[i],i
  while j>1 and compfn(array[j-1],c) do
   array[j]=array[j-1]
   j-=1
  end
  array[j]=c
 end
end

function confirm(prompt,fn)
 confirmprompt=prompt
 confirmfn=fn
 confirmx=1
end

-->8
-- menu

function drawgamename()
 rectfill(20,6,105,37,0)
 print("\^pmOT'S",44,10,7)
 print("\^pgRAND pRIX",24,25,7)
end

menu_type,menu_dif,menu_laps,menu_track,menu_start,menu_tour_start,menu_tour_quit=1,2,3,4,5,6,7

function getmenuitems()
 local items={menu_type}
 if racetype~=type_prac then
  add(items,menu_dif)
  add(items,menu_laps)
 end
 if racetype==type_tour then
  if tour.tracknum==0 or tour.tracknum>#tour.tracks then
  	add(items,menu_tour_start)
  else
   add(items,menu_tour_quit)
   if tour.tracknum>=1 and tour.tracknum<=#tracknames then
    add(items,menu_start) 
   end
  end
 else
  add(items,menu_track)
  add(items,menu_start) 
 end
 return items
end

function drawmenu()
 local items=getmenuitems()
 local yoffs=(5-#items)*3
 palt(12,false)
 if not istransition and not confirmprompt then
	 sspr(8,0,8,8,0,menuy*8-2+yoffs,128,9)
	end
 for i,item in ipairs(items) do
  local txt,arrows="",false
  if     item==menu_type  then txt=racetypenames[racetype]         arrows=true
  elseif item==menu_dif   then txt="dIFFICULTY: "..difnames[dif]   arrows=true
  elseif item==menu_laps  then txt="lAPS: "..lapoptions[lapoption] arrows=true
  elseif item==menu_track then txt="tRACK: "..tracknames[tracknum] arrows=true
  elseif item==menu_start then txt="!! rACE !!"
  elseif item==menu_tour_start then txt="nEW cHAMPIONSHIP"
  elseif item==menu_tour_quit  then txt="qUIT cHAMPIONSHIP"
	 end
	 local y=(i-1)*8+yoffs
  mprint(txt,y,i-1)    
  if arrows then
   spr(114,6,y-1,1,1,true)
   spr(114,114,y-1)
  end
 end
end

function updatemenu()
 -- up/down arrows
 if(btnp(⬆️))menui-=1
 if(btnp(⬇️))menui+=1

 -- find current menu item
 local items=getmenuitems()
 menui=mid(0,#items-1,menui)
 local item=items[menui+1]

 -- left/right arrows
 local d=0
 if(btnp(⬅️))d-=1
 if(btnp(➡️))d+=1

 if item==menu_type and d~=0 then  
  if racetype+d>=1 and racetype+d<=#racetypenames then
			local prevtype=racetype
			racetype+=d
			local animset,prevset=getmodeanimset(racetype),getmodeanimset(prevtype)
			animsets={animset,prevset}
			local anim=d<0 and anims["tranleft"] or anims["tranright"]
			transition(anim,anims["idle"])
  end
 end
 if(item==menu_dif)dif+=d
 if(item==menu_laps)lapoption+=d
 if(item==menu_track)tracknum+=d
 dif=mid(1,#difnames,dif)
 lapoption=mid(1,#lapoptions,lapoption)
 tracknum=mid(1,#tracknames,tracknum)
 
 dset(10,racetype)
 dset(11,dif)
 dset(12,tracknum)
 dset(13,lapoption)

 -- buttons
 if btnp(❎)or btnp(🅾️) then
  if(item==menu_start)rungame(false)
  if(item==menu_tour_start)newtournament()
  if(item==menu_tour_quit)confirm("qUIT cHAMPIONSHIP?",quittournament)
 end
 
 -- animate menu highlight
 if(menuy~=menui)menuy+=sgn(menui-menuy)/4

 -- demo counter 
 if((btn()&0x3f)~=0)democtr=max(democtr,1800)
 democtr-=1
 if democtr<=0 then 
  demo=true
		racetype,dif,lapoption,tracknum=1,2,1,rnd(#tracknames)\1+1
 	rungame(true) 
 end
end

-->8
-- debugging

lines,s={},0 function dadd(n,v,i,p)while p>1 and lines[p-1].i==i and type(lines[p-1].n)==type(n)and lines[p-1].n>n do p-=1 end add(lines,{n=n,v=v,x=type(v)=="table"and"+"or" ",i=i},p)end
function dexp(l,p)if l.x=="+"then for n,v in pairs(l.v)do p+=1 dadd(n,v,l.i.." ",p)end l.x="-"elseif l.x=="-"then while p<#lines and #lines[p+1].i>#lines[p].i do deli(lines,p+1)end	l.x="+" end end
function dinp()local x,y,b,w=stat(32),stat(33),stat(34),stat(36)line(x,y,x,y+2,10)if btnp(❎) then local i=(y-10)\6+1 local p=s+i local l=lines[p]if l and(x-10)\4==#l.i then dexp(l,p)end end s=max(min(s-stat(36),#lines-18),0) end
function dui()while true do rectfill(10,10,118,118,1)for i=1,18 do local l=lines[i+s]if l then print(sub("\fc"..l.i..l.x..l.n..":\f7"..tostr(l.v),1,31),10,(i-1)*6+10,7)end end dinp()flip()end end
function dinsp(v)dadd("value",v,"",#lines+1)poke(0x5f2d,3)cursor()pal()clip()dui()end

-->8
-- tournament

function newtournament()
 tour.tracks=randomnums(#tracknames)
 tour.tracknum=1
 tour.roster=makerandomroster()
 tour.playerpts=0
 tour.pts={}
 for i=1,7 do
  add(tour.pts,0)
 end
 savetournament()
 updateleaderboard()
 menui=4
 
 -- todo: animation
end

function quittournament()

 -- todo: confirmation prompt if tournament running
 tour.tracknum=0
 savetournament()
end

function loadtournament()
 tour={
  tracknum=dget(40),
  tracks={},
  roster={},
  pts={},
  playerpts=0
 }
 if tour.tracknum>0 then
  for i=1,#tracknames do
   add(tour.tracks,dget(40+i))
  end
  for i=0,6 do
   add(tour.roster,dget(50+i))
   add(tour.pts,dget(57+i))
  end
  tour.playerpts=dget(49)
  updateleaderboard() 
 end 
end

function savetournament()
 dset(40,tour.tracknum)
 if tour.tracknum>0 then
  for i=1,#tracknames do
   dset(40+i,tour.tracks[i])
  end
  for i=0,6 do
   dset(50+i,tour.roster[i+1])
   dset(57+i,tour.pts[i+1])
  end
  dset(49,tour.playerpts)
 end 
end

function updateleaderboard()
 leaderboard={}
 for i,car in ipairs(tour.roster) do  
  add(leaderboard,
  	{
  	 name=aicarnames[car],
  	 p=aicarpals[car],
  	 pts=tour.pts[i]
  	})
 end
 add(leaderboard,{
 		name="pLAYER",
 		pts=tour.playerpts,
 		isplayer=true
 	})
 sort(leaderboard,function(a,b)return a.pts<b.pts end)
end

function drawleaderboard()
 print("driver",0,1,5)
 print("points",58,1,5)
 if(tour.tracknum==0)return
 for i,e in ipairs(leaderboard) do
  local y,col=i*6+2,e.isplayer and 7 or 6
  pal()
  palt(0,false)
  palt(12,true)
  if(e.p)pal(e.p,0)
  spr(8,0,y)
  pal()
		print(e.name,10,y,col)
		local txt=tostr(e.pts)		
		print(txt,82-#txt*4,y,col)
 end
 
 if tour.tracknum>#tour.tracks then
  if frame%30<15 then
	  print("fINAL sTANDINGS",12,60,7)
	 end
 else
  local tracknum=tour.tracks[tour.tracknum]
  local trackname=tracknames[tracknum]
  print("nEXT:"..trackname,-2,60,7)
 end 
end

function applyraceresults()

 -- player points
 local playerpos=dget(31)
 tour.playerpts+=racepts[playerpos]

 -- ai car points
 for i=1,7 do
  local pos=dget(31+i)
  tour.pts[i]+=racepts[pos]
 end
 
 -- advance to next track 
 tour.tracknum+=1
  
 savetournament() 
 updateleaderboard() 
end

-->8
-- tracks
trackdata={
-- brands hatch
"²⁸³fin³(\0=²\0ャ⁸¹ᶠ¹\r2\0□ル¹ᵉ#\0\"\0¹ᶜ\r⁘ヨ\0d\0⁘ヨ\0X\0⁸フ\0F\0□⁘\0⁘\0□⁘\0、\0□⁘\0$\0□⁘\0*\0」」\0*\0」⁘\0⁵\0。ᶠ\0U\0⁙ᶠ\0d\0⁴」³6\0ᵇ\0\0b\0³pdk⁷⁘\0003¹\0\n¹ᵉ¹ᶜ゛\0ᶠ	\0Fム⁘⁘\0¹⁸\0」\0S⁴\0ル¹ᶜ¹ぬ⁘\0¹◝◝⁘\0O¹\0\0ャ⁵²むス(\0r\0¹\r¹\r²ム⁘⁴◀ろ\0A\0「ろ\0F\0◀ウ\0H\0•\0\0🐱\0³drd⁷-\0_「\0‖ロ⁘¹ᶜ¹ヌ゛\0H⁸²フ⁘\n\0¹ュ◝⁘\0ᵇ◝◝\0゛•\0¹ヨ◝(\0rレ²ᶠᵉ¹ᵉ¹ヌ⁘\0iュ◝⁸¹\r¹ムᵉ「ヨ\0ᶠ\0□ヨ\0⁸\0¥⁸\0⁙\0¥⁸\0 \0¥⁸\0-\0¥⁸\0:\0¥ン\0お\0¥ン\0し\0、2\0い\0、2\0♥\0\n<\0n\0□」\0ゆ\0□」◜ゆ\0□」ュゆ\0³sur\r(\0!ョ◝¹ᶜ⁘\0)ョ◝#¹ᵉᶠ\0¹◜◝⁘\0タッ◝\0⁸¹\r¹#」\0z	\n¹ᶠ¹ᶠ²ヨᶠ゛\0@²ヨᶠ\n\0A³\0²ヨᶠ#\0B」²ヨᶠ\n\0N゛ャ⁵²ヨᶠ⁘\0@²ヨᶠ⁘\0Lロ\n²ヨᶠ⁘\0Bラ²ヨᶠᶠ\0@²ヨᶠ\n◀ᶠ\0ᶠ\0◀ᶠ\0◀\0「ᶠ\0。\0◀ᶠ\0$\0•\0\0ス\0¥⁷\0⌂\0¥⁷\0▥\0¥⁷\0ル\0¥⁷\0²¹¥ン\0²¹³haw³⁘\0uᵉ\0ム¹\r¹ᵉ²フᶠ⁘\0Gᵉ\0\0ル³フᶠヌ2\0`¹\r²ムᶠ¹⁙ヨ\0R\0³wst⁸⁘\0Aᶠ\0²ヨᶠ」\0C³\0。²ヨᶠ⁘\0C⁶\0002²ヨ⁘⁘\0Bフ²ヨ⁘#\0C⁷\0\0²ヨᶠ⁘\0Q⁷\0¹ᶜ²ヨᶠᶠ\0Oᵇ\0ᵇムᶜ²ホ■(\0N¥ロ\n²ム■²¥⁸\0き\0¥⁸\0て\0⁴strl	ᶠ\0Yリ◝⁘¹\r²ヨ」ᶠ\0Kリ◝\0ᶜ²ヨ⁘<\0B◀²ᶠヨ\n\0N	ャ⁵²ヨᶠ\n\0Bロ²ルᶜ⁘\0Lヨ⁘¹ヤ⁘\0P¹ᶠ¹マ(\0C	\0ᵉ¹マ⁘\0{⁴\0\0⁸¹ᶜ¹ᶜ¹ス⁴•\0\0g\0¥⁸\0K\0¥ヲ\0K\0⁘フ\0っ\0³end²<\0[⁴\0モ⁵¹ᶠ¹ス」\0/¹\0\0ヨ⁵¹\r⁴「ツ\0>\0「ツ\0D\0□ツ\0J\0◀ツ\0P\0ᶜ⁴",
-- hockenheim
"²⁷⁶finish¹x\0004ル¹\r¹\r▮⁷ム\0\0\0⁷ム\0⁘\0⁷ム\0(\0³フョ#\0⁷ム\0<\0⁷ム\0P\0ᵇ\0\0002\0。ᶜ\0'\0³▮³3\0◀\n\0⁘\0 ⁷ュ@\0³▮³G\0⁷ム\0d\0⁸ム\0x\0³▮³[\0³▮³o\0⁴nordᵉ!\0」ᶜ\0ᶜ¹ᶜᶜ\0 ¹ᶜ⁘\0⁴ヲᶠ\0X⁵²ᶠ\r²フ(⁘\0p¹\r¹\r²ム⁘⁸\0Dュ²ヨᶠ⁴\0@²ルᶜ⁘\0Lヲ\n²ユ▮⁘\0P¹ᶠ²ヨᶠd\0A¹\0²ルᵉd\0Q²\0¹\r²レᵉ\n\0Lャ⁵²ロᶜ⁸\0@²ルᶜ゛\0H⁘²ヲ゛ᵉ⁷ム\0\n\0⁷ム\0゛\0³▮³ᵇ\0」ツ\0゛\0」ツ\0#\0⁷ム\0002\0¥⁸\0*\0¥⁸\0002\0¥⁸\0:\0•\0\0n\0 ッョき\0 ッョキ\0」ム\0⁴¹•\0\0m¹⁵clarkᶠᶜ\0G⁘\0⁷ム²ス(⁸\0Dヌ²ス」ᵉ\0Gヒ◝\0ル²ク゛⁘\0X⁸¹ᶜ²ツ゛-\0Q²\0¹\r²ᶜツ(\0A¹\0²ᶜツ(\0A¹\0²ᶜツ(\0A¹\0²ᶜツ(\0A¹\0³ラᶜヌ\n\0Lャ⁵¹ᶜ⁸\0@¹ロ\n\0\\ヲ⁸²ᶠ\r²ルᶜ⁘\0@²ルᶜ■\0R\n¹\r²モᶜᶠ\0V\nヨ²ᶠ\r²モᶜ▶⁷チ²ᶠ\0⁙」\0 \0⁷ム¹(\0⁷ム²<\0⁷ム²P\0⁷ム²d\0⁷ム²x\0 ヨ◜d\0⁷ム²😐\0⁷ム²き\0⁷ム²ひ\0⁷ム²っ\0 ヨ◜ひ\0▮リ\0ふ\0 ヨ◜ゆ\0 ヨ◜っ\0 ヨ◜キ\0•\0\0ᵉ¹⁸ヤ²⁴¹ ッョ゜¹「レ\0005¹◀レ\0<¹ ッョD¹³ost▮ᶜ\0W「\0ᶠス¹ᶜ³スろᶜ\n\0F	ス²ろᶜ⁸\0Gフ◝ロス³ᶜろ□\n\0¹\r\0⁘\0G⁶\0\0ル³スᶜ□ᶠ\0Q⁴\0¹\r²ラᶜ2\0R⁴¹ᶜ²ラᶜ\n\0\\ャ⁵¹\r²ルᶜ⁵\0@²ᶜル\n\0Lヲ⁸²ルᶜ2\0Bッ²ルᶜF\0N⁴ヲ⁸²ルᶜ\n\0N\0ャ⁵²ル\n⁵\0@²ロ\n\n\0Lヲ⁸²ルᶜ⁘\0dム¹ᶜ²フᶜ⁷⁸ウ\0ᵉ\0⁸ウ\0「\0•\0\0○\0•\0\0¥¹■マ\0-\0▮ム\0000\0▮ヌ\0*\0⁵senna	⁸\0Mノ◝フᶜ²ネᵉ\n\0Lヌ•²ナ。□\0i⁘\0◀¹\r²ウ゛\n\0Lモ⁸²ナ◀⁘\0Eュ◝ヲ²モ\n2\0Bッ²ロ\n2\0B	²ロ\n2\0Bᶜ²ロ\n2\0Bワ²ロ\n²⁸タ¹「\0▮フ\0*\0⁴agip⁷⁵\0Lャ⁵¹ロ⁵\0@¹ロ⁵\0Lヲ⁸¹ロᶠ\0@¹ルᶠ\0p²ᶠ\r²ᶠ\r¹ホ゛\0005ᶜ\0ヌ¹ᶜ¹ᶜ7\0\0■•\0\0⁷\0■⁘\0\"\0■¥\0#\0▮゜\0#\0■%\0#\0▮ᵉ\0□\0■ᵉッ□\0⁷ス\0>\0	ᵉ²K\0	ᵉ²_\0	ᵉ²s\0 ッョ\"\0 ⁶ョ\"\0」ゃ\0D\0」よ\0L\0⁷ス\0Z\0□ス\0x\0⁵sachs\n#\0■ム◝¹\rᶠ\0	ヨ◝ᶠᵉ\0²⁷ᵇ\0³リ◝ャ\n\0\0ᵇ\0¹ᶜ\0ᶜ\0\0」\0C■\0\0¹ろ	\0Bャ¹ろ#\0Gᶠ\0\0ル¹ろᵉ	ᵉ²⁵\0³⁘²⁵\0◀」\0 \0◀」\0&\0゜<\0007\0▮⁘\0。\0▮」\0。\0□⁘\0:\0」゛\0d\0⁸エ\0i\0⁷ウ\0x\0⁷ウ\0😐\0⁷ツ\0お\0」ろ\0て\0¹²",
-- autodromo nazionale monza
"²⁸³fin\n(\0<ャ⁴¹ᶠ¹ᶜ\n\0¹³\0-\0\0(\0\0002\0p²ᶠ\r¹\r¹ム⁘\0\0゛\0@¹ワ゛\0p¹ᶠ¹ᶠ¹ム\n\0 ¹ᶜ\n\0⁸ᶠ&³ラ³(\0	ᶜ¹³\0▮ᶜ\0、\0◀\n\0*\0「ᶠ\0*\0「\n\0%\0◀ᶠ\0%\0、⁸\0004\0⁸ロ¹ゆ\0。⁸\0♥\0³ᶜ⁴き\0ᵇ\0\0∧\0¥⁶◝キ\0¥⁶◝っ\0¥⁶◝ゆ\0	\n\0ユ\0▮	\0ヒ\0⁙ヲ\0	¹ ョョミ\0 ョョワ\0 ョョ³¹\n\n\0⁴¹	⁸²A\0	⁸²U\0	⁸²i\0\n⁸²}\0 ョョᶠ¹」ル\0ᵉ¹⁙ワャ(\0³ラ³<\0³ラ³P\0³ラ³d\0³ラ³x\0⁸ル\0⁘¹³モ³\0\0▮ラ\0、\0▮モ\0、\0■ヨュ、\0	rettifilo³\n\0⁵゜\0ムᶜ\0Eト◝ム¹。(\0Lワ⁶¹」⁷⁙⁘\0◀\0⁙⁙\0•\0⁙■\0!\0⁷フ\0#\0⁷ヌ\0⁸\0▮■\0<\0⁷ム\0007\0⁸biassonoᶠᶠ\0i⁶\0⁵¹\r¹ᵉᶠ\0P¹\r²ᵇヨ⁵\0Dャ²ᵇヨ⁵\0@²ᵇラ⁵\0Dワ²ᵇラᶠ\0@²ᵇラ゛\0A⁴\0¹ラ゛\0Q⁵\0¹ᶜ²リᶜ゛\0Q⁴\0¹ᶠ²ム□⁘\0@²モ\n」\0P¹\r²リ⁸\n\0Lャ⁵²リ\n⁵\0@²リ\r⁵\0Lッ⁸²ル\r#\0P¹ᶠ¹ᶜ⁵」⁶\0⁵\0•\0\0%\0•\0\0エ\0◀\n\0~\0◀\n\0♥\0⁶roggia⁷\n\0Dル¹\r\n\0¹ト◝\n\0⁵•\0ロ⁘\0P¹ᶜ¹リ\n\0Mュ◝ャ⁵¹ル⁵\0@²ロ\n#\0Tリ¹ᶠ²\rヨ⁵	⁘¹\r\0•\0\0:\0	ᵉ¹$\0 ッョI\0¥ヲ\0U\0⁵lesmo⁶゛\0Q\r\0¹ᵉ²ホ\n゛\0P¹ᶜ²ユ\n⁘\0P¹\r²ユ\n\n\0P¹ᶜ¹ユ⁘\0Y■\0ᶜ¹\r¹ユ\n\0H⁶²ユᶠ³⁙ヤ\0□\0\nᶜ²P\0◀\n\0[\0	serraglioᵉ(\0Lャ⁵²ユ\n⁵\0@²ラᵉ⁵\0@²ロ\n゛\0@²ヲ⁸゛\0A◜◝²ヲ⁘⁘\0B⁸²ヲᶜ⁘\0Bャ²ヲᶜ⁵\0@²ラᵉ⁵\0@²ロᶜ(\0B\0²ヲᶜ⁵\0@²ルᶜ⁵\0@²ᵇロ⁘\0Lム⁸²\nム⁘\0dル¹ᶜ²ヘᶜ⁵•\0\0*\0•\0\0▤\0•\0\0ゅ\0□ᵉ\0d\0◀ᵉ◜d\0⁶ascari⁘ᶠ\0]ヘ◝ュ⁘¹ᶜ²‖ム\n\0q\n\0¹ᵉ¹ᵉ²ヲ◀\n\0E\r\0ル²ル◀\n\0A\n\0¹ユᶠ\0Eヘ◝ッ²、ユ-\0「ᶜ¹ᶠ」\0x⁸¹\r¹\r¹ル⁵\0Lャ⁵²ロ\n⁵\0@²ロ\n⁵\0ᶜッ⁶⁘\0P¹ᶠ¹リ⁘\0@²ᶜラ\n\0H\n¹リ⁘\0@²▮ラ⁵\0\\ャ⁵¹\r²ルᶜ⁵\0@²ロ\n⁵\0ᶜヲ⁶\n\0P¹ᶠ²ロᶜ-\0▮¹\rᶠ\0Dレ¹ᵉ ⁙ン\0ᶜ\0\n、¹=\0⁙ル\0004\0⁙ルョ4\0•\0\0웃\0•\0\0テ\0	⁘\0P\0³⁘\0P\0\n⁘\0n\0゜■\0}\0²⁘\0n\0▮‖\0L\0■◀\0H\0■\r\0🐱\0▮ᶠ\0|\0⁙ヲ\0n\0⁘ᶠ²い\0゜ᶠ\0し\0゜ᶠ\0み\0◀	\0へ\0゜」\0チ\0▮ᶜ\0ゆ\0■ᶜュゆ\0 ッョモ\0⁷ユ¹レ\0⁷ユ¹	¹⁸ユ¹。¹゜」\0	¹゜」\0。¹▮ᶜ\0⁙¹▮ᶜ\0	¹」⁸\0;¹\nparabolica⁴\n\0⁘ラ¹ᶜ゛\0E\r\0ム²ヘᶜ⁘\0A\r\0²ヘᶜ゛\0]\r\0ル⁶¹ᶠ¹マ⁴⁸モ\0\0\0²モ\0\0\0⁙⁸\0⁵\0 ルョT\0ᶜ\r",
-- silverstone
"²ᶠ⁸hamilton³⁘\0>\0ヲ⁴¹ᶜ¹ᶜ゛\0\0\n\0\"\0¹\r	⁴」²\0\0⁴」²⁘\0⁴」²(\0⁷ユ\0ᵇ\0³ユ\0ᵇ\0▮ユ\0%\0⁷ユ\0/\0³ユ\0/\0ᵇ\0\0゜\0⁵abbey³ᶠ\0	ᶠ\0ᶠ゛\0⁘ロ¹ᵉ\n\0⬇️ム◝ᶠ⁴■フ\0⁘\0⁷ユ\0」\0■ヨ\0/\0⁷ユ\0001\0⁴farm³ᶠ\0\"\0¹ᵉ」\0@¹゛\n\0\0³⁷ユ\0\0\0⁷ユ\0'\0³ユ\0'\0⁷village²⁘\0C゛\0\0¹ヌ\n\0B\0¹ム\0⁴loop¹゛\0³ノ◝\0\0⁷aintree²」\0?ャ◝\0ロᶠ¹ᶠ¹ᶠ」\0Cム◝\0¹゛\0\nwellington⁷*\0j\0\n²ᶠ\r¹゛⁶\0゛\0ャ⁵²ᶠ\r⁴\0\0⁶\0ᵉ\0ロ\n゛\0R\0¹ᶠ¹ツ%\0\0」\0@¹マᶠ「マ\0」\0」⁘\0。\0¥ッ\0゛\0¥⁶\0゛\0³」⁴$\0「マ\0%\0•\0\0002\0◀マ\0>\0	ᵉ\0?\0³ᵉ\0?\0◀マ\0L\0◀マ\0Z\0「⁘\0h\0「⁘\0q\0。ᶠ\0z\0\nbrooklands²2\0⁙マ◝\0¹ᶜ⁸\0²\0⁶▮ᶠ\0\r\0\n⁘\0▶\0²⁘\0▶\0▮ᶠ\0.\0\n⁘\0002\0²⁘\0002\0⁸woodcote⁶」\0?」\0\0ヨ\n¹ᶠ¹ᵉ⁘\0▶」\0\0ム¹\r゛\0\0⁘\0	ᶠ\0⁴F\0\0゛\0\0「◀ツ\0ᵇ\0■フ\0□\0◀ツ\0、\0▮ツ\0!\0⁷ヌ\0(\0³ヌ\0(\0⁸ヌ\0A\0²ヌ\0A\0⁸ヌ\0F\0²ヌ\0F\0、ᶠ\0P\0⁸ヌ\0[\0²ヌ\0[\0、ᶠ\0🐱\0「ヌ\0~\0■フ\0●\0」フ\0⬅️\0◀ヌ\0★\0◀ヌ\0え\0◀ヌ\0そ\0◀ヌ\0は\0、ᶠ\0😐\0□ᶠ\0ひ\0⁘ᶠュ♥\0⁵copse⁵⁘\0•⁙\0⁙ᶜ¹ᶜ゛\0¹¹\0⁘\0C¹\0\0¹ヌ⁘\0|ャ⁵²ᶠᵉ¹ᵉ¹ヌ゛\0p²ᶠᵉ²ᶠᵉ¹ヌ⁸⁸ヌ\0ᵇ\0²ヌ\0ᵇ\0⁸ヌ\0」\0²ヌ\0」\0⁸ヌ\0'\0²ヌ\0'\0□ᶠ\0003\0•\0\0i\0⁷maggots³ᶠ\0³ロ◝\0」\0⁵ᵇ\0ル⁘\0\0³⁸ム\0/\0²ム\0/\0」ラ\0\0\0⁸becketts⁴゛\0=ヨ◝ヌ゛²ᶠ\r²ᶠ\r#\0Q⁙\0¹\r¹ス⁸\0⁘ヨ¹ᵉᶠ\0Uヤ◝ン²ᶠᵉ¹ス²「チ\0>\0「チ\0F\0⁶hangar⁵」\0\n	⁘」\0.	ャ⁵²ᶠᵉ」\0Lワ	²⁘ヌ」\0bᵉ¹ᵉ¹ム゛\0\"\0¹ᶜ\n」ル\0¥\0◀\"\0。\0「」\0(\0•\0\0003\0□フ\0007\0⁙フ◝8\0¥ッ\0P\0¥⁶\0P\0「ᶠ\0]\0◀⁘\0m\0⁵stowe²<\0Qᵉ\0¹ᵉ¹ウ\n\0¹ヤ◝⁴⁸フ\0\r\0⁸フ\0」\0⁸フ\0%\0◀ム\0007\0⁴vale⁸ᶠ\0\nᵉ	\n\0²ヨᶠ\0²\0ᶠ\0¹ツ◝\n\0A\"\0¹ᶠ\n\0¹⁵\0」\0\rᵉ\0ヲ⁴゛\0⁘ヲ¹ᶜ\n「ᶠ\0⁴\0「ᶠ\0ᶜ\0•\0\0¥\0\nᶠ\0。\0、ᶠ\0(\0⁷ツ\0?\0⁷ツ\0Y\0◀ム\0s\0³ツ\0Y\0「ム\0{\0ᶜ²",
-- spa francorchamps
"²ᵇ³fin⁶゛\0>\0ャ⁵²ᶠ\r¹ᵉ(\0000¹\r¹\r\n\0P¹ᶠ¹ロ\n\0\0⁘\0F	ワ¹ル\n\0²ワ	、\n\0゜\0⁷ル¹#\0³ル\0#\0⁘\n\0*\0、\n\0005\0•\0\0?\0、\n\0C\0□ヨ\0W\0「ヨ◜W\0⁶source⁴゛\0S゜\0⁘¹ᵉ¹ム#\0@¹ヌ゛\0003²\0▶¹ᶜ¹ᶜ7\0□。¹ᶠᶜ「ユ\0⁶\0⁷ユ²(\0⁸ユ²<\0⁷ユ\0F\0³ユ\0F\0⁘\r\0<\0³ᶠ⁴R\0⁘\r\0H\0³ᶠ⁴f\0□ᶜ\0😐\0◀ム\0g\0 ⁷ョn\0⁴raid⁷\n\0エル◝マヨᶜ¹」\n\0タ	\0シ⁘¹ᵉ¹」」\0ょ⁸\0\0ᶜ¹」⁸\0わヨ◝ッ¹ᵉ2\0Rᵇ¹ᶜ²⁘ム⁘\0X⁷¹ᶠ²ᶠレᶠ\0ニ⁸\0¹\r²ᵇレ⁵³フ²「\0「フ◜-\0□フ\0-\0⁙ᶠ¹A\0⁙ᶠ¹H\0³kem⁴U\0B³¹⁘#\0Rャ²ᶠ\r¹ᶜ(\0@¹ᶜ」\0\0ᶜ⁷ラ\0⁵\0⁷ラ\0」\0⁷ラ\0-\0⁷ラ\0A\0゜ᶜ\0<\0□ᶜ\0@\0 ュョT\0⁙	\0S\0 ⁶ョT\0▮ᵉ\0R\0■ᵉャR\0 ュョて\0⁶combes⁷⁘\0m「\0ヌ⁘¹ᵉ¹ツ⁘\0}フ◝ッ⁶¹ᵉ¹ᶜ²ナ⁘⁸\0`¹\r¹	⁘\0A⁘\0¹\n\n\0A「\0¹\n(\0\"\n¹ᵉ⁘\0r‖²ᶠ\r¹\r¹ᶠ\r」ス\0」\0⁙ヨ\0007\0◀ヨ\0:\0「ヨ\0A\0⁷ヤ¹F\0 ュョz\0□ム\0∧\0□ム◜∧\0▮ム\0_\0■ムャ_\0゜ᶠ\0n\0▮⁘\0k\0■⁘ャk\0⁴brux	<\0Y「\0\n¹ᵉ¹フ#\0tヌ¹ᶠ¹ᶠ¹ᶠ」\0eホ◝ヲ¹ᵉ¹ᶠA\0p²ᶠ\r¹\r²ヨᶠᶠ\0A³\0²ヨᶠ⁵\0Lャ⁵²ヨᶠ⁵\0@²ヨᶠ⁵\0Lヲ⁷¹ヨ#\0@¹ヨ⁴¥⁷\0d\0¥⁷\0a\0•\0\0エ\0	ᶠ²ヒ\0⁴pouh⁷」\0yマ◝\n¹\r¹ᵉ¹ム⁸\0iワ◝▮¹ᶜ¹ム」\0iラ◝⁘¹ᵉ²゛ム゛\0`¹ᶜ²゛ム⁘\0`¹ᵉ¹ヨ⁘\0~	ャ⁵¹ᵉ¹ᵉ¹ヨ⁵\0@¹ヨᵇ\n⁘²⁴\0「◀\0ᶠ\0\n」\0‖\0「◀\0!\0⁙◀\0-\0「」\0R\0「」\0J\0\n゛¹Z\0\n⁘¹s\0□゛\0g\0•\0\0🐱\0⁶campus⁷⁘\0}■\0ヨ⁸¹ᶜ¹\r¹ヌᶠ\0Y■\0ᶠ¹ᵉ¹ヌ⁶\0@²ム⁘」\0mモ◝ヲ⁸¹ᵉ¹゛⁘\0ᶜャ⁵⁵\0\0⁘\0,ッ⁸¹ᶠ⁵•\0\0S\0⁙⁘\0B\0◀⁘\0H\0¥ロ◝k\0⁸フ\0~\0⁴stav⁶」\0E‖\0ル¹ス⁘\0\0」\0A‖\0¹ヌ(\0A²\0¹ヌ゛\0A¹\0²フᶠ(\0A²\0²ムᶠ⁷「フ\0A\0□フ\0G\0「フ◜G\0□ᵉ\0U\0◀ᵉ◜U\0▮ᶜ\0P\0■▮\0O\0⁴blanᵇ゛\0@²ムᶠ⁵\0Lャ⁵²ヨᶠ⁵\0@²ヨᶠ⁵\0/ロ◝\0ヲ⁸¹ᵉ゛\0Aル◝²ム⁘゛\0@²」ム⁘\0Aワ◝²」ム⁸\0Aマ◝²フ⁘2\0H▮²ム」(\0I⁶\0゛¹フ」\0▮¹ᶜ⁵•\0\0%\0¥ッ\0に\0¥ッ\0ほ\0¥⁶\0ほ\0³マ³ノ\0⁴chic²゛\0	¥\0⁷゛\0-ヌ◝ャ⁵²ᶠᶜ¹⁘ス\0ᶠ\0ᶜ²",
-- suzuka
"²⁵⁵start⁸\n\0<ロ⁴¹ᶠ¹\r<\0,ロ⁴¹\r⁘\0⁸ᶠ⁘\0 ²ᶠ\r#\0G\n\0\nヨ¹フ#\0Qᵉ\0¹ᵉ¹ツᶠ\0⁴マ⁘\0dヨ²ᶠᵉ¹ぬ■ᵇ\0\0⁘\0、ᶠ\0\0\0、ᶠ\0\n\0、ᶠ\0⁘\0、ᶠ\0゛\0、ᶠ\0(\0、ᶠ\0002\0⁸ム\0\0\0⁷ム\0‖\0•\0\0A\0□ムャ(\0゜⁸\0H\0⁷フ\0∧\0 ヲョU\0、゛\0キ\0⁷ヌ\0ね\0¥\n\0h\0⁴scrv⁸」\0ᶠラ◝¹ャ゛゛\0ᵇ\r\0⁘ᶠ⁘\0ᶜヨ⁵」\0⁵リ◝ヲ*\0Sᵉ\0⁙²ᶠᵉ¹ツ\n\0Cュ◝ヲ¹ろ」\0sユ◝\0²ᶠ\r¹ᶜ¹((\0Aリ◝¹<ᵇ。゛\0\n\0「フ\0.\0⁸ヌ\0}\0」⁘\0キ\0」\n\0ゆ\0◀7\0 \0⁸ヌ\0007\0「2\0^\0⁘⁘\0_\0ᶜムュK\0⁷ム\0⬅️\0⁶degner	」\0hᶠ¹\r¹ヨ\n\0クᵇ\0	²ᶠᵉ¹ヨ⁘\0@¹ヨ」\0]▮\0ャ⁵¹ᵉ¹フ\n\0\0゛\0□ロ¹\r⁘\0p²ᶠ\r²ᶠ\r¹ムᶠ\0s\r\0\0¹ᵉ¹\r¹ウ□\0`¹ᶜ¹ᶠᵇ゜ウ\0-\0•\0\0U\0「ヨ\0F\0「ロ\0d\0「\n\0d\0□\n\0]\0\nᶠ\0s\0 ョョ☉\0⁸ス\0か\0!を◝U\0!:◝U\0²hp▮<\0Kナ◝\0ᶜ²F-⁘\0 ¹\r」\0y⁷\0\n²ᶠᵉ²ᶠ\r²ムツ\n\0Kᵇ\0ᶜ⁶²ムツ⁘\0³⁸\0ュ⁘\0M⁸\0リ⁘¹ム」\0⁷	\0ワヌ⁘\0b\0¹ᶜ¹゛゛\0aモ◝²ᶠᶜ¹゛」\0¹ル◝ᶠ\0Gム◝⁘ロ¹゛゛\0O◝◝\0ン⁷¹゛(\0○◝◝ワャ⁵¹\r¹\r¹ᶠ2\0B\0²ᶠ▶」\0`²ᶠ\r¹ワ」\0▮²ᶠ\rᵉ	□\0=\0•\0\0○\0 ョョP\0「」\0シ\0	#\0マ\0◀\n\0/¹•\0\0Z¹「⁸\0d¹•\0\0🐱¹¥ヲ\0j¹□\n\0け¹□\n◜け¹」ル\0の¹ ³ョね¹³cas⁶⁘\0=ラ◝ヲᶜ²ᶠᵉ²ᶠᵉ゛\0¹ワ◝゛\0,ッ⁴¹ᶜ⁘\0⁵‖\0ム⁘\0\rミ◝ヲ⁘#\0-\r\0ロ⁴¹\r⁶•◝\0O\0」□\0'\0」⁘\0:\0⁸ヌ\0V\0⁸ヌ\0c\0⁷ム\0█\0\r²"
}

__gfx__
00000000cccccccc00000000000077770000000000000000000000000000000099cccccc81111111111111888811111111111118ccccc677d1dcc777d1dcc677
0000000077777777000000077777776700770000000000000000000000000000c67ccccc81111111111118111181111111111118ccc11d77d1117777d111d677
00700700777777770007677766777777777707000077000000000000000000005577755c81111111111181000018111111111118ccc11d76111177761111d676
0007700077777777077777667777777766777777777777700000000000000000559995598ccccccccccc81000018ccccccccccc8ccc11d5111116d5111116656
0007700077777777666677777777766766666677066776670000000000000000cccccccc81111111111811000011811111111118cc1dd111d5111111d51d1117
0070070077777777000776676667666766770000007660000000000000000000cccccccc81111111111811000011811111111118cc7761116776111d67711117
0000000077777777000000007670007000000000000000000000000006688668cccccccc8ccccccccc811111111118ccccccccc8cc76d1116777111d6771111c
00000000cccccccc000000000000000000000000000000006688668866886688cccccccc8ccccccccc811111111118ccccccccc8cc5115d6115d15d6115155dc
ddddddddebebbbee0000b0000000000b200000000000000007777770cccccccccccccccc8ccccccccc8111bbbb1118ccccccccc8cc111777111177771111d77c
ddddddddebbbebbe0000b0000000000be00000000000000005577550cccccccccccccccc8ccccccccc811eb77be118ccccccccc8cd111777111177771d11d77c
ddddddddbeee2eee000be200000000eee20000000000000000077000cccccccccccccccc8cccccccc811ebbbbbbe118cccccccc8cd11d776111177761d11d77c
ddddddddbbbee2ee00eb20000000000ee00000000777700000077000cccccccccccccccc8cccccccc81191111119118cccccccc8c6dd11516d516d51665ddd5c
ddddddddbeeeb2e2000bee0000000ebb202000000066000000077000cccccccccccccccc8cccccccc81177777777118cccccccc8c776111177761111777611cc
ddddddddbee2eee20e0eb220000000ebe0e000000000000000055000ccc2222222222ccc8cc888cc8167766666677618cc888cc8677711117777111d777d11cc
ddddddddebeee2220bbee0000000b0beee2200000000000000000000cc222222222222cc8ccaaacc8ddd66777766ddd8ccaaacc877cccc11777d111d776d11cc
ddddddddee22ee2ebbee2e2000000eeee20000000000000000000000cc222222222222cc8cccccac1dd8888888888dd1caccccc8cccccccccc6d11cccc6111cc
55555555ee2ebebbbbbeeee20000b0b0bbb0000000000000ccccccc1111111111111228888888888888ff888aaaaaaaaaaaa888888221111111111111ccccccc
55555555e22bbbbbbbbbbb22000bbbb0bb00bb0000000000cccccc121111111111211aaaaaaaa88888fff8888aaaaaaa11aaaaa1aaa112111111111121cccccc
55555555ebebbeebbebebeee0b00beebbe0eb00000000000cccccc152122121222511a1111111a88a8fff8888aaaaaaa1aaa111111a115222121221251cccccc
55555555bbbbbbbeeebbeebbbbb00bbeeebbeee000000000cccccc15225522525521111111111aa8a8fff8888aaaaaaa1aa11111111112552522552251cccccc
55555555bbbbebbbebbeeeee0bbbebbbebbe00ee00000000ccccc1212222122225111111111111a8a8fff8888aaaaaaa1aa111111111115222212222121ccccc
55555555ebbbbbbeeeeee2e200bbbbbeeeeee2e200000000ccccc1211111111115111111dd111118a8ff88888aaaaaaa1aa111111111115111111111121ccccc
55555555bbbebeeee2e22ee2b0bebeeee2e22e0086688660ccccc111111111111211dd1111dd111aa8888aaaa11aaaaaaa11111111dd112111111111111ccccc
55555555bbbbebee22eeee22bbbbebee22eee02288668866ccccc11111111111111151dd1111dd1aa88aa8888aa11aaaa1111111dd15111111111111111ccccc
ccccccccbeebe2e22beeeee2beebe2e22beeeee200000000cccc88111111111111115111dd111111a8a888888aaaa1aa111111dd11151111111111111188cccc
ccccccccbbbeeee2bbee222ebbbeeee2bbee200000000000ccccfa11111111111111511111dd11ddaa8888888aaaaa1add11dd11111511111111111111afcccc
ccccccccebeee2eebeee222eebeee2eebeee202000000000ccccfa1111111111111151111111dd11aa8888888aaaaaaa11dd1111111511111111111111afcccc
ccccccccebe22ebeeee22e220be22ebeeee22e2200000000cccf8aaaaaaaaaaa1111511111dd111a8a8888888aaaaaa1a111dd1111151111aaaaaaaaaaa8fccc
ccccccccebebeeeeee22e22e0bebeeeeee22e22000000000ccc8aaaaaaaaaaaaaaaaaaaaaaaaaaaaf8a88888aaaaaaa1aaaaaaaaaaaaaaaaaaaaaaaaaaaa8ccc
ccccccccb2e2eee2eeee2e2e0e0eee02eee0202000000000ccc8a8888888888888888888888888888faa8888aaaaaa1a888888888888888888888888888a8ccc
ccccccccee22e222e2e2bbe2000e2002e2e0000000000000ccc8ac111111111111111111111111111aaaa88aaaaaa1aa11111111111111111111111111ca8ccc
ccccccccee2eee22222eee2e0000ee02202e000088668866cccaacc111111111111111ccccccccc111aaaaaaaaaaa1111ccccccccc111111111111111ccaaccc
6d6d6d6d0000000066666666666666666666666dcccccccccccccccc000000000000000000000000000000000000000000000000000000000000000000000000
d6d6d6d6000000006555555555555555555555d5cccccccccccccccc000000000000000000000000000000000000000000000000000000000000000000000000
6d6d6d6d00000000650000000000000000000065c55c55cc55ccc55c000000000000000000000000000000000000000000000000000000000000000000000000
d6d6d6d6000000006500000000000000000000655cc5cc5ccc5c5ccc000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd00000000650000000000000000000065ccccccccccc5cccc000000000000000000000000000000000000000000000000000000000000000000000000
d6d6d6d688888888650000000000000000000065cccccccccccccccc000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd88888888650000000000000000000065cccccccccccccccc000000000000000000000000000000000000000000000000000000000000000000000000
dd6ddd6d88888888650000000000000000000065cccccccccccccccc000000000000000000000000000000000000000000000000000000000000000000000000
dddddddd00000000650000000000000000000065cc1111111cccc111111ccccc0000000000000000000000000000000000000000000000000000000000000000
dddddddd00000000650000000000000000000065cc16616611111161161111cc0000000000000000000000000000000000000000000000000000000000000000
dddddddd00000000650000000000000000000065cc16161616661161111661cc0000000000000000000000000000000000000000000000000000000000000000
dddddddd00000000650000000000000000000065cc16161616161666116111cc0000000000000000000000000000000000000000000000000000000000000000
d5ddd5dd00000000650000000000000000000065cc16161616161161111161cc0000000000000000000000000000000000000000000000000000000000000000
dddddddd66666666650000000000000000000065cc16161616661161c16611cc0000000000000000000000000000000000000000000000000000000000000000
5d5d5d5d66666666650000000000000000000065cc11111111111111c1111ccc0000000000000000000000000000000000000000000000000000000000000000
dddddddd66666666650000000000000000000065cccccccccccccccccccccccc0000000000000000000000000000000000000000000000000000000000000000
d5d5d5d5cc56d5cc6500000000000000000000650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d5d5d5dcc56d5cc6500000000000000000000650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d5d5d5cc56d5cc6500000000000000000000650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d5d5d5dcc56d5cc6500000000000000000000650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555cccccccc6500000000000000000000650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d5d5d5dcccccccc6500000000000000000000650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555cccccccc6d66666666666666666666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55d555d5ccccccccd555555555555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000017100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000016710000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
51555155000000000016671000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000016d10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151500000000001d100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
51515151888866660001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111888866660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000cccccc0000000000000000
cccccccccccc0000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc07777770cccccc0000000000000000
cccccccccc007777777770cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc07777770cccccc0000000000000000
ccccccccc0777777777770cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc07777770cccccc0000000000000000
ccccccc007777777777770cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc07777770cccccc0000000000000000
cccccc0077777777777770cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc07777770cccccc0000000000000000
cccccc0777777777777770cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc07777770cccccc0000000000000000
ccccc07777777777777770cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc07777770cccccc0000000000000000
ccccc09999999990000000cccccccccccc0000000cccccc0000000000ccccccccccccc000000000ccccccccccccc00000009999990cccccc0000000000000000
cccc099999999008888880ccccccccccc09999990ccccc0099999999900cccccccccc00999999990cccccccccc0099999009999990cccccc0000000000000000
cccc099999990080000000cccccccccc099999990ccc0099999999999900cccccccc0999999999990cccccccc09999999009999990cccccc0000000000000000
cccc09999999080c000000000cccccc0999999990ccc09999999999999900cccccc099999999999990cccccc099999999009999990cccccc0000000000000000
cccc0999999900cc0999999900cccc09999999990cc099999999999999990ccccc00999999999999990cccc0999999999009999990cccccc0000000000000000
cccc099999990ccc0999999990cccc09999999990c09999999999999999990cccc09999999999999990ccc00999999999009999990cccccc0000000000000000
cccc099999990ccc09999999990ccc09999999900c09999999999999999990cccc09999999999999990ccc09999999999009999990cccccc0000000000000000
cccc099999990ccc09999999990ccc09999990000c09999990000099999990cccc09999990009999990ccc09999990000009999990cccccc0000000000000000
cccc099999990ccc09999999990ccc09999990880c09999990888809999990ccc099999908809999990ccc09999990888009999990cccccc0000000000000000
cccc0999999900cc00099999990cc09999999000c099999990000009999990ccc099999900009999990cc099999990000009999990cccccc0000000000000000
cccc08888888800c08808888880cc088888800ccc008888880cccc08888880ccc08888880cc08888880cc008888880cccc08888880cccccc0000000000000000
cccc00888888880000008888880cc088888800ccc008888880000008888880ccc08888880cc08888880cc008888880000008888880cccccc0000000000000000
cccc00888888888888888888880cc08888880ccccc08888888888008888880ccc08888880cc08888880ccc08888888888888888880cccccc0000000000000000
ccccc0088888888888888888880cc08888880ccccc08888888888008888880ccc08888880cc08888880ccc08888888888888888800cccccc0000000000000000
ccccc0808888888888888888800cc08888880ccccc00888888888008888880ccc08888880cc08888880ccc0088888888888888880ccccccc0000000000000000
cccccc000444444444444444000cc04444440ccccc08044444444004444440ccc04444440cc04444440ccc0804444444444444400ccccccc0000000000000000
ccccccc0804444444444444000ccc04444440cccccc0004444444004444440ccc04444440cc04444440cccc000444444444444000ccccccc0000000000000000
ccccccc0080044444444440080ccc04444440ccccccc080044444004444440ccc04444440cc04444440ccccc0800444444440080cccccccc0000000000000000
ccccccccc0880000000000880cccc00000000cccccccc08000000000000000ccc00000000cc00000000cccccc080000000000800cccccccc0000000000000000
cccccccccc00888888888800ccccc08888880ccccccccc0888888008888880ccc08888880cc08888880ccccccc088888888880cccccccccc0000000000000000
cccccccccccc0000000000ccccccc00000000cccccccccc000000000000000ccc00000000cc00000000cccccccc0000000000ccccccccccc0000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000
cccccccccccccccccccccccccccccccccccccccccccc00000ccccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccccccccccccccccccccc0777770cccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000
ccccccccccccc000000000ccccccccccccccccccccc0777770cccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000
ccccccccccc0077777777700cccccccccccccccccc07777770cccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000
cccccccccc007777777777700ccccccccccccccccc00777770cccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000
ccccccccc00777777777777700cccccccccccccccc00777770cccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000
ccccccccc07777777777777770ccccccccccccccccc0000000cccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000
cccccccc0999999999999999990cccccccccccccccc0888880cccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000
cccccccc0999999999999999990ccccccccccccccc00000000ccc00000000cc00000000c00000000000000000000000000000000000000000000000000000000
cccccccc0999999000099999990ccccccc0000000c09999990ccc09999990cc09999990c00000000000000000000000000000000000000000000000000000000
cccccccc0999999088099999990cccccc09999990c09999990ccc09999990cc09999990c00000000000000000000000000000000000000000000000000000000
cccccccc0999990000099999990ccccc099999990c09999990ccc09999990cc09999990c00000000000000000000000000000000000000000000000000000000
ccccccc09999990000999999990cccc0999999990c09999990ccc09999990cc09999990c00000000000000000000000000000000000000000000000000000000
ccccccc09999990c09999999990ccc09999999990c09999990ccc00999990cc09999990c00000000000000000000000000000000000000000000000000000000
ccccccc09999990c09999999990ccc09999999990c09999990ccc009999990009999990c00000000000000000000000000000000000000000000000000000000
ccccccc09999990c09999999900ccc09999999900c09999990cccc09999999999999990c00000000000000000000000000000000000000000000000000000000
ccccccc09999990c09999999000ccc09999990000c09999990cccc00999999999999990c00000000000000000000000000000000000000000000000000000000
ccccccc09999990c0999999000cccc09999990880c09999990cccc00099999999999000c00000000000000000000000000000000000000000000000000000000
ccccccc08888880c0000000800ccc08888888000cc08888880ccccc0088888888888000c00000000000000000000000000000000000000000000000000000000
ccccccc08888880c088888800cccc088888800cccc08888880cccc00888888088888880c00000000000000000000000000000000000000000000000000000000
ccccccc08888880c0000000cccccc088888800cccc08888880cccc08888880008888880c00000000000000000000000000000000000000000000000000000000
ccccccc08888880cccccccccccccc08888880ccccc08888880cccc08888880808888880c00000000000000000000000000000000000000000000000000000000
ccccccc08888880cccccccccccccc08888880ccccc08888880cccc08888808008888880c00000000000000000000000000000000000000000000000000000000
ccccccc08888880cccccccccccccc08888880ccccc08888880ccc088888800c08888880c00000000000000000000000000000000000000000000000000000000
ccccccc04444440cccccccccccccc04444440ccccc04444440ccc04444440cc04444440c00000000000000000000000000000000000000000000000000000000
ccccccc04444440cccccccccccccc04444440ccccc04444440ccc04444440cc04444440c00000000000000000000000000000000000000000000000000000000
ccccccc04444440cccccccccccccc04444440ccccc04444440ccc04444440cc04444440c00000000000000000000000000000000000000000000000000000000
ccccccc00000000cccccccccccccc00000000ccccc00000000ccc00000000cc00000000c00000000000000000000000000000000000000000000000000000000
ccccccc08888880cccccccccccccc08888880ccccc08888880ccc08888880cc08888880c00000000000000000000000000000000000000000000000000000000
ccccccc00000000cccccccccccccc00000000ccccc00000000ccc00000000cc00000000c00000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000000000000000000000000000
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777ccccccc7777cccccccccccccc7777cccc777cccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777ccccc77777cccccccccccccc7777cccc777cccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77777ccccc77777cccccccccccccc7777cccc777cccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777ccc777777cccc77777cccc77777777c777ccc77777cccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777ccc777777ccc7777777ccc77777777c777cc77777777cccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777577c7757777cc777555777cc57777555c555cc77755577cccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777c77c77c7777cc777ccc777ccc7777ccccccccc77777c55cccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777c57775c7777c7777ccc7777cc7777ccccccccc7777777ccc00000000cccccc
cccccccccccccccccccccccc00000000000ccccccccccccccccccccccccccc7777cc777cc7777c5777ccc7775cc7777ccccccccc5555777ccc07777770cccccc
cccccccccccccccccccccc0077777777770ccccccccccccccccccccccccccc7777cc575cc7777cc777ccc777ccc5777cccccccc7cccc777ccc07777770cccccc
ccccccccccccccccccccc07777777777700c77cccccccccccccccccccccccc7777ccc5ccc7777cc577777775cccc777777ccccc77777777cc077777700cccccc
ccccccccccccccccccc0077777777777700777777ccccccccccccccccccccc7777ccccccc7777ccc5777775ccccc577777ccccc55777775cc077777700cccccc
cccccccccccccccccc007777777777777006677667cccccccccccccccccccc5555ccccccc5555cccc55555ccccccc55555ccccccc55555ccc077777700cccccc
ccccccccccccccccc07777777777777770cc766cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc07777770ccccccc
cccccccccccccccc007777777777777770ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc000007777770ccccccc
cccccccccccccccc077777777700000000ccccccccccc0000000ccccccc000000000ccccccccccccccc00000000ccccccccccccc00000000077777700ccccccc
ccccccccccccccc0aaaaaaaa0088888880ccccccccc00aaaaaa0ccccc00aaaaaaaaa00ccccccccccc00aaaaaaaa00cccccccccc00aaaaa000aaaaaa00cjccccc
ccccccccccccccc0aaaaaaa08888888880cccccccc00aaaaaaa0ccc00aaaaaaaaaaaaa0cccccccc00aaaaaaaaaaa00ccccccc00aaaaaaa000aaaaaa00jjjcccc
cccccccccccccc0aaaaaaa00880000000cccccccc00aaaaaaaa0cc00aaaaaaaaaaaaaaa0cccccc00aaaaaaaaaaaaa0cccccc00aaaaaaaa000aaaaaa0jjjjjjjc
cccccccccccccc0aaaaaaa0800c00000000ccccc00aaaaaaaaa000aaaaaaaaaaaaaaaaa0cccccc0aaaaaaaaaaaaaaa0cccc0aaaaaaaaaa000aaaaaa0j3j1jj1j
ccccccccccccc0aaaaaaa080cc0aaaaaaa0ccccc0aaaaaaaaa0000aaaaaaaaaaaaaaaaa0ccccc0aaaaaaaaaaaaaaaa0ccc00aaaaaaaaa000aaaaaa003jjjj11j
jcccccccccccc0aaaaaaa000cc0aaaaaaaa0ccc00aaaaaaaa0000aaaaaaaaaaaaaaaaaaa0ccc00aaaaaaaaaaaaaaaa0ccc0aaaaaaaaa0000aaaaaa00j3jjjj11
jcccccccccccc0999999900ccc0999999990ccc0999999900000999999900000099999990ccc0999999000009999990cc09999999000000099999900jjjjj1jj
jjccccccccccc099999990cccc0999999990ccc0999999088800999999008888099999990ccc0999999088809999990cc0999999088880009999990jrr3jrrrr
jjccccccccccc099999990cccc099999999033r0999999088000999999088888099999990ccc0999999088809999990cc0999999088800c09999990rjrrrrr3r
jjrjccccccccc0999999900j3r00999999903r09999990800009999990800000099999900cc09999990000099999900c09999999000000099999900rrr3rrr33
jj3jjcccccrcr0999999990ar30409999990r3099999900ccc0999999900j1j1099999900cc099999900jj099999900j09999999033j30099999900r33rr33j3
j3rr3jjjcccrr088888888800000088888803j088888800ccc08888888000000088888800cc08888880033088888800308888888000000888888800r33r3jj3r
3r333jjjjjrrj008888888888888888888003r08888880cccc0888888888880008888880jjj08888880rrj088888803j0888888888888888888800j3jr33jjrr
3rj3jjjjjjjj300888888888888888888800jr08888880cccc0088888888880008888880jjj08888880j3j08888880rr0088888888888888888000jj3j33jjr3
r333rrjjjjj3308088888888888888888080j0888888006ccc0088888888800088888800jj088888800jr0888888003r0088888888888888888080jj3jjj3j3j
33r3r3rjjj3rr3000888888888888888080r3088888800cccc0008888888800088888800jj088888800r60888888003j080888888888888880080r3r3r3jrr66
r3rr3333jrr3jr08004444444444444088033044444400cccjj000444444400044444400jj0444444006304444440033r00044444444444400800rrr3366rr3r
jrrjjr33j333jr30800444444444400880r6304444440674444080044444400044444404440444444046r04444440r3j30800444444444008880r563r3rr366r
333666jj3jj33rr008800000000008880r6560000000044444400880000440000000000444000000004630000000033333088000000000888003353366rrr333
6663j3jj333j33j500888888888888803636408888880444444400888880000088888804440888888046608888880r3jj600888888888888006rj5j333r66633
3r33j3rrr43jr665600888888888800j636460888888044444777008888880008888880444088888804460888888033rr360088888888800r3r36563jj3333r3
rrr33rr36666666566600000000003j6656640000000044444444450000880000000000444000000004470000000063jrrr66000000000rr33rr353j366633r3
3666666666jjrr3566666j3r3r5363633746644444444444444445165550006555555555444444444444447646r737j63j366665j333666666333533r3376j33
3673j367r3373335r3633j3j63566j733444464444444444444440555555555555555055444444444444444464656533637656j5rr7337rrr7333566rr73r367
rr3676r3663366r56r56735733565r56667444444444444444445055555555555555555544000004444444444464446646636365673673r663r6753366r3j366
7rr656rr637jjr653j735375j75476488888866888888444444505555555555555555055407777088886688888874444647636r533363r73637rr5r73rr676rr
6663j366j36j73357j567r3646546448888a956688000000000055555555555555555555077777708a9566a888847664445760000r36r66jr6633566r33666rr
33j36rjr663j6475447444746654444888894999007777777770055555555555555555550777777085499998888446476466307703j763563j3665336633r366
77633j76344644657646644676564448888588007777777777777055555555555555555507777700808888088884444444576077036588888888888888888888
66574644664446454474646464444444444440077777777777777705556666666666666507777080444444444444444444000077000088888888888888888888
777777777777775d4646664444444444444400777777777777777770775575555555555600000880444444444444444444077777777088888888888888888886
d77777777777775d444444444444444444400777777777777777777055555555555555550888880644444444444444444407777777708888888888885aaa4996
d44676444344445d4444444777777174444077777777777777777770555555555550000000000044664000000044440000000077000088888888888805994495
d44646733333335d0047444777777110004077777700000077777770557555000000000777777044440777777044407777088077088088888888888805aaa44a
d00444433333335d5001000144444000050777777088888077777770555500777777000777777065440777777044407777000077000088888888888805599949
d50044333333335d0000055504440000510aaaaaa0888800aaaaaaa055500aaaaaaa000aaaaaa055650aaaaaa04440aaaaaa0000044488888888888855599949
d5504433333333500000551503350000100aaaaaa00000aaaaaaaaa05500aaaaaaaa000aaaaaa005550aaaaaa04440aaaaaa0088044488888888888885544449
d0157333333333500000510050330000100aaaaaa0550aaaaaaaaa00500aaaaaaaaa000aaaaaa055550aaaaaa06640aaaaaa0000044488888888888885500049
3300100000033330000051605033000050aaaaaa0050aaaaaaaaaa0050aaaaaaaaa000aaaaaa0055550aaaaaa0650aaaaaa00444444488888888888885500544
3000500005003330000050105033000050aaaaaa0050aaaaaaaaa08000aaaaaaaa0000aaaaaa0055550aaaaaa0000aaaaaa00444444444444444444444444444
00051111110003j0000051050j555000109999990050999999990005099999990000009999990055550999999999999999000444444444444444444444444444
00005111150003300000555505555555709999990550999999900805099999908880009999990555550099999999999990005555554444444444444444444444
00000000000000jj0000050055555557509999990550999990088055099999908800009999990555550009999999999900800055555544444444444444444444
55555555555555555555555555555575099999900500000000880050999999080000099999900555550999999999999990005555555566554444444444444444
55555555555555555555555555555575099999900508888888800550999999005550099999900555509999999999999999055000550000055555555444444444
55555555555555555555555555555755088888800508888880055550888888005555088888800555088888800000888888065555555555005555555555544444
55550005555555555555555555557555088888805500000000555550888888005555088888806655088888808880888888056555555555555555666555555444
55555555555555555555555555575555088888805555555555555550888888055555088888805555088888808880888888055655555555555555110000055555
55555555555555555555555555755550888888005555555555555508888880055550888888005550888888000008888880055565555555555555555555500005
55555555555555555555555555655550444444005555555555555504444440055550444444005550444444005504444440055565555555555555000055500005
55555555555555555555555556555550444444005555555555555504444440055550444444005550444444005504444440055556555555555555555000055555
55555555555555555555555565555550444444055555555555555504444440555550444444055550444444055504444440555555655555555555555555555555
55555555555555555555555565555550000000055555555555555500000000555550000000055550000000055500000000555555655555555555555555555555
55555555555555555555555655555550888888055555555555555508888880555550888888055550888888055508888880555555565555555555555555555555
55555555555555555555555655555550888888055550000555555508888880555550888888055550888888055508888880555555565555555555555555555500
55555555555555555555556555555550000000055555555555555500000000555550000000055550000000055500000000555555556555555555555555555555
55555555555555500555556555555555555555555555555555555555555555555555555555555555555555555555555555555555556555550055555555555555
00000000000000000155556555555555555555555555555555555555555555555555555555555555555555555555555555555555556500010000000000000000
00000000000000000015565555555555555555555555555555555555555555555555555555555555555555555555555555555555555655100000000000000000
55555555555550000005565555555555555577777777777777777777777777777777777777777777777777777777555555555555555655000000555555555555
11111111111100000005565555555555555776777677767776777677767776777677767776777677767776777677755555555555555651000000011111111111
00000000000000000000655555555555555775555555555555557777555555555555555555555555555555555557755555555555555560000000000000000000
000000000000000000006555555555555c676508800888080005676750000000000000000000000000000000005767c555555555555560000000000000000000
000000000000000000006555555555ccc7767500800808080005767650r0r0r0r0r0r0r0r0909090909080800056767ccc555555555560000000000000000000
0000000000000006100165555555cc7776666500800888088805666650r0r0r0r0r0r0r0r0909090909080800056666777cc5555555161001610000000000000
11111111110000056006155555cc777776666500800008080805676650r0r0r0r0r0r0r0r090909090908080005666677777cc55555116006560000111111111
555555555500000561061555cc7777776666650888000808880566665000000000000000000000000000000000566666777777cc555106016560000555555555
1111111111000065561615cc777777cc6666655555555555555566665555555555555555555555555555555555566666cc777777cc5106165550000111111111
11111111110000655616cc777777cccs6666666666666666666666666666666666666666666666666666666666666666sccc777777cc16165550000111111111
000000000000006556cc777777ccccsc6666666666666666666666666555555555565556666666666666666666666666cscccc777777cc165550000000000000
0000000000000065cc777777cccscscs6566656665666566656665655555885555555555556665666566656665666566scscsccc777777cc5550000000000000
00000000000001cc777777ccccscssss6666666666666666666555555000880000050005555566666666666666666666sssscscccc777777cc50000000000000
000000000001cc777777cccscscsssss5656565656565656555555500000880000000000055555565656565656565656ssssscscsccc777777cc100000000000
1111111111cc777777ccccscssssssss6565656565656565555500000000088000000000000005556565656565656565sssssssscscccc777777cc1011111111
55555555cc777777cccscscsssssssss5555555555555555550000000000088000000000000000555555555555555555ssssssssscscsccc777777cc15555555
111111cc777777ccccscsssssssssjs566666666666665500000000000000880000000000000000055556666666666665sjssssssssscscccc777777cc111111
1111cc777777cccscscsssssssssss55555555555555550000000000005555555550055000000000005555555555555555ssssssssssscscsccc777777cc1111
01cc777777ccccscsssssssssssjs5555555555555555500000000000500000100055005500000000005555555555555555sjssssssssssscscccc777777cc10
cc777777cccscscsssssssssssss555555555555555500000000055550010017100010000550000000005555555555555555ssssssssssssscscsccc777777cc
777777ccccscsssssssssssssjs55555555555555550000000055550001710010001710005550000000005555555555555555sjssssssssssssscscccc777777
7777cccscscsssssssssssssss5555555555555555000000055555000001000000001000005555000000005555555555555555ssssssssssssssscscsccc7777
77ccccscsssssssssssssssss555555555555555500000005555500010000000000000010005555000000005555555555555555ssssssssssssssssscscccc77
cccscscsssssssssssssssss55555555555555550000005555555001710000000000001710055555500000055555555555555555ssssssssssssssssscscsccc
ccscsssssssssssssssssjs5550000555555555000000055555500001000000000000001000055555500000055555555555555555sjssssssssssssssssscscc
cscsssssssssssssssssss555055550555555500000005555555000000000000000000000000555555500000005555550000001155ssssssssssssssssssscsc
sssssssssssssssssssjs55505373350555555000000055555550001000000000000000001005555555500000055555500055676555sjsssssssssssssssssss
ssssssssssssssssssss5555053333505555550000005555555500171000000099990000171055555550500000555555000556765555ssssssssssssssssssss
sssssssssssssssssjs5555505r33r5055055000000500555555000100000000000099990100555555005000000550550000001155555sjsssssssssssssssss
ssssssssssssssssss555555053rr350500500000005000555550000000000000000000000005555500175000005550555555555555555ssssssssssssssssss
sssssssssssssssss5555555565555655055000000500005555500001000000000000001000055555001150000005505555555555555555sssssssssssssssss
ssssssssssssssss555555555566665550550000059990055555500171000000000000171005555550171050000055055555555555555555ssssssssssssssss
sssssssssssssjsj555555555511115555500000050010055555500010000000000000010005555550010050000055055555555555555555jsjsssssssssssss
ssssssssssssssjj555555555044440555500000500171055555550000010000000010000055555550171050000005550000001155555555jjssssssssssssss
sssssssssssjsjsj555555550487884055500000500110055555556000171000000171000655555550011050000005550005567655555555jsjsjsssssssssss
ssssssssssssjjj05555555504888840550000050017105555555550000100000000100005555555550171050000055500055676555555550jjjssssssssssss
sssssssssjsjsjjj5055505504f88f4055000005000105555550555661000000000016166515515555555550000005550000001150555055jjjsjsjsssssssss
ssssssssssjjj0j055555555048ff840550000050001655555555555566666666666666666666655550000000000005555555555555555550j0jjjssssssssss
sssssssssjsjjj0j050505055644446505500000501655050515151556666655556666666666660000000000000000555555555505050505j0jjjsjsssssssss
ssssssssjjj0j000555555555566665555000005666555555566666666666566665666666666660000000000000000555555555555555555000j0jjjssssssss
sssssjsjsjjj0j0050505050505151505500000055555550006666666666566776656666666666000000000000000055505050505050505000j0jjjsjsjsssss
ssssssjjj0j0000005050505050505055500000000000000006666666666567667656666666666000555500000000055050505050505050500000j0jjjssssss
sssjsjsjjj0j00005050505050505050550000000000000000666666666656666665666666666655505055555000005550505050505050500000j0jjjsjsjsss
ssssjjj0j00000000505050505050505550000000000000000666666666675666657666665151505050505055000005505050505050505050000000j0jjjssss
sjsjsjjj0j000000000000000000000055000000000000055566666666666755557666100000000000000000500000550000000000000000000000j0jjjsjsjs
ssjjj0j000000000050505050505050555000000000555550515151666666677776666050505050505050505000005550505050505050505000000000j0jjjss
sjsjjj0j0000000000000000000000005500000555550000000000000166666666666100000000000000000500000550000000000000000000000000j0jjjsjs
jjj0j0000000000000500050005000505500000500500050005000500051666666661050005000500050005500000550005000500050005000000000000j0jjj

__map__
0000303030090a0b0c3030300000000000000015000000000000000000000000000000000000000000000000424343434343434343434344303030303030303030303030303030304546808182838485868788898a8b8c8dc0c1c2c3c4c5c6c7c800000000000000000000000000000000000000000000000000000000000000
0000301718191a1b1c1718300500000002030400000000000000000000000000000000000000000000000000525353535353535353535354303030303030303030303030303030300000909192939495969798999a9b9c9dd0d1d2d3d4d5d6d7d800000000000000000000000000000000000000000000000000000000000000
0000262728292a2b2c2d2e2f0000001500000000000000000000000000000000000000000000000000000000525353535353535353535354303030303030303030303030303030300000a0a1a2a3a4a5a6a7a8a9aaabacade0e1e2e3e4e5e6e7e800000000000000000000000000000000000000000000000000000000000000
0000363738393a3b3c3d3e3f0000000000000000000000000013140000000000232400121314000000002324525353535353535353535354303030303030303030303030303030300000b0b1b2b3b4b5b6b7b8b9babbbcbdf0f1f2f3f4f5f6f7f800000000000000000000000000000000000000000000000000000000000000
0000000000000000000000002400000000000000000000000023242324000023212223222124131400233132525353535353535353535354303030303030303030303030303030300000555657000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000161616161616161616161124001314131400000000002321221132242322313231323132232423222122525353535353535353535354303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000002122242324232400002324232131322121223132112122212211313231323132525353535353535353535354303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000161616161616161616163132113132313224233132313132113131321121223132313221222122112122525353535353535353535354303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000002535350000000000000000000006060771714151415141514151415141517171626363636363636363636364303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000161616161616161616164040404040404040404040404040404040404040404040404040404040404040306130303030303030306130303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000001010101010101010101010101010101010101010101010101010101010101010000000000000000000000000303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000001010101010101010101010101010101010101010101010101010101010101010000000000000000000000000303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000005050505050505050505050505050505050505050505050505050505050505050000000000000000000000000303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000006060606060606060606060606060606060606060606060606060606060606060000000000000000000000000303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000007070707070707070707070707070707070707070707070707070707070707070000000000000000000000000303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000003030303030303030303030303030303000000000000000000000000000000000000000000000000000000000303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000003030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000003030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000003030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000003030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000003030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000002020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000002020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000002020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000002020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
650c00080933009430153301543009330094301533015430003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
050c00001d0531d01329600000001d4531d413286040000029634000001d0531d0131d4531d41339013000001d0531d01328604000001d4531d413286040000029634000001d0531d0131d4531d4133901329605
050c00001d0531d01329600000001d4531d413286040000029634000001d0531d0131d4531d41339013000001d0531d01328604000001d4531d413286040000029634000001d0531d0131d4531d4132963529635
110c00001c4551c4301a4551a4301c4551c43018455184301c4551c4301a4551a4301c4551c43018455184301c4551c4301a4551a4301c4551c43018455184301c4551c4301a4551a4301c4551c4302145021450
650c00080433004430103301043004330044301033010430000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
110c00001f4501f4501f4501f4501f4401f4401f4401f4401f4401f4401f4401f4401f4321f4321f4321f4321f4321f4321f4321f4321f4221f4221f4221f4201f4221f4221f4221f4221f4121f4121f4121f412
650c00080733007430133301343007330074301333013430000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
110c00001f4551f4301d4551d4301f4551f4301a4551a4301f4551f4301d4551d4301f4551f4301a4551a4301f4551f4301d4551d4301f4551f4301a4551a4301f4551f4301d4551d4301f4551f4301a4501a450
110c00001c4501c4501c4501c4501c4401c4401c4401c4401c4401c4401c4401c4401c4321c4321c4321c43200000000001c4401c44000000000001c4401c44000000000001c4401c44000000000001c4401c440
110c00001c4501c4501c4501c4501c4401c4401c4401c4401c4401c4401c4401c4401c4321c4321c4321c4321c4501c4551c4501c4501a4501a4501c4501c4501d4501d4501c4501c4501a4501a4501845018450
050c00001d0531d01329600000001d4531d413286040000029634000001d0531d0131d4531d41339013000001d0531d01328604000001d4531d41339013000001d4431d4431a4431a44315443154431344313443
290c00202875028750287502875028750287502875228752287422874228742287422873228732287322873228722287222871228712007000070000700007000070000700007000070026750267502475024750
290c002026750267502675026750267502675023750237501f7501f7501f7501f7501f7421f7421f7421f7421f7321f7321f7321f7321f7221f7221f7121f7120070000700007000070000000000000000000000
290c00202675026750267502675026750267502675026750267402674026740267402673226732267322673226722267222671226712007000070000700007000000000000000000000000000000000000000000
290c00202675026750267502675026740267402674026740267322673226732267322672226722267122671200000000000000000000000000000000000000002875028750287502875026750267502675026750
290c00202475024750247502475024750247502375023750217502175021750217502174021742217422174221732217322173221732217222172221712217122170021700217002170021750217502375023750
650c00080533005430113301143005330054301133011430000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
290c00202475024750247502475024740247422474224742247322473224732247322472224722247122471200000000000000000000000000000000000000002675026750267502675024750247502475024750
650c00200733007430133301343007330074301333013430073300743013330134300733007430133301343008330084301433014430083300843014330144300833008430143301443008330084301433014430
050c00001d0531d01329600000001d4531d413286040000029634000001d0531d0131d4531d41339013000001d4531d4531d4131c4531c4531c4131a4531a4531a4131845318453184131d4531c4531a45318453
290c00202675026750267502675026750267502675026752267422674226742267422673226732267322673228750287502875028750287002870028750287502870228702287402874028702287022874028740
110c00001533015330153301533015330153301533015330153301533015330153301532015322153221532215322153221532215322153221532215322153221531215312153121531215312153121531215312
650c00000933009430153301543009330094301533015430093300943015330154200932009420153201542009320094201532015420093200941015310154100931009410153101541009310094101531015410
__music__
00 00424344
00 00424344
00 00420144
00 00420244
00 00030144
00 04050244
00 06070144
00 04080244
00 00030144
00 04050244
00 06070144
00 04090a44
00 0057010b
00 0458020c
00 0057010b
00 0458020d
00 0659010e
00 0057010f
00 10420111
00 12421314
00 00030144
00 04050244
00 06070144
00 04080a44
00 00030144
00 04050244
00 06070144
00 04091344
00 00150144
00 00420144
00 00424344
00 16424344
00 29424344

