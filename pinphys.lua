
-- GAMES

function new_g()
  -- set up a new game with all its components, and sizing to draw
  local g = {
    -- render colors and game sizes
    ["bc"] = 0,
    ["wc"] = 1,
    ["x"] = 0,
    ["y"] = 0,
    ["w"] = 100,
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

function draw_g(g)
  -- draw the game board and components
  cls(g.bc)
  rectfill(g.x, g.y, g.x + g.w, g.y + g.h, g.wc)
  local r = g.w / 2 - g.ew -- top cutout radius

  circfill(g.x + g.w / 2, g.y + r + g.ew, r, g.bc)
  rectfill(g.x + g.ew, g.y + r, g.x + g.w - g.ew, g.y + g.h, g.bc) -- bottom hollow
  -- rectfill(g.x + g.w / 2 - bw, g.y + g.h - p, g.x + g.w / 2 + bw, g.y + g.h, g.bc) -- drain
  -- rectfill(g.x + p, g.y + g.h - p, g.x + p + bw, g.y + g.h, g.bc) -- l outlane

  rectfill(g.x + g.ew + g.lw, g.y + g.h - 3 * g.lw, g.x + g.w / 2 - g.dw, g.y + g.h, g.wc) -- l inlane
  rectfill(g.x + g.w - g.ew - g.lw, g.y + g.h - 3 * g.lw, g.x + g.w / 2 + g.dw, g.y + g.h, g.wc) -- r inlane


  -- spr(17, g.x + g.w / 2 - bw * 4, g.y + g.h - p - bw - 16, 2, 2)-- l slingshot
  -- rectfill(g.x + g.w - p, g.y + g.h - p, g.x + g.w - p - bw, g.y + g.h, g.bc) -- r outlane
  -- r slingshot


  for f in all(g.lfs) do
    draw_f(f)
  end

  for f in all(g.rfs) do
    draw_f(f)
  end

  for b in all(g.bs) do
    draw_b(b)
  end
end

function update_g(g)

  -- update ball positions
  for b in all(g.bs) do
    move_b(b)
  end

  -- nudge controls
  if (btnp(5)) then
    for b in all(g.bs) do
      nudge(b)
    end
  end

  -- flipper controls
  for f in all(g.lfs) do
    f.up = btn(0)
  end

  for f in all(g.rfs) do
    f.up = btn(1)
  end
end

-- BALLS

function new_b(x, y, vx, vy)
  return {
    ["x"] = x,
    ["y"] = y,
    ["vx"] = (vx == nil and 0 or vx),
    ["vy"] = (vy == nil and 0 or vy),
    ["spr"] = 1
  }
end

function draw_b(b)
  spr(b.spr, b.x, b.y)
  line(b.x + 4, b.y + 4, b.x + 4 + b.vx, b.y + 4 + b.vy, 10) -- xxx collision line
end

function move_b(b)
  if b.x + b.vx < 0 + 7 or
  b.x + b.vx > 128 - 7
  then
    -- bounce on side!
    b.vx = b.vx * - 1
    sfx(1)
  else
    b.x = b.x + b.vx
  end

  -- move ball up/down
  if b.y + b.vy < 0 + 7 or b.y + b.vy > 128 - 7
  then
    -- bounce on floor/ceiling
    b.vy = b.vy * - 0.9
  else
    b.y = b.y + b.vy
  end

  -- friction!
  b.vx = b.vx * 0.97
  b.vy = b.vy * 0.97

  -- gravity!
  b.vy = b.vy + 0.2
end

function nudge(b)
  b.vx = b.vx + rnd(2) - 1
  b.vy = b.vy + rnd(6) - 3
  -- xxx nudge cooldown
end

-- FLIPPERS

function new_lf(x, y)
  return {["x"] = x, ["y"] = y, ["up"] = false, ["spr"] = {2, 6}}
end

function new_rf(x, y)
  return {["x"] = x, ["y"] = y, ["up"] = false, ["spr"] = {4, 8}}
end

function draw_f(f)
  spr((f.up and f.spr[2] or f.spr[1]), f.x, f.y, 2, 1)
end
