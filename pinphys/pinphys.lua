
-- GAMES

function new_g()
  -- set up a new game with all its components, and sizing to draw
  local g = {
    -- render colors and game sizes
    ["bc"] = 0, -- background color
    ["wc"] = 1, -- wall color
    ["x"] = 10,
    ["y"] = 0,
    ["w"] = 110,
    ["h"] = 128,
    ["ew"] = 3, -- edge width
    ["lw"] = 9, -- lane width, for inlanes/drains
    -- objects in the world
    ["bs"] = {}, -- balls
    ["lfs"] = {}, -- left flippers
    ["rfs"] = {}, -- right flippers
    ["pbs"] = {}, -- pop bumpers
    ["os"] = {}, -- all objects
    -- max velocity magnitudes
    ["mvx"] = 3,
    ["mvy"] = 11,
    -- bump elasticity, per material (pixel color of bump)
    ["el"] = {
      [1] = 0.5, -- wall color, also set above
      [6] = 1.5, -- ball outer
      [10] = 1, -- yellow kicker
      [12] = 1, -- pop bumper
      [14] = 0.3, -- pink flipper
    }
  }
  g["dw"] = g.lw * 1.5 -- drain width
  return g
end

function init_g(g)

  -- clear any previously created objects
  for o in all(g.os) do
    g[o["t"].."s"] = {}
  end
  g.o = {}

  -- properties set in draw_g()
  add_o(g, new_lf())
  add_o(g, new_rf())

  -- properties set in draw_g()
  add_o(g, new_pb())
  add_o(g, new_pb())
  add_o(g, new_pb())

  return g
end

function add_o(g, o)
  -- add an object to the world, classified by its 't' (type) key
  o.g = g
  add(g.os, o)
  -- pluralize the type and store in dedicated tables
  local k = o.t.."s"
  add(g[k], o)
end

function draw_g(g)
  -- draw the game board and components
  cls(g.bc)
  rectfill(g.x, g.y, g.x + g.w, g.y + g.h, g.wc)
  local r = g.w / 2 - g.ew -- top cutout radius

  circfill(g.x + g.w / 2, g.y + r + g.ew, r, g.bc) -- top cutout
  rectfill(g.x + g.ew, g.y + r, g.x + g.w - g.ew, g.y + g.h, g.bc) -- bottom hollow

  -- inlanes is a rect, with a circle cutout for the drain and two flippers
  local ilr = g.dw * 2 -- radius of inline cutout
  local ily = g.y + g.h - ilr -- inlane starting "y" value
  rectfill(g.x + g.ew + g.lw, ily, g.x + g.w - g.ew - g.lw, g.y + g.h - g.ew, g.wc) -- inlane walls
  circfill(g.x + g.w / 2, ily, ilr, g.bc) -- inlane cutout


  -- lflip
  g.lfs[1].x = g.x + g.w / 2 - g.dw - g.lfs[1].w / 2
  g.lfs[1].y = g.y + g.h - g.lfs[1].h + g.ew

  -- rflip
  g.rfs[1].x = g.x + g.w / 2 + g.dw - g.rfs[1].w / 2
  g.rfs[1].y = g.y + g.h - g.rfs[1].h + g.ew

  spr(17, g.x + g.ew + g.lw, ily - 16, 2, 2)-- l sling
  spr(19, g.x + g.w - g.ew - g.lw - 16 + 1, ily - 16, 2, 2)-- r sling

  -- pop bumpers
  g.pbs[1].x = g.x + g.w / 2 - r / 3 - g.pbs[1].w
  g.pbs[1].y = g.y + r / 2 + g.ew

  g.pbs[2].x = g.x + g.w / 2 + r / 3
  g.pbs[2].y = g.pbs[1].y

  g.pbs[3].x = g.x + g.w / 2 - g.pbs[1].w / 2
  g.pbs[3].y = g.pbs[1].y + g.pbs[1].h

  --
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

  for pb in all(g.pbs) do
    draw_pb(pb)
  end
end

