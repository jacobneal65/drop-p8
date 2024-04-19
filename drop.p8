pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--main
--jupiter collection
--by olivander65
function _init()
	v="1"
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
	warp_c={7,11,11,3}
	--sun class
	sclrl={ 7,10,9}
	sclrd={12, 9,2}
	scls={"b","k","m"}
	sgtyp={"irregular","normal","incongruent"}
	intro_sun = f_rnd(3)+1
	--player
	p_x=64
	p_y=100
	p_spd=2.5
	pc_spr=3
	p_spr=3
	--player offset l,r,b,t
	p_o={-1,8,1,-7}
	
	fruits={}
	fruitlet={}
	t_spr=64 --fruit sprite
	t_ybnd=128--lower y bound
	t_uybnd=-11--upper y bound
	t_grav=2.5
	grav=2.5
	
	b_arr={}--bezier array
	--pattern,sx,end_x,bez_arr
	levels={
		{{0,8,64},{1,64,120},{5,32,64,{64,-10,-40,32,64,140}},{5,32,64,{64,-10,168,32,64,140}},{1,64,120},{0,8,64},{3,0,0}},
		{{2,0,60},{3,0,0},{2,0,60},{4,40,80},{4,40,80},{5,32,64,{64,-10,-40,32,64,140}},{5,32,64,{64,-10,168,32,64,140}}},
		{{8,80,80},{7,80,80},{9,70,100},{3,0,0},{9,70,100},{8,80,80},{7,80,80}},
		{{3,0,0},{6,0,0,{64,-10,180,120,-60,120,64,-11}},{5,32,64,{64,-10,-40,32,64,140}},{5,32,64,{64,-10,168,32,64,140}},{9,70,100},{8,80,80},{7,80,80}},

	}
	
	t_blue=0--tank blue
	points=0--points
	b_points=0--blue points
	b_amnt=0--#blue in wave
	fr_ani=false
	fr_spr=36
	fr_tmr=0
	
	fuel=110--red tank
	fuel_mx=110
	low_fuel=false
	fuel_mask_mx=91
	fuel_mask_r=fuel_mask_mx
	fl_ani=false
	fl_spr=52
	fl_tmr=0
	fl_off=0
	mult=1
	mult_up=0
	temp_points=0
	
	mult_sfx=1
	fruit_chain=0
	tf_tmr=0--transfer timer
	
	poke(0x5f34, 0x2)--circfade
	fade_dir=0
	fadding=false
	fade_r=100
	
	--stars
	starx={}
	stary={}
	starspd={}
	for i=1,100 do
		add(starx,flr(rnd(128)))
		add(stary,flr(rnd(128)))
		add(starspd,rnd(2)+0.5)		
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
	
 init_menu()
 in_menu=true
end

function blank() end

function _update()
	t+=1
	update_fx()
	if intensity > 0 then shake() end
	_upd()
	animatestars()
end

function _draw()
	cls()
	starfield()
	_drw()
	circfade()
	
	--debug
	--debug_bounds()
	offst=0
	for txt in all(debug) do
		print(txt,10,offst,8)
		offst+=8
	end
end

function init_menu()
	_upd=upd_menu
	_drw=drw_menu
	sun_off=-140
	gen_tmr=0
	init_fruitlet()
	m={"start game","endless mode","ship cust","high scores"}
	my_off={0,0,0,0}
	_lerpfn=blank
	lerp_tmr=0
	btn_sprs={92,93,94}
	s_stat="docked"
	s_clr=3
	rnd_chars={"ア","イ","ウ","エ","オ","カ","キ","ク","ケ","コ","サ","シ","ス","セ","ソ","タ","チ","ツ","テ","ト","ナ","ニ","ヌ","ネ","ノ"}
	rnd_char={}
	gen_char()
end

