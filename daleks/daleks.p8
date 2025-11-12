pico-8 cartridge // http://www.pico-8.com
version 35
__lua__
-- daleks for pico-8
-- a port of the classic mac game

__sfx__
00030000300003200034000360003800039000370003500033000310002f0002d0002b00029000270002500023000210001f0001d0001b00019000170001500013000110000f0000d0000b00009000070000500003000
000800001f0501d0501b05019050170501505013050110500f0500d0500b0500905007050050500305001050000500000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000707006070050700407003070020700107000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600000d5500c5500b5500a550095500855007550065500555004550035500255001550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000005000150030500505007050090500b0500d0500f05011050130501505017050190501b0501d0501f050000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001d6501c6501a65018650176501565013650116500f6500d6500b650096500765005650036500165000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__lua__
-- daleks for pico-8
-- a port of the classic mac game

-- sprite data for player and enemies
local sprite_data = {
  -- player sprite (human shape)
  player = {
    -- colors
    body_color = 12,  -- blue
    head_color = 15,  -- white
    detail_color = 7, -- light gray

    -- dimensions (relative to cell_size)
    width = 0.8,
    height = 0.8
  },

  -- enemy sprite (dalek - salt shaker with plunger)
  dalek = {
    -- colors
    body_color = 8,   -- dark red
    dome_color = 9,   -- orange
    plunger_color = 5, -- dark gray
    eye_color = 10,    -- yellow

    -- dimensions (relative to cell_size)
    width = 0.8,
    height = 0.8
  },

  -- junk pile
  junk = {
    -- colors
    base_color = 5,    -- dark gray
    flicker_color = 6, -- light gray
    line_color = 0     -- black
  }
}

-- sound effects
-- 0: sonic screwdriver - high pitched electronic sound
-- 1: teleport - warping sound
-- 2: dalek movement - mechanical movement sound
-- 3: dalek collision - explosion sound
-- 4: level complete - victory jingle
-- 5: game over - sad tone

-- stub sound data (in pico-8 format)
-- format: note, instrument, volume, effect
local sound_data = {
  -- 0: sonic screwdriver (high pitched electronic sound)
  {
    notes = {{48, 2, 8, 0}}, -- high C note with instrument 2
    speed = 8
  },

  -- 1: teleport (warping sound)
  {
    notes = {{36, 3, 8, 5}}, -- C note with pitch slide effect
    speed = 12
  },

  -- 2: dalek movement (mechanical movement sound)
  {
    notes = {{24, 6, 6, 0}}, -- low mechanical sound
    speed = 4
  },

  -- 3: dalek collision (explosion sound)
  {
    notes = {{20, 7, 8, 3}}, -- noise with fade out
    speed = 10
  },

  -- 4: level complete (victory jingle)
  {
    notes = {{60, 0, 8, 0}}, -- high note with instrument 0
    speed = 16
  },

  -- 5: game over (sad tone)
  {
    notes = {{18, 1, 7, 1}}, -- low note with fade
    speed = 6
  }
}

-- game constants
local grid_width = 16 -- 16 columns
local grid_height = 13 -- 13 rows (reduced from 14)
local cell_size = 8  -- 8 pixels per cell
local max_daleks = 20
local max_junk = 30  -- junk piles from destroyed daleks
local base_daleks = 5 -- starting number of daleks
local dalek_increase = 2 -- how many more daleks per level

-- game state
local player = {x=0, y=0}
local daleks = {}
local junk = {}
local game_over = false
local win = false
local level = 1
local score = 0
local teleports = 2
local screwdrivers = 1
local max_teleports = 5
local max_screwdrivers = 3
local game_state = "title" -- title, game, gameover
local high_score = 0 -- persistent high score

-- initialize the game
function _init()
  cartdata("daleks_save") -- enable persistent data
  high_score = dget(0) or 0 -- load high score
  init_sounds() -- initialize sound effects
  init_level()
end

-- initialize a new level
function init_level()
  -- place player in center
  player.x = flr(grid_width/2)
  player.y = flr(grid_height/2)

  -- clear and create daleks
  daleks = {}
  junk = {}
  game_over = false
  win = false

  -- reset teleports and screwdrivers at the start of each level
  teleports = 2
  screwdrivers = 1

  -- spawn daleks at random positions (not on player)
  local dalek_count = min(base_daleks + (level-1) * dalek_increase, max_daleks)
  while #daleks < dalek_count do
    local x = flr(rnd(grid_width))
    local y = flr(rnd(grid_height))

    -- don't place on player or existing daleks
    if not (x == player.x and y == player.y) and not is_dalek_at(x, y) then
      add(daleks, {x=x, y=y})
    end
  end

  game_state = "game"
