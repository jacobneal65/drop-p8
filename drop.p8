pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--main
--comet collection
--sun chaser
--by olivander65
function _init()
	--music(1)
	level=1
	wave=1
	t=0
	debug={""}
	effects={}
	--two flame effects
	f1c={8,9,10,5}--red effect
	f2c={7,6,6,5}--white to grey
	f3c={7,12,12,1}--blue flame
	shwv_clrs={8,9,9,10}
	bshv_c={7,12,12,12}
	--player
	p_x=64
	p_y=100
	p_spd=2
	--player offset l,r,b,t
	p_o={-1,8,1,-7}
	
	fruits={}
	fruitlet={}
	t_spr=64 --fruit sprite
	t_ybnd=128--lower y bound
	t_uybnd=-11--upper y bound
	t_grav=2
	grav=2
	
	b_arr={}--bezier array
	--pattern,sx,end_x,bez_arr
	levels={
		{{0,8,64},{1,64,120},{0,8,64},{1,64,120},{0,8,64},{1,64,120},{0,8,64}},
		{{2,64,64},{3,0,10},{4,48,80},{5,64,64,{64,-10,-40,32,64,140}},{5,64,64,{64,-10,168,32,64,140}}},

	}
	
	t_blue=0--tank blue
	points=0--points
	b_points=0--blue points
	b_amnt=0--#blue in wave
	fr_ani=false
	fr_spr=36
	fr_tmr=0
	
	
	fuel=120--red tank
	fl_ani=false
	fl_spr=52
	fl_tmr=0
	mult=1
	mult_up=0
	combo=0
	mult_sfx=1
	tf_tmr=0--transfer timer
	
	--stars
	starx={}
	stary={}
	starspd={}
	for i=1,100 do
		add(starx,flr(rnd(128)))
		add(stary,flr(rnd(128)))
		add(starspd,rnd(1.5)+0.5)		
	end
	
	--spinning score
	ss_ani={22,23,24,25,26,27,28,29,30,31}
	
	dots={}
	_dot_fn=init_dots
	
		--screen shake variables
	intensity = 0
	score_intensity = 0
	shake_control = 2
	cam_x,cam_y=0,0
	
 init_fruit()
 init_fruitlet()
 
 _upd=upd_player
	_drw=drw_level
end

function transfer_points()
		if tf_tmr>60 then
				if combo>0 then
					combo-=1
					points+=1
				else
				 tf_tmr=0
				end
		else
			tf_tmr+=1
		end
end

function _update()
	t+=1
	update_fx()
	if intensity > 0 then shake() end
	_upd()
	animatestars()
end

function _draw()
	cls()
	rectfill(0,0,128,8,1)
	starfield()
	draw_fx()
	_drw()
	
	--debug
	--debug_bounds()
	offst=0
	for txt in all(debug) do
		print(txt,10,offst,8)
		offst+=8
	end
end

-->8
--player

function upd_player()
	fuel-=0.3
	if fuel <=0 then
		debug[1]="out of fuel"
	end
	p_spr,b_spr,s_spr=3,1,19
	p_flp=false

	--left/right
	if btn(0) then 
	 p_x-=p_spd 
	 p_spr,b_spr,s_spr=4,17,21
	end
	if btn(1) then
	 p_x+=p_spd 
	 p_spr,b_spr,s_spr=4,17,21
	 p_flp=true
	end
	--up/down
	if (btn(2)) p_y-=p_spd
	if (btn(3)) p_y+=p_spd
	
	--bounds
	if (p_x > 114) p_x=114
	if (p_x < 0) p_x=1
	if (p_y > 120) p_y=120
	if (p_y < 16) p_y=17
	--transfer_points()
	--fruit
	update_fruit()
	update_fruitlet()
end

function drw_level()
	drw_dots()
	drw_player()
	drw_fruit()
	drw_points()
end

function drw_dots()
	--dots line
	for d in all(dots) do
		pset(d.x+4,d.y+4,2)
		fire(d.x+5,d.y+5,0,-0.5,1,2,f2c)
	end
