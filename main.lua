local memory = require "memory"
local world = require "world"
local actions = require "actions"
local directions = require "directions"
local creature = require "creature"
local worker = require "worker"
local bit = require "bit"
local ffi = require "ffi"

for i = 1, world.w do
  table.insert(world.size,{})
end
for i = 1, 150 do
  local obj = creature.new()
  for j = 1, world.logic_values do
    obj.memory:set(j, math.random(world.logic_values))
  end
  world:insert(obj)
  programming_creature = obj
end

local programming_photosyntesis = {world.logic_values / 2, world.logic_values / 4, world.logic_values - 7}
for i = 1, world.logic_values do
  world.objects[programming_creature].memory:set(i, programming_photosyntesis[i % 3 + 1])
end

function love.threaderror(thread, errorstr)
  print("Thread error!\n"..errorstr)
end

success = love.window.setMode( 1900, 1000)
local timer = 0
font = love.graphics.newFont( [[NovaMono.ttf]], 50 )
love.graphics.setFont( font )

local function rendering_action_and_count(obj)
  love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
  local color_gene = obj:gene(obj.memory.p)
  if color_gene == world.logic_values / 8 then
    obj_melee = obj_melee + 1
    love.graphics.setColor(1, 0, 0, 1)
  end
  if color_gene ==  world.logic_values / 4 then
    obj_swim = obj_swim + 1
    love.graphics.setColor(0, 0.75, 1, 1)
  end
  if color_gene ==  world.logic_values / 2 then
    obj_photosyntesis = obj_photosyntesis + 1
    love.graphics.setColor(0, 1, 0, 1)
  end
  if color_gene ==  world.logic_values * 3 / 4 then
    obj_check = obj_check + 1
    love.graphics.setColor(0, 0, 0, 1)
  end
  if color_gene ==  world.logic_values * 5 / 8 then
    obj_give_energy = obj_give_energy + 1
    love.graphics.setColor(1, 1, 0, 1)
  end
  if color_gene ==  world.logic_values * 7 / 8 then
    obj_div = obj_div + 1
    love.graphics.setColor(1, 1, 1, 1)
  end
  if color_gene ==  world.logic_values * 3 / 8 then
    obj_sensor = obj_sensor + 1
    love.graphics.setColor(0.75, 0.75, 0.75, 1)
  end
  love.graphics.rectangle("fill", obj.x * 3, (obj.y + world.h + 15) * 3, 3, 3)
end

local function rendering_energy(obj)
  love.graphics.setColor(1, obj.energy / world.energy.limit, 0, 1)
  love.graphics.rectangle("fill", obj.x * 3, obj.y * 3 + 15, 3, 3)
end

local function rendering_type(obj)
  local color = {r = 0, g = 0, b = 0}
  for i = 1, obj.memory:size() do
    local gene = obj:gene(i)
    local r = gene / 64 % 4 / 4
    local g = gene / 8 % 8 / 8
    local b = gene % 8 / 8

    if r < g then
      if g < b then
        color.b = color.b + b * i
      else
        color.g = color.g + g * i
      end
    else
      if r < b then
        color.b = color.b + b * i
      else
        color.r = color.r + r * i
      end
    end

    -- color.r = color.r + r * i
    -- color.g = color.g + g * i
    -- color.b = color.b + b * i
  end
  local len = math.sqrt(color.r ^ 2 + color.g ^ 2 + color.b ^ 2)
  love.graphics.setColor(color.r / len, color.g / len, color.b / len, 1)
  love.graphics.rectangle("fill", obj.x * 3, obj.y * 3 + (world.h + 15) * 2 * 3, 3, 3)
end

local function change_world(timer)
  if timer % 500 == 0 then
    local global_rand=math.random()
    if global_rand < 0.1 then
      local rand=math.random()
      if rand < 0.5 then
        if rand < 0.25 then
          world.sun.power = math.max(1, world.sun.power - math.random(1, 2))
        else
          world.sun.depth_degradation = math.max(0.05,world.sun.depth_degradation - math.random(100)/1000)
        end
      else
        if rand < 0.75 then
          world.sun.power = world.sun.power+math.random(1, 2)
        else
          world.sun.depth_degradation = math.min(0.95, world.sun.depth_degradation + math.random(100)/1000)
        end
      end
    else
      if global_rand > 0.9 then
        local rand = math.random()
        if rand < 0.5 then
          if rand < 0.25 then
            world.heat.power = math.max(1, world.heat.power - math.random(1,2))
          else
            world.heat.depth_degradation = math.max(0.05, world.heat.depth_degradation - math.random(100) / 1000)
          end
        else
          if rand < 0.75 then
            world.heat.power = world.heat.power + math.random(1, 2)
          else
            world.heat.depth_degradation = math.min(0.95, world.heat.depth_degradation + math.random(100) / 1000)
          end
        end
      end
    end
  end
end


function love.load()
	pause = false
  wait = 0
  curr_x_pressed_creation, curr_y_pressed_creation = 0, 0
  exist_pressed_creation = false
end


function love.update(dt)
  function love.keyreleased(key)
    if key == 'p' or 'P' then
      pause = not pause
    elseif key == 'w' or 'W' then
      wait = 1
    end
  end
end