end

-- check if a dalek exists at position
function is_dalek_at(x, y)
  for d in all(daleks) do
    if d.x == x and d.y == y then
      return true
    end
  end
  return false
end

-- check if junk exists at position
function is_junk_at(x, y)
  for j in all(junk) do
    if j.x == x and j.y == y then
      return true
    end
  end
  return false
end

-- main update function
function _update60() -- use _update60 for smoother animations
  if game_state == "title" then
    update_title()
  elseif game_state == "game" then
    update_game()
  elseif game_state == "gameover" then
    update_gameover()
  end
end

-- title screen update
function update_title()
  if btnp(❎) or btnp(🅾️) then
    game_state = "game"
  end
end

-- game update
function update_game()
  -- player's turn - handle input
  local moved = false

  -- cardinal direction movement
  if btnp(⬆️) then -- up
    if player.y > 0 and not is_junk_at(player.x, player.y-1) then
      player.y -= 1
      moved = true
    end
  elseif btnp(⬇️) then -- down
    if player.y < grid_height-1 and not is_junk_at(player.x, player.y+1) then
      player.y += 1
      moved = true
    end
  elseif btnp(⬅️) then -- left
    if player.x > 0 and not is_junk_at(player.x-1, player.y) then
      player.x -= 1
      moved = true
    end
  elseif btnp(➡️) then -- right
    if player.x < grid_width-1 and not is_junk_at(player.x+1, player.y) then
      player.x += 1
      moved = true
    end
  end

  -- sonic screwdriver (x button)
  if btnp(❎) and screwdrivers > 0 then
    use_sonic_screwdriver()
    moved = true
  end

  -- teleport (o button)
  if btnp(🅾️) and teleports > 0 then
    teleport_player()
    moved = true
  end

  -- spacebar "wait" function removed as requested

  -- if player moved, it's daleks' turn
  if moved then
    move_daleks()
    check_collisions()
    check_game_state()
  end
end

-- use sonic screwdriver
function use_sonic_screwdriver()
  screwdrivers -= 1

  -- destroy all daleks adjacent to player
  local destroyed = false
  for i=#daleks,1,-1 do
    local d = daleks[i]
    local dx = abs(d.x - player.x)
    local dy = abs(d.y - player.y)

    if dx <= 1 and dy <= 1 then
      -- add junk at this position
      add(junk, {x=d.x, y=d.y})
      -- remove dalek
      deli(daleks, i)
      score += 5
      destroyed = true
    end
  end

  -- sound effect only if daleks were destroyed
  if destroyed then
    play_sonic_screwdriver()
  end
end

-- teleport player to random position
function teleport_player()
  teleports -= 1

  -- find a safe spot (no daleks or junk)
  local attempts = 0
  local max_attempts = 100
  local found = false

  while not found and attempts < max_attempts do
    local x = flr(rnd(grid_width))
    local y = flr(rnd(grid_height))

    if not is_dalek_at(x, y) and not is_junk_at(x, y) then
      player.x = x
      player.y = y
      found = true
    end

    attempts += 1
  end

  play_teleport()
end

-- move all daleks one step toward player
function move_daleks()
  local any_moved = false

  -- optimization: pre-calculate directions once
  local move_daleks_toward_player = function()
    for d in all(daleks) do
      local old_x, old_y = d.x, d.y

      -- determine direction to move (toward player)
      if d.x < player.x then d.x += 1
      elseif d.x > player.x then d.x -= 1 end

      if d.y < player.y then d.y += 1
      elseif d.y > player.y then d.y -= 1 end

      if old_x != d.x or old_y != d.y then
        any_moved = true
      end
    end
  end

  move_daleks_toward_player()

  if any_moved and #daleks > 0 then
    play_dalek_movement()
  end
end
-- check for collisions between daleks and with junk
function check_collisions()
  -- check dalek-dalek collisions
  local to_remove = {}

  for i=1,#daleks do
    for j=i+1,#daleks do
      if daleks[i].x == daleks[j].x and daleks[i].y == daleks[j].y then
        -- mark both for removal
        to_remove[i] = true
        to_remove[j] = true
        -- add junk at collision site
        add(junk, {x=daleks[i].x, y=daleks[i].y})
        score += 10
        play_dalek_collision()
      end
    end
  end

  -- check dalek-junk collisions
  for i=1,#daleks do
    if not to_remove[i] then
      for j in all(junk) do
        if daleks[i].x == j.x and daleks[i].y == j.y then
          to_remove[i] = true
          score += 5
          play_dalek_collision()
          break
        end
      end
    end
  end

  -- remove marked daleks (in reverse order)
  for i=#daleks,1,-1 do
    if to_remove[i] then
      deli(daleks, i)
    end
  end
