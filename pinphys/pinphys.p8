pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

#include pinphys.lua


function _init()
  g = new_g()
  g.bs = {
    new_b(10,10),
    new_b(20,20,1),
    new_b(30,15,-1)
  }
  g.lfs = {
    new_lf(60,120),
  }
  g.rfs = {
    new_rf(86,120)
  }
end

function _draw()
  draw_g(g)
end

function _update60()
  update_g(g)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066677600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000065677600eeeeee000000000000000000eeeeee00eeeeeeeeeeeeee00eeeeeeeeeeeeee0000000000000000000000000000000000000000000000000
0000000006566660e88888eeee000000000000eeee88888ee88888888888ee0000ee88888888888e000000000000000000000000000000000000000000000000
0000000006655660e58888888eee00000000eee88888885ee58888888eee00000000eee88888885e000000000000000000000000000000000000000000000000
0000000000666600e88888888888ee0000ee88888888888ee88888eeee000000000000eeee88888e000000000000000000000000000000000000000000000000
00000000000000000eeeeeeeeeeeeee00eeeeeeeeeeeeee00eeeeee000000000000000000eeeeee0000000000000000000000000000000000000000000000000