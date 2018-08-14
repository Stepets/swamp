local memory = require "memory"
local wrld = require "world"
local world = wrld.world
local actions = wrld.actions
local directions = wrld.directions

local function mergesort(a, b, cmp)
  local result = {}
  local pa, pb = 1, 1
  while pa <= #a and pb <= #b do
    if cmp(a[pa], b[pb]) then
      result[#result + 1] = a[pa]
      pa = pa + 1
    else
      result[#result + 1] = b[pb]
      pb = pb + 1
    end
  end

  for i = pa, #a do
    result[#result + 1] = a[i]
  end

  for i = pb, #b do
    result[#result + 1] = b[i]
  end

  return result
end
for i = 1, world.w do
  table.insert(world.size,{})
end
for i = 1, 20000 do
  local obj = {

    x = math.floor(i % world.w + 1),
    y = math.random(world.h),
    energy = world.energy.limit / 2,
    memory = memory.new(world.logic_values),
  }
  for j = 1, world.logic_values do
    obj.memory:set(j, math.random(world.logic_values))
  end
  world:insert(obj)
end


function love.threaderror(thread, errorstr)
  print("Thread error!\n"..errorstr)
end

success = love.window.setMode( 1900, 1000)
local timer = 0
font = love.graphics.newFont( [[NovaMono.ttf]],50 )
love.graphics.setFont( font )
function love.draw()
  timer=timer+1
  require("worker")()

  love.graphics.setBackgroundColor(1, 1, 1, 1)
  for obj in pairs(world.objects) do
    obj.memory = setmetatable(obj.memory, {__index = memory})
    love.graphics.setColor(1, obj.energy / world.energy.limit,0, 1)
    love.graphics.rectangle("fill", obj.x * 3, obj.y * 3, 3, 3)
    local color_gene = gene(obj.memory,obj.memory.p)
    if color_gene == world.logic_values/8 then
      love.graphics.setColor(1,0,0,1)
    end
    if color_gene ==  world.logic_values/4 then
      love.graphics.setColor(0,0.75,1,1)
    end
    if color_gene ==  world.logic_values/2 then
      love.graphics.setColor(0,1,0,1)
    end
    if color_gene ==  world.logic_values*3/4 then
      love.graphics.setColor(0,0,0,1)
    end
    if color_gene ==  world.logic_values*5/8 then
      love.graphics.setColor(1,1,0,1)
    end
    love.graphics.rectangle("fill", obj.x * 3, (obj.y+world.h+20) * 3, 3, 3)
  end
  if timer%750==0 then
    local global_rand=math.random()
    if global_rand<0.1 then
      local rand=math.random()
      if rand<0.5 then
        if rand<0.25 then
          world.sun.power = world.sun.power-math.random(1,2)
        else
          world.sun.depth_degradation = world.sun.depth_degradation - math.random(1,2)
        end
      else
        if rand<0.75 then
          world.sun.power = world.sun.power+math.random(1,2)
        else
          world.sun.depth_degradation = world.sun.depth_degradation + math.random(1,2)
        end
      end
    else
      if global_rand>0.9 then
        local rand=math.random()
        if rand<0.5 then
          if rand<0.25 then
            world.heat.power = world.heat.power-math.random(1,2)
          else
            world.heat.depth_degradation = world.heat.depth_degradation - math.random(1,2)
          end
        else
          if rand<0.75 then
            world.heat.power = world.heat.power+math.random(1,2)
          else
            world.heat.depth_degradation = world.heat.depth_degradation + math.random(1,2)
          end
        end
      end
    end
  end
  love.graphics.setColor(0,0,0,1)
  love.graphics.print(world.sun.power,270*3,120*3)
  love.graphics.print(world.heat.power,270*3,140*3)
  love.graphics.print(world.heat.depth_degradation,340*3,140*3)
  love.graphics.print(world.sun.depth_degradation,340*3,120*3)
  love.graphics.print(timer,270*3,160*3)
  love.graphics.print("fps: " .. tostring(love.timer.getFPS()) .. " count: " .. tostring(world.object_count), 0, 0, 0, 0.2, 0.2)
end
