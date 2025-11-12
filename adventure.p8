pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
-- adventure: atari 2600 port
-- by pico-8 adventure team

-- game constants
local game_state = {
  title = 0,
  playing = 1,
  game_over = 2,
  win = 3
}

local difficulty = {
  level1 = 1,  -- original level 1
  level2 = 2,  -- original level 2
  level3 = 3   -- original level 3
}

-- sound effect constants
local sfx_ids = {
  move = 0,
  pickup = 1,
  drop = 2,
  sword = 3,
  dragon_death = 4,
  player_death = 5,
  gate_open = 6,
  bat_steal = 7,
  bridge_place = 8,
  menu_select = 9,
  menu_change = 10,
  room_transition = 11,
  dragon_roar = 12,
  bat_wings = 13,
  victory = 14,
  easter_egg = 15
}

-- music constants
local music_ids = {
  title = 0,
  castle = 1,
  maze = 2,
  catacombs = 3,
  dragon_near = 4,
  victory = 5,
  game_over = 6
}

-- global variables
local current_state = game_state.title
local current_difficulty = difficulty.level1
local player = {}
local dragons = {}
local bat = {}
local items = {}
local current_room = 1

-- initialization
function _init()
  init_title_screen()
end

function init_title_screen()
  current_state = game_state.title
  music(music_ids.title)
end

function init_game(diff)
  current_state = game_state.playing
  current_difficulty = diff
  init_player()
  init_dragons()
  init_bat()
  init_items()
  init_map()
end

function init_player()
  player = {
    x = 64,
    y = 64,
    sprite = 0,
    base_sprite = 0,
    anim_frame = 0,
    anim_timer = 0,
    anim_speed = 8,
    speed = 1,
    direction = {x=0, y=0},
    facing = "down",
    has_item = nil,
    alive = true,
    size = 6  -- collision size (radius)
  }
end

function init_dragons()
  -- yorgle (yellow)
  dragons[1] = {
    x = 32,
    y = 32,
    room = 2,  -- Main maze
    sprite = 16,
    base_sprite = 16,
    anim_frame = 0,
    anim_timer = 0,
    anim_speed = 10,
    color = 10,  -- yellow
    speed = 0.5,
    direction = {x=0, y=0},
    state = "roam",
    fear_sword = true,
    fear_target = nil,
    alive = true,
    size = 6,  -- collision size (radius)
    hunt_chance = 70,  -- % chance to hunt when player is near
    hunt_range = 48    -- distance to detect player
  }

  -- grundle (green)
  dragons[2] = {
    x = 96,
    y = 32,
    room = 3,  -- Black castle
    sprite = 16,
    base_sprite = 16,
    anim_frame = 0,
    anim_timer = 0,
    anim_speed = 10,
    color = 11,  -- green
    speed = 0.5,
    direction = {x=0, y=0},
    state = "roam",
    fear_sword = true,
    fear_target = nil,
    alive = true,
    size = 6,
    hunt_chance = 85,
    hunt_range = 64
  }

  -- rhindle (red)
  dragons[3] = {
    x = 96,
    y = 96,
    room = 4,  -- White castle
    sprite = 16,
    base_sprite = 16,
    anim_frame = 0,
    anim_timer = 0,
    anim_speed = 8,  -- faster animation
    color = 8,  -- red
    speed = 0.75,
    direction = {x=1, y=0},  -- start moving right
    state = "hunt",
    fear_sword = false,  -- doesn't fear sword as much
    fear_target = nil,
    alive = true,
    size = 6,
    hunt_chance = 95,
    hunt_range = 80
  }
end

function init_bat()
  bat = {
    x = 48,
    y = 48,
    room = 2,  -- Main maze
    sprite = 32,
    base_sprite = 32,
    anim_frame = 0,
    anim_timer = 0,
    anim_speed = 4,  -- fast animation
    speed = 1.5,
    direction = {x=0, y=0},
    has_item = nil,
    state = "roam",
    steal_chance = 10,  -- % chance to steal per frame when close
    steal_range = 16,   -- distance to attempt stealing
    size = 6,           -- collision size (radius)
    teleport_chance = 0.5  -- % chance to teleport per frame
  }
end