end

-- check if game is over or won
function check_game_state()
  -- check if player collided with a dalek
  for d in all(daleks) do
    if d.x == player.x and d.y == player.y then
      game_over = true
      game_state = "gameover"
      play_game_over()
      return
    end
  end

  -- check if player collided with junk
  for j in all(junk) do
    if j.x == player.x and j.y == player.y then
      game_over = true
      game_state = "gameover"
      play_game_over()
      return
    end
  end

  -- check if all daleks are destroyed
  if #daleks == 0 then
    win = true
    level += 1
    -- reward player with items based on level
    if level % 2 == 0 then -- every even level
      teleports = min(teleports + 1, max_teleports)
    end
    if level % 3 == 0 then -- every third level
      screwdrivers = min(screwdrivers + 1, max_screwdrivers)
    end
    -- increase score for completing level
    score += level * 50
    play_level_complete()
    init_level()
  end
end

-- gameover screen update
function update_gameover()
  if btnp(❎) or btnp(🅾️) then
    -- check for high score
    if score > high_score then
      high_score = score
      dset(0, high_score) -- save high score
    end

    -- reset game
    level = 1
    score = 0
    teleports = 2
    screwdrivers = 1
    init_level()
  end
end

-- main draw function
function _draw()
  cls(0) -- clear screen with black

  if game_state == "title" then
    draw_title()
  elseif game_state == "game" then
    draw_game()
  elseif game_state == "gameover" then
    draw_gameover()
  end
end

-- draw title screen
function draw_title()
  draw_title_elements()
end

-- draw game screen
function draw_game()
  -- draw background grid
  draw_background_grid()

  -- Calculate y offset for all game elements
  local y_offset = 20 -- Start after the expanded top UI bar with 1px extra space

  -- draw junk piles
  for j in all(junk) do
    draw_junk(j.x, j.y, y_offset)
  end

  -- draw daleks
  for d in all(daleks) do
    draw_dalek(d.x, d.y, y_offset)
  end

  -- draw player
  draw_player(player.x, player.y, y_offset)

  -- draw UI
  draw_game_ui()
end

-- draw game over screen
function draw_gameover()
  draw_gameover_elements()
end

-- draw junk pile at specified position
function draw_junk(x, y, y_offset)
  local junk_color = sprite_data.junk.base_color
  if sin(time()*2 + x/3 + y/5) > 0.7 then
    junk_color = sprite_data.junk.flicker_color -- occasional flicker
  end

  -- junk pile base
  rectfill(x*cell_size, y*cell_size+y_offset, (x+1)*cell_size-1, (y+1)*cell_size-1+y_offset, junk_color)

  -- add some detail to junk piles
  line(x*cell_size, y*cell_size+y_offset, (x+1)*cell_size-1, (y+1)*cell_size-1+y_offset, sprite_data.junk.line_color)
  line(x*cell_size, (y+1)*cell_size-1+y_offset, (x+1)*cell_size-1, y*cell_size+y_offset, sprite_data.junk.line_color)

  -- add some random debris dots
  for i=1,3 do
    local dx = x*cell_size + flr(rnd(cell_size))
    local dy = y*cell_size + flr(rnd(cell_size)) + y_offset
    pset(dx, dy, sprite_data.junk.line_color)
  end
end

-- draw dalek at specified position (salt shaker with plunger)
function draw_dalek(x, y, y_offset)
  local center_x = x*cell_size+cell_size/2
  local center_y = y*cell_size+cell_size/2+y_offset
  local width = sprite_data.dalek.width * cell_size
  local height = sprite_data.dalek.height * cell_size

  -- body (salt shaker shape)
  rectfill(
    center_x - width/2,
    center_y - height/2 + 1,
    center_x + width/2,
    center_y + height/2,
    sprite_data.dalek.body_color
  )

  -- dome top
  circfill(
    center_x,
    center_y - height/2 + 1,
    width/2,
    sprite_data.dalek.dome_color
  )

  -- plunger arm (extends toward player)
  local plunger_dir_x = (player.x > x) and 1 or ((player.x < x) and -1 or 0)
  local plunger_dir_y = (player.y > y) and 1 or ((player.y < y) and -1 or 0)

  -- plunger base
  line(
    center_x,
    center_y,
    center_x + plunger_dir_x * 2,
    center_y + plunger_dir_y * 2,
    sprite_data.dalek.plunger_color
  )

  -- plunger cup
  circfill(
    center_x + plunger_dir_x * 3,
    center_y + plunger_dir_y * 3,
    1,
    sprite_data.dalek.plunger_color
  )

  -- eye stalk - follows player
  local eye_x = center_x + plunger_dir_x
  local eye_y = center_y - 1 + plunger_dir_y/2
  pset(eye_x, eye_y, sprite_data.dalek.eye_color)
