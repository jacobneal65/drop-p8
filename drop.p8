pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--space trash
--by olivander65

function _init()
	music(1)
	debug={""}
	effects={}
	--two flame effects
	f1c={8,9,10,5}
	f2c={7,6,6,5}
	--player
	p_x=64
	p_y=100
	p_dx=0
	p_dy=0
	max_dx=3
	max_dy=3
	acc=0.3
	vacc=0.4--vertical acc
	trashs={}
	t_spr=16
	t_cnt=5
	t_itrvl=16
	t_ybnd=128
	t_df_ybnd=128--default y bound
	t_grav=2
	grav=2
	frict=0.90
	level=1  --level
	pt=0
	t=0
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
	sss=22
	ssl=9
	ss_ani={}
	for i=0,ssl do
		add(ss_ani,sss+i)
	end
	
 load_trash()
end

function _update()
t+=1
	update_fx()
	--plyr friction
	p_dx*=frict
	p_dy*=frict

	p_l=false
	p_r=false
	p_u=false
	p_d=false
	p_spr=2
	
	--plyr movment
	--left/right
	if (btn(0)) p_dx-=acc p_l=true p_spr=3 sfx(2)
	if (btn(1)) p_dx+=acc p_r=true sfx(2) p_spr=4
	--up/down
	if (btn(2)) p_dy-=vacc p_u=true sfx(3)
	if (btn(3)) p_dy+=vacc p_d=true sfx(2)
	
	p_dx=(mid(-max_dx,p_dx,max_dx))
	p_dy=(mid(-max_dy,p_dy,max_dy))
	p_x+=p_dx
	p_y+=p_dy

	--bounds
	if (p_x > 120) p_x=120
	if (p_x < 0) p_x=1
	if (p_y > 120) p_y=120
	if (p_y < 0) p_y=1
	
	--trash
	trash_update()

	animatestars()
	
end

function _draw()
	cls()
	starfield()
 	draw_fx()
 local t_px=flr(p_x)
 local t_py=flr(p_y)
	--rectfill(0,108,127,127,3)
	spr(p_spr,p_x,p_y)--plyr
	spr(1,p_x,p_y-8)--basket
	
	if p_l then
		fire(p_x+6,p_y+2,0.5,0,1,2,f2c)
	elseif p_r then
		fire(p_x+1,p_y+2,-0.5,0,1,2,f2c)				
	end
	
	if p_u then
		fire(p_x+4,p_y+4,0,0.5,2,5,f1c)
	elseif p_d then
		fire(p_x+4,p_y-2,0,0,-0.5,10,f2c)
	else		
		
	end
	fire(t_px+4,t_py+4,0,0.5,1,10,f1c)
	
	--trash
	for trash in all(trashs) do
		spr(trash.sprite,trash.x,trash.y)
	end
	
	spr(get_frame(ss_ani,2),0,0)
	print(pt,8,2,7)
	print("level:"..level,40,2,7)

	offst=0
	for txt in all(debug) do
		print(txt,10,offst,8)
		offst+=8
	end
end
-->8
--trash
--load trash is called at
--start and each new level
function load_trash()
	t_tmr=0
	t_ybnd=t_df_ybnd
	t_grav=grav
	if level==1 then	
		fill_trash(64,2,10,0)--zig
	elseif level==2 then
		fill_trash(64,-2,10,0)--zig
	elseif level==3 then
		fill_trash(0,1,10,1)--cross
	elseif level==4 then
		fill_trash(0,1,5,2)--line
	elseif level==5 then
		fill_trash(88,2,10,0)--dblzig
		fill_trash(88,-2,10,0)
	elseif level==6 then
		fill_trash(32,2,10,0)--dblzig
		fill_trash(32,-2,10,0)	
	end
end

function fill_trash(_x,_sdir,_amt,_typ)
	for i=1,_amt do
		local _i,nx=i,_x
		if _typ==1 and i%2==0 then--cros
			_i=i-1
			nx=118
		elseif _typ==2 then--line
			nx=20*i
			_i=1
		end
 	trash={
 		sprite=flr(rnd(t_cnt)+t_spr),
 		x=nx,
 		bx=nx,--base x
 		y=_i*(-t_itrvl),
 		i=i,
 		dir=_sdir,
 		typ=_typ
 	}
 	add(trashs,trash)
 end	
end

function trash_update()
	for trash in all(trashs) do
		trash.y+=t_grav
		trash.x=get_pattern_x(trash)
		--trash captured
		if trash.y+4>p_y-8
		and trash.y+4<p_y
		and trash.x+4>p_x
		and trash.x+4<p_x+8 then
			pt+=1
			del(trashs,trash)
			sfx(1)
		end
		
		--trash survived
		if (trash.y>t_ybnd and t_ybnd>0)
		or (trash.y<=0 and t_ybnd==0)
		then
			del(trashs,trash)
			sfx(0)
		end
	end
	--got all trash
	if #trashs==0 then
		if t_tmr>60 then
			level+=1
			load_trash()
		else
			t_tmr+=1
		end
		
	end