function init_items()
  -- yellow key
  items[1] = {
    name = "yellow_key",
    x = 24,
    y = 100,
    sprite = 48,
    room = 1,
    carried = false
  }

  -- black key
  items[2] = {
    name = "black_key",
    x = 100,
    y = 24,
    sprite = 49,
    room = 5,
    carried = false
  }

  -- white key
  items[3] = {
    name = "white_key",
    x = 64,
    y = 64,
    sprite = 50,
    room = 9,
    carried = false
  }

  -- sword
  items[4] = {
    name = "sword",
    x = 48,
    y = 48,
    sprite = 51,
    room = 3,
    carried = false
  }

  -- bridge
  items[5] = {
    name = "bridge",
    x = 80,
    y = 80,
    sprite = 52,
    room = 7,
    carried = false,
    placed = false,
    placed_x = 0,
    placed_y = 0,
    placed_room = 0
  }

  -- chalice
  items[6] = {
    name = "chalice",
    x = 64,
    y = 64,
    sprite = 53,
    room = 15,
    carried = false
  }

  -- magnet
  items[7] = {
    name = "magnet",
    x = 32,
    y = 96,
    sprite = 54,
    room = 10,
    carried = false
  }
end

function init_map()
  -- Define room data structure
  rooms = {
    [1] = {
      name = "gold_castle",
      map_x = 0,   -- x position in the map (in tiles)
      map_y = 0,   -- y position in the map (in tiles)
      connections = {left = 2, right = 3, up = nil, down = 4},
      type = "castle",
      scheme = "gold_castle",
      music = music_ids.castle
    },
    [2] = {
      name = "main_maze",
      map_x = 0,   -- x position in the map (in tiles)
      map_y = 16,  -- y position in the map (in tiles)
      connections = {left = nil, right = 1, up = nil, down = nil},
      type = "maze",
      scheme = "main_maze",
      music = music_ids.maze
    },
    [3] = {
      name = "black_castle",
      map_x = 0,   -- x position in the map (in tiles)
      map_y = 32,  -- y position in the map (in tiles)
      connections = {left = 1, right = nil, up = nil, down = nil},
      type = "castle",
      scheme = "black_castle",
      music = music_ids.catacombs
    },
    [4] = {
      name = "white_castle",
      map_x = 0,   -- x position in the map (in tiles)
      map_y = 48,  -- y position in the map (in tiles)
      connections = {left = nil, right = nil, up = 1, down = nil},
      type = "castle",
      scheme = "white_castle",
      music = music_ids.castle
    }
  }

  -- Set starting room
  current_room = 1

  -- Initialize visible objects for current room
  update_room_objects()
end

-- update functions
function _update()
  if current_state == game_state.title then
    update_title()
  elseif current_state == game_state.playing then
    update_game()
  elseif current_state == game_state.game_over then
    update_game_over()
  elseif current_state == game_state.win then
    update_win()
  end
end

function update_title()
  -- handle title screen input
  if btnp(4) then  -- o/z button
    sfx(sfx_ids.menu_select)
    init_game(current_difficulty)
  end

  -- cycle through difficulties with up/down
  if btnp(2) then  -- up
    current_difficulty = max(1, current_difficulty - 1)
    sfx(sfx_ids.menu_change)
  elseif btnp(3) then  -- down
    current_difficulty = min(3, current_difficulty + 1)
    sfx(sfx_ids.menu_change)
  end
end

-- Function to update ambient sounds
function update_ambient_sounds()
  -- Bat wing sound when bat is in room
  if bat.room == current_room then
    -- Play bat sound occasionally
    if rnd(100) < 2 then
      sfx(sfx_ids.bat_wings, 3)  -- Use channel 3 for ambient
    end
  end

  -- Dragon roar when hunting
  for i=1,#dragons do
    local dragon = dragons[i]
    if dragon.room == current_room and dragon.state == "hunt" then
      if rnd(100) < 1 then
        sfx(sfx_ids.dragon_roar, 2)  -- Use channel 2 for dragons
      end
    end
  end
end

function update_game()
  update_player()
  update_dragons()
  update_bat()
  check_collisions()
  check_win_condition()
  update_ambient_sounds()
end

