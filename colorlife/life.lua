
function new_colony(w, h)
  -- initialize a colony of life cells of a maximum width and height
  colony = {}
  colony.w = w
  colony.h = h
  colony.cells = {}
  return colony
end

function randomize(colony)
  -- initialize a block of cells with random values
  cells = {}
  for x = 1, colony.w do
    cells[x] = {}
    for y = 1, colony.h do
      cells[x][y] = flr(rnd(16))
    end
  end
  colony.cells = cells
end

function compute(colony, x, y, mask)
  --[[ In the given colony cell(x,y), get neighbors count those impacted by the mask ]]
  sum = 0
  for r = x-1, x+1  do
    for c = y-1, y+1   do
      color = 0
      if colony.cells[r] and colony.cells[r][c] then
        color = colony.cells[r][c]
      end
      sum = sum + min(color & mask, 1)
      if sum > 3 then return 0 end
    end
  end
  if sum < 2 then return 0 end
  if sum == 3 then return mask end
  return colony.cells[x][y] & mask
end

function render(colony)
  --[[ render cells centered in the window, colored based on their 0-15 value ]]
  cls()
  for x = 1, colony.w do
    for y = 1, colony.h do
      pset(128 / 2 - colony.w / 2 + x, 128 / 2 - colony.h / 2 + y, colony.cells[x][y])
    end
  end
end

function step(colony)
  -- advance the cells one generation per Conway's rules
  next = {}
  for x = 1, colony.w do
    next[x] = {}
    for y = 1, colony.h do
      next[x][y] = compute(colony,x,y,8) + compute(colony,x,y,4) + compute(colony,x,y,2) + compute(colony,x,y,1)
    end
  end
  colony.cells = next
end