end

function drw_player()
	--red tank
 tank=flr(min(fuel,100)/100*24)
 ty=0
	for i=1,tank do
		local _i=(i-1)%4+1
		if _i==1 then--newline
			ty+=1
		end
		local _clr = min(2,1+i%3)+8
		pset(p_x+8+_i,p_y+ty+1,_clr)
	end
	
	--blue tank
	blue_tnk=flr(min(b_points,t_blue)/t_blue*24)
 ty=0
	for i=1,blue_tnk do
		local _i=(i-1)%4+1
		if _i==1 then--newline
			ty+=1
		end
		--clrs = 3 and 12
		local _clr = min(1,i%3)*9+3
		pset(p_x-7+_i,p_y+ty+1,_clr)
	end

	--player
 local t_px=flr(p_x)
 local t_py=flr(p_y)
	spr(p_spr,p_x,p_y,1,1,p_flp)
	--red tank
	spr(s_spr,p_x+7,p_y+1,1,1)
	spr(fl_spr,p_x+7,p_y-7,1,1)
	--blue tank
	spr(s_spr,p_x-8,p_y+1,1,1)
	spr(fr_spr,p_x-8,p_y-7,1,1)
	
	--catching bucket
	spr(b_spr,p_x-4,p_y-8,2,1,p_flp)

	--flame
	if fuel >0 then
			f_sprs={5,6,7,6,5}
			spr(get_frame(f_sprs,1),t_px,t_py+8)
		end
end

function drw_points()
	--points
	spr(get_frame(ss_ani,2),0,0)
	print(points,8,2,7)
	
	--combo
	local c = combo.." x"..mult
	local lx,ly=126-#c*4,2
	if score_intensity > 0 then 
		lx,ly,score_intensity=shake_field(lx,ly,score_intensity)
		puff(lx,ly-2,{12,12,13,13})--{8,8,9,9})
	end
	print(c,lx,ly,8)
	print(combo,lx,ly,7)

end

function drw_fruit()
	--fruit
	for t in all(fruits) do
		circfill(t.x+4,t.y+4,2,12)
		rectfill(t.x+3,t.y+3,t.x+5,t.y+5,9)
		pset(t.x+3,t.y+3,7)
		fire(t.x+5,t.y+5,0,-0.5,2,3,f3c)
	end
	--fruitlet
	for fl in all(fruitlet) do
		local fls={11,12,13}
		if (fl.sz>1) fls={44,45,46,47}
		spr(get_frame(fls,2),fl.x,fl.y)
		fire(fl.x+3,fl.y+3,0,-1,1,2,f1c)
	end
end
-->8
--fruit
--load fruit is called at
--start and each new level
function init_fruit()
	--fill first array with fruit
	fill_fruit_wave()
	
	--calculate total blue points
	local wvs = levels[level]
	t_blue=0
	for wv in all(wvs) do
		local amt,_typ=10,wv[1]
		if _typ==4 then
			amt=5
		elseif _typ==5 then
			amt=20
		end
		t_blue+=amt
	end
	