function update_player()
  -- Player movement
  local dx, dy = 0, 0

  -- Get input
  if btn(0) then dx -= player.speed end  -- left
  if btn(1) then dx += player.speed end  -- right
  if btn(2) then dy -= player.speed end  -- up
  if btn(3) then dy += player.speed end  -- down

  -- Store direction for animation
  if dx != 0 or dy != 0 then
    player.direction.x = dx
    player.direction.y = dy

    -- Set facing direction based on dominant direction
    if abs(dx) > abs(dy) then
      player.facing = dx > 0 and "right" or "left"
    else
      player.facing = dy > 0 and "down" or "up"
    end
  end

  -- Normalize diagonal movement
  if dx != 0 and dy != 0 then
    dx *= 0.7071  -- 1/sqrt(2)
    dy *= 0.7071
  end

  -- Try to move with sliding along walls
  local moved = false

  -- Try full movement first
  if not check_wall_collision(player.x + dx, player.y + dy) then
    player.x += dx
    player.y += dy
    moved = true
  else
    -- Try horizontal movement only
    if dx != 0 and not check_wall_collision(player.x + dx, player.y) then
      player.x += dx
      moved = true
    end

    -- Try vertical movement only
    if dy != 0 and not check_wall_collision(player.x, player.y + dy) then
      player.y += dy
      moved = true
    end
  end

  -- Update animation if moving
  if moved then
    animate_player()

    -- Play movement sound occasionally
    if rnd(100) < 10 then  -- 10% chance per frame when moving
      sfx(sfx_ids.move, 0, 0, 1)  -- Play at low volume (1/8)
    end
  else
    -- Reset to base sprite when not moving
    player.sprite = player.base_sprite
  end

  -- Item pickup/drop with button
  if btnp(4) then  -- o/z button
    if player.has_item then
      drop_item()
    else
      pickup_item()
    end
  end

  -- Use sword with button
  if btnp(5) and player.has_item and player.has_item.name == "sword" then  -- x button
    use_sword()
  end

  -- Screen transitions
  check_screen_transition()
end

function animate_player()
  player.anim_timer += 1
  if player.anim_timer > player.anim_speed then
    player.anim_timer = 0
    player.anim_frame = (player.anim_frame + 1) % 2
    player.sprite = player.base_sprite + player.anim_frame
  end
end

function update_dragons()
  for i=1,#dragons do
    local d = dragons[i]
    if d.alive and d.room == current_room then
      -- Update dragon state based on conditions
      update_dragon_state(d)

      -- Move based on current state
      if d.state == "hunt" then
        move_towards_target(d, player)
      elseif d.state == "flee" then
        move_away_from_target(d, d.fear_target)
      elseif d.state == "roam" then
        roam_movement(d)
      end

      -- Update animation
      animate_dragon(d)
    end
  end
end

function update_dragon_state(dragon)
  -- Check for sword proximity
  if player.has_item and player.has_item.name == "sword" and dragon.fear_sword then
    local dist = distance(dragon.x, dragon.y, player.x, player.y)
    if dist < 32 then
      dragon.state = "flee"
      dragon.fear_target = player
      return
    end
  end

  -- Check for player proximity
  local dist = distance(dragon.x, dragon.y, player.x, player.y)

  -- Dragon-specific behavior
  if dragon.color == 10 then  -- Yorgle (yellow)
    -- Afraid of gold key
    if player.has_item and player.has_item.name == "yellow_key" then
      if dist < 32 then
        dragon.state = "flee"
        dragon.fear_target = player
        return
      end
    end

    -- 70% chance to hunt player if close
    if dist < dragon.hunt_range and rnd(100) < dragon.hunt_chance then
      dragon.state = "hunt"
    else
      dragon.state = "roam"
    end

  elseif dragon.color == 11 then  -- Grundle (green)
    -- 85% chance to hunt player if seen
    if dist < dragon.hunt_range and rnd(100) < dragon.hunt_chance then
      dragon.state = "hunt"
    else
      dragon.state = "roam"
    end

  elseif dragon.color == 8 then  -- Rhindle (red)
    -- 95% chance to hunt player if in same room
    if rnd(100) < dragon.hunt_chance then
      dragon.state = "hunt"
    else
      dragon.state = "roam"
    end
  end
end

function move_towards_target(entity, target)
  -- Calculate direction vector
  local dx = target.x - entity.x
  local dy = target.y - entity.y

  -- Normalize
  local dist = sqrt(dx*dx + dy*dy)
  if dist > 0 then
    dx = dx / dist
    dy = dy / dist
  end

  -- Apply movement with collision check
  local new_x = entity.x + dx * entity.speed
  local new_y = entity.y + dy * entity.speed

  if not check_wall_collision(new_x, new_y) then
    entity.x = new_x
    entity.y = new_y
    entity.direction = {x=dx, y=dy}
  else
    -- Try to slide along walls
    if not check_wall_collision(entity.x + dx * entity.speed, entity.y) then
      entity.x += dx * entity.speed
      entity.direction = {x=dx, y=0}
    elseif not check_wall_collision(entity.x, entity.y + dy * entity.speed) then
      entity.y += dy * entity.speed
      entity.direction = {x=0, y=dy}
    else
      -- Change direction if stuck
      entity.direction = {
        x = rnd(2) - 1,
        y = rnd(2) - 1
      }
    end
  end
end

