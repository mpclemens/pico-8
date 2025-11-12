
function new_colony(w, h, min, birth, max_w, max_h)
  -- initialize a colony of life cells of a maximum width and height
  colony = {}
  colony.w = w
  colony.max_w = max_w
  colony.max_h = max_h
  colony.h = h
  colony.cells = {}
  colony.minimum = min
  colony.birth = birth
  return colony
end

function randomize(colony)
  -- initialize a block of cells with random values
  cells = {}
  for x = 1, colony.w do
    cells[x] = {}
    for y = 1, colony.h do
      cells[x][y] = max(0, flr(rnd(32)-16))
    end
  end
  colony.cells = cells
end

function compute(colony, x, y)
  --[[ In the given colony cell(x,y), return a new cell color, where 0 == off/dead ]]
  local colors = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  local sum = 0
  for r = x-1, x+1 do
    for c = y-1, y+1 do
      if not (r == x and c == y) and colony.cells[r] and colony.cells[r][c] then
        if colony.cells[r][c] > 0 then
          sum = sum + 1
          if sum > colony.birth then return 0 end
          colors[colony.cells[r][c]] += 1
        end
      end
    end
  end
  if sum < colony.minimum then return 0 end
  return max(colony.cells[x][y], flr(rnd(15))+1)
end

function render(colony)
  --[[ render cells centered in the window, colored based on their 0-15 value ]]
  cls()
  for x = 1, colony.w do
    for y = 1, colony.h do
      pset(colony.max_w / 2 - colony.w / 2 + x, colony.max_h / 2 - colony.h / 2 + y, colony.cells[x][y])
    end
  end
end

function step(colony)
  -- advance the cells one generation
  next = {}
  for x = 1, colony.w do
    next[x] = {}
    for y = 1, colony.h do
      next[x][y] = compute(colony,x,y)
    end
  end
  colony.cells = next
end
