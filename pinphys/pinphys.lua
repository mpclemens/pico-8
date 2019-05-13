
-- GAMES

function new_g()
  -- set up a new game with all its components, and sizing to draw
  return {
    -- render colors and game sizes
    ["bc"] = 0,
    ["wc"] = 1,
    ["x"] = 0,
    ["y"] = 0,
    ["w"] = 100,
    ["h"] = 128,
    -- members
    ["bs"] = {}, -- balls
    ["lfs"] = {}, -- left flippers
    ["rfs"] = {}, -- right flippers
  }
end

function draw_g(g)
  -- draw the game board and components
  cls(g.bc)
  rectfill(g.x, g.y, g.x + g.w, g.y + g.h, g.wc)

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