function move_away_from_target(entity, target)
  -- Calculate direction vector away from target
  local dx = entity.x - target.x
  local dy = entity.y - target.y

  -- Normalize
  local dist = sqrt(dx*dx + dy*dy)
  if dist > 0 then
    dx = dx / dist
    dy = dy / dist
  end

  -- Apply movement with collision check
  local new_x = entity.x + dx * entity.speed
  local new_y = entity.y + dy * entity.speed

  if not check_wall_collision(new_x, new_y) then
    entity.x = new_x
    entity.y = new_y
    entity.direction = {x=dx, y=dy}
  else
    -- Try to slide along walls
    if not check_wall_collision(entity.x + dx * entity.speed, entity.y) then
      entity.x += dx * entity.speed
      entity.direction = {x=dx, y=0}
    elseif not check_wall_collision(entity.x, entity.y + dy * entity.speed) then
      entity.y += dy * entity.speed
      entity.direction = {x=0, y=dy}
    else
      -- Change direction if stuck
      entity.direction = {
        x = rnd(2) - 1,
        y = rnd(2) - 1
      }
    end
  end
end

function roam_movement(entity)
  -- Change direction occasionally
  if rnd(100) < 5 then
    entity.direction = {
      x = rnd(2) - 1,
      y = rnd(2) - 1
    }
  end

  -- Apply movement with collision check
  local new_x = entity.x + entity.direction.x * entity.speed
  local new_y = entity.y + entity.direction.y * entity.speed

  -- Check for wall collisions
  if not check_wall_collision(new_x, new_y) then
    entity.x = new_x
    entity.y = new_y
  else
    -- Bounce off walls by reversing direction
    entity.direction.x *= -1
    entity.direction.y *= -1
  end

  -- Keep within room bounds
  if entity.x < 4 then
    entity.x = 4
    entity.direction.x *= -1
  end
  if entity.x > 123 then
    entity.x = 123
    entity.direction.x *= -1
  end
  if entity.y < 4 then
    entity.y = 4
    entity.direction.y *= -1
  end
  if entity.y > 123 then
    entity.y = 123
    entity.direction.y *= -1
  end
end

function animate_dragon(dragon)
  dragon.anim_timer += 1
  if dragon.anim_timer > dragon.anim_speed then
    dragon.anim_timer = 0
    dragon.anim_frame = (dragon.anim_frame + 1) % 2
    dragon.sprite = dragon.base_sprite + dragon.anim_frame
  end
end

function update_bat()
  if bat.room == current_room then
    -- Erratic movement
    bat_movement()

    -- Item stealing/swapping logic
    update_bat_item_interaction()

    -- Animation
    animate_bat()
  end
end

function bat_movement()
  -- Change direction frequently
  if rnd(100) < 15 then
    bat.direction = {
      x = rnd(2) - 1,
      y = rnd(2) - 1
    }
  end

  -- Apply movement
  local new_x = bat.x + bat.direction.x * bat.speed
  local new_y = bat.y + bat.direction.y * bat.speed

  -- Bats can fly over walls but stay in room bounds
  bat.x = mid(4, new_x, 123)
  bat.y = mid(4, new_y, 123)

  -- Occasionally teleport to a random location
  if rnd(1000) < bat.teleport_chance * 10 then
    bat.x = 4 + rnd(119)
    bat.y = 4 + rnd(119)
  end
end

function update_bat_item_interaction()
  -- Check for nearby items to steal
  if not bat.has_item then
    -- Try to steal from player
    if player.has_item and distance(bat.x, bat.y, player.x, player.y) < bat.steal_range then
      if rnd(100) < bat.steal_chance then  -- chance to steal per frame when close
        bat.has_item = player.has_item
        player.has_item = nil
        -- play steal sound
        sfx(sfx_ids.bat_steal)
      end
    end

    -- Try to pick up items on ground
    for i=1,#items do
      local item = items[i]
      if item.room == current_room and not item.carried then
        if distance(bat.x, bat.y, item.x, item.y) < bat.steal_range then
          if rnd(100) < bat.steal_chance * 2 then  -- higher chance for ground items
            bat.has_item = item
            item.carried = true
            -- play steal sound
            sfx(sfx_ids.bat_steal)
          end
        end
      end
    end
  else
    -- Occasionally drop carried item
    if rnd(500) < 3 then  -- 0.6% chance per frame
      local item = bat.has_item
      item.x = bat.x
      item.y = bat.y
      item.room = current_room
      item.carried = false
      bat.has_item = nil
      -- play drop sound
      sfx(sfx_ids.drop)
    end
  end
end

function animate_bat()
  bat.anim_timer += 1
  if bat.anim_timer > bat.anim_speed then
    bat.anim_timer = 0
    bat.anim_frame = (bat.anim_frame + 1) % 2
    bat.sprite = bat.base_sprite + bat.anim_frame
  end