end

-- draw player at specified position (human shape)
function draw_player(x, y, y_offset)
  local center_x = x*cell_size+cell_size/2
  local center_y = y*cell_size+cell_size/2+y_offset
  local width = sprite_data.player.width * cell_size
  local height = sprite_data.player.height * cell_size

  -- body (torso)
  rectfill(
    center_x - width/4,
    center_y - height/4,
    center_x + width/4,
    center_y + height/3,
    sprite_data.player.body_color
  )

  -- head
  circfill(
    center_x,
    center_y - height/3,
    width/4,
    sprite_data.player.head_color
  )

  -- legs
  line(
    center_x - width/4,
    center_y + height/3,
    center_x - width/4,
    center_y + height/2,
    sprite_data.player.body_color
  )

  line(
    center_x + width/4,
    center_y + height/3,
    center_x + width/4,
    center_y + height/2,
    sprite_data.player.body_color
  )

  -- arms
  line(
    center_x - width/4,
    center_y,
    center_x - width/2.5,
    center_y,
    sprite_data.player.body_color
  )

  line(
    center_x + width/4,
    center_y,
    center_x + width/2.5,
    center_y,
    sprite_data.player.body_color
  )

  -- face details (changes with time for blinking effect)
  local detail_color = sprite_data.player.detail_color
  if sin(time()*4) > 0 then
    -- eyes
    pset(center_x - 1, center_y - height/3 - 1, detail_color)
    pset(center_x + 1, center_y - height/3 - 1, detail_color)
  end

  -- mouth
  pset(center_x, center_y - height/3 + 1, detail_color)
end

-- draw game background grid
function draw_background_grid()
  -- Calculate offset to center the grid between UI bars
  local y_offset = 20 -- Start after the top UI bar (which is now taller)

  for x=0,grid_width-1 do
    for y=0,grid_height-1 do
      if (x+y) % 2 == 0 then
        rectfill(x*cell_size, y*cell_size+y_offset, (x+1)*cell_size-1, (y+1)*cell_size-1+y_offset, 1)
      end
    end
  end
end

-- draw UI elements
function draw_game_ui()
  -- draw top UI with box
  rectfill(0, 0, 127, 18, 0)

  -- top UI - first row
  print("level: "..level, 2, 2, 7)  -- left-aligned

  -- center the daleks count
  local daleks_text = "daleks: "..#daleks
  local daleks_width = #daleks_text * 4  -- approximate width (4 pixels per character)
  print(daleks_text, 64 - daleks_width/2, 2, 8)  -- centered

  -- right-align the score
  local score_text = "score: "..score
  local score_width = #score_text * 4  -- approximate width
  print(score_text, 127 - score_width, 2, 7)  -- right-aligned

  -- top UI - second row (controls) - spread them out evenly with more space
  print("🅾️: "..teleports, 30, 11, 11)     -- left side
  print("❎: "..screwdrivers, 90, 11, 10)   -- right side
end

-- draw title screen elements
function draw_title_elements()
  -- title
  print("daleks", 48, 30, 7)
  print("pico-8 edition", 35, 40, 6)

  -- animated daleks in background
  for i=1,5 do
    local x = (sin(time()/8 + i/5) * 40) + 64
    local y = (cos(time()/6 + i/5) * 20) + 50

    -- draw mini daleks using our sprite function but scaled down
    local mini_center_x = x
    local mini_center_y = y

    -- mini body
    rectfill(mini_center_x-2, mini_center_y-1, mini_center_x+2, mini_center_y+2, sprite_data.dalek.body_color)

    -- mini dome
    circfill(mini_center_x, mini_center_y-1, 2, sprite_data.dalek.dome_color)

    -- mini eye
    pset(mini_center_x + 1, mini_center_y - 1, sprite_data.dalek.eye_color)
  end

  -- instructions
  rectfill(15, 70, 113, 110, 1)
  rect(15, 70, 113, 110, 7)
  print("controls:", 45, 75, 7)
  print("⬆️⬇️⬅️➡️: move", 30, 85, 5)
  print("❎: sonic screwdriver", 20, 95, 10)
  print("🅾️: teleport", 40, 105, 11)

  -- blinking prompt
  if sin(time()*2) > 0 then
    print("press ❎ or 🅾️ to start", 20, 120, 6)
  end