function gen_char()
	rnd_char={}
	for i=1,9 do
		add(rnd_char,rnd_chars[rnd_rng(1,#rnd_chars)])
	end
end

function upd_menu()
	if btnp(⬆️) then
		gen_char()
		--move vals down
		lerp_tmr=0
		local t_m=m[4]
		m[4]=m[3]
		m[3]=m[2]
		m[2]=m[1]
		m[1]=t_m
		ldir=-1
		_lerpfn=lerp_menu
		btn_sprs[1]=108
	elseif btnp(⬇️) then
		--move vals up
		gen_char()
		lerp_tmr=0
		local t_m=m[1]
		m[1]=m[2]
		m[2]=m[3]
		m[3]=m[4]
		m[4]=t_m
		ldir=1
		_lerpfn=lerp_menu
		btn_sprs[2]=109
		
		
	elseif btnp(🅾️) then
		--enter menu
		btn_sprs[3]=110
	end
	--bring in menu
	gen_tmr=min(gen_tmr+0.01,1)
	local _tmr=easeinoutovershoot(gen_tmr)
	sun_off=lerp(-150,-60,_tmr)
	menu_y=lerp(150,76,_tmr)
	if false then
		init_level()
	end
	if gen_tmr==1 then
		update_fruitlet()
	end
	
	_lerpfn()
	
end

function lerp_menu()
	lerp_tmr=min(lerp_tmr+0.2,1)
	local _t=easeinoutovershoot(lerp_tmr)
	for i=1,#m do
		my_off[i]=lerp(ldir*4,0,_t)
	end
	
	if lerp_tmr==1 then
		btn_sprs={92,93,94}
		_lerpfn=blank
	end
end

function oline(x1,y1,x2,y2,c1,c2,xo,yo)
	line(x1,y1,x2,y2,c1)
	line(x1+xo,y1+yo,x2+xo,y2+yo,c2)
end

function drw_menu()
	draw_fx()
	drw_fruit()
	draw_sun(intro_sun)
	local q = {"jupiter","collection"}
	oprint(q[1],hcenter(q[1])+sun_off+60,15,7,13)
	oprint(q[2],hcenter(q[2])+sun_off+60,23,7,13)
	--widow
	rect(0,0,127,75,6)
	rect(1,1,126,74,1)
	rectfill(0,76,128,128,5)
	--wires
	oline(0,85,45,85,8,2,0,1)
	oline(65,105,100,105,8,2,0,1)
	oline(65,85,100,85,8,2,0,1)
	oline(15,85,15,100,8,2,1,0)
	
	oline(15,100,64,100,8,2,0,1)
	oline(0,110,64,110,8,2,0,1)
	oline(64,110,120,110,8,2,0,1)
	
	roundrect(2,96,32,11,6,0)--stxt	
	print(s_stat,6,99,s_clr)
	roundrect(37,78,54,40,6,0)--term
	
	
	--ship ui
	roundrect(8,78,16,16,6,0)
	spr(p_spr,12,82)
	
	--central menu screen
	local iclr={3,11,3,3}--menu color
	for i=1,#m do
		if i==2 then
			lprint(m[i],hcenter(m[i]),menu_y+8*i+my_off[i],iclr[i],5)		
		else
			print(m[i],hcenter(m[i]),menu_y+8*i+my_off[i],iclr[i])		
		end
		rectfill(93,79,105,108,13)
		--btns
		spr(btn_sprs[1],96,80)
		spr(btn_sprs[3],96,90)
		spr(btn_sprs[2],96,99)
		
		--blocks the text scrolling in
		line(38,117,89,117,6)
		rectfill(0,118,128,128,5)
			--rivets
		circfill(3,80,2,6)--topleft
		rectfill(2,79,4,81,13)
		
		circfill(124,80,2,6)--toprght
		rectfill(123,79,125,81,13)
		
		circfill(3,124,2,6)--botleft
		rectfill(2,123,4,125,13)
		
		circ(116,80,1,13)
		pset(116,80,0)
		circ(110,80,1,13)
		pset(110,80,0)
		--r console
		roundrect(108,85,19,29,6,0)
		local ct=1
		for i=1,4 do
			for j=1,2 do
				print(rnd_char[ct],102+j*8,i*6+82,11)
				ct+=1
			end
		end
		
		local tx="property of orion corp"
		print(tx,hcenter(tx),122,6)
		print("v"..v,120,122,6)
	end	
end

-->8
--level
function init_level()
	init_fruit_wave()
 init_fruitlet()
 music(1)
 _upd=upd_level
	_drw=drw_level
end

function upd_level()
	fuel-=0.2
	fuel=max(fuel,0)
	if fuel <=0 then
		debug[1]="out of fuel"
	end
	rst_pspr()

	--left/right
	if btn(0) then 
	 p_x-=p_spd 
	 pc_spr,b_spr,s_spr=p_spr+1,17,21
	end
	if btn(1) then
	 p_x+=p_spd 
	 pc_spr,b_spr,s_spr=p_spr+1,17,21
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
	--fruit
	update_fruit()
	update_fruitlet()
end

function drw_level()
	drw_circ_mask()
	rectfill(0,0,128,8,1)
	draw_fx()
	drw_dots()
	drw_player()
	draw_fuel()
	drw_fruit()
	drw_points()
end

function drw_circ_mask()
	if low_fuel then
		fuel_mask_r=max(fuel_mask_r-1,79)
	else
		fuel_mask_r=min(fuel_mask_r+1,fuel_mask_mx)	
	end
	circfill(64,64,fuel_mask_r+sin(time()),2 | 0x1800)
end

function drw_dots()
	--dots line
	for d in all(dots) do
		pset(d.x+4,d.y+4,11)
		fire(d.x+5,d.y+5,0,-0.5,1,2,f2c)
	end
end

function draw_fuel()
		local _f=fl_off
		roundrect(1+_f,14,9+_f,9,5,2)
		print("f",4+_f,17,1)
		print("f",4+_f,16,9)
 	roundrect(2+_f,24,7+_f,40,5,6)
 	line(6+_f,25,4+_f,25,1)
 	line(6+_f,62,4+_f,62,1)
 	
 	--fuel warning
	 bigtank=flr(min(fuel,fuel_mx)/fuel_mx*36)
	 for i=1,bigtank do
	 	local _clr = min(2,1+i%3)+8
	 	if bigtank < 10 then
	 		_clr=max(1,(i%3-1)*7)+7
	 		local txt="low fuel"
	 		low_fuel=true
	 		print(txt,hcenter(txt),64+sin(time()),8)
	 		else
	 			low_fuel=false
			end
			line(3+_f,62-i,7+_f,62-i,_clr)
  end
end

function drw_player()
	--line under ship
	line(p_x-1,p_y+5,p_x+8,p_y+5,5)
	--red tank insides
 tank=flr(min(fuel,fuel_mx)/fuel_mx*24)
 ty=0
	for i=1,tank do
		local _i=(i-1)%4+1
		if _i==1 then--newline
			ty+=1
		end
		local _clr = min(2,1+i%3)+8
		pset(p_x+8+_i,p_y+ty+1,_clr)
	end
	
	--blue tank insides
	blue_tnk=flr(min(b_points,t_blue)/t_blue*24)
 ty=0
	for i=1,blue_tnk do
		local _i=(i-1)%4+1
		if _i==1 then--newline
			ty+=1
		end
		--clrs = 3 and 12
		local _clr = min(1,i%3)*9+3
		pset(p_x-5+_i,p_y+ty+1,_clr)
	end

	--player
	spr(pc_spr,p_x,p_y,1,1,p_flp)
	--red tank
	spr(s_spr,p_x+7,p_y+1,1,1,p_flp)
	spr(fl_spr,p_x+7,p_y-7,1,1)
	--blue tank
	spr(s_spr,p_x-6,p_y+1,1,1,p_flp)
	spr(fr_spr,p_x-7,p_y-7,1,1)
		
	--catching bucket
	spr(b_spr,p_x-4,p_y-8,2,1,p_flp)

	--flame
	if fuel >0 then
		f_sprs={5,6,7,6,5}
		spr(get_frame(f_sprs,1),p_x,p_y+8)
	end

end

function rst_pspr()
	pc_spr,b_spr,s_spr=p_spr,1,19
	p_flp=false
end

function drw_points()
	local _lvl="level: "..level
 print(_lvl,hcenter(_lvl),2,7)
	--points
	spr(get_frame(ss_ani,2),0,0)
	print(points,8,2,7)
	
	--temp_points
	local c = temp_points.." x"..mult
	local lx,ly=126-#c*4,2
	if score_intensity > 0 then 
		lx,ly,score_intensity=shake_field(lx,ly,score_intensity)
		puff(lx,ly-2,{12,12,13,13})--{8,8,9,9})
		puff(lx+10,ly-2,{12,12,13,13})
	end
	print(c,lx,ly,8)
	print(temp_points,lx,ly,7)

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
function init_fruit_wave()
	local wv=levels[level][wave]

	t_grav,t_tmr=grav,0
	prvw,prvw_tmr=true,0
	
	local _x=rnd_rng(wv[2],wv[3])
	b_arr=wv[4]--bezier array
	local _typ=wv[1]	
	if _typ==3 then--line
		fill_fruit(0,5,_typ)
	elseif _typ==4 then--dbl zig
		fill_fruit(_x,10,0)
		fill_fruit(_x,10,1)
	elseif _typ==6 then--c_bez
		fill_fruit(64,10,_typ)
	elseif _typ==7 then--stgr l
		fill_fruit(0,8,_typ)
	elseif _typ==8 then--stgr r
		fill_fruit(120,8,_typ)
	else--any other pattern
		fill_fruit(_x,10,_typ)		
	end
	
	--calculate total blue points
	local wvs = levels[level]
	t_blue=0
	for wv in all(wvs) do
		local amt,_typ=10,wv[1]
		if _typ==3 then
			amt=5
		elseif _typ==5 then
			amt=20
		end
		t_blue+=amt
	end	
end

function fill_fruit(_x,_amt,_typ)
	prvw_typ=_typ
	for i=1,_amt do
		local _i,nx=i,_x
		--cros
		if _typ==2 and i%2==0 then
			_i=i-1
			nx=_x+80
		--line
		elseif _typ==3 then
			nx=20*i
			_i=1
		elseif _typ==7 then--stag line
			nx=12*i
		elseif _typ==8 then--stag line
				nx-=12*i
		elseif _typ==9 then--zig r stgr
				if i<5 then
					nx-=12*i
				else
					nx+=12*(i-10)
				end
		end
 	fruit={
 		x=nx,
 		y=-10,
 		i=i,
 		tmr=0,
 		dly=8*_i,--delay
 		typ=_typ,
 		amt=_amt,
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
				fruit_chain+=1
				if mult_up > 9 then
					mult_up=0
					mult+=1
				end
				temp_points+=5
				b_points+=1
				
				fr_ani,fr_tmr=true,0
				fr_spr=32
				
				mult_sfx=1
				if fruit_chain > 9 then
					mult_sfx=7

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
			fruit_chain=0
			--no more waves in level
			if wave > #levels[level] then
				wave=1
				_upd=init_eol--end of lvl
			else
				init_fruit_wave()
			end		
		end
	end
end

function get_pattern(_f)
	local _typ=_f.typ
	if _typ==0 or _typ==1 then--zig
		return zig_p(_f)
	elseif _typ==2 then--cros
		return cros_p(_f)
	elseif _typ==3 then--line
		if _f.y>100 then
			t_grav=-1
		end
		return _f.x
	elseif _typ==5 then--qbezier
		local b = b_arr
		return qbc(_f.tmr,b[1],b[2],b[3],b[4],b[5],b[6])
	elseif _typ==6 then--cbezier
		local b = b_arr
		return cbc(_f.tmr,b[1],b[2],b[3],b[4],b[5],b[6],b[7],b[8])
	else--simple falling
		return _f.x
	end	
end

function zig_p(_f)
	local dir=2
	if (_f.typ==1) dir=-2
	if _f.y >= 0 and _f.y < 50 then
		_f.x+=dir
	elseif _f.y >=50 then
		_f.x-=dir
	end
	return _f.x
end

function cros_p(_f)
	if _f.y >= 0 then
		local c_dir=-2
		if _f.i%2==1 then
			c_dir=2
		end
		_f.x+=c_dir
	end
	return _f.x
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
		if bucket_collides(fl) and not in_menu then
			temp_points+=fl.sz
			fuel = min(fuel+fl.sz*4,110)
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
--dots
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
				if cd.typ==5 or cd.typ==6 then
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
-->8
--end of level
function init_eol()
	s_tmr=0
	dk_tmr=0--dock
	m_off=80
	mv_plyr=true
	fruitlet={}
	--reset plyr spr
	rst_pspr()
	fr_spr,fl_spr=36,52--tanks
	dock_spr=76
	wrp_spr=86
	w_off=-100
	init_plerp()
	d_plyr=drw_player--draw fn
	e_state=0
	eol_mask=10
	ismask=true
	fl_off=-20
	sun_off=140
	_upd=upd_eol
	_drw=drw_eol
end

function upd_eol()
	--lerp the player to middle
	if e_state == 0 then
		m_off=max(0,m_off-1)
		if m_off == 0 then
			e_state=1
		end
	end
	
	if mv_plyr then
		p_lerp(74,72)
	else
		s_tmr=min(s_tmr+1,90)
		if s_tmr==60 then
			temp_points=mult*temp_points
			mult=1
			score_intensity=0.5
			sfx(11)
		elseif s_tmr>=90 then
			if temp_points > 0 then
				if temp_points > 50 then
					points+=50
					temp_points-=50
				else
					points+=temp_points
					temp_points-=temp_points
				end
				sfx(12)
			end
		end
	end
	if e_state==1 then
		--extend
		if gen_tmr > 2 then
			dock_spr-=1
			gen_tmr=0
			sfx(13)
			if dock_spr==70 then
				puff(62,74,f2c)
				e_state=2
			end
		else
		 gen_tmr+=1
		end
	end
	if e_state==2 then
		--drain and fill tanks
		if gen_tmr > 10 then
			sfx(14)
			gen_tmr=0
			fuel=min(fuel+10,fuel_mx)
			if b_points > 10 then
				b_points-=10
			else
				b_points=0
			end
			if fuel==fuel_mx and b_points == 0 then
				e_state=3
			end
		else
			gen_tmr+=1
		end
	end
	if e_state==3 then
		--retract
		if gen_tmr > 2 then
			dock_spr+=1
			gen_tmr=0
			sfx(13)
			if dock_spr==76 then
				e_state=4
				init_plerp()
			end
		else
		 gen_tmr+=1
		end
	end
	if e_state==4 then
		m_off+=1.5
		p_lerp(60,64)
		if m_off>150 then
			e_state=5
			gen_tmr=0
		end
	end
	if e_state==5 then
		--open warp
		w_off=0
		wrp_spr=min(wrp_spr+2,90)
		puff(60,24+w_off,warp_c)
		if wrp_spr==90 then
			e_state=6
			d_plyr=drw_sqsh
			sfx(16)
		end
	end
	if e_state == 6 then
		--warp out
		p_y=max(p_y-5,30)
		if p_y==30 then
			d_plyr=blank
			e_state =7
			gen_tmr=0
		end
	end
	if e_state == 7 then
		gen_tmr=min(gen_tmr+1,10)
		if gen_tmr==10 then
			w_off=-40
			e_state=8
			init_circfade()
			gen_tmr=0
		end
	end
	--show next sun
	if e_state==8 and fadding == false then
		gen_tmr=min(gen_tmr+0.01,1)
		local _tmr=easeoutinquart(gen_tmr)
		sun_off=lerp(140,-140,_tmr)
		if sun_off ==-140 then
			e_state=9
		end
	end
	
	if e_state==9 and fadding == false then
		--open warp
		w_off=80
		wrp_spr=min(wrp_spr+2,90)
		puff(60,24+w_off,warp_c)
		if wrp_spr==90 then
			e_state=10
			p_x,p_y=60,102
			init_plerp()
			d_plyr=drw_sqsh
			sfx(16)
		end
	end
	if e_state==10 then
		--warp in
		p_y=max(p_y-5,64)
		if p_y==64 then
			d_plyr=drw_player
			e_state =11
			gen_tmr=0
			w_off=-40
		end
	end
	if e_state == 11 then
		ismask=false
		if eol_mask==10 then
			gen_tmr=0
			fl_str=fl_off
			e_state = 12
		end
	end
	if e_state==12 then
		--slide in ui elements
		gen_tmr=min(gen_tmr+0.02,1)
	 local _t=easeinoutovershoot(gen_tmr)
		fl_off=lerp(fl_str,0,_t)
		if gen_tmr==1 then
			e_state=13
		end
	end
	if e_state==13 then
		if level < #levels then
			level+=1
			_upd=upd_level
			_drw=drw_level
			fuel_mask_r=fuel_mask_mx
			init_fruitlet()
			init_fruit_wave()
			
		else
			debug[1]="no more levels"
		end
	end

end

function init_plerp()
	gen_tmr=0
	ip_x,ip_y=p_x,p_y
end

function p_lerp(ex,ey)
	gen_tmr=min(gen_tmr+0.01,1)
 local _t=easeinoutovershoot(gen_tmr)
	p_x=lerp(ip_x,ex,_t)
	p_y=lerp(ip_y,ey,_t)
	if gen_tmr==1 then
		mv_plyr=false
	end
end  

function drw_sqsh()
	line(p_x+4,p_y-5,p_x+4,p_y+10,7)
	line(p_x+3,p_y-5,p_x+3,p_y+10,7)		
end

function drw_eol()
	draw_sun()
	
	d_plyr()
	draw_fuel()
	drw_eol_mask()
	rectfill(0,0,128,8,1)
	draw_fx()
	draw_mothership()
	drw_points()
	draw_warp()
end

function drw_eol_mask()
	if ismask then
		eol_mask=max(eol_mask-0.5,0)	
	else 
		eol_mask=min(eol_mask+0.5,11)	
	end	
	rectfill(10-eol_mask,-10,118+eol_mask,130,0 | 0x1800)
	rect(10-eol_mask,-10,118+eol_mask,130,13)
end

function draw_mothership()
	local mx,my=16,32
	spr(64,mx,my+m_off,6,10)
	fire(mx+11,my+72+m_off,0,0.5,6,6,f3c)
	fire(mx+39,my+72+m_off,0,0.5,6,6,f3c)
	spr(dock_spr,mx+45,my+42+m_off)
end

function draw_warp()
	spr(wrp_spr,56,20+w_off,2,2)	
end

function draw_sun(l)
	if l then
		_l=l
	else
		_l=level
	end
	c2,c1=sclrl[_l],sclrd[_l]
 x,y=63,63+sun_off
 num=100
 r=30
 rndm=15
 for i=1,num do
 	line(x,y,x+cos(i/num)*(r+flr(rnd(rndm)))
 	, y+sin(i/num)*(r+flr(rnd(rndm))),c1)
 end
 for i=1,num do
 	line(x,y,x+cos(i/num)*(r+flr(rnd(rndm)))
 	, y+sin(i/num)*(r+flr(rnd(rndm))),c2)
 end
 rd=34
 circfill(x,y,rd+1+cos(time()),c2)
	circfill(x,y,rd+cos(time()),c1)
	local y1=54+sun_off
	local y2=y1+16
	ovalfill(30-cos(time()),y1,97+cos(time()),y2,c2)--white
	ovalfill(30-cos(time()),y1-1,97+cos(time()),y2-1,c1)--blue
	local txt="class "..scls[level]
	local txt2="grav: "..sgtyp[level]	
	if not l then
		oprint(txt,hcenter(txt)+sun_off,48,7,13)
		oprint(txt2,hcenter(txt2)+sun_off,56,7,13)
	end
end

 
-->8
--particles

--starfield
function starfield()
	scols={6,13,1}
	for i=1,#starx do
		local scol=scols[1]
		
		if starspd[i] < 1 then
			scol=scols[3]
		elseif starspd[i] < 1.5 then
			scol=scols[2]
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

function hcenter(s)
	return 64-#s*2
end

--do not use a changing
--value for a silly boi
function lerp(a,b,t)
	return a+(b-a)*t
end

function easeoutovershoot(t)
	t-=1
	return 1+2.7*t*t*t+1.7*t*t
end

function easeinoutovershoot(t)
	if t<.5 then
		return (2.7*8*t*t*t-1.7*4*t*t)/2
	else
		t-=1
		return 1+(2.7*8*t*t*t+1.7*4*t*t)/2
	end
end

function easeoutelastic(t)
	if(t==1) return 1
	return 1-2^(-10*t)*cos(2*t)
end

function easeoutquad(t)
	t-=1
	return 1-t*t
end

function easeoutinquart(t)
	if t<.5 then
		t-=.5
		return .5-8*t*t*t*t
	else
		t-=.5
		return .5+8*t*t*t*t
	end
end

function init_circfade()
	fade_tmr=0
	fade_dir = -1
	fadding=true
	fade_r=100
end

function circfade()
	--add 111
	if fade_dir == -1 then
		fade_r = max(fade_r-2,0)
		if fade_r==0 then
			pset(64,64,1)
			fade_tmr+=1
			if fade_tmr>9 then
				fade_dir = 1
			end
		end
	elseif fade_dir==1 then
		fade_r=min(fade_r+2,100)
		if fade_r==100 then
			fadding = false
			fade_dir = 0
		end
	end
	circfill(64,64,fade_r,1 | 0x1800)
	if fade_r>1 then
		circ(64,64,fade_r,5)
	end
--	fade_dir
end

function roundrect(_x,_y,_w,_h,_oc,_ic)--draws box with round corner
	rectfill(_x,_y+1,_x+max(_w-1,0),_y+max(_h-1,0)-1,_oc)
	rectfill(_x+1,_y,_x+max(_w-1,0)-1,_y+max(_h-1,0),_oc)
	rectfill(_x+1,_y+2,_x+max(_w-1,0)-1,_y+max(_h-1,0)-2,_ic)
	rectfill(_x+2,_y+1,_x+max(_w-1,0)-2,_y+max(_h-1,0)-1,_ic)
end

function oprint(_t,_x,_y,_main_c,_shadow_c)
	print(_t,_x+1,_y+1,_shadow_c)
	print(_t,_x,_y,_main_c)
end

function lprint(_t,_x,_y,_main_c,_shadow_c)
	print(_t,_x,_y+1,_shadow_c)
	print(_t,_x,_y,_main_c)
end
__gfx__
0000000000000000000000000c0000c00c000c000007700000c77c000007700000c77c0000000000000000000000000000000000000000000000000000000000
00000000000d00000000d0000c0000c00c000c0000000000000cc000000cc00000c77c0000000000000000000000000000000000000000000000000000000000
007007000005d000000d50000c0000c00c000c000000000000000000000cc000000cc00000000000000000000000900000090000009009000000000000000000
0007700000056500005650000c0000c00c000c00000000000000000000000000000000000000000000000000009a90000009a900000a90000000000000000000
00077000000565dddd5650000d0b30d0050b0d000000000000000000000000000000000000000000000000000009a900009a90000009a0000000000000000000
007007000005655665565000635cc536655c53560000000000000000000000000000000000000000000000000009000000009000009009000000000000000000
000000000005665665665000003dd300003d30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000055555555000003033030050303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000565000000550000005500000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000d0000000d000005000500005005000050050000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000005d00000d50000050005000050050000500500009559000045590000455a0000455a0000955a0000a55a0000a5590000a5540000a5540000955400
0000000000056500056500000500050000500d0000d00500009999000049990000499a000049aa00009aaa0000aaaa0000aaa90000aa940000a9940000999400
00000000000565ddd56500000500050000500d0000d00500009669000046690000469a000049aa00009aaa0000aaaa0000aaa90000aa940000a9640000966400
0000000000056556556500000500050000500d0000d00500009999000049990000499a000049aa00009aaa0000aaaa0000aaa90000aa940000a9940000999400
00000000000566565665000005000d000050050000500500009999000049990000499a000049aa00009aaa0000aaaa0000aaa90000aa940000a9940000999400
0000000000005555555000000055d0000005d000000d500000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000022000000220000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000288200002882000000000000000000000000000000000000000900009000000009000000009000
00000000000000000000000000000000000000000000000000288200002882000000000000000000000044444444000009009000000900900009000000090000
00000000000000000000000000000000000000000000000002e88e2000288e2000000000000000000444555cc155444000988000000889000008899009088900
00000c3000000350000005500000055000000550000000002e87c8e2027c88200000000000000000455566c7dc16555400088900009880000998800000988090
000050000000c0000000300000005000000050000000000028811882021188200000000000000000466666cddc16666400090090090090000000900000009000
00005000000050000000c00000003000000050000000000002855820025582200000000000000000466666666666666400900000000009000000900000090000
0000500000005000000050000000c000000050000000000000299200002992000000000000000000544466666666444500000000000000000000000000000000
0000000000000000000000000000000000000000000000000d0000d00d000d000700707007070700055544444444555000000000000000000000000000000000
00000000000000000000000000000000000000000000000005600650056065000600606006060600061055555555006100000000000000000000000000000000
00000000000000000000000000000000000000000000000006566560055657000655666006566660061000000000006100000000000000000000000000000000
000000000000000000000000000000000000000000000000006cc600005c70006666d666566d6667061000000000006100000000000000000000000000000000
09a000000590000005500000055000000550000000000000005dd500055d7500666d766656d76667061000000000006100000000000000000000000000000000
00050000000a00000009000000050000000500000000000055566555556665555665d665565d6667061000000000006100000000000000000000000000000000
0005000000050000000a000000090000000500000000000006566560065656000566665005666670006610000000661000000000000000000000000000000000
000500000005000000050000000a000000050000000000000542245005422500005dd500006dd600000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000d000000d000000d000000d000000d000000d000000d000000000000000000000000000000
000000000000000000000000000000000000000000000000551551d315515d505155d500551d500055d500005d500000d5000000000000000000000000000000
000000000000000000000000000000000000000000000000616616d366166d501661d500616d500061d500001d500000d5000000000000000000000000000000
000000000000000000000000000000000000000000000000166166d361661d506616d500166d500016d500006d500000d5000000000000000000000000000000
0000000600000000000000000000000000000000060000000000000d000000d000000d000000d000000d000000d000000d000000000000000000000000000000
00000006600000000000000000000000000000006600000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000006660000000000000000000000000000066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000006560000000000000000000000000000065600000000000000000000000000000000000000000000000000000000000000000000000088800000000000
00000006566000666666666666666666666000665600000000000000000000000000000000000000000000000000000088888880888888800855580000000000
00000006566006666666666666666666666600665600000000000000000000000000000000000000000000000000000088858880858885808588858000000000
00000006566666111111111111111111111666665600000000003333333300000000000000000000000000000000000088585880885858808588858000000000
0000000656666611111111111111111111166666560000000003bbbbbbbb30000000333333330000000000000000000085888580888588808588858000000000
000000065666611111111111111111111111666656000000033bbbbbbbbbb3300333bbbbbbbb3330000000000000000088888880888888802855582000000000
00000006556661111111111111111111111166655600000003bbb333333bbb303bbbbbbbbbbbbbb3000333333333300088888880888888800288820000000000
0000000665666111111111111111111111116665660000003bbb3bbbbbb3bbb33bb3333333333bb3033bbbbbbbbbb33022222220222222200022200000000000
0000000655666111111111111111111111116665566000003bb3bbbbbbbb3bb33bb3333333333bb33bbb33333333bbb300000000000000000000000000000000
0000006655666611111111111111111111166665566000003bbb3bbbbbb3bbb33bbbbbbbbbbbbbb3033bbbbbbbbbb33000000000000000000088800000000000
00000066556666111111111111111111111666655660000003bbb333333bbb300333bbbbbbbb3330000333333333300088888880888888800855580000000000
00000033556655dd66666666666666666dd5566553300000033bbbbbbbbbb3300000333333330000000000000000000088858880858885808588858000000000
00000033556655dd66666666666666666dd55665533000000003bbbbbbbb30000000000000000000000000000000000088585880885858808588858000000000
00000033556655dd66666666666666666dd556655330000000003333333300000000000000000000000000000000000085888580888588808588858000000000
00000033556666dd5555dd66666dd5555dd666655330000000000000000000000000000000000000000000000000000088888880888888800855580000000000
00000033556666dd5555dd66666dd5555dd666655330000000000000000000000000000000000000000000000000000088888880888888800088800000000000
00000066556666dd6666dd66666dd6666dd666655660000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000066556666dd6666dd66666dd6666dd666655660000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000066556666dd6666dd66666dd6666dd666655660000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000066556666dd6666dd66666dd6677dd666655660000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000066556666dd6666dd66666dd6677dd666655660000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000066556666dd6666dd66666dd6677dd666655660000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000066556677dd6666dd66777dddd66dd667755660000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000066556677dd6666dd66777dddd66dd667755660000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006655556666dd6666dd66666dd6666dd666655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006655556666dd6666dd66666dd6666dd666655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006655556666dd6666dd66666dd6666dd666655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006655556666dd6677dd66666dd7766dd666655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006655556666dd6677dd66666dd7766dd666655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006655556666dd6677dd66666dd7766dd666655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000
000011555566dddd6666dd66666dd6666dd666655551100000000000000000000000000000000000000000000000000000000000000000000000000000000000
000011555566dddd6666dd66666dd6666dd666655551100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001155557766dd7766dd66666dd6677dd776655551100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001155557766dd7766dd66666dd6677dd776655551100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001155557766dd7766dd66666dd6677dd776655551100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001155556666dd6666dd66666dd6666dd666655551100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001155556666dd6666dd66666dd6666dd666655551100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001155556666dd6666dd66666dd6666dd666655551100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001155556666dd6666dd66666dd7766dd666655551100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001155556666dd6666dd66666dd7766dd666655551100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001155556677dd6677dd66666dd6666dd667755551100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001155556677dd6677dd66666dd6666dd667755551100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001155556677dd6677dd66666dd6666dd667755551100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006655556666dd6666dddd666dd6666dd666655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006655556666dd6666dddd666dd6666dd666655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006655556666dd6666dddd666dd6666dd666655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006655556666dd6666dd66666dd6677dd776655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006655556666dd6666dd66666dd6677dd776655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006655556666dd6666dd66666dd6666dd666655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006655556666dd6666dd66666dd6666dd666655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006655556666dd6666dd66666dd6666dd666655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006655557766dd77665555555556666dd666655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006655557766dd77665555555556666dd666655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006655557766dd77665555555556666dd666655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006655556666dd66555111111155566dd666655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006655556666dd66555ccccccc55566dd666655556600000000000000000000000000000000000000000000000000000000000000000000000000000000000
00665555556655dd6655ccccccccc5566dd556655555566000000000000000000000000000000000000000000000000000000000000000000000000000000000
00665555556655dd6655ccccccccc5566dd556655555566000000000000000000000000000000000000000000000000000000000000000000000000000000000
00665555556655dd6655ccccccccc5566dd556655555566000000000000000000000000000000000000000000000000000000000000000000000000000000000
00665555666666dd66557777777775566dd666666555566000000000000000000000000000000000000000000000000000000000000000000000000000000000
00665555666666dd66557777777775566dd666666555566000000000000000000000000000000000000000000000000000000000000000000000000000000000
00665555666666dd66557777777775566dd666666555566000000000000000000000000000000000000000000000000000000000000000000000000000000000
00665566555555665555fffffffff555566555555665566000000000000000000000000000000000000000000000000000000000000000000000000000000000
00665566500005665555fffffffff555566500005665566000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666655000000556655555555555556655000000556666000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666650000000056655555555555556650000000056666000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666650000000056655555555555556650000000056666000000000000000000000000000000000000000000000000000000000000000000000000000000000
00665500000000005566660000066665500000000005566000000000000000000000000000000000000000000000000000000000000000000000000000000000
00665000000000000566660000066665000000000000566000000000000000000000000000000000000000000000000000000000000000000000000000000000
00665000000000000566660000066665000000000000566000000000000000000000000000000000000000000000000000000000000000000000000000000000
00220000000000000033000000000330000000000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000
00220000000000000033000000000330000000000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000029050290502805027050270501f0501d0501c0501b0503105018050170501605015050140501305012050110501c050100500e0500d0500b0500a0500905007050060500505005050040500305003050
49010000080500a0500d0502a050140501c0503205025050000002c05028050300502305034050360503905015050100501005010050100500000000000000000000000000000000000000000000000000000000
c11000000f1350f1350f1350f1350f1350f1350f1350f1350f1350f1050f1050f1050f1050f1050f1350f1351110511105111050c1050f1350f1350f135111351113511135111351113511135111351113511135
c1100000131351313513135131351313513135131351313513135131051310513105131351313513135131350c1350c1350c1350c1350c1350c1350c1350c1350c135131351313513135221351d1351613518135
051000000005500055000550000500055000550000500005000550005500005000050005500055000050000500055000550005500005000550005500005000050005500055000050000500055000550000500005
04100000000000000000003000030a063000000000300003000000000000000000000a063000000000000003000000000000000000000a063000000000000000000000000000000000000a063000000000000003
9101000008050370501b0501c0503805021050210503605032050230502f0502f050190501805018050300502d050250502d0502d050300503505000000000000000000000000000000000000000000000000000
900100001405116051190513605120051280513e05131051300012600116051170511b0511f0512305126051290512c051300513105139001380013a0513a0013d00100001000010000100001000010000100001
001000002330023300233002630028300283002830028300283002630026300263002630026300263002630026300233001f3001f3001f3001f3001f3001c3001c3001c3001c3001f3001f3001f3001f30000000
0101000012150081500a1500d150101501215014150171501a1501e1501b1500e1000f10012100081000a1000d100101001210014100171001a1001e1001b1001710000100001000010000100001000010000100
00010000190500e0501005014050160503705037050300503805038050300503805031050380503805032050380503405039050390503a0500000000000000000000000000000000000000000000000000000000
020100002c6502c6602b6602a6602a660296602965028650286502865028650286502765027650276502765027650276502665025650256502465023650226502165021650206501f6501e6501e6501e6501f650
49010000320202f0200d0002a000140001c0003200025000000002c00028000300002300034000360003900015000100001000010000100000000000000000000000000000000000000000000000000000000000
c1010000126500f650006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
490100001a0201a0201a0201702014020100200f0200e0200e0200f020100200e0200a0200802008020090200a0200c0200e0200c0200a0200a0200b0200d0201002012040130401204011040140401504015040
0001000022650286502e6503165031650336503465035650366403762038610386103861039610396103961039610396103961039610396103961039610386103761036610316103161000600006000060000600
000200000c0530f053110531305316053180531b0531d0531f0532205324053270532905329053290532905327053240531f0531f0531b05318053180531605316053180531b0531d0531f053240532705329053
48100000177221c73221742267522d742317223472236722177221c73221732267322d73231732347323672223732217421f7522174225732287222572225722287222a7322b7422a7422674223732217221e722
48100000177221c73221742267522d752317623476236722177221c72221732267222d73231732347423674236752347422f7522d74226732257321f7321e72236732347422f7422d75226752257321f7421e732
581000002a2252a2252a2252522525225252252522525225282252822528225282252822528225282252822528225282252a2252a2252a2252a22525225252252522525225252252322523225232252322523225
101000002a3152a3152a3152a3152a3152a3152a3152a315283152831528315283152831528315283152631525315253152531525315253152531525315253152531525315253152331523315233152331523315
791000003952539525395253955500505015050150501505395003950039500395000050500505005050150531525315253152531555005050050500505005050050500505005050050500505005050050500505
__music__
01 04454344
00 04054344
00 04050244
00 04050344
00 04050244
02 04050344
00 41424344
00 41424344
01 11055344
00 12055444
00 11051344
00 12051444
00 11051315
02 12051415

