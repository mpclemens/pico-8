
-- GAMES

function new_g()
  -- set up a new game with all its components, and sizing to draw
  local g = {
    -- render colors and game sizes
    ["bc"] = 0,
    ["wc"] = 1,
    ["x"] = 10,
    ["y"] = 0,
    ["w"] = 110,
    ["h"] = 128,
    ["ew"] = 3, -- edge width
    ["lw"] = 8, -- lane width, for inlanes/drains
    -- members
    ["bs"] = {}, -- balls
    ["lfs"] = {}, -- left flippers
    ["rfs"] = {}, -- right flippers
  }
  g["dw"] = g.lw * 1.25 -- drain width
  return g
end

function init_g(g)
  g.bs = {
    new_b(g, 40, 20, rnd(4) - 2, rnd(4) - 2),
    new_b(g, 50, 20, rnd(4) - 2, rnd(4) - 2),
    new_b(g, 60, 20, rnd(4) - 2, rnd(4) - 2)
  }

  g.lfs = {
    new_lf()
  }
  g.rfs = {
    new_rf()
  }
  return g
end

function draw_g(g)
  -- draw the game board and components
  cls(g.bc)
  rectfill(g.x, g.y, g.x + g.w, g.y + g.h, g.wc)
  local r = g.w / 2 - g.ew -- top cutout radius

  circfill(g.x + g.w / 2, g.y + r + g.ew, r, g.bc)
  rectfill(g.x + g.ew, g.y + r, g.x + g.w - g.ew, g.y + g.h, g.bc) -- bottom hollow
  -- rectfill(g.x + g.w / 2 - bw, g.y + g.h - p, g.x + g.w / 2 + bw, g.y + g.h, g.bc) -- drain
  -- rectfill(g.x + p, g.y + g.h - p, g.x + p + bw, g.y + g.h, g.bc) -- l outlane

  -- inlanes is a rect, with a circle cutout and two flippers
  local ilr = g.dw * 2.5 -- radius of inline cutout
  local ily = g.y + g.h - ilr -- inlane starting "y" value
  rectfill(g.x + g.ew + g.lw, ily, g.x + g.w - g.ew - g.lw, g.y + g.h - g.ew, g.wc) -- inlane walls
  circfill(g.x + g.w / 2, ily, ilr, g.bc) -- inlane cutout

  -- lflip
  g.lfs[1].x = g.x + g.w / 2 - g.dw * 2
  g.lfs[1].y = g.y + g.h - g.lfs[1].h + g.ew

  -- rflip
  g.rfs[1].x = g.x + g.w / 2 + g.dw * 2 - g.rfs[1].w
  g.rfs[1].y = g.y + g.h - g.rfs[1].h + g.ew

  spr(17, g.x + g.ew + g.lw, ily - 16, 2, 2)-- l sling
  spr(19, g.x + g.w - g.ew - g.lw - 16 + 1, ily - 16, 2, 2)-- r sling

  for f in all(g.lfs) do
    draw_f(f)
  end

  for f in all(g.rfs) do
    draw_f(f)
  end

  for b in all(g.bs) do
    if b.live then
      draw_b(b)
    else
      del(g.bs, b)
    end
  end
end

function update_g(g)

  -- update ball positions
  for b in all(g.bs) do
    if b.live then move_b(b) end
  end

  -- reset
  if (btnp(4)) then
    init_g(g)
  end

  -- nudge controls
  if (btnp(5)) then
    for b in all(g.bs) do
      if b.live then nudge_b(b) end
    end
  end

  -- flipper controls
  for f in all(g.lfs) do
    f.up = btn(0)
  end

  for f in all(g.rfs) do
    f.up = btn(1)
  end

  -- add-a-ball for xxx testing, down-arrow
  if (btnp(3)) then
    if (#g.bs < 5) then
      sfx(1)
      add(g.bs, new_b(g, g.x + g.w / 2, g.y + g.w / 2 - g.ew, rnd(4) - 3, rnd(4) - 3))
    else
      sfx(2)
    end
  end
end

-- BALLS

function new_b(g, x, y, vx, vy)
  return {
    ["g"] = g, -- containing game reference
    ["x"] = x,
    ["y"] = y,
    ["w"] = 6, -- actual visible pixels of sprite
    ["h"] = 6,
    ["vx"] = (vx == nil and 0 or vx),
    ["vy"] = (vy == nil and 0 or vy),
    ["spr"] = 1,
    ["live"] = true
  }
end

function draw_b(b)
  spr(b.spr, b.x, b.y)
  --  line(b.x + b.w / 2, b.y + b.h / 2, b.x + b.w / 2 + b.vx * 5, b.y + b.h / 2 + b.vy * 5, 7) -- xxx move vector
end

function sgn(n)
  -- -1 if n < 0, 0 if n == 0, 1 if n > 0
  if n == 0 then
    return 0
  end

  return n / abs(n)
end

function move_b(b)

  -- out of bounds
  if b.x < b.g.x or b.x > b.g.x + b.g.w or b.y < b.g.y or b.y > b.g.y + b.g.h then
    b.live = false
    return
  end

  local newx = b.x + b.vx
  local newy = b.y + b.vy

  -- friction!
  b.vx = b.vx * 0.99
  b.vy = b.vy * 0.97

  -- gravity!
  b.vy = b.vy + 0.2

  -- quantum!
  b.vx = b.vx + (rnd(10) - 5) / 1000

  -- not moving
  if abs(b.vx) <= 0.25 and abs(b.vy) <= 0.25 then return end

  -- check the new x and new y for collisions
  local nx = b.x + b.w + b.vx * sgn(b.vx)
  local ny = b.y + b.h + b.vy * sgn(b.vy)

  -- xxx better checker here, identify what was hit
  if pget(nx, ny) ~= b.g.bc then
    b.vx = 0 - b.vx
    b.vy = 0 - b.vy
  end

  b.x = b.x + b.vx
  b.y = b.y + b.vy
end

function nudge_b(b)
  b.vx = b.vx + rnd(2) - 1
  b.vy = b.vy + rnd(6) - 3
  -- xxx nudge cooldown
end

-- FLIPPERS

function new_lf(x, y)
  return {["x"] = x, ["y"] = y, ["w"] = 16, ["h"] = 8, ["up"] = false, ["spr"] = {2, 6}}
end

function new_rf(x, y)
  return {["x"] = x, ["y"] = y, ["w"] = 16, ["h"] = 8, ["up"] = false, ["spr"] = {4, 8}}
end

function draw_f(f)
  spr((f.up and f.spr[2] or f.spr[1]), f.x, f.y, f["w"] / 8, f["h"] / 8)
end
