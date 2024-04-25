pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--solar collection
--by olivander65
function _init()
	cartdata("solar_collection")
	menuitem(1, "clear cart",
		function() clear_cart() extcmd("reset") end
	)
	showver=true--used to make cart image
	v="1"
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
	sclrl={7,10,9,8}
	sclrd={12,9,2,14}
	scls={"b","k","m","g"}
	sgtyp={"variable","incongruent","normal","irregular"}
	intro_sun = f_rnd(4)+1
	--player
	p_spd=2.5
	--player ship options
	p_spr_opt={40,3,38,54,56}
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
		{{6,0,0,{120,-10,-20,184,-20,-56,120,129}},{6,0,0,{64,-10,180,120,-60,120,64,-11}},{5,32,64,{64,-10,-40,32,64,140}},{5,32,64,{64,-10,168,32,64,140}},{6,0,0,{120,-10,0,120,0,-120,120,129}},{6,0,0,{0,-10,120,184,120,-56,0,129}},{7,80,80}},
	}
	
	--stuff to load from save file
	high_score=0
	endless_score=0
	medal = false
	medal2 = false
	p_spr=40
	
	load_data()
	
	pc_spr=p_spr
	
	b_points=0--blue points
	b_amnt=0--#blue in wave
	fr_ani=false
	fr_spr=36
	fr_tmr=0
	
	fuel_mx=110
	low_fuel=false
	fuel_mask_mx=91
	fuel_mask_r=fuel_mask_mx
	fl_ani=false
	fl_spr=52
	fl_tmr=0
	fl_off=0
	mult_sfx=1
	
	tf_tmr=0--transfer timer
	
	poke(0x5f34, 0x2)--enable mask
	fade_dir=0
	fadding=false
	fade_r=100
	
	--starfield
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
end

function clear_cart()
	for i=0,10 do
		dset(i,0)--reset cart data
	end
end

function load_data()
	high_score = dget(0)
	endless_score=dget(1)
	if dget(2)==1 then
		medal = true
	end
	if dget(3)==1 then
		medal2 = true
	end
	if dget(4)>0 then
		p_spr=dget(4)
	end
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
	level=1
	wave=1
	t_blue=0--tank blue
	points=0--points
	music(16,1000)
	endless=false--endless mode
	in_menu=true
	sun_off=-140
	perfect=true
	p_x,p_y=64,100
	mult,mult_up=1,0
	temp_points=0
	fruit_chain=0
	gen_tmr=0
	init_fruitlet()
	m={"help","main game","fuel rush","customize"}
	my_off={0,0,0,0}
	_lerpfn=blank
	lerp_tmr=0
	btn_sprs={92,93,94}
	s_stat="docked"
	s_clr=3
	rnd_chars={"ア","イ","ウ","エ","オ","カ","キ","ク","ケ","コ","サ","シ","ス","セ","ソ","タ","チ","ツ","テ","ト","ナ","ニ","ヌ","ネ","ノ"}
	rnd_char={}
	gen_char()
	btn_tmr=0
	sel=0
	draw_help=false
	draw_cust=false
	
	game_over=false
	--screen
	screen_offset=0
	_upd=upd_menu
	_drw=drw_menu
end