function update_g(g)

  -- update ball positions
  for b in all(g.bs) do
    if b.live then move_b(b) end
  end

  -- reset
  if (btnp(4)) then
    sfx(0)
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

  -- add-a-ball
  if (btnp(2)) then
    if (#g.bs < 5) then
      sfx(3)
      local b
      b = new_b(g.x + g.w / 2, g.y + g.ew * 2 )
      b.x = b.x - b.w / 2
      -- b.y = b.y - b.h
      b.vx = rnd(g.mvx) - g.mvx / 2
      b.vy = rnd(g.mvy) - g.mvy / 2

      add_o(g, b)
    else
      sfx(2)
    end
  end
end

-- BALLS

function new_b(x, y, vx, vy)
  return {
    ["t"] = "b", -- type
    ["g"] = nil, -- parent game
    ["x"] = x,
    ["y"] = y,
    ["w"] = 8, -- sprite dimensions
    ["h"] = 8,
    ["vx"] = (vx == nil and 0 or vx),
    ["vy"] = (vy == nil and 0 or vy),
    ["ci"] = {}, -- collision information
    ["spr"] = 1,
    ["live"] = true
  }
end

function draw_b(b)
  spr(b.spr, b.x, b.y)
end

function move_b(b)

  local g = b.g
  -- center of the ball
  local cx = b.x + b.w / 2
  local cy = b.y + b.h / 2

  -- ball is out of bounds
  if cx < g.x or cx > g.x + g.w or cy < g.y or cy > g.y + g.h then
    b.live = false
    return
  end

  -- friction!
  b.vx = b.vx * 0.97
  b.vy = b.vy * 0.97

  -- gravity!
  b.vy = b.vy + 0.3

  -- not moving
  if abs(b.vx) <= 0.25 and abs(b.vy) <= 0.25 then return end

  -- velocity cap
  if abs(b.vx) > g.mvx then b.vx = g.mvx * sgn(b.vx) end
  if abs(b.vy) > g.mvy then b.vy = g.mvy * sgn(b.vy) end

  bump_b(b)

  b.x = b.x + b.vx
  b.y = b.y + b.vy
end

function bump_b(b)
  -- set collision information for the given ball

  --[[since the "ball" is really just a chunky block, check the surrounding
  pixels for non-background colors]]

  local bumped = false

  -- top and bottom, outer corners

  local x, y, c

  -- done as while loops to allow fast breakout when a collision is found
  -- top and bottom, outer corners
  x = b.x
  while not bumped and x <= b.x + b.w do
    y = b.y
    while not bumped and y <= b.y + b.h do
      c = pget(x, y)
      if c ~= b.g.bc then
        b.ci = {["x"] = x, ["y"] = y, ["c"] = c}
        bumped = true
      end
      y = y + b.h
    end
    x = x + 1
  end

  -- sides, with no corner overlap
  x = b.x
  while not bumped and x <= b.x + b.w do
    y = b.y + 1
    while not bumped and y <= b.y + b.h - 1 do
      c = pget(x, y)
      if c ~= b.g.bc then
        b.ci = {["x"] = x, ["y"] = y, ["c"] = c}
        bumped = true
      end
      y = y + 1
    end
    x = x + b.w
  end

  -- four inner corner "bites"
  x = b.x + 1
  while not bumped and x <= b.x + b.w - 1 do
    y = b.y + 1
    while y <= b.y + b.h - 1 do
      c = pget(x, y)
      if c ~= b.g.bc then
        b.ci = {["x"] = x, ["y"] = y, ["c"] = c}
        bumped = true
      end
      y = y + b.h - 2
    end
    x = x + b.w - 2
  end


  if bumped then
    sfx(1)
    c = b.ci.c
    -- adjust vectors based on the quadrant of the bump

    if g.el[c] then
      -- bump with a force depending on the impact direction and material bumped
      b.vx = 0 - b.vx + ((b.x + b.w / 2) - (b.ci.x)) / b.w * g.el[c]
      b.vy = 0 - b.vy + ((b.y + b.h / 2) - (b.ci.y)) / b.h * g.el[c]
    end
    -- if it's a wall or ball color, bounce appropriately
    -- otherwise look up the sprite at the location and determine what to do
    -- based on the type and state (bumpeder, flipper, rollover, etc.)
  else
    b.ci = {}
  end

end

function nudge_b(b)
  b.vx = b.vx + rnd(2) - 1
  b.vy = b.vy + rnd(6) - 3
  -- xxx nudge cooldown
end

-- FLIPPERS

function new_lf(x, y)
  return {["t"] = "lf", ["x"] = x, ["y"] = y, ["w"] = 16, ["h"] = 8, ["up"] = false, ["spr"] = {2, 6}}
end

function new_rf(x, y)
  return {["t"] = "rf", ["x"] = x, ["y"] = y, ["w"] = 16, ["h"] = 8, ["up"] = false, ["spr"] = {4, 8}}
end

function draw_f(f)
  spr((f.up and f.spr[2] or f.spr[1]), f.x, f.y, f["w"] / 8, f["h"] / 8)
end

-- POP BUMPERS

function new_pb(x, y)
  return {["t"] = "pb", ["x"] = x, ["y"] = y, ["w"] = 16, ["h"] = 16, ["lit"] = false, ["spr"] = 21}
end

function draw_pb(pb)
  spr(pb.spr, pb.x, pb.y, pb["w"] / 8, pb["h"] / 8)
end