--	if level==1 then	
--		fill_fruit(64,2,10,0)--zig
--	elseif level==2 then
--		fill_fruit(64,-2,10,0)--zig
--	elseif level==3 then
--		fill_fruit(0,1,10,1)--cross
--	elseif level==4 then
--		fill_fruit(0,1,5,2)--line
--	elseif level==5 then
--		fill_fruit(88,-2,10,0)
--		fill_fruit(88,2,10,0)--dzig
--	elseif level==6 then
--		fill_fruit(32,2,10,0)--dzig
--		fill_fruit(32,-2,10,0)
--	elseif level==7 then
--		bx2,by2=-40,32
--		bx3,by3=64,140
--		fill_fruit(64,1,10,3)--qbezier
--	elseif level==8 then
--		bx2,by2=168,32
--		bx3,by3=64,140
--		fill_fruit(64,1,10,3)--qbezier
--	elseif level==9 then
--		bx2,by2=64,150
--		bx3,by3=120,t_uybnd
--		fill_fruit(8,1,10,3)--qbezier
--	elseif level==10 then
--		bx2,by2=180,120
--		bx3,by3=-60,120
--		bx4,by4=64,t_uybnd
--		fill_fruit(64,1,10,4)--cbezier
--	end
end
function fill_fruit_wave()
	local wv=levels[level][wave]

	t_grav,t_tmr=2,0
	prvw,prvw_tmr=true,0
	
	local _x=rnd_rng(wv[2],wv[3])
	b_arr=wv[4]--bezier array
	local _typ=wv[1]
	
	if _typ==0 then--l_zig
		--(_x,_amt,_typ)
		fill_fruit(_x,10,0)
	elseif _typ==1 then--r_zig
		fill_fruit(_x,10,1)
	elseif _typ==2 then--cross
		fill_fruit(_x,10,2)
	elseif _typ==3 then--line
		fill_fruit(0,5,3)
	elseif _typ==4 then--dbl zig
		fill_fruit(_x,10,0)
		fill_fruit(_x,10,1)
	elseif _typ==5 then--q_bez
		fill_fruit(_x,10,5)
	elseif _typ==6 then--c_bez
--		bx2,by2=180,120
--		bx3,by3=-60,120
--		bx4,by4=64,t_uybnd
		fill_fruit(64,1,10,6)
	end
end

function fill_fruit(_x,_amt,_typ)
	prvw_typ=_typ
	for i=1,_amt do
		local _i,nx=i,_x
		--cros
		if _typ==2 and i%2==0 then
			_i=i-1
			nx=118
		--line
		elseif _typ==3 then
			nx=20*i
			_i=1
		end
 	fruit={
 		x=nx,
 		y=-10,
 		by=-10,
 		i=i,
 		tmr=0,
 		dly=8*_i,--delay
 		typ=_typ,
 	}
 	add(fruits,fruit)
 end	
end

function bucket_collides(fruit)
	--player bound
	pbl=p_x+p_o[1]
	pbr=p_x+p_o[2]
	pbb=p_y+p_o[3]
	pbt=p_y+p_o[4]
	--fruit bound
	fbl=fruit.x+3
	fbr=fruit.x+5
	tx={fbl,fbr}
	
	tbt=fruit.y+3
	tbb=fruit.y+5
	ty={tbt,tbb}

	local collides=false
	for i=1,2 do
		if tx[i]<pbr and tx[i]>pbl then
			for j=1,2 do
				if ty[j]>pbt and ty[j]<pbb then
					collides=true
				end
			end
		end
	end
	return collides
end

function update_fruit()
	if prvw then
		_dot_fn()
		--else start the delay
	else
		for fruit in all(fruits) do
			if fruit.dly >0 then
				fruit.dly-=1
			else
				if fruit.typ==5 or fruit.typ==6 then
						fruit.tmr=min(fruit.tmr+0.02,1)
						fruit.x,fruit.y=get_pattern(fruit)
				else
					fruit.y+=t_grav
					fruit.x=get_pattern(fruit)
				end
			end
			--fruit captured
			if bucket_collides(fruit) then
				score_intensity=0.5
				mult_up+=1
				if mult_up > 9 then
					mult_up=0
					mult+=1
				end
				combo+=5
				b_points+=1
				
				fr_ani,fr_tmr=true,0
				fr_spr=32
				
				if mult >4 then
					mult_sfx=7
				elseif mult>1 then
					mult_sfx=6
				end
				shwave(fruit.x+3,fruit.y+3,1,4,bshv_c)
				puff(fruit.x+3,fruit.y,f2c)
				del(fruits,fruit)
				tf_tmr=0	
				sfx(mult_sfx)
			end
			
			--tank animation		
			if fr_ani then
				fr_tmr+=1
				if fr_tmr>=8 then
					fr_spr=min(fr_spr+1,36)
					fr_tmr=0
					if (fr_spr==36) fr_ani=false
				end
			end
		
			--fruit survived
			if fruit.y>t_ybnd
			or fruit.y<=t_uybnd
			then
				del(fruits,fruit)
			end
		end		

		--got all fruit
		if #fruits==0 then
			fr_spr=36
			wave+=1
			if wave > #levels[level] then
				wave=1
				level+=1
			end
			if level < #levels+1 then
				fill_fruit_wave()
			else
				debug[2]="victory"
			end
		end
	end