end

function check_collisions()
  -- Check collisions with items
  for i=1,#items do
    local item = items[i]
    if item.room == current_room and not item.carried then
      local dist = distance(player.x, player.y, item.x, item.y)
      if dist < 10 then
        -- Player is touching an item (pickup handled by button press)
        -- Visual feedback could be added here
      end
    end
  end

  -- Check collisions with dragons
  for i=1,#dragons do
    local d = dragons[i]
    if d.alive and d.room == current_room then
      local dist = distance(player.x, player.y, d.x, d.y)
      if dist < 8 then
        -- Player touched dragon
        if player.has_item and player.has_item.name == "sword" then
          -- Dragon dies
          kill_dragon(d)
        else
          -- Player dies
          kill_player()
        end
      end
    end
  end

  -- Check for dragon-sword collisions (when sword is dropped)
  for i=1,#items do
    local item = items[i]
    if item.room == current_room and not item.carried and item.name == "sword" then
      for j=1,#dragons do
        local dragon = dragons[j]
        if dragon.room == current_room and dragon.alive then
          if distance(dragon.x, dragon.y, item.x, item.y) < 8 then
            -- Dragon touched sword
            kill_dragon(dragon)
          end
        end
      end
    end
  end
end

function kill_dragon(dragon)
  dragon.alive = false
  dragon.state = "dead"

  -- Start death animation
  dragon.death_timer = 30  -- 30 frames for death animation

  -- Play death sound
  sfx(sfx_ids.dragon_death)

  -- Visual effect - screen flash
  for i=1,4 do
    -- Flash white
    if i % 2 == 0 then
      for c=0,15 do pal(c, 7) end
    else
      pal()  -- Reset
    end

    -- Draw frame
    flip()
  end

  -- Reset palette
  pal()

  -- Drop carried item if any
  if dragon.has_item then
    local item = dragon.has_item
    item.x = dragon.x
    item.y = dragon.y
    item.room = dragon.room
    item.carried = false
    dragon.has_item = nil
  end
end

function kill_player()
  player.alive = false
  current_state = game_state.game_over

  -- Play death sound
  sfx(sfx_ids.player_death)

  -- Drop carried item if any
  if player.has_item then
    drop_item()
  end
end

function check_win_condition()
  -- Check if player has chalice and is in Gold Castle
  if player.has_item and player.has_item.name == "chalice" then
    -- Check if in Gold Castle (room 1)
    if current_room == 1 then
      -- Win!
      current_state = game_state.win

      -- Play victory sound
      sfx(sfx_ids.victory)
      music(music_ids.victory)

      return true
    end
  end

  return false
end

function update_game_over()
  -- handle game over screen input
  if btnp(4) then  -- o/z button
    sfx(sfx_ids.menu_select)
    init_title_screen()
  end
end

function update_win()
  -- handle win screen input
  if btnp(4) then  -- o/z button
    sfx(sfx_ids.menu_select)
    init_title_screen()
  end
end

-- helper functions
function distance(x1, y1, x2, y2)
  return sqrt((x2-x1)^2 + (y2-y1)^2)
end

function check_wall_collision(x, y)
  -- Check boundaries
  if x < 0 or x > 127 or y < 0 or y > 127 then
    return true
  end

  -- Check multiple points around the player for better collision
  local points = {
    {x = x, y = y},                     -- center
    {x = x - player.size, y = y},       -- left
    {x = x + player.size, y = y},       -- right
    {x = x, y = y - player.size},       -- top
    {x = x, y = y + player.size}        -- bottom
  }

  -- Get the map offset for the current room
  local map_x = rooms[current_room].map_x
  local map_y = rooms[current_room].map_y

  -- Check each point
  for i=1,#points do
    local p = points[i]

    -- Convert pixel position to tile position
    local tile_x = flr(p.x / 8)
    local tile_y = flr(p.y / 8)

    -- Make sure we're within map bounds
    if tile_x >= 0 and tile_x < 16 and tile_y >= 0 and tile_y < 16 then
      -- Get the tile at this position
      local tile = mget(map_x + tile_x, map_y + tile_y)

      -- Check if this tile is solid (flag 0)
      if fget(tile, 0) then
        return true
      end
    end
  end

  return false
end

