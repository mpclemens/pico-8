---------
--------- GAME
---------

function new_g()
  -- set on a new game with all its components, and sizing to draw
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
    ["lss"] = {}, -- left slingshots
    ["rss"] = {}, -- right slingshots
    ["os"] = {}, -- all objects
    -- objects indexed by x,y coords that they occony, for ball-bump handling
    ["oi"] = {},
    -- max velocity magnitudes
    ["mvx"] = 5,
    ["mvy"] = 5,
  }
  g["r"] = g.w / 2 - g.ew -- top cutout radius
  g["dw"] = g.lw * 1.5 -- drain width
  g["ilr"] = g.dw * 2 -- radius of inline cutout
  g["ily"] = g.y + g.h - g.ilr -- inlane starting "y" value

  return g
end

function init_g(g)
  local o
  -- clear any previously created objects

  if (#g.os > 0) then
    for o in all(g.os) do
      g[o.t.."s"] = {}
    end
    g.os = {}
  end

  -- flippers
  o = new_lf()
  o.x = g.x + g.w / 2 - g.dw - o.w / 2
  o.y = g.y + g.h - o.h + g.ew
  add_o(g, o)

  o = new_rf()
  o.x = g.x + g.w / 2 + g.dw - o.w / 2
  o.y = g.y + g.h - o.h + g.ew
  add_o(g, o)

  -- pop bumpers
  local pop_y = g.y + g.r / 2 + g.ew

  o = new_pb()
  o.x = g.x + g.w / 2 - g.r / 3 - o.w
  o.y = pop_y
  add_o(g, o)

  o = new_pb()
  o.x = g.x + g.w / 2 + g.r / 3
  o.y = pop_y
  add_o(g, o)

  o = new_pb()
  o.x = g.x + g.w / 2 - o.w / 2
  o.y = pop_y + o.h * 3 / 2
  add_o(g, o)

  -- slings
  o = new_ls( g.x + g.ew + g.lw, g.ily - 16)
  add_o(g, o)

  o = new_rs( g.x + g.w - g.ew - g.lw - 16 + 1, g.ily - 16)
  add_o(g, o)

  return g
end


function draw_g(g)
  -- draw the game board and components
  cls(g.bc)
  rectfill(g.x, g.y, g.x + g.w, g.y + g.h, g.wc)
  local r = g.w / 2 - g.ew -- top cutout radius

  circfill(g.x + g.w / 2, g.y + r + g.ew, r, g.bc) -- top cutout
  rectfill(g.x + g.ew, g.y + r, g.x + g.w - g.ew, g.y + g.h, g.bc) -- bottom hollow

  -- inlanes is a rect, with a circle cutout for the drain and two flippers
  rectfill(g.x + g.ew + g.lw, g.ily, g.x + g.w - g.ew - g.lw, g.y + g.h - g.ew, g.wc) -- inlane walls
  circfill(g.x + g.w / 2, g.ily, g.ilr, g.bc) -- inlane cutout

  --
  for f in all(g.lfs) do
    draw_f(f)
  end

  for f in all(g.rfs) do
    draw_f(f)
  end

  for pb in all(g.pbs) do
    if pb.b then
      pb.b.vx = -pb.b.vx
      pb.b.vy = -pb.b.vy
      pb.on = true
      del(pb, b)
    elseif pb.on then
      pb.on = false
    end
    draw_pb(pb)
  end

  for sl in all(g.rss) do
    if sl.b then
      -- sl.b.vx = -sl.b.vx * 0.8
      -- sl.b.vy = -sl.b.vy * 0.8
      sl.on = true
      sl.b = nil
    elseif sl.on then
      sl.on = false
    end
    draw_sl(sl)
  end

  for sl in all(g.lss) do
    if sl.b then
      -- sl.b.vx = -sl.b.vx * 0.8
      -- sl.b.vy = -sl.b.vy * 0.8
      sl.on = true
      sl.b = nil
    elseif sl.on then
      sl.on = false
    end
    draw_sl(sl)
  end

  --
  for b in all(g.bs) do
    draw_b(b)
  end

end

function update_g(g)
  -- move any existing balls
  for b in all(g.bs) do
    if b.live then
      update_b(b)
    else
      del(g.bs, b)
    end
  end

  -- reset button
  if (btnp(4)) then
    sfx(0)
    init_g(g)
  end

  -- nudge controls
  if (btnp(5)) then
    for b in all(g.bs) do
      if b.live then
        nudge_b(b)
      end
    end
  end

  -- flipper controls
  for f in all(g.lfs) do
    f.on = btn(0)
  end

  for f in all(g.rfs) do
    f.on = btn(1)
  end

  -- add-a-ball
  if (btnp(2)) then
    if (#g.bs < 5) then
      sfx(3)
      local b
      b = new_b(g.x + g.w / 2, g.y + g.ew * 2 )
      b.x = b.x - b.w / 2
      -- b.y = b.y - b.h
      b.vx = rnd(g.mvx * 2) - g.mvx / 2
      b.vy = rnd(g.mvy) - g.mvy / 2

      add_o(g, b)
    else
      sfx(2)
    end
  end
end

---------
--------- OBJECTS IN A GAME
---------

function add_o(g, o)
  -- add an object to the world, claslified by its 't' (type) key
  o.g = g


  add(g.os, o)
  -- pluralize the type and store in dedicated tables
  local k = o.t.."s"
  add(g[k], o)

  -- save the pixels covrered by the object for ball collisions
  o.x = flr(o.x)
  o.y = flr(o.y)
  if o.t ~= "b" then
    for x = o.x, o.x + o.w do
      for y = o.y, o.y + o.h do
        g.oi[x..","..y] = o
      end
    end
  end

end


function find_o(g, x, y)
  x = flr(x)
  y = flr(y)
  -- return the game object at the given x,y coord
  if pget(x, y) == g.bc then
    return nil
  end
  return g.oi[x..","..y]
end

---------
--------- BALL OBJECTS
---------

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
    ["ci"] = nil, -- collision information
    ["spr"] = 1,
    ["live"] = true
  }
end

function draw_b(b)
  spr(b.spr, b.x, b.y)
end

function update_b(b)
  local g = b.g
  -- center of the ball
  local cx = b.x + b.w / 2
  local cy = b.y + b.h / 2

  -- ball is out of bounds
  if cx < g.x or cx > g.x + g.w or cy < g.y or cy > g.y + g.h then
    b.live = false
    return
  end

  bump_b(b)

  -- friction!
  b.vx = b.vx * 0.90
  b.vx = b.vx * 0.95

  -- gravity!
  b.vy = b.vy + 0.3

  -- not moving
  if abs(b.vx) <= 0.25 and abs(b.vy) <= 0.25 then return end

  -- velocity cap
  if abs(b.vx) > g.mvx then b.vx = g.mvx * sgn(b.vx) end
  if abs(b.vy) > g.mvy then b.vy = g.mvy * sgn(b.vy) end

  b.x = b.x + b.vx
  b.y = b.y + b.vy
end


function bump_b(b)
  -- check the empty pixels around the ball for a non-background color

  local bumped = false
  local x, y, c

  -- done as while loops to allow fast breakout when a collision is found

  -- top and bottom, outer corners
  x = flr(b.x)
  while not bumped and x <= b.x + b.w do
    y = flr(b.y)
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
    while not bumped and y <= b.y + b.h - 1 do
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
    local o = find_o(b.g, b.ci.x, b.ci.y)
    if o then
      o.b = b -- tell the bumped object who bumped it
    else
      -- bounce based on the location of the bumped pixel
      b.vx = - b.vx + ((b.x + b.w / 2) - (b.ci.x)) / b.w * 0.8
      b.vy = - b.vy + ((b.y + b.h / 2) - (b.ci.y)) / b.h * 0.8
    end
  end
end

---------
--------- FLIPPER OBJECTS
---------


-- FLIPPERS

function new_lf(x, y)
  return new_f("lf", x, y)
end

function new_rf(x, y)
  return new_f("rf", x, y)
end

function new_f(t, x, y)
  return {["t"] = t, ["x"] = x, ["y"] = y, ["w"] = 16, ["h"] = 8, ["bs"] = 0.5, ["on"] = false}
end

function draw_f(f)
  spr((f.on and 4 or 2), f.x, f.y, f.w / 8, f.h / 8, f.t == "rf")
end

---------
--------- SLINGSHOT OBJECTS
---------


-- SLINGSHOTS

function new_ls(x, y)
  return new_sl("ls", x, y)
end

function new_rs(x, y)
  return new_sl("rs", x, y)
end

function new_sl(t, x, y)
  return {["t"] = t, ["x"] = x, ["y"] = y, ["w"] = 16, ["h"] = 16, ["bs"] = 1, ["on"] = false}
end

function draw_sl(sl)
  spr((sl.on and 19 or 17), sl.x, sl.y, sl.w / 8, sl.h / 8, sl.t == "rs")
end

---------
--------- POP BUMPER OBJECTS
---------


-- POP BUMPERS

function new_pb(x, y)
  return {["t"] = "pb", ["x"] = x, ["y"] = y, ["w"] = 16, ["h"] = 16, ["bs"] = 1, ["on"] = false}
end

function draw_pb(pb)
  spr((pb.on and 23 or 21), pb.x, pb.y, pb.w / 8, pb.h / 8)
end
