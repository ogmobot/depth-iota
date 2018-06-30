pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- iota
-- by ogmobot

function update_move(t)
  t.y+=t.vel*sin(t.ang)
  t.x+=t.vel*cos(t.ang)
  if t.x<-8 then
    t.x+=(16+world.size.x)
  elseif t.x>world.size.x+8 then
    t.x-=(16+world.size.x)
  end
end

function apply_grav(t,g)
  g=g or .1
  yv=t.vel*sin(t.ang)
  xv=t.vel*cos(t.ang)
  yv+=g
  t.vel=sqrt((xv*xv)+(yv*yv))
  t.ang=atan2(xv,yv)
end

function collide(p,q)
  return (abs(p.x-q.x)<(p.rad+q.rad-1)) and (abs(p.y-q.y)<(p.rad+q.rad-1))
end

function wait(f)
  for _=1,f do
    flip()
  end
end

function wait_for_input()
  while btn()==0 do
    flip()
  end
end

function newbubble(x,y)
  b={x=x,y=y,hp=30,vel=0,ang=.25}
  -- hp is lifespan in frames
  b.update=function(t)
    apply_grav(t,-.01)
    update_move(t)
    if t.y<=world.waterlevel then
      t.hp=0
    else
      t.hp-=1
    end
  end
  b.draw=function(t)
    pset(t.x,t.y,7)
  end
  return b
end
function newdroplet(x,y)
  b={x=x,y=y,hp=5,vel=0,ang=0.75}
  -- hp drops in water
  b.update=function(t)
    update_move(t)
    if t.y>world.waterlevel then
      t.hp-=1
      if t.vel>=1 and rnd()<.1 then
        t.ang=.25
        t.vel/=2
      end
    end
    apply_grav(t)
  end
  b.draw=function(t)
    pset(t.x,t.y,world.watercolour)
  end
  return b
end
function splash(x,y,v)
  sfx(0)
  for _=1,20 do
    b=newdroplet(x,y)
    b.vel=v*rnd()
    b.ang=rnd(.3)+.1
    add(particles,b)
  end
end
function sparks(x,y)
  for i=1,20 do
    b=newbubble(x,y)
    b.vel=rnd()
    b.ang=rnd()
    b.hp=i
    add(particles,b)
  end
end
function newcoin(minx,miny,maxx,maxy,value,colour)
  b={rad=2,value=value,colour=colour,hp=1}
  b.respawn=function(t)
    while true do
      t.x=minx+rnd(maxx-minx)
      t.y=miny+rnd(maxy-miny)
      happy=true
      for q in all(blocks) do
        if collide(t,q) then
          happy=false
        end
      end
      if happy then
        break
      end
    end
  end
  b.update=function(t)
    if collide(t,player) then
      world.score+=t.value
      sfx(1,-1,0,3*t.value)
      sparks(t.x,t.y)
      t:respawn()
    end
  end
  b.draw=function(t)
    circfill(t.x,t.y,t.rad,t.colour)
  end
  b:respawn()
  return b
end
function newblock(x,y)
  b={x=x,y=y,rad=4}
--  local sprite=flr(rnd(8))+8
  sprite=sprite or 8
  b.draw=function(t)
    spr(sprite,t.x-t.rad,t.y-t.rad)
  end
  return b
end
function endgame()
  sfx(0)
  print("game over",cam.x+64-18,cam.y+48-4,0)
  print("game over",cam.x+64-18,cam.y+48-5,7)
  flip()
  wait(15)
  print("press any key to restart",cam.x+64-48,cam.y+48+8,0)
  print("press any key to restart",cam.x+64-48,cam.y+48+7,7)
  wait_for_input()
  _init()
end

function _init ()
world={
  size={x=512,y=256},
  waterlevel=32,
  score=0,
  watercolour=1,
  skycolour=12
  }
particles={}
player={
  x=16,
  y=16,
  rad=4,
  vel=2,
  ang=.125,
  sprite=0,
  bubtick=0,
  wet=false,
  dead=false,
  update=function(t)
    --movement
    if t.y<world.waterlevel then
      apply_grav(t)
    else
      t.vel=2+(.1*world.score)
      if (btn(⬅️)) t.ang+=.02
      if (btn(➡️)) t.ang-=.02
      t.ang%=1
    end
    update_move(t)
    t.sprite=flr((t.ang*8)+.5)%8
    --particles
    t.bubtick+=1
    if t.bubtick>=10 then
      t.bubtick=0
      if t.y>world.waterlevel then
        add(particles,newbubble(t.x,t.y))
      end
    end
    if t.wet and t.y<world.waterlevel then
      splash(t.x,t.y,t.vel)
      t.wet=false
    end
    if (t.wet==false) and t.y>=world.waterlevel then
      splash(t.x,t.y,t.vel)
      sparks(t.x,t.y)
      t.wet=true
    end
    --death
    for b in all(blocks) do
      if collide(t,b) then
        t.dead=true
      end
    end
  end,
  draw=function(t)
    spr(t.sprite,t.x-t.rad,t.y-t.rad)
  end
  }