function check_screen_transition()
  -- Check if player is at screen edge
  local new_room = nil

  if player.x < 4 then
    -- Try to move to room to the left
    new_room = rooms[current_room].connections.left
    if new_room then
      current_room = new_room
      player.x = 123  -- Place at right edge of new room
    else
      player.x = 4  -- Stop at edge
    end
  elseif player.x > 123 then
    -- Try to move to room to the right
    new_room = rooms[current_room].connections.right
    if new_room then
      current_room = new_room
      player.x = 4  -- Place at left edge of new room
    else
      player.x = 123  -- Stop at edge
    end
  elseif player.y < 4 then
    -- Try to move to room above
    new_room = rooms[current_room].connections.up
    if new_room then
      current_room = new_room
      player.y = 123  -- Place at bottom edge of new room
    else
      player.y = 4  -- Stop at edge
    end
  elseif player.y > 123 then
    -- Try to move to room below
    new_room = rooms[current_room].connections.down
    if new_room then
      current_room = new_room
      player.y = 4  -- Place at top edge of new room
    else
      player.y = 123  -- Stop at edge
    end
  end

  -- If room changed, update visible objects
  if new_room then
    -- Play room transition sound
    sfx(sfx_ids.room_transition)

    -- Update visible objects
    update_room_objects()

    -- Play room-appropriate music
    if rooms[current_room].music then
      music(rooms[current_room].music)
    end
  end
end

function pickup_item()
  -- Check for nearby items to pick up
  for i=1,#items do
    local item = items[i]
    if item.room == current_room and not item.carried then
      local dist = distance(player.x, player.y, item.x, item.y)
      if dist < 10 then
        player.has_item = item
        item.carried = true

        -- Play pickup sound
        sfx(sfx_ids.pickup)

        -- Visual feedback
        -- item_pickup_effect()  -- Could be implemented later

        return
      end
    end
  end
end

function drop_item()
  if player.has_item then
    local item = player.has_item

    -- Special handling for bridge placement
    if item.name == "bridge" then
      if try_place_bridge() then
        return  -- Bridge was placed successfully
      end
    end

    -- Normal item drop
    item.x = player.x
    item.y = player.y
    item.room = current_room
    item.carried = false
    player.has_item = nil

    -- Play drop sound
    sfx(sfx_ids.drop)
  end
end

function try_place_bridge()
  -- Check if player is carrying bridge
  if player.has_item and player.has_item.name == "bridge" then
    local bridge = player.has_item

    -- Calculate placement position based on player facing
    local place_x = player.x
    local place_y = player.y

    if player.facing == "right" then
      place_x += 8
    elseif player.facing == "left" then
      place_x -= 8
    elseif player.facing == "up" then
      place_y -= 8
    elseif player.facing == "down" then
      place_y += 8
    end

    -- Check if placement location is valid (water/lava)
    local tile_x = flr(place_x / 8)
    local tile_y = flr(place_y / 8)

    -- Get the map offset for the current room
    local map_x = rooms[current_room].map_x
    local map_y = rooms[current_room].map_y

    -- Get the tile at this position
    local tile = mget(map_x + tile_x, map_y + tile_y)

    -- Check if this tile is water (flag 4)
    if fget(tile, 4) then
      -- Place bridge
      bridge.placed = true
      bridge.placed_x = place_x
      bridge.placed_y = place_y
      bridge.placed_room = current_room

      -- Update map tile to bridge tile
      mset(map_x + tile_x, map_y + tile_y, 52)  -- Bridge sprite

      -- Drop from inventory
      player.has_item = nil
      bridge.carried = false

      -- Play bridge placement sound
      sfx(sfx_ids.bridge_place)

      return true
    end
  end

  return false
end

function use_sword()
  -- Check if player has sword
  if player.has_item and player.has_item.name == "sword" then
    -- Set sword attack state
    player.attacking = true
    player.attack_timer = 10  -- Attack lasts 10 frames

    -- Play sword sound
    sfx(sfx_ids.sword)

    -- Check for dragons in attack range
    for i=1,#dragons do
      local dragon = dragons[i]
      if dragon.room == current_room and dragon.alive then
        -- Calculate attack area based on player direction
        local attack_x = player.x
        local attack_y = player.y
        local attack_range = 12

        if player.facing == "right" then
          attack_x += attack_range
        elseif player.facing == "left" then
          attack_x -= attack_range
        elseif player.facing == "up" then
          attack_y -= attack_range
        elseif player.facing == "down" then
          attack_y += attack_range
        end

        -- Check if dragon is in attack range
        if distance(attack_x, attack_y, dragon.x, dragon.y) < attack_range then
          kill_dragon(dragon)
        end
      end
    end

    return true
  end

  return false
end

-- draw functions
function _draw()
  cls()

  if current_state == game_state.title then
    draw_title()
  elseif current_state == game_state.playing then
    draw_game()
  elseif current_state == game_state.game_over then
    draw_game_over()
  elseif current_state == game_state.win then
    draw_win()
  end
end

