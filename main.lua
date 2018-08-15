local memory = require "memory"
local world = require "world"
local actions = require "actions"
local directions = require "directions"
local creature = require "creature"
local worker = require "worker"

for i = 1, world.w do
  table.insert(world.size,{})
end
for i = 1, 150 do
  local obj = creature.new()
  for j = 1, world.logic_values do
    obj.memory:set(j, math.random(world.logic_values))
  end
  world:insert(obj)
  programming_creature=obj
end

local programming_photosyntesis = {world.logic_values/2, world.logic_values/4, world.logic_values-7}
for i=1, world.logic_values do
  world.objects[programming_creature].memory:set(i, programming_photosyntesis[i%3+1])
end

function love.threaderror(thread, errorstr)
  print("Thread error!\n"..errorstr)
end

success = love.window.setMode( 1900, 1000)
local timer = 0
font = love.graphics.newFont( [[NovaMono.ttf]],50 )
love.graphics.setFont( font )

local function rendering_action_and_count(obj)
  love.graphics.setColor(0.5,0.5,0.5,0.5)
  local color_gene = obj:gene(obj.memory.p)
  if color_gene == world.logic_values/8 then
    obj_melee=obj_melee+1
    love.graphics.setColor(1,0,0,1)
  end
  if color_gene ==  world.logic_values/4 then
    obj_swim=obj_swim+1
    love.graphics.setColor(0,0.75,1,1)
  end
  if color_gene ==  world.logic_values/2 then
    obj_photosyntesis=obj_photosyntesis+1
    love.graphics.setColor(0,1,0,1)
  end
  if color_gene ==  world.logic_values*3/4 then
    obj_check=obj_check+1
    love.graphics.setColor(0,0,0,1)
  end
  if color_gene ==  world.logic_values*5/8 then
    obj_give_energy=obj_give_energy+1
    love.graphics.setColor(1,1,0,1)
  end
  if color_gene ==  world.logic_values*7/8 then
    obj_div = obj_div+1
    love.graphics.setColor(1,1,1,1)
  end
  if color_gene ==  world.logic_values*3/8 then
    obj_sensor = obj_sensor+1
    love.graphics.setColor(0.75,0.75,0.75,1)
  end
  love.graphics.rectangle("fill", obj.x * 3, (obj.y+world.h+20) * 3, 3, 3)
end

local function rendering_energy(obj)
  love.graphics.setColor(1, obj.energy / world.energy.limit,0, 1)
  love.graphics.rectangle("fill", obj.x * 3, obj.y * 3+ 20, 3, 3)
end

local function change_world(timer)
  if timer%500==0 then
    local global_rand=math.random()
    if global_rand<0.1 then
      local rand=math.random()
      if rand<0.5 then
        if rand<0.25 then
          world.sun.power = math.max(1,world.sun.power-math.random(1,2))
        else
          world.sun.depth_degradation = math.max(0.05,world.sun.depth_degradation - math.random(300)/1000)
        end
      else
        if rand<0.75 then
          world.sun.power = world.sun.power+math.random(1,2)
        else
          world.sun.depth_degradation = math.min(0.95, world.sun.depth_degradation + math.random(300)/1000)
        end
      end
    else
      if global_rand>0.9 then
        local rand=math.random()
        if rand<0.5 then
          if rand<0.25 then
            world.heat.power = math.max(1,world.heat.power-math.random(1,2))
          else
            world.heat.depth_degradation = math.max(0.05,world.heat.depth_degradation - math.random(300)/1000)
          end
        else
          if rand<0.75 then
            world.heat.power = world.heat.power+math.random(1,2)
          else
            world.heat.depth_degradation = math.min(0.95,world.heat.depth_degradation + math.random(300)/100)
          end
        end
      end
    end
  end
end

local function print_count_action()
end


function love.draw()
  timer=timer+1
  worker:process(world)

  love.graphics.setBackgroundColor(0, 0, 1, 1)
  obj_melee, obj_photosyntesis, obj_give_energy, obj_sensor, obj_swim, obj_check, obj_div = 0, 0, 0, 0, 0, 0, 0
  for obj in pairs(world.objects) do
    obj.memory = setmetatable(obj.memory, {__index = memory})
    rendering_energy(obj)
    rendering_action_and_count(obj)
  end
  change_world(timer)
  love.graphics.setColor(0,0,0,1)
  love.graphics.print('melee: '..tostring(obj_melee),270*3)
  love.graphics.print('photosyntesis: '..tostring(obj_photosyntesis),270*3,60)
  love.graphics.print('give energy: '..tostring(obj_give_energy),270*3,120)
  love.graphics.print('swim: '..tostring(obj_swim),270*3,180)
  love.graphics.print('check world: '..tostring(obj_check),270*3,240)
  love.graphics.print('division: '..tostring(obj_div),270*3,300)
  love.graphics.print('sensor: '..tostring(obj_sensor),270*3,360)
  love.graphics.print(world.sun.power,270*3,140*3)
  love.graphics.print(world.heat.power,270*3,160*3)
  love.graphics.print(world.heat.depth_degradation,340*3,160*3)
  love.graphics.print(world.sun.depth_degradation,340*3,140*3)
  love.graphics.print(timer,270*3,180*3)
  love.graphics.print("fps: " .. tostring(love.timer.getFPS()) .. " count: " .. tostring(world.object_count), 0, 0, 0, 0.3, 0.3)
end
