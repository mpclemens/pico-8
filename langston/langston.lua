function new_ant()
  -- x,y coords, and heading, where 0 == due east, neadings are counterclockwise
  return {["x"] = flr(rnd(130)) + 1, ["y"] = flr(rnd(130)) + 1, ["h"] = flr(rnd(8))}
end

function move_ant(a)
  --[[
At a white square, turn 90° right, flip the color of the square, move forward one unit
At a black square, turn 90° left, flip the color of the square, move forward one unit
]]
  if pget(a.x, a.y) == 7 then
    a.h = (a.h + 1) % 8
    pset(a.x, a.y, 0)
  else
    -- black or any other color changes to white
    a.h = (a.h - 1) % 8
    pset(a.x, a.y, 7)
  end
  step_ant(a)
end

function step_ant(a)
  if a.h == 0 or a.h == 1 or a.h == 7 then
    a.x = (a.x + 1) % 128
  elseif a.h == 3 or a.h == 4 or a.h == 5 then
    a.x = (a.x - 1) % 128
  end

  if a.h == 1 or a.h == 2 or a.h == 3 then
    a.y = (a.y - 1) % 128
  elseif a.h == 5 or a.h == 6 or a.h == 7 then
    a.y = (a.y + 1) % 128
  end
end