end

function get_pattern_x(_t)
	local _typ=_t.typ
	if _typ==0 then--zig
		return zig_p(_t)
	elseif _typ==1 then--cros
		return cros_p(_t)
	elseif _typ==2 then--line
		if _t.y>100 then
			t_grav=-1
			t_ybnd=0--make bnd top of scrn
		end
		return _t.x
	end	
end

function zig_p(_t)
	if _t.y >= 0 and _t.y < 50 then
		_t.x+=_t.dir
	elseif _t.y >=50 then
		_t.x-=_t.dir
	end
	return _t.x
end

function cros_p(_t)--_x,_y,i)
	if _t.y >= 0 then
		local c_dir=-2
		if _t.i%2==1 then
			c_dir=2
		end
		_t.x+=c_dir
	end
	return _t.x
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
-->8
--tools
function get_frame(ani,spd)
 return ani[flr(t/spd)%#ani+1]
end 
-->8
--particles
function add_fx(x,y,die,dx,dy,grav,grow,shrink,r,c_table)
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
        c_table=c_table
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
            circfill(fx.x,fx.y,fx.r,fx.c)
        end
    end
end

-- fire effect
--dx/dy should be mults of -+.5
function fire(x,y,dx,dy,r,l,c_table)
    for i=0, 1 do
        --settings
        add_fx(
            x+rnd(1)-1/2,  -- x
            y+rnd(1)-1/2,  -- y
            l+rnd(l),-- die
            dx,         -- dx
            dy,       -- dy
            false,     -- gravity
            false,     -- grow
            true,      -- shrink
            r,         -- radius
            c_table    -- color_table
        )
    end
end


__gfx__
00000000000000000d5665d005d65d0000d56d50000000000000000000000000000000000d0000d0000000000000000000000000000000000000000000000000
0000000070000006065cc560055c56000065c5500000000000000000000000000000000005600650000000000000000000000000000000000000000000000000
0070070057070605006dd600006d60000006d6000000000000000000000000000000000006566560000000000000000000000000000000000000000000000000
000770005070606506066060050606000060605000000000000000000000000000000000006cc600000000000000000000000000000000000000000000000000
000770005706060500500500005050000005050000000000000000000000000000000000006dd600000000000000000000000000000000000000000000000000
00700700506060d50000000000000000000000000000000000000000000000000000000000066000000000000000000000000000000000000000000000000000
0000000056060d050000000000000000000000000000000000000000000000000000000006566560000000000000000000000000000000000000000000000000
00000000055555500000000000000000000000000000000000000000000000000000000005000050000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0088880000cccc0000aaaa0000bbbb0000eeee000099990000000000000000000000000000000000000000000000000000000000000000000000000000000000
02000880010cc0c009aa00a0030bbbb0020e0ee004000990008558000025580000255e0000255e0000855e0000e55e0000e5580000e5520000e5520000855200
0200088001c00cc009a0a0a003b0bbb0020e00e004999090008888000028880000288e000028ee00008eee0000eeee0000eee80000ee820000e8820000888200
0200088001c00cc0090a0aa003b00bb00200eee004009090008668000026680000268e000028ee00008eee0000eeee0000eee80000ee820000e8620000866200
02888080010cc0c009a0a0a0030bb0b0020000e004909090008888000028880000288e000028ee00008eee0000eeee0000eee80000ee820000e8820000888200
002222000011110000999900003333000022220000444400008888000028880000288e000028ee00008eee0000eeee0000eee80000ee820000e8820000888200
__sfx__
0001000029050290502805027050270501f0501d0501c0501b0503105018050170501605015050140501305012050110501c050100500e0500d0500b0500a0500905007050060500505005050040500305003050
00010000080500a0500d0502a050140501c0503205025050000002c05028050300502305034050360503905015050100501005010050100500000000000000000000000000000000000000000000000000000000
930100003065031650316501460001600016000160000600006000060000600006000360000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
4b0100000665007650076500c6500e650106501265013650176501a6501c6501e6502165024650286502a6002c6002c6002c6002d6002d6002e60030600306003060030600306003160031600000000000000000
051000000005500055000050000500055000550000500005000550005500005000050005500055000050000500055000550000500005000550005500005000050005500055000050000500055000550000500005
051000000000000000000030000300053000000000300003000000000000000000000005300000000000000300000000000000000000000530000000000000000000000000000000000000053000000000000003
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09200000232502325023250232502625028250282502825028250282502625026250262502625026250262502625026250232501f2501f2501f2501f2501f2501c2501c2501c2501c2501f2501f2501f2501f250
__music__
01 04454344
02 04054344