end

function init_dots()
	dots={}
	for i=1,#fruits do
		add(dots,ct(fruits[i]))
	end
	_dot_fn=update_dots
end

function update_dots()
		for cd in all(dots) do
			if cd.dly >0 then
					cd.dly-=1
			else
				local _typ = cd.typ
				if _typ==5 or _typ==6 then
						cd.tmr=min(cd.tmr+0.02,1)
						cd.x,cd.y=get_pattern(cd)
				else
					cd.y+=t_grav
					cd.x=get_pattern(cd)
				end
			end
		end
		if prvw_tmr<=70 then
			prvw_tmr+=1
		else
			_dot_fn=finish_dots--switch fn
		end
end

function finish_dots()
	deli(dots,1)
	if #dots>0 then
		deli(dots,1)
	end
	if #dots==0 then
		prvw=false
		t_grav=grav
		_dot_fn=init_dots
	end
end

function get_pattern(_t)
	local _typ=_t.typ
	if _typ==0 or _typ==1 then--zig
		return zig_p(_t)
	elseif _typ==2 then--cros
		return cros_p(_t)
	elseif _typ==3 then--line
		if _t.y>100 then
			t_grav=-1
		end
		return _t.x
	elseif _typ==5 then--qbezier
		local b = b_arr
		return qbc(_t.tmr,b[1],b[2],b[3],b[4],b[5],b[6])
	elseif _typ==6 then--cbezier
		return cbc(_t.tmr,b[1],b[2],b[3],b[4],b[5],b[6],b[7],b[8])
	end	
end

function zig_p(_t)
	local dir=2
	if (_t.typ==1) dir=-2
	if _t.y >= 0 and _t.y < 50 then
		_t.x+=dir
	elseif _t.y >=50 then
		_t.x-=dir
	end
	return _t.x
end

function cros_p(_t)
	if _t.y >= 0 then
		local c_dir=-2
		if _t.i%2==1 then
			c_dir=2
		end
		_t.x+=c_dir
	end
	return _t.x
end

--quadratic bezier curve 3pts
function qbc(t,x1,y1,x2,y2,x3,y3)
	local _t1=(1-t)
	local _x = _t1^2*x1+2*_t1*t*x2+t^2*x3
	local _y = _t1^2*y1+2*_t1*t*y2+t^2*y3
	return _x,_y
end

--cubic bezier curve 4pts
function cbc(t,x1,y1,x2,y2,x3,y3,x4,y4)
	local _t1=(1-t)
	local _x = _t1^3*x1+3*_t1^2*t*x2+3*_t1*t^2*x3+t^3*x4
	local _y = _t1^3*y1+3*_t1^2*t*y2+3*_t1*t^2*y3+t^3*y4
	return _x,_y
end

-->8
--fruitlets
function init_fruitlet()
	fl_amt=5
	fruitlet={}
	for i=1,fl_amt do 
		generate_fruitlet(i)
	end
end

function generate_fruitlet(i)
	local fl={
 		x=rnd(96)+16,
 		y=-10,
 		tmr=0,
 		dly=8*i,--delay
 		spd=2,--f_rnd(2)+1,
 		sz=f_rnd(2)+1--1 or 2
 }
 add(fruitlet,fl)
end

