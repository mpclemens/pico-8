
-- cells are colored by their age
colors = {7, 12, 10, 9, 8, 14, 2, 1}

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
      if flr(rnd(3)) == 1 then
        cells[x][y] = 1 -- newborn, generation 1
      end
    end
  end
  colony.cells = cells
end

function render(colony)
  --[[ render cells centered in the window, such that cells with
  a value of zero are "live" and anything else is dead
  ]]
  cls()
  for x = 1, colony.w do
    for y = 1, colony.h do
      if colony.cells[x][y] then
        pset(128 / 2 - colony.w / 2 + x, 128 / 2 - colony.h / 2 + y, colors[min(#colors, colony.cells[x][y])])
      end
    end
  end
end

function step(colony)
  -- advance the cells one generation per Conway's rules
  next = {}
  for x = 1, colony.w do
    next[x] = {}
    for y = 1, colony.h do
      n = 0 -- neighbor count
      -- pick up the surrounding cells, but not the current one
      for nx = max(1, x - 1), min(x + 1, colony.w) do
        for ny = max(1, y - 1), min(y + 1, colony.h) do
          if not (nx == x and ny == y) and colony.cells[nx][ny] then
            n = n + 1
          end
        end
      end

      if n == 2 or n == 3 then
        if colony.cells[x][y] then
          next[x][y] = colony.cells[x][y] + 1
        elseif n == 3 then
          next[x][y] = 1
        end
      end
    end
  end
  colony.cells = next
end