function love.mousepressed(x, y, button, istouch)
    exist_pressed_creation = false
   if button == 1 then
     curr_x_pressed_creation = math.floor(x / 3) - 5
     curr_y_pressed_creation = math.floor(y / 3) - 5
      if (not world:empty(curr_x_pressed_creation, curr_y_pressed_creation)) then
        exist_pressed_creation = true
      end
   end
end


function love.draw()
  if exist_pressed_creation then
    local curr_obj = world:find(curr_x_pressed_creation, curr_y_pressed_creation)
    local curr_action = curr_obj:gene(curr_obj.memory.p)
    if curr_action == math.floor(world.logic_values / 2) then
      love.graphics.print("I synthesize", 400 * 3, 20)
    elseif curr_action == math.floor(world.logic_values / 4) then
      love.graphics.print("I'm swimming", 400 * 3, 20)
    elseif curr_action == math.floor(world.logic_values * 3 / 4) then
      love.graphics.print("I'm checking", 400 * 3, 20)
    elseif curr_action == math.floor(world.logic_values / 8) then
      love.graphics.print("I'm attacking", 400 * 3, 20)
    elseif curr_action == math.floor(world.logic_values * 3 / 8) then
      love.graphics.print("How deep am I?", 400 * 3, 20)
    elseif curr_action == math.floor(world.logic_values  * 5 / 8) then
      love.graphics.print("I share energy with others", 400 * 3, 20)
    elseif curr_action == math.floor(world.logic_values * 7 / 8) then
      love.graphics.print("Doing budding", 400 * 3, 20)
    else
      love.graphics.print("I'm chilling, don't touch me", 400 * 3, 20)
    end
    exist_pressed_creation = false
    --[[
    action = {
      [math.floor(world.logic_values / 2)] = function () love.graphics.print("I synthesize", 400 * 3, 20) end,
      [math.floor(world.logic_values / 4)] = function () love.graphics.print("I'm swimming", 400 * 3, 20) end,
      [math.floor(world.logic_values * 3 / 4)] = function () love.graphics.print("I'm checking", 400 * 3, 20) end,
      [math.floor(world.logic_values / 8)] = function () love.graphics.print("I'm attacking", 400 * 3, 20) end,
      [math.floor(world.logic_values * 3 / 8)] = function () love.graphics.print("How deep am I?", 400 * 3, 20) end,
      [math.floor(world.logic_values * 5 / 8)] = function () love.graphics.print("I share energy with others", 400 * 3, 20) end,
      [math.floor(world.logic_values * 7 / 8)] = function () love.graphics.print("Doing budding", 400 * 3, 20) end,
    }

    local f = action[curr_action]
    if not f then
      love.graphics.print("I'm chilling, don't touch me", 400 * 3, 20)
    end
    ]]
    wait = 2
  end

  love.graphics.setBackgroundColor(1, 1, 1, 1)
  obj_melee, obj_photosyntesis, obj_give_energy, obj_sensor, obj_swim, obj_check, obj_div = 0, 0, 0, 0, 0, 0, 0
  for obj in pairs(world.objects) do
    obj.memory = setmetatable(obj.memory, {__index = memory})
    rendering_energy(obj)
    rendering_action_and_count(obj)
    rendering_type(obj)
  end
  change_world(timer)
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.print('First map. Map of energy: ', 60*3, 0, 0, 0.3)
  love.graphics.print('Second map. Map of actions: ', 60*3, (world.h) * 3 + 20, 0, 0.3)
  love.graphics.print('Third experimental map. Map of teams: ', 60*3, (world.h) * 3 * 2 + 20 * 3, 0, 0.3)
  love.graphics.print('Melee: '..tostring(obj_melee), 270 * 3)
  love.graphics.print('Photosyntesis: '..tostring(obj_photosyntesis), 270 * 3, 60)
  love.graphics.print('Give energy: '..tostring(obj_give_energy), 270 * 3, 120)
  love.graphics.print('Swim: '..tostring(obj_swim), 270 * 3, 180)
  love.graphics.print('Check world: '..tostring(obj_check), 270 * 3, 240)
  love.graphics.print('Division: '..tostring(obj_div), 270 * 3, 300)
  love.graphics.print('Sensor: '..tostring(obj_sensor), 270 * 3, 360)
  love.graphics.print('Chill: '..tostring(world.object_count - obj_melee - obj_photosyntesis - obj_give_energy - obj_sensor - obj_swim - obj_check - obj_div), 270 * 3, 420)
  love.graphics.print('Sun power: '..world.sun.power, 270 * 3, 160 * 3)
  love.graphics.print('Ground power: '..world.heat.power, 270 * 3, 180 * 3)
  love.graphics.print(world.heat.depth_degradation, 440 * 3, 180 * 3)
  love.graphics.print(world.sun.depth_degradation, 420 * 3, 160 * 3)
  love.graphics.print('Year: '..timer, 270 * 3, 200 * 3)
  love.graphics.print("fps: " .. tostring(love.timer.getFPS()) .. " count: " .. tostring(world.object_count), 0, 0, 0, 0.3, 0.3)
  if pause then
    love.graphics.print("Game is paused", 1000, 800)
    love.timer.sleep(2)
  elseif wait == 0 then
	  love.graphics.print("Game is running", 1000, 800)
    timer = timer + 1
    worker:process(world)
  end
  if wait > 0 then
    love.graphics.print("Wait 4 seconds...", 1000, 800)
    if wait == 2 then
      love.timer.sleep(1)
    else
      love.timer.sleep(3)
    end
    wait = wait - 1
  end
end