function draw_title()
  -- draw title screen
  print("adventure", 44, 40, 7)
  print("atari 2600 port", 32, 50, 6)

  -- draw difficulty selection
  print("select difficulty:", 28, 70, 7)
  for i=1,3 do
    local color = (i == current_difficulty) and 10 or 5
    print("level " .. i, 52, 70 + i*10, color)
  end

  print("press \142 to start", 30, 110, 7)
end

function draw_game()
  -- draw map
  draw_room()

  -- draw items
  for i=1,#items do
    local item = items[i]
    if item.room == current_room and not item.carried then
      spr(item.sprite, item.x-4, item.y-4)
    end
  end

  -- draw dragons
  for i=1,#dragons do
    local d = dragons[i]
    if d.alive and d.room == current_room then
      pal(7, d.color)
      spr(d.sprite, d.x-4, d.y-4)
      pal()
    end
  end

  -- draw bat
  if bat.room == current_room then
    spr(bat.sprite, bat.x-4, bat.y-4)
    -- draw bat's carried item if any
    if bat.has_item then
      spr(bat.has_item.sprite, bat.x, bat.y-8)
    end
  end

  -- draw player
  spr(player.sprite, player.x-4, player.y-4)

  -- draw player's carried item if any
  if player.has_item then
    spr(player.has_item.sprite, player.x, player.y-8)
  end
end

function draw_room()
  -- Get the map offset for the current room
  local map_x = rooms[current_room].map_x
  local map_y = rooms[current_room].map_y

  -- Draw the map for the current room
  map(map_x, map_y, 0, 0, 16, 16)

  -- Apply color scheme for current room
  apply_room_palette()
end