--generate blocks
blocks={}
for i=world.waterlevel+16,world.size.y-8,8 do
  add(blocks,newblock(flr(rnd(world.size.x-8)),i))
end
for i=-8,world.size.x,8 do
  add(blocks,newblock(i,world.size.y))
end

coins={
--water coins
  newcoin(0,world.waterlevel,world.size.x,world.size.y-8,1,10),
  newcoin(0,world.waterlevel,world.size.x,world.size.y-8,1,10),
--sky coin
  newcoin(0,-32,world.size.x,world.waterlevel,2,9)
  }
cam={
  x=0,
  y=0,
  vel=0,
  ang=0,
  follow=player,
  update=function(t)
    targetx=-64+t.follow.x--+(1*t.follow.vel*cos(t.follow.ang))
    targety=-64+t.follow.y--+(1*t.follow.vel*sin(t.follow.ang))
--    t.ang=atan2(targetx-t.x,targety-t.y)
--    distance=sqrt((targetx-t.x)^2+(targety-t.y)^2)

--    update_move(t)
    t.x=targetx
    t.y=targety

    t.x=mid(0,t.x,-128+world.size.x)
    t.y=min(t.y,-128+world.size.y)

    camera(t.x,t.y)
  end
  }
end

function _update()
  if player.dead then
    endgame()
  else
    player:update()
    cam:update()
    for p in all(particles) do
      if p.hp<=0 then
        del(particles,p)
      else
	       p:update()
	     end
    end
    for c in all(coins) do
      c:update()
    end
  end
end

function _draw()
-- draw sky
cls(world.skycolour)
-- draw sun
circfill(
  cam.x+128*(1-((cam.x+64)/world.size.x)),
  16+.2*(cam.y+16),
  8,10)
-- draw water
rectfill(0,world.waterlevel,world.size.x,world.size.y,world.watercolour)
-- draw particles
for p in all(particles) do
  p:draw()
end
-- draw blocks
for b in all(blocks) do
  b:draw()
end
-- draw player
player:draw()
-- draw coins
for c in all(coins) do
  c:draw()
end
-- draw score
print("score: "..world.score,cam.x+1,cam.y+2,0)
print("score: "..world.score,cam.x+1,cam.y+1,7)
-- camera debug
--pset(cam.x+64,cam.y+64,8)
end
__gfx__
00777770077777000700007000777770077777000777000000700700000077705555555555555555555555555555555555555555555555555555555555555555
07777777777770007707707700077777777777707770007007000070070007775ffffff55ffffff55ffff5f55ffff5f55ff5fff55ffffff55ffffff55ffffff5
70000700770077077777777770770077007000077700770077077077007700775ffffff55ffffff55ffff5f55ff3f5f55f5fff555ffffff555fffff55fffff35
00777770700777777707707777777007077777007707770077077077007770775ffffff55ffffff55fff5ff55fff5ff555f5fff55ffffff55fffff555ffffff5
00777770007770777707707777077700077777007777700777077077700777775ffffff55ffffff55ff5fff55ff5fff55fff5ff55ffffff555fffff55ffffff5
70000700007700777707707777007700007000077077007777777777770077075ffffff55ffffff55f5ffff55f5ffff55ffff5f55ffffff55fffff555f3ffff5
07777777070007770700007077700070777777700007777777077077777770005ffffff55ffffff55f5ffff55f5ffff55ffff5f55ffffff55ffffff55ffffff5
00777770000077700070070007770000077777000077777007000070077777005555555555555555555555555555555555555555555555555555555555555555
__sfx__
010200000763007620076100701007600076000760007600201032010320103201032010320103201032010320103201032010320103201032010314103141031410314103201032010320103201032010300003
010300002a0502d050320502d05032050360500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800000200009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00002605226052260522605226052000002105000000210500000021050000002105000000210501800025052250522505225052250520000021050000002105000000210500000021050000002105000000
__music__
01 08424344