function update_fruitlet()
	for fl in all(fruitlet) do
		if fl.dly >0 then
				fl.dly-=1
		else		
					fl.y+=fl.spd
		end
			--fruit captured
		if bucket_collides(fl) then
			combo+=fl.sz
			fuel = min(fuel+fl.sz*4,120)
			shwave(fl.x+3,fl.y+3,1,3,shwv_clrs)
			fl_ani,fl_tmr=true,0
			fl_spr=48
			del(fruitlet,fl)
			generate_fruitlet(1)
			tf_tmr=0	
			sfx(9)
		end
		
		--fl tank animation		
		if fl_ani then
			fl_tmr+=1
			if fl_tmr>=8 then
				fl_spr=min(fl_spr+1,52)
				fl_tmr=0
				if (fl_spr==52) fl_ani=false
			end
		end
		
		--fruit survived
		if fl.y>t_ybnd then
			del(fruitlet,fl)
			generate_fruitlet(1)
		end
	end
end


-->8
--tools
function get_frame(ani,spd)
 return ani[flr(t/spd)%#ani+1]
end 
--i=2 gives num between 0,1
--rnd never gives the limit
--value. rnd(1) will never
--give 1
function f_rnd(_i)
	return flr(rnd(_i))
end
--gives random number between
-- _s and _e
function rnd_rng(_s,_e)
	return f_rnd(_e-_s+1)+_s
end

function debug_bounds()
	--l,r,b,t
	local pl=p_x+p_o[1]--l
	local pr=p_x+p_o[2]--r
	local pb=p_y+p_o[3]--b
	local pt=p_y+p_o[4]--t
	pset(pl,pb,8)--bl
	pset(pr,pb,8)--br
	pset(pl,pt,8)--tl
	pset(pr,pt,8)--tr
		
	for fruit in all(fruits) do
		pset(fruit.x+4,fruit.y+4,8)
	end
		
end

--copy table
function ct(table)
	_nt={}
	for key,value in pairs(table) do
		_nt[key]=value
	end
	return _nt
end


function shake()
	local shake_x=rnd(intensity) - (intensity /2)
	local shake_y=rnd(intensity) - (intensity /2)
  
	--offset the camera
	camera( shake_x + cam_x, shake_y + cam_y)
  
	--ease shake and return to normal
	intensity *= .9
	if intensity < .3 then 
		intensity = 0 
		camera(cam_x,cam_y)
	end
end

function shake_field(_x,_y,_intensity)
	local shk_x=rnd(_intensity) - (_intensity /2)
	local shk_y=rnd(_intensity) - (_intensity /2)
	local rx,ry=shk_x+_x,shk_y+_y
	--ease shake and return to normal
	_intensity *= .9
	if _intensity < .3 then 
		return _x,_y,0
	end
	return rx,ry,_intensity
end



-->8
--particles
function add_fx(x,y,die,dx,dy,grav,grow,shrink,r,c_table,shwave)
    local fx={
        x=x,
        y=y,
        t=0,
        die=die,
        dx=dx,
        dy=dy,
        grav=grav,
        grow=grow,
        shrink=shrink,
        r=r,
        c=0,
        c_table=c_table,
        shwave=shwave
    }
    add(effects,fx)
end

function update_fx()
 for fx in all(effects) do
  --lifetime
  fx.t+=1
  if fx.t>fx.die then del(effects,fx) end

  --color depends on lifetime
  if fx.t/fx.die < 1/#fx.c_table then
      fx.c=fx.c_table[1]

  elseif fx.t/fx.die < 2/#fx.c_table then
      fx.c=fx.c_table[2]

  elseif fx.t/fx.die < 3/#fx.c_table then
      fx.c=fx.c_table[3]

  else
      fx.c=fx.c_table[4]
  end

  --physics
  if fx.grav then fx.dy+=.5 end
  if fx.grow then fx.r+=.1 end
  if fx.shrink then fx.r-=.1 end
		if fx.shwave then fx.r+=1 end
  --move
  fx.x+=fx.dx
  fx.y+=fx.dy
 end
end

function draw_fx()
 for fx in all(effects) do
  --draw pixel for size 1, draw circle for larger
  if fx.r<=1 then
      pset(fx.x,fx.y,fx.c)
  else
  	if fx.shwave then
				circ(fx.x,fx.y,fx.r,fx.c)           
  	else
  	 circfill(fx.x,fx.y,fx.r,fx.c)
  	end
  	 
  end
 end
end

-- fire effect
--dx/dy should be mults of -+.5
function fire(x,y,dx,dy,r,l,c_table)
 for i=0, 1 do
  --settings
  add_fx(
   x+rnd(1)-1/2,--x
   y+rnd(1)-1/2,--y
   l+rnd(l),--die
   dx,--dx
   dy,--dy
   false,--gravity
   false,--grow
   true,--shrink
   r,--radius
   c_table,--color_table
   false--shwave
      
  )
 end
end

function shwave(x,y,r,l,c_table)
 --settings
 add_fx(
     x,  -- x
     y,  -- y
     l+rnd(l),--die
     0,--dx
     0,--dy
     false,--gravity
     false,--grow
     false,--shrink
     r,--radius
     c_table,--color_table
     true --shwave
 )
end

function puff(x,y,col)
	for i=0,10 do
		local _ang=rnd()
		local _dx=sin(_ang)*2
		local _dy=cos(_ang)*2
		add_fx(
			x+4,
			y+4,
			5,-- die
			_dx,--dx
			_dy,--dy
			false,     -- gravity
			false,     -- grow
			true,      -- shrink
			rnd(3),--radius
			col,
			false--shwave
		)
	end
end

-->8
--starfield
function starfield()
	for i=1,#starx do
		local scol=6
		
		if starspd[i] < 1 then
			scol=1
		elseif starspd[i] < 1.5 then
			scol=13
		end
		
		if starspd[i] <= 1.5 then
			pset(starx[i],stary[i],scol)
			else
			line(starx[i],stary[i],starx[i],stary[i]+1,scol)
		end
		
	end
end

function animatestars()
	for i=1,#stary do
		local sy=stary[i]
		sy+=starspd[i]
		if sy>128 then
			sy-=128
		end
		stary[i]=sy
	end
end
__gfx__
00000000000000000000000007007070070707000007700000c77c000007700000c77c0000000000000000000000000000000000000000000000000000000000
00000000000d00000000d000060060600606060000000000000cc000000cc00000c77c0000000000000000000000000000000000000000000000000000000000
00700700000560000006500006556660065666600000000000000000000cc000000cc00000000000000000000000900000090000009009000000000000000000
0007700000056500005650006666d666566d6667000000000000000000000000000000000000000000000000009a90000009a900000a90000000000000000000
000770000005656666565000666d766656d766670000000000000000000000000000000000000000000000000009a900009a90000009a0000000000000000000
0070070000056556655650005665d665565d66670000000000000000000000000000000000000000000000000009000000009000009009000000000000000000
00000000000566566566500005666650056666700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000555555550000005dd500006dd6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000555500005550000055500000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000d0000000d000005000050050005000500050000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000005600000650000050000500500050005000500009559000045590000455a0000455a0000955a0000a55a0000a5590000a5540000a5540000955400
0000000000056500056500000500005005000d000d000500009999000049990000499a000049aa00009aaa0000aaaa0000aaa90000aa940000a9940000999400
0000000000056566656500000500005005000d000d000500009669000046690000469a000049aa00009aaa0000aaaa0000aaa90000aa940000a9640000966400
0000000000056556556500000500005005000d000d000500009999000049990000499a000049aa00009aaa0000aaaa0000aaa90000aa940000a9940000999400
000000000005665656650000050000d00500050005000500009999000049990000499a000049aa00009aaa0000aaaa0000aaa90000aa940000a9940000999400
00000000000055555550000000555d000055d00000d5500000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000022000000220000c0000c00c000c00000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000288200002882000c0000c00c000c00000000000000000000000900009000000009000000009000
00000000000000000000000000000000000000000000000000288200002882000c0000c00c000c00000044444444000009009000000900900009000000090000
00000000000000000000000000000000000000000000000002e88e2000288e200c0000c00c000c000444555cc155444000988000000889000008899009088900
00000c3000000350000005500000055000000550000000002e87c8e2027c88200d0b30d0050b0d00455566c7dc16555400088900009880000998800000988090
000050000000c000000030000000500000005000000000002881188202118820035cc530055c5300466666cddc16666400090090090090000000900000009000
00005000000050000000c0000000300000005000000000000285582002558220003dd300003d3000466666666666666400900000000009000000900000090000
0000500000005000000050000000c000000050000000000000299200002992000303303005030300544466666666444500000000000000000000000000000000
0000000000000000000000000000000000000000000000000d0000d00d000d000000000000000000055544444444555000000000000000000000000000000000
00000000000000000000000000000000000000000000000005600650056065000000000000000000061055555555006100000000000000000000000000000000
00000000000000000000000000000000000000000000000006566560055657000000000000000000061000000000006100000000000000000000000000000000
000000000000000000000000000000000000000000000000006cc600005c70000000000000000000061000000000006100000000000000000000000000000000
09a000000590000005500000055000000550000000000000005dd500055d75000000000000000000061000000000006100000000000000000000000000000000
00050000000a00000009000000050000000500000000000055566555556665550000000000000000061000000000006100000000000000000000000000000000
0005000000050000000a000000090000000500000000000006566560065656000000000000000000006610000000661000000000000000000000000000000000
000500000005000000050000000a0000000500000000000005422450054225000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0088880000cccc0000aaaa0000bbbb0000eeee000099990000000000000000000000000000000000000000000000000000000000000000000000000000000000
02000880010cc0c009aa00a0030bbbb0020e0ee00400099000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200088001c00cc009a0a0a003b0bbb0020e00e00499909000000000000000000000000000000000000000000000000000000000000000000000000000000000
0200088001c00cc0090a0aa003b00bb00200eee00400909000000000000000000000000000000000000000000000000000000000000000000000000000000000
02888080010cc0c009a0a0a0030bb0b0020000e00490909000000000000000000000000000000000000000000000000000000000000000000000000000000000
00222200001111000099990000333300002222000044440000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000029050290502805027050270501f0501d0501c0501b0503105018050170501605015050140501305012050110501c050100500e0500d0500b0500a0500905007050060500505005050040500305003050
49010000080500a0500d0502a050140501c0503205025050000002c05028050300502305034050360503905015050100501005010050100500000000000000000000000000000000000000000000000000000000
901000000f1550f1550f1550f1550f1550f1550f1550f1550f1550f1050f1050f1050f1050f1050f1550f1551110511105111050c1050f1550f1550f155111551115511155111551115511155111551115511155
90100000131551315513155131551315513155131551315513155131051310513105131551315513155131550c1550c1550c1550c1550c1550c1550c1550c1550c155131551315513155221551d1551615518155
051000000005500055000050000500055000550000500005000550005500005000050005500055000050000500055000550000500005000550005500005000050005500055000050000500055000550000500005
05100000000000000000003000030a063000000000300003000000000000000000000a063000000000000003000000000000000000000a063000000000000000000000000000000000000a063000000000000003
9101000008050370501b0501c0503805021050210503605032050230502f0502f050190501805018050300502d050250502d0502d050300503505000000000000000000000000000000000000000000000000000
900100001405116051190513605120051280513e05131051300012600116051170511b0511f0512305126051290512c051300513105139001380013a0513a0013d00100001000010000100001000010000100001
01200000233222332223322233222632228322283222832228322283222632226322263222632226322263222632226322233221f3221f3221f3221f3221f3221c3221c3221c3221c3221f3221f3221f3221f322
0101000012150081500a1500d150101501215014150171501a1501e1501b1500e1000f10012100081000a1000d100101001210014100171001a1001e1001b1001710000100001000010000100001000010000100
00010000190500e0501005014050160503705037050300503805038050300503805031050380503805032050380503405039050390503a0500000000000000000000000000000000000000000000000000000000
__music__
01 04454344
01 04054344
00 04050244
00 04050344
00 04050244
02 04050344