function gen_char()
	rnd_char={}
	for i=1,9 do
		add(rnd_char,rnd_chars[rnd_rng(1,#rnd_chars)])
	end
end

function upd_menu()
	if gen_tmr==1 then
		menu_input()
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

function menu_input()
	if btnp(⬆️) then
		sfx(8)
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
		sfx(8)
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
		sfx(9)
		--enter menu
		btn_sprs[3]=110
		btn_tmr=5
		sc_tmr,sc_dir=0,1
		if m[2]=="main game" then
			init_start_game()
		elseif m[2]=="customize" then
			_upd=upd_ship_cust
			for i=1,#p_spr_opt do
				if (p_spr==p_spr_opt[i]) sel=i
			end
		elseif m[2]=="help" then
			_upd=upd_help
		elseif m[2]=="fuel rush" then
			endless=true
			init_start_game()
		end
		
	end
end

function upd_help()
	move_screen(sc_dir)
	if btnp(🅾️) then
		sfx(9)
		btn_sprs[3],btn_tmr=110,5
		sc_dir=-1
		sc_tmr=0
		draw_help=false
	end
	if sc_tmr==1 then
		if sc_dir==1 then
			draw_help=true
		else
			_upd=upd_menu
		end
	end
end

function upd_ship_cust()
	move_screen(sc_dir)
	if sc_tmr==1 then
		if sc_dir==1 then
			draw_cust=true
			if btnp(🅾️) then
				sfx(9)
				btn_sprs[3],btn_tmr=110,5
				sc_dir=-1
				sc_tmr=0
				draw_cust=false
			end
			if btnp(➡️) or btnp(⬇️) then
				sfx(8)
				sel+=1
				if sel>#p_spr_opt then
					sel=1
				end
				p_spr=p_spr_opt[sel]
				dset(4,p_spr)
				btn_sprs[2]=109
			end
			if btnp(⬅️) or btnp(⬆️) then
				sfx(8)
				sel-=1
				if sel<1 then
					sel=#p_spr_opt
				end
				p_spr=p_spr_opt[sel]
				dset(4,p_spr)
				btn_sprs[1]=108
			end
		else
			_upd=upd_menu
		end
	end
end

function move_screen(dir)
	btn_reset()
	sc_tmr=min(sc_tmr+0.04,1)
	local _t=easeoutquart(sc_tmr)
	if dir==1 then
		screen_offset=lerp(0,80,_t)
		--+= screen offset
	elseif dir==-1 then
		screen_offset=lerp(80,0,_t)
	end
	if sc_tmr==1 then
	end
end

function init_start_game()
	--🅾️ btn press timer
	sg_tmr=0
	s_stat="launch"
	s_clr=2
	fuel=fuel_mx--red tank
	fuel_drain=0.2
	fuel_tmr=0
	_upd=upd_start_game
	init_circfade()
end

function btn_reset()
	update_fruitlet()
	if btn_tmr>0 then
		btn_tmr-=1
	else
		btn_sprs={92,93,94}
	end
end

function upd_start_game()
	btn_reset()
	if sg_tmr<6 then
		sg_tmr+=1
	else
		if fade_dir == 1 then
			init_eol(8)
			in_menu=false
			music(0,1000)
		end	
	end
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

function drw_menu()
	local oc1,oc2=8,2--cord colors
	draw_fx()
	drw_fruit()
	draw_sun(intro_sun)
	local q = {"solar","collection"}
	lprint(q[1],hcenter(q[1])+sun_off+60,15,7,0)
	lprint(q[2],hcenter(q[2])+sun_off+60,23,7,0)
		if showver then
			--high score
			roundrect(22,53,83,21,1,0)
			hc="main score:"..high_score
			print(hc,hcenter(hc),56,7)
			ec="fuel rush score:"..endless_score
			print(ec,hcenter(ec),66,7)
		end
	--screen drop
		rectfill(0,0,128,screen_offset+1,0)
		rectfill(0,0,128,screen_offset,1)	
		
	--widow
	rect(0,0,127,75,6)
	rect(1,1,126,74,13)
	rectfill(0,76,128,128,5)

	if (draw_help) help_draw()
	if (draw_cust) cust_draw()
	--wires
	oline(0,85,45,85,oc1,oc2,0,1)
	oline(65,105,100,105,oc1,oc2,0,1)
	oline(65,85,100,85,oc1,oc2,0,1)
	oline(15,85,15,100,oc1,oc2,1,0)
	
	oline(15,100,64,100,oc1,oc2,0,1)
	oline(0,110,64,110,oc1,oc2,0,1)
	oline(64,110,120,110,oc1,oc2,0,1)
	
	roundrect(2,96,32,11,6,0)--stxt	
	print(s_stat,6,99,s_clr)
	roundrect(37,78,54,40,6,0)--term
	
	
	--ship ui
	local sy = max(t%4-2,0)
	roundrect(8,78,16,15,6,0)
	for i=1,5 do
			line(9,78+i*2+sy,22,78+i*2+sy,1)
	end
	line(9+sy,90+sy,22-sy,90+sy,1)
	
	spr(p_spr,12,81)
	if s_stat=="launch" then
		spr(get_frame({5,6,7,6,5},1),12,89)
	end
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
		
		circ(32,80,1,13)
		pset(32,80,0)
		circ(26,80,1,13)
		pset(26,80,0)
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
		if showver then	
			print("v"..v,120,122,6)
		end
	end	
	if showver then
		local mspr=111
		if medal then
			mspr=79
		end
		spr(mspr,116,2,1,2)
		
		m2spr=111
		if medal2 then
			m2spr=143
		end
		spr(m2spr,106,2,1,2)
	end
end

function help_draw()
	local txt={"fuel and pts","more fuel and pts","increase mult"}
	for i=1,#txt do
		print(txt[i],18,-4+i*10,7)
	end
	spr(get_frame({11,12,13},2),8,4)
 spr(get_frame({44,45,46,47},2),8,14)
	frt_drw(8,24,2)
	lprint("goal: collect as many points\nwhile keeping your fuel from\nrunning out.",8,45,9,0)
	local et = "press 🅾️ to exit"
	print(et,hcenter(et),68,6)
end

function cust_draw()
	roundrect(34,15,59,36,6,0)
	roundrect(38,18+sin(time()),51,10,6,2)
	local st="select ship"
	lprint(st,hcenter(st),20+sin(time()),7,4)
	spr(16,30+sel*10,30+sin(time()))
	for i = 1,#p_spr_opt do
		spr(p_spr_opt[i],30+i*10,40)
	end
	local et = "press 🅾️ to exit"
	print(et,hcenter(et),68,6)
end
-->8
--level
function init_level()
	if not endless then
		init_fruit_wave()
	end
 init_fruitlet()
 music(1,1000)
 _upd=upd_level
	_drw=drw_level
end

function upd_level()
	fuel-=fuel_drain
	if endless then
		fuel_tmr+=1
		if fuel_tmr==300 then
			fuel_tmr=0
			fuel_drain+=0.1
			score_intensity=0.5
			sfx(11)
			mult+=1
		end
	end
	fuel=max(fuel,0)
	if fuel <=0 then
		game_over=true
		_upd=init_game_over
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
	if not endless then
		update_fruit()
	end
	update_fruitlet()
end

function init_game_over()
	music(-1)
	sfx(15)
	eol_mask=10
	ismask=true
	fruits={}
	fruitlet={}
	dots={}
	rst_pspr()
	init_plerp()
	mv_plyr=true
	gen_tmr=0
	s_tmr=0
	_upd=upd_game_over
	_drw=drw_game_over
end

function upd_game_over()
	if mv_plyr then
				p_lerp(60,72)
	end
	s_tmr=min(s_tmr+1,90)
	if s_tmr >= 90 then
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
	elseif s_tmr == 60 then
		temp_points=mult*temp_points
		mult=1
		score_intensity=0.5
		sfx(11)
	end	

	if btnp(🅾️) and temp_points==0 then
		init_circfade()
	end
	
	if fade_dir == 1 then
		if endless then
			endless_score=points
			if endless_score>dget(1) then
				dset(1,endless_score)
			end
			if endless_score>=900 then
				medal2=true
				dset(3,1)
			end
		else
			high_score=points
			if high_score>dget(0) then
				dset(0,high_score)
			end
		end
			_upd=init_menu
	end	
end

function drw_game_over()
	drw_player()
	drw_eol_mask()
	rectfill(0,0,128,8,1)
	draw_fx()
	
	drw_points()
	local tx={"out of fuel","game over","press 🅾️ to return to menu"}
	lprint(tx[1],hcenter(tx[1]),40,9,5)
	lprint(tx[2],hcenter(tx[2]),50,9,5)
	lprint(tx[3],hcenter(tx[3]),120,6,1)
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
	 	
	 	if not ismask then
		 	if bigtank < 10 then
		 		_clr=max(1,(i%3-1)*7)+7
		 	
		 		local txt="low fuel"
		 		low_fuel=true
		 		print(txt,hcenter(txt),64+sin(time()),8)
		 	else
		 		low_fuel=false
				end
			end
			line(3+_f,62-i,7+_f,62-i,_clr)
  end
end

function drw_player()
	--line under ship
	if not endless then
		line(p_x-1,p_y+5,p_x+8,p_y+5,5)
	end
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
	if not endless then
		--blue tank
		spr(s_spr,p_x-6,p_y+1,1,1,p_flp)
		spr(fr_spr,p_x-7,p_y-7,1,1)
	end	
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
	_lvl="level: "..level
	if endless then
		_lvl="fuel drain:"..fuel_drain
	end
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
	local l,d=sclrl[level],sclrd[level]
	for t in all(fruits) do	
		frt_drw(t.x,t.y,level)
		fire(t.x+5,t.y+5,0,-0.5,2,3,{l,l,l,d})
	end
	--fruitlet
	for fl in all(fruitlet) do
		local fls={11,12,13}
		if (fl.sz>1) fls={44,45,46,47}
		spr(get_frame(fls,2),fl.x,fl.y)
		fire(fl.x+3,fl.y+3,0,-1,1,2,f1c)
	end
end

function frt_drw(x,y,lvl)
		local l,d=sclrl[lvl],sclrd[lvl]
		circfill(x+4,y+4,2,l)
		rectfill(x+3,y+3,x+5,y+5,d)
		pset(x+3,y+3,7)
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
				perfect=false
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
function init_eol(_e)
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
	fl_state=true--jump to middle of eol
	if _e then
		fl_state=false
		e_state=_e
		m_off=120
		d_plyr=blank
		mv_plyr=false
	else
		e_state=0	
	end
	eol_mask=10
	ismask=true
	fl_off=-20
	sun_off=140
	gen_tmr=0
	
	end_draw=false

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
	if fl_state then
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
			level+=1
			d_plyr=blank
			if level > #levels then	
				if perfect then
					medal=true
					dset(2,1)
				end
				level-=1
				music(24,1000)
				high_score=points
			 end_draw=true
			 w_off=-40
			 end_tmr=0
				_upd=game_end
			else
				e_state =7
				gen_tmr=0
		end
			
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
			_upd=upd_level
			_drw=drw_level
			fuel_mask_r=fuel_mask_mx
			init_fruitlet()
			init_fruit_wave()
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
	if (end_draw) draw_end()
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
	fire(mx+38,my+72+m_off,0,0.5,6,6,f3c)
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
	if endless and not in_menu then
		c2,c1=1,0
	end
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
	local txt="class:"..scls[level]
	local txt2="grav:"..sgtyp[level]	
	if endless then
		txt="class:🐱"
		txt2="grav:yup"
	end
	if not l then
		oprint(txt,hcenter(txt)+sun_off,48,7,0)
		oprint(txt2,hcenter(txt2)+sun_off,56,7,0)
	end
end

function game_end()
	if btnp(🅾️) then
		init_circfade()
	end
	end_tmr=min(end_tmr+0.01,1)
	if fade_dir == 1 then
			_upd=init_menu
	end
end

function draw_end()
	local st=sin(time())
	local tx={"you win!!","thanks for playing","press 🅾️ to return to menu"}
	lprint(tx[1],hcenter(tx[1]),40+st,9,5)
	lprint(tx[2],hcenter(tx[2]),50+st,9,5)
	lprint(tx[3],hcenter(tx[3]),120,6,1)
	local ey={90,80,70,80,90}
	for i = 1,#p_spr_opt do
		local _t=easeoutquad(end_tmr)
		ly=lerp(ey[i]+60,ey[i],_t)
		spr(p_spr_opt[i],14+i*15,ly)
		spr(get_frame({5,6,7,6,5},1),14+i*15,ly+8)
	end
	local pt="not perfect"
	local mspr=111
	local clr1=6
	if medal then
		mspr=79
		pt="perfect!!!"
		clr1=9
	end
	spr(mspr,90,9,1,2)
	lprint(pt,hcenter(pt),12,clr1,5)
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

function easeoutquart(t)
	t-=1
	return 1-t*t*t*t
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
end

function roundrect(_x,_y,_w,_h,_oc,_ic)--draws box with round corner
	rectfill(_x,_y+1,_x+max(_w-1,0),_y+max(_h-1,0)-1,_oc)
	rectfill(_x+1,_y,_x+max(_w-1,0)-1,_y+max(_h-1,0),_oc)
	rectfill(_x+1,_y+2,_x+max(_w-1,0)-1,_y+max(_h-1,0)-2,_ic)
	rectfill(_x+2,_y+1,_x+max(_w-1,0)-2,_y+max(_h-1,0)-1,_ic)
end

function oline(x1,y1,x2,y2,c1,c2,xo,yo)
	line(x1,y1,x2,y2,c1)
	line(x1+xo,y1+yo,x2+xo,y2+yo,c2)
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
0aaaaaa000056500056500000500050000500d0000d00500009999000049990000499a000049aa00009aaa0000aaaa0000aaa90000aa940000a9940000999400
a999999a000565ddd56500000500050000500d0000d00500009669000046690000469a000049aa00009aaa0000aaaa0000aaa90000aa940000a9640000966400
0a9999a000056556556500000500050000500d0000d00500009999000049990000499a000049aa00009aaa0000aaaa0000aaa90000aa940000a9940000999400
00a99a00000566565665000005000d000050050000500500009999000049990000499a000049aa00009aaa0000aaaa0000aaa90000aa940000a9940000999400
000aa00000005555555000000055d0000005d000000d500000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000b00b0000b0b0000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000b3113b00b313b00006cd600005d6700000000000000000000000900009000000009000000009000
0000000000000000000000000000000000000000000000000b3dd3b00b3d3b000061160000516700000000000000000009009000000900900009000000090000
0000000000000000000000000000000000000000000000000b3333b00b333b005556655555566555000000000000000000988000000889000008899009088900
00000c300000035000000550000005500000055000000000bd37c3db0b7c33b066528566dd587567000000000000000000088900009880000998800000988090
000050000000c00000003000000050000000500000000000bd3113db0b113db00052850000587500000000000000000000090090090090000000900000009000
00005000000050000000c0000000300000005000000000000b3663b00b663b000052550000565500000000000000000000900000000009000000900000090000
0000500000005000000050000000c000000050000000000000b33b0000b3b0000005500000055000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000d0000d00d000d000700707007070700000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005600650056065000600606006060600000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000006566560055657000655666006566660000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000006cc600005c70006666d666566d6667000000000000000000000000000000000000000000000000
09a000000590000005500000055000000550000000000000005dd500055d7500666d766656d76667000000000000000000000000000000000000000000000000
00050000000a00000009000000050000000500000000000055566555556665555665d665565d6667000000000000000000000000000000000000000000000000
0005000000050000000a000000090000000500000000000006566560065656000566665005666670000000000000000000000000000000000000000000000000
000500000005000000050000000a000000050000000000000542245005422500005dd500006dd600000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009a9a79a9
0000000000000000000000000000000000000000000000000000000d000000d000000d000000d000000d000000d000000d0000000000000000000000979aa9a9
000000000000000000000000000000000000000000000000551551d315515d505155d500551d500055d500005d500000d500000000000000000000009a97a9a9
000000000000000000000000000000000000000000000000616616d366166d501661d500616d500061d500001d500000d500000000000000000000009a9a79a9
000000000000000000000000000000000000000000000000166166d361661d506616d500166d500016d500006d500000d50000000000000000000000979aa979
0000000600000000000000000000000000000000060000000000000d000000d000000d000000d000000d000000d000000d00000000000000000000009a97a9a9
0000000660000000000000000000000000000000660000000000000000000000000000000000000000000000000000000000000000000000000000009a9a79a9
00000006660000000000000000000000000000066600000000000000000000000000000000000000000000000000000000000000000000000000000009a99a90
00000006560000000000000000000000000000065600000000000000000000000000000000000000000000000000000000000000000000000088800000666600
00000006566000666666666666666666666000665600000000000000000000000000000000000000000000000000000088888880888888800855580006311960
00000006566006666666666666666666666600665600000000000000000000000000000000000000000000000000000088858880858885808588858061181a96
00000006566666111111111111111111111666665600000000003333333300000000000000000000000000000000000088585880885858808588858061828116
0000000656666611111111111111111111166666560000000003bbbbbbbb30000000333333330000000000000000000085888580888588808588858061171116
000000065666611111111111111111111111666656000000033bbbbbbbbbb3300333bbbbbbbb3330000000000000000088888880888888802855582056117165
00000006556661111111111111111111111166655600000003bbb333333bbb303bbbbbbbbbbbbbb3000333333333300088888880888888800288820005666650
0000000665666111111111111111111111116665660000003bbb3bbbbbb3bbb33bb3333333333bb3033bbbbbbbbbb33022222220222222200022200000555500
0000000655666111111111111111111111116665566000003bb3bbbbbbbb3bb33bb3333333333bb33bbb33333333bbb300000000000000000000000056567565
0000006655666611111111111111111111166665566000003bbb3bbbbbb3bbb33bbbbbbbbbbbbbb3033bbbbbbbbbb33000000000000000000088800057566565
00000066556666111111111111111111111666655660000003bbb333333bbb300333bbbbbbbb3330000333333333300088888880888888800855580056576565
00000033556655dd66666666666666666dd5566553300000033bbbbbbbbbb3300000333333330000000000000000000088858880858885808588858056567565
00000033556655dd66666666666666666dd55665533000000003bbbbbbbb30000000000000000000000000000000000088585880885858808588858057566575
00000033556655dd66666666666666666dd556655330000000003333333300000000000000000000000000000000000085888580888588808588858056576565
00000033556666dd5555dd66666dd5555dd666655330000000000000000000000000000000000000000000000000000088888880888888800855580056567565
00000033556666dd5555dd66666dd5555dd666655330000000000000000000000000000000000000000000000000000088888880888888800088800005655650
00000066556666dd6666dd66666dd6666dd666655660000000000000000000000000000000000000000000000000000000000000000000000000000000666600
00000066556666dd6666dd66666dd6666dd666655660000000000000000000000000000000000000000000000000000000000000000000000000000006555560
00000066556666dd6666dd66666dd6666dd666655660000000000000000000000000000000000000000000000000000000000000000000000000000065555556
00000066556666dd6666dd66666dd6677dd666655660000000000000000000000000000000000000000000000000000000000000000000000000000065555556
00000066556666dd6666dd66666dd6677dd666655660000000000000000000000000000000000000000000000000000000000000000000000000000065555556
00000066556666dd6666dd66666dd6677dd666655660000000000000000000000000000000000000000000000000000000000000000000000000000056555565
00000066556677dd6666dd66777dddd66dd667755660000000000000000000000000000000000000000000000000000000000000000000000000000005666650
00000066556677dd6666dd66777dddd66dd667755660000000000000000000000000000000000000000000000000000000000000000000000000000000555500
00006655556666dd6666dd66666dd6666dd66665555660000000000000000000000000000000000000000000000000000000000000000000000000008282e828
00006655556666dd6666dd66666dd6666dd66665555660000000000000000000000000000000000000000000000000000000000000000000000000008e822828
00006655556666dd6666dd66666dd6666dd6666555566000000000000000000000000000000000000000000000000000000000000000000000000000828e2828
00006655556666dd6677dd66666dd7766dd66665555660000000000000000000000000000000000000000000000000000000000000000000000000008282e828
00006655556666dd6677dd66666dd7766dd66665555660000000000000000000000000000000000000000000000000000000000000000000000000008e8228e8
00006655556666dd6677dd66666dd7766dd6666555566000000000000000000000000000000000000000000000000000000000000000000000000000828e2828
000011555566dddd6666dd66666dd6666dd66665555110000000000000000000000000000000000000000000000000000000000000000000000000008282e828
000011555566dddd6666dd66666dd6666dd666655551100000000000000000000000000000000000000000000000000000000000000000000000000008288280
00001155557766dd7766dd66666dd6677dd776655551100000000000000000000000000000000000000000000000000000000000000000000000000000999900
00001155557766dd7766dd66666dd6677dd776655551100000000000000000000000000000000000000000000000000000000000000000000000000009222290
00001155557766dd7766dd66666dd6677dd77665555110000000000000000000000000000000000000000000000000000000000000000000000000009289a829
00001155556666dd6666dd66666dd6666dd666655551100000000000000000000000000000000000000000000000000000000000000000000000000092999929
00001155556666dd6666dd66666dd6666dd666655551100000000000000000000000000000000000000000000000000000000000000000000000000092899829
00001155556666dd6666dd66666dd6666dd666655551100000000000000000000000000000000000000000000000000000000000000000000000000059222295
00001155556666dd6666dd66666dd7766dd666655551100000000000000000000000000000000000000000000000000000000000000000000000000005999950
00001155556666dd6666dd66666dd7766dd666655551100000000000000000000000000000000000000000000000000000000000000000000000000000555500
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
__label__
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
6dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd6
6d0000000000000000000000000922222222222222222222222222222222222222222222222222222222222222222222222900000056567565005656756500d6
6d0000000000000000099999999929222222222222222222222222222222222222222222222222222222222222222222229900000057566565005756656500d6
6d0000000000000000000000000922922222222222222222222222222222222222222222222222222222222222222222292906000056576565005657656500d6
6d0000000000000000000009999922299222222222222222222222222222222222222222222222222222222222222229922906000056567565005656756500d6
6d0000000000000000000000000922222992222222222222222222222222222222222222222222222222222222222992222900000057566575005756657500d6
6d0000000000000000000000000922222229999222222222222222222222222222222222222222222222222229999222222999990056576565005657656500d6
6d0000000000000000000000000922222222222999992222222222222222222222222222222222222222999992222222222920000056567565005656756500d6
6d0000000000000000000000000992222222222222229999999922222222222222222222222299999999222222222222229222000005655650000565565000d6
6d0000000000000000000000000092222222222222222222222299999999999999999999999922222222222222222222229000222000666600000066666000d6
6d0000000000000000000000000092222222222222222222222222222222222222222222222222222222222222222222229220000006555560000655556000d6
6d0000000000000000000000000092222222222222222222222222222222222222222222222222222222222222222222229000000065555556006555555600d6
6d0000000000000000000000999992222222222222222222222222222222222222222222222222222222222222222222229999900065555556006555555600d6
6d0000000000000000000099000099222222222222222222222222222222222222222222222222222222222222222222292000099065555556006555555600d6
6d0000000000000000000d00099929222222222222222222222222277227727222777277722222222222222222222222292200000056555565005655556500d6
6d0000000000000000000009922229922222222222222222222222700270727222707270722222222222222222222222990022000005666650000566665000d6
6d0000000000000000000000022000922222222222222222222222777272727222777277022222222222222222222222900000000000555500000655550000d6
6d0000000000000000000000000000922222222222222222222222007272727222707270722222222222222222222222900000000000000000000000000000d6
6d0000000000000000000000000029992222222222222222222222770277027772727272722222222222222222222229200000000000000000000000000000d6
6d0000000000000000000000002990092222222222222222222222002200220002020202022222222222222222222229022000000000000000000000000000d6
6d0000000000000000000000220000009222222222222222222222222222222222222222222222222222222222222290000220000000000000000000000000d6
6d0000000000000000000000000000999922222222222222222222222222222222222222222222222222222222222999900000000000000000000000000000d6
6d0000000000000000000000600009900922222222222772277272227222777227727772777227727722222222222909099000000000000000000000000000d6
6d0000000000000000000006600090000292222222227002707272227222700270020702070270727072222222229000990900000000000000000000000000d6
6d0000100000000000000006000000002009222222227222727272227222772272222722272272727272222222290000009900000000000000000000000000d6
6d0000000000000000000000000000000009922222227222727272227222702272222722272272727272222222991000000090000000000000000000000000d6
6d0000000000000000000000000000000090992222220772770277727772777207722722777277027272222229900000000000000000000000000000000000d6
6d0000000000000000000000000000009900099222222002002200020002000220022022000200220202222299020000000000000600000000000000000000d6
6d0000000000000000000000000000090000209922222222222222222222222222222222222222222222222992002000000000000600000000000000000000d6
6d0000000000000000000000000000900002000992222222222222222222222222222222222222222222229900200200000000000000000000000000000000d6
6d0000000000000000000000000000000000000099222222222222222222222222222222222222222222299090020020000000000000000000000000000000d6
6d0000000000000000000000000000000000000092922222222222222222222222222222222222222222900009000000000000000000000000000000000000d6
6d0000000000000000000000000000000000000000099222222222222222222222222222222222222299200000000000000000d00000000000000000000000d6
6d0000000000000000000000000000000000000000009922222222222222222222222222222222222990020000000000000000000000000000000000000000d6
6d0000000000000000000000000000000000000000090099222222222222222222222222222222299000000000000000000000000000000000000000000000d6
6d0000000000000000000000000000000000000000900009999222222222222222222222222299990900000000000000000000000000000000000000000000d6
6d0000000000000000000000000000000000000000900009009992222222222222222222229990009900000000000000000000000000000000000000000000d6
6d0000000000000000000000000000000000000009000090009009999922222222222999999002009090000000060000000000000000000000000000000000d6
6d0000000000000000000000000000000000000000000090000002000099999999999000909002000000000000060000000000000000000000000000000000d6
6d0000000000000000000000000000000000000000000000000002000002000909000000299000000000000000000000000000000000000000000000000000d6
6d0000000000000000000000000000000000000000000000000000d00002000909000000090900000000000000000000000000000000000000000000000000d6
6d6000000000000000000000000000000000000000000000000000000002000900000000020900000000000000000000000000000000000000000000000000d6
6d6000000000000000000000000000000000000000000000000000000002000900000000000000000000000000000000000000000000000000000000000000d6
6d0000000000000000000000000000000000000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000d6
6d0000000000000000000000000000000000000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000d6
6d0000000000000000000000000000000000000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000d6
6d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d6
6d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d6
6d000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d6
6d0000000000000000000000000000000000000000000000000000d00000000000000000000000000000000000000000000000000000000000000000000000d6
6d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000d6
6d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000d6
6d0000000000000000000001111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000d6
6d0000000000000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000011000000000000000000000d6
6d0000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000d6
6d0000000000000000000010000000000000000077707770777077000000077007700770777077700000777000000000000000001000000000000000000000d6
6d00000000000000000d0010000000000000000077707070070070700000700070007070707070000700707000000000000000001000000000000000000000d6
6d0000000000000000000010000000000000000070707770070070700000777070007070770077000000707000000000000000001000001000d00000000000d6
6d0000000000000000000010000000000000000070707070070070700000007070007070707070000700707000000000000000001000000000000000000000d6
6d000000000000000000001000000000000000007070707077707070000077000770770070707770000077700000000000000000100d000000000000000000d6
6d0000000000000060000010000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000d6
6d0000000000000060000010000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000d6
6d0000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000d6
6d0000000006000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000600000000d6
6d0000000006000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000600000000d6
6d0000000000000000000010000000777070707770700000007770707007707070000007700770077077707770000077700000001000000000000000000000d6
6d0000000000000000000010000000700070707000700000007070707070007070000070007000707070707000070070700000001000000000000000000000d6
6d000000000000000000001000000077007070770070000000770070707770777000007770700070707700770000007070000000100000000d000000000000d6
6d0000000000000000000010000000700070707000700000007070707000707070000000707000707070707000070070700000001001000000000000000000d6
6d0000000000000000000010000000700007707770777000007070077077007070000077000770770070707770000077700000001000000060000000000000d6
6d0000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000001000000060000000000000d6
6d0000000000000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000011000000000000000000000d6
6d0000000000000000000001111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000d6
6dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd6
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55666555566666666666666555555555555555666666666666666666666666666666666666666666666666666655555555555555555555555555555555566655
56ddd655660000000000006655d55555d555566000000000000000000000000000000000000000000000000006655ddddddddddddd5555d55555d555556ddd65
56ddd65561111111111111165d0d555d0d55560000000000000000000000000000000000000000000000000000655ddddddddddddd555d0d555d0d55556ddd65
56ddd655600000000000000655d55555d555560000000000000000000000000000000000000000000000000000655ddd8888888ddd5555d55555d555556ddd65
556665556111116cd6111116555555555555560000000000000000000000000000000000000000000000000000655ddd8885888ddd5555555555555555566655
555555556000006116000006555555555555560000000000000000000000000000000000000000000000000000655ddd8858588ddd5555555555555555555555
555555556111555665551116555555555555560000000000000000003030333030003330000000000000000000655ddd8588858ddd5555555555555555555555
888888886000665285660006888888888888860000000000000000003030300030003030000000000000000000688ddd8888888ddd5556666666666666666655
222222226111115285111116222222222222260000000000000000003330330030003330000000000000000000622ddd8888888ddd5566000000000000000665
555555556000005255000006555555555555560000000000000000003030300030003000000000000000000000655ddd2222222ddd5560000000000000000065
555555556111111551111116555555555555560000000000000000003030333033303000000000000000000000655ddddddddddddd55600bbbbb00000b000065
555555556000000000000006555555555555560000000000000000000000000000000000000000000000000000655ddddddddddddd556000000b000bbbbb0065
555555556111111111111116555555555555560000000000000000000000000000000000000000000000000000655ddddd888ddddd55600000b0000000bb0065
555555556600000000000066555555555555560000000000000000000000000000000000000000000000000000655dddd85558dddd5560000bb0000bbbb0b065
5555555556666666666666655555555555555600000000bbb0bbb0bbb0bb0000000bb0bbb0bbb0bbb000000000655ddd8588858ddd55600bb00b00000b000065
5555555555555558255555555555555555555600000000bbb0b5b05b50b5b00000b550b5b0bbb0b55000000000655ddd8588858ddd5560000000000000000065
5555555555555558255555555555555555555600000000b5b0bbb00b00b0b00000b000bbb0b5b0bb0000000000655ddd8588858ddd5560000b00000b000b0065
5555555555555558255555555555555555555600000000b0b0b5b00b00b0b00000b0b0b5b0b0b0b50000000000655ddd2855582ddd55600bbbbb0000b00b0065
5556666666666666666666666666666665555600000000b0b0b0b0bbb0b0b00000bbb0b0b0b0b0bbb000000000655dddd28882dddd5560000b000000000b0065
556600000000000000000000000000006655560000000050505050555050500000555050505050555000000000655ddddd222ddddd55600bbbbb000000b00065
556000000000000000000000000000000655560000000000000000000000000000000000000000000000000000655ddddddddddddd5560000b000000bb000065
556000330003300330303033303300000655560000000000000000000000000000000000000000000000000000655ddddddddddddd5560000000000000000065
556000303030303000303030003030000688860000000033303030333030000000333030300330303000000000655ddd8888888ddd5560000b00000b000b0065
556000303030303000330033003030000622260000000030003030300030000000303030303000303000000000655ddd8588858ddd55600bbbbb0000b00b0065
556000303030303000303030003030000655560000000033003030330030000000330030303330333000000000655ddd8858588ddd55600000bb0000000b0065
556000333033000330303033303330000655560000000030003030300030000000303030300030303000000000655ddd8885888ddd55600bbbb0b00000b00065
556000000000000000000000000000000655560000000030000330333033300000303003303300303000000000655ddd8888888ddd5560000b000000bb000065
556600000000000000000000000000006655560000000000000000000000000000000000000000000000000000688ddd8888888ddd5560000000000000000065
555666666666666666666666666666666555560000000000000000000000000000000000000000000000000000622ddd2222222ddd556000b00b00000b000065
555555555555555555555555555555555555560000000000000000000000000000000000000000000000000000655ddddddddddddd55600bbbbbb00bbbbb0065
555555555555555555555555555555555555560000000003303030033033300330333033303330333000000000655ddddddddddddd556000b00b000b000b0065
5555555555555555555555555555555555555600000000300030303000030030303330030000303000000000006555555555555555556000000b0000000b0065
888888888888888888888888888888888888860000000030003030333003003030303003000300330000000000688888888888888888600000b000000bb00065
22222222222222222222222222222222222226000000003000303000300300303030300300300030000000000062222222222222222260000000000000000065
55555555555555555555555555555555555556000000000330033033000300330030303330333033300000000065555555555555555566000000000000000665
55555555555555555555555555555555555556000000000000000000000000000000000000000000000000000065555555555555555556666666666666666655
55555555555555555555555555555555555556000000000000000000000000000000000000000000000000000065555555555555555555555555555555555555
55555555555555555555555555555555555556000000000000000000000000000000000000000000000000000065555555555555555555555555555555555555
55555555555555555555555555555555555556600000000000000000000000000000000000000000000000000665555555555555555555555555555555555555
55555555555555555555555555555555555555666666666666666666666666666666666666666666666666666655555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55666555555555555555666566655665666566656665666565655555566566655555566566656665566566555555566556656665666555555555555555555555
56ddd655555555555555656565656565656565556565565565655555656565555555656565655655656565655555655565656565656555555555555555555555
56ddd655555555555555666566556565666566556655565566655555656566555555656566555655656565655555655565656655666555555555555555555555
56ddd655555555555555655565656565655565556565565555655555656565555555656565655655656565655555655565656565655555555555555555555555
55666555555555555555655565656655655566656565565566655555665565555555665565656665665565655555566566556565655555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555

__sfx__
0101000029050290502805027050270501f0501d0501c0501b0503105018050170501605015050140501305012050110501c050100500e0500d0500b0500a0500905007050060500505005050040500305003050
49010000080500a0500d0502a050140501c0503205025050000002c05028050300502305034050360503905015050100501005010050100500000000000000000000000000000000000000000000000000000000
791000000f1350f1350f1350f1350f1350f1350f1350f1350f1350f1050f1050f1050f1050f1050f1350f1351110511105111050c1050f1350f1350f135111351113511135111351113511135111351113511135
79100000131351313513135131351313513135131351313513135131051310513105131351313513135131350c1350c1350c1350c1350c1350c1350c1350c1350c135131351313513135221351d1351613518135
051000000005500055000550000500055000550000500005000550005500005000050005500055000050000500055000550005500005000550005500005000050005500055000050000500055000550000500005
04100000000000000000003000030a063000000000300003000000000000000000000a063000000000000003000000000000000000000a063000000000000000000000000000000000000a063000000000000003
9101000008050370501b0501c0503805021050210503605032050230502f0502f050190501805018050300502d050250502d0502d050300503505000000000000000000000000000000000000000000000000000
900100001405116051190513605120051280513e05131051300012600116051170511b0511f0512305126051290512c051300513105139001380013a0513a0013d00100001000010000100001000010000100001
010100000f5500f5500f5500f55011550135500f5500a550035500555007550075500a5500c550005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
0101000012150081500a1500d150101501215014150171501a1501e1501b1500e1000f10012100081000a1000d100101001210014100171001a1001e1001b1001710000100001000010000100001000010000100
00010000190500e0501005014050160503705037050300503805038050300503805031050380503805032050380503405039050390503a0500000000000000000000000000000000000000000000000000000000
020100002c6502c6602b6602a6602a660296602965028650286502865028650286502765027650276502765027650276502665025650256502465023650226502165021650206501f6501e6501e6501e6501f650
49010000320202f0200d0002a000140001c0003200025000000002c00028000300002300034000360003900015000100001000010000100000000000000000000000000000000000000000000000000000000000
c1010000126500f650006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
490100001a0201a0201a0201702014020100200f0200e0200e0200f020100200e0200a0200802008020090200a0200c0200e0200c0200a0200a0200b0200d0201002012040130401204011040140401504015040
0001000022650286502e65031050310503205033050330503404034020330103301032010310102f0102e0102c0102a01027010250102401022010200101f0101d0101c0101b0101a0101901019000190000d000
000200000c0530f053110531305316053180531b0531d0531f0532205324053270532905329053290532905327053240531f0531f0531b05318053180531605316053180531b0531d0531f053240532705329053
48100000177221c73221742267522d742317223472236722177221c73221732267322d73231732347323672223732217421f7522174225732287222572225722287222a7322b7422a7422674223732217221e722
48100000177221c73221742267522d752317623476236722177221c72221732267222d73231732347423674236752347422f7522d74226732257321f7321e72236732347422f7422d75226752257321f7421e732
581000002a2252a2252a2252522525225252252522525225282252822528225282252822528225282252822528225282252a2252a2252a2252a22525225252252522525225252252322523225232252322523225
101000002a3152a3152a3152a3152a3152a3152a3152a315283152831528315283152831528315283152631525315253152531525315253152531525315253152531525315253152331523315233152331523315
791000003952539525395253955500505015050150501505395003950039500395000050500505005050150531525315253152531555005050050500505005050050500505005050050500505005050050500505
011c00001f032180321f032180001f0321f0321f0321c0311d0311c0311a032180321a0321c03218032180321a032180321a0321c0321a0321803218032180321c0321d0321c0321a0321c0321a0311a0321a032
011c00001f032180321f032180021f0321f0321f0321d032180321d032200321d0322003224032200321d0321b032200322203220002220322203222032200321d032200321b0321d032180321b0321603218032
011c00000063500635296350f6350063500635296351c00500635006352963518005006350063529635180050063500635296351c005006350063529635126350063500635296351a00500635006352963129635
a11c00000047500475004750047500475004750047500475004750047500475004750047500475004750047500475004750047500475004750047500475004750047500475004750047500475004750047500475
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a91000000e05513055170551a0551c05521055230552405526051280512d0522805226055230551f0551c05518055170551f055150522105215055170511a0551d0551f0551d0551a05117052130521f05513055
a9100000280552b0552805526055210551f055230552805528055260552605523055210551f0551c0551a0551805517055150551f0511a0551505517055180511c055230551f0551d0511c0551c0551d0511d055
0110000000655000053b6152060020655000053b6150000500655000053b6152060020655000053b6150000500655000053b6152060020655000053b6150000500655000053b6152060020655000053b61500005
011000000005500055000550005500055000550005500055000550005500055000550005500055000550005507055070550705507055070550705507055070550705507055070550705507055070550705507055
701000003045530405344552840530455004052d45500405004050040500405004050040500405004050040532455004053045528405324550040537455004050040500405004050040500405004050040500405
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
00 41424344
00 41424344
01 16185a44
00 17185844
00 16181944
00 17181944
02 17585944
00 41424344
00 41424344
00 41424344
01 5c1e1f20
00 1c1e1f44
00 5c1e1f20
02 1d1e1f44