function apply_room_palette()
  -- Color scheme definitions
  local color_schemes = {
    gold_castle = {
      wall = 10,      -- Yellow
      floor = 4,      -- Brown
      accent = 7,     -- White
      background = 4  -- Brown
    },
    black_castle = {
      wall = 1,       -- Dark Blue
      floor = 0,      -- Black
      accent = 12,    -- Light Blue
      background = 0  -- Black
    },
    white_castle = {
      wall = 7,       -- White
      floor = 6,      -- Light Gray
      accent = 12,    -- Light Blue
      background = 6  -- Light Gray
    },
    main_maze = {
      wall = 11,      -- Green
      floor = 3,      -- Dark Green
      accent = 10,    -- Yellow
      background = 3  -- Dark Green
    }
  }

  -- Get the scheme for the current room
  local scheme = color_schemes[rooms[current_room].scheme]

  -- Apply background color
  -- (This would normally be done with cls() but we're drawing the map first)

  -- Any specific color remapping could be done here
  -- For example:
  -- pal(5, scheme.wall)  -- Remap color 5 to wall color
end

function update_room_objects()
  -- Update which objects are visible in the current room

  -- Reset visible objects
  visible_items = {}
  visible_dragons = {}

  -- Add objects from current room
  for i=1,#items do
    if items[i].room == current_room then
      add(visible_items, items[i])
    end
  end

  for i=1,#dragons do
    if dragons[i].room == current_room and dragons[i].alive then
      add(visible_dragons, dragons[i])
    end
  end

  -- Check if bat is in this room
  bat_visible = (bat.room == current_room)
end

function draw_game_over()
  -- draw game over screen
  print("game over", 46, 60, 8)
  print("press \142 to continue", 24, 80, 7)
end

function draw_win()
  -- draw win screen
  print("you win!", 48, 50, 11)
  print("you have returned", 30, 70, 7)
  print("the chalice!", 40, 80, 7)
  print("press \142 to continue", 24, 100, 7)
end

__gfx__
-- Set sprite flags
-- Flag 0: Solid (for collision detection)
-- Flag 1: Collectible
-- Flag 2: Dangerous
-- Flag 3: Door/Gate
-- Flag 4: Water (requires bridge)
-- Flag 5: Special interaction
-- player sprites (0-3)
00000000003bb30000377300003bb30000377300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000037bb73003777730037bb73003777730000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000003bbbbbb33777777337bbb7333777773300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000003bbbbbb33777777337bbb7333777773300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000003bbbbbb33777777337bbb7333777773300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000003bbbbbb33777777337bbb7333777773300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000037bb73003777730037bb73003777730000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000003bb30000377300003bb30000377300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- dragon sprites (16-31)
00000000000aa000000aa000000aa000000aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaa0000aaaa0000aaaa0000aaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaa00aaaaaa00aaaaaa00aaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aa0aa0aaaa0000aaaa0aa0aaaa0000aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000a000000aa000000aa000000aa000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000a000000aa000000aa000000aa000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- bat sprites (32-39)
00000000a000000aa000000aa000000aa000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aa0000aaaa0000aaaa0000aaaa0000aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaa0000aaaa0000aaaa0000aaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000a0000a00a0000a00a0000a00a0000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000a000000aa000000aa000000aa000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- item sprites (48-63)
0000000000088000000880000008800000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000088000000880000008800000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000088000000880000008800000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000088000000880000008800000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000088800000888000008880000088800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000888880008888800088888000888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000888880008888800088888000888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000088800000888000008880000088800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- sword sprite (51)
0000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- bridge sprite (52)
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- chalice sprite (53)
0000000000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000088800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000008888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- magnet sprite (54)
0000000088000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000088000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- gate sprites (64-67)
0000000080808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000080808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000080808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000080808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
-- Gold Castle (Room 1)
5050505050505050505050505050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5000000000000000004000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5050505050505050505050505050505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- Main Maze (Room 2)
6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e00000000000000000000000000006e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e00006e6e6e6e6e6e6e6e6e6e00006e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e00006e0000000000000000006e006e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e00006e0000000000000000006e006e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e00006e0000000000000000006e006e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e00006e0000000000000000006e006e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e00006e0000000000000000006e006e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e00006e0000000000000000006e006e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e00006e0000000000000000006e006e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e00006e0000000000000000006e006e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e00006e0000000000000000006e006e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e00006e6e6e6e6e00006e6e6e6e006e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e00000000000000000000000000006e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e00000000000000000000000000006e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- Black Castle (Room 3)
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000004100000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- White Castle (Room 4)
0707070707070707070707070707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0700000000000000004200000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0707070707070707070707070707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
-- Player Movement (SFX 0)
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200001d0501c0501a05018050160501405012050100500e0500c0500a05008050060500405002050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- Item Pickup (SFX 1)
010200001f0502105023050250502705029050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- Item Drop (SFX 2)
01020000290502705025050230502105020050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- Sword Swing (SFX 3)
010300001f05021050230502505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000000001d0501b0501905017050150501305011050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- Dragon Death (SFX 4)
01040000290502b0502d0502f05030050320503305035050370503805000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01040000350003300031000300002e0002c0002a00028000260002400022000200001e0001c0001a000180001600014000120001000000000000000000000000000000000000000000000000000000000000000000
-- Player Death (SFX 5)
010400002e0502c0502a05028050260502405022050200501e0501c0501a05018050160501405012050100500e0500c0500a05008050060500405002050000500000000000000000000000000000000000000000000
-- Gate Open (SFX 6)
010200001a0501c0501e05020050220502405026050280502a0502c0502e05030050320503405036050380500000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- Bat Steal (SFX 7)
01020000240502605028050290502b0502d0502f050310503305035050370503905000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- Bridge Place (SFX 8)
010200001f0501d0501b050190501705015050130501105000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- Menu Select (SFX 9)
01020000240502605028050290502b0502d05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- Menu Change (SFX 10)
010200001f05021050230500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- Room Transition (SFX 11)
010300001f05021050230502505027050290502b0502d0502f05031050330503505037050390503b0503d0503f050000000000000000000000000000000000000000000000000000000000000000000000000000000
-- Dragon Roar (SFX 12)
010400002e0502c0502a05028050260502405022050200501e0501c0501a05018050160501405012050100500e0500c0500a05008050060500405002050000500000000000000000000000000000000000000000000
-- Bat Wings (SFX 13)
010200001f0502105023050250502705029050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- Victory (SFX 14)
010400002e0502c0502a05028050260502405022050200501e0501c0501a05018050160501405012050100500e0500c0500a05008050060500405002050000500000000000000000000000000000000000000000000
-- Easter Egg (SFX 15)
010200001f05021050230502505027050290502b0502d0502f05031050330503505037050390503b0503d0503f050000000000000000000000000000000000000000000000000000000000000000000000000000000

__music__
-- Title Theme (Music 0)
00 01020304
00 01020304
00 05060708
00 05060708

-- Castle Theme (Music 1)
01 09080a0b
01 09080a0b
01 0c0d0e0f
01 0c0d0e0f

-- Maze Theme (Music 2)
02 10111213
02 10111213
02 14151617
02 14151617

-- Catacombs Theme (Music 3)
03 18191a1b
03 18191a1b
03 1c1d1e1f
03 1c1d1e1f

-- Dragon Near (Music 4)
04 20212223
04 20212223
04 24252627
04 24252627

-- Victory Theme (Music 5)
05 28292a2b
05 28292a2b
05 2c2d2e2f
05 2c2d2e2f

-- Game Over (Music 6)
06 30313233
06 30313233
06 34353637
06 34353637