end

-- draw game over screen elements
function draw_gameover_elements()
  -- background effect - match the new grid size
  local y_offset = 20
  for i=0,grid_width-1 do
    for j=0,grid_height-1 do
      if (i+j) % 2 == 0 then
        rectfill(i*cell_size, j*cell_size+y_offset, (i+1)*cell_size-1, (j+1)*cell_size-1+y_offset, 1)
      end
    end
  end

  -- game over box
  rectfill(20, 30, 108, 100, 0)
  rect(20, 30, 108, 100, 8)

  -- game over text
  print("game over", 45, 40, 8)

  if win then
    print("level "..level.." complete!", 30, 55, 11)
  else
    print("exterminated!", 35, 55, 8)
  end

  -- score display
  print("final score: "..score, 35, 65, 7)
  print("high score: "..high_score, 35, 75, 6)

  -- blinking restart prompt
  if sin(time()*2) > 0 then
    print("press ❎ or 🅾️ to restart", 15, 90, 6)
  end

  -- draw a sad player or happy player based on win/lose
  if win then
    -- happy player
    local p_x = 64
    local p_y = 85
    draw_mini_player(p_x, p_y, true)
  else
    -- sad player with dalek
    local p_x = 50
    local p_y = 85
    draw_mini_player(p_x, p_y, false)

    -- victorious dalek
    local d_x = 78
    local d_y = 85

    -- mini body
    rectfill(d_x-2, d_y-1, d_x+2, d_y+2, sprite_data.dalek.body_color)

    -- mini dome
    circfill(d_x, d_y-1, 2, sprite_data.dalek.dome_color)

    -- mini eye
    pset(d_x + 1, d_y - 1, sprite_data.dalek.eye_color)

    -- mini plunger pointing at player
    line(d_x-1, d_y, d_x-3, d_y, sprite_data.dalek.plunger_color)
  end
end

-- helper function to draw mini player for title/game over screens
function draw_mini_player(x, y, is_happy)
  -- mini body
  rectfill(x-1, y-1, x+1, y+2, sprite_data.player.body_color)

  -- mini head
  circfill(x, y-2, 2, sprite_data.player.head_color)

  -- mini face
  if is_happy then
    -- happy face
    pset(x-1, y-2, sprite_data.player.detail_color) -- left eye
    pset(x+1, y-2, sprite_data.player.detail_color) -- right eye
    pset(x, y-1, sprite_data.player.detail_color)   -- smiling mouth
  else
    -- sad face
    pset(x-1, y-3, sprite_data.player.detail_color) -- left eye
    pset(x+1, y-3, sprite_data.player.detail_color) -- right eye
    pset(x, y-1, sprite_data.player.detail_color)   -- sad mouth
  end

  -- mini arms
  pset(x-2, y, sprite_data.player.body_color) -- left arm
  pset(x+2, y, sprite_data.player.body_color) -- right arm

  -- mini legs
  pset(x-1, y+3, sprite_data.player.body_color) -- left leg
  pset(x+1, y+3, sprite_data.player.body_color) -- right leg
end

-- initialize sound effects
function init_sounds()
  -- In PICO-8, sounds are defined in the __sfx__ section
  -- The sound_data table is used for reference only

  -- Sonic screwdriver sound (sfx 0)
  -- High pitched electronic sound

  -- Teleport sound (sfx 1)
  -- Warping sound

  -- Dalek movement sound (sfx 2)
  -- Mechanical movement sound

  -- Dalek collision sound (sfx 3)
  -- Explosion sound

  -- Level complete sound (sfx 4)
  -- Victory jingle

  -- Game over sound (sfx 5)
  -- Sad tone
end

-- play sonic screwdriver sound
function play_sonic_screwdriver()
  sfx(0)
end

-- play teleport sound
function play_teleport()
  sfx(1)
end

-- play dalek movement sound
function play_dalek_movement()
  sfx(2)
end

-- play dalek collision sound
function play_dalek_collision()
  sfx(3)
end

-- play level complete sound
function play_level_complete()
  sfx(4)
end

-- play game over sound
function play_game_over()
  sfx(5)
end
