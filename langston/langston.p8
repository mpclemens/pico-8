pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

#include langston.lua
function _init()
  ants = {}
  add(ants,new_ant())
  cls()
end

function _draw()
  for a in all(ants) do
    move_ant(a)
  end
end

function _update()

  if (btnp(4) and btnp(5)) then
    -- invert pixels
    sfx(5)
    for x = 0,128 do
      for y = 0,128 do
        pset(x,y,(pget(x,y) == 7 and 0 or 7))
      end
    end
  elseif (btnp(5)) then
    -- clear screen with white
    sfx(4)
    cls(7)
  elseif (btnp(4)) then
    -- clear screen with black
    sfx(3)
    cls(0)
  end

  -- add-an-ant
  if (btnp(2)) then
    if (#ants < 10) then
      local a = new_ant()
      add(ants,a)
      sfx(1)
    else
      sfx(0)
    end
  end

  -- remove-an-ant
  if (btnp(3)) then
    if (#ants > 1) then
      pset(ants[1].x, ants[1].y, 8)
      del(ants, ants[1])
      sfx(2)
    else
      sfx(0)
    end
  end
end
__sfx__
000600001d15000100181501110000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
0004000003550085500c55010550175501e5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000215501a55016550105500b550075500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800002335001300223502530020350213002c30000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
0008000017350000001a350243001f3501f3000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800002b35015350293501c35027350203500030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300