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
for i = 1, 1 do
  local obj = {

    x = math.floor(2 * i),
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

-- local workers = {}
-- for i = 1, love.system.getProcessorCount() do
--   local worker = { thread = love.thread.newThread("worker.lua"), channel = love.thread.newChannel()}
--   worker.thread:start(i)
--   print("worker", i)
--   love.thread.getChannel("init"):supply(worker.channel)
--   table.insert(workers, worker)
-- end
success = love.window.setMode( 1900, 1000)
local timer = 0
font = love.graphics.newFont( [[lucon.ttf]],50 )
love.graphics.setFont( font )
function love.draw()
timer=timer+1
  -- for i = 1, #workers - 1 do
  --   local worker = workers[i]
  --   worker.channel:supply(world.objects)
  --   worker.channel:supply(math.floor(#world.objects / #workers * (i-1) + 1))
  --   worker.channel:supply(math.floor(#world.objects / #workers * i))
  -- end
  -- local last_worker = workers[#workers]
  -- last_worker.channel:supply(world.objects)
  -- last_worker.channel:supply(math.floor(#world.objects / #workers * (#workers-1) + 1))
  -- last_worker.channel:supply(#world.objects)

  -- local new_objects = {}
  -- for i = 1, #workers do
  --   local worker = workers[i]
  --   -- print("waiting for worker", i)
  --   new_objects = mergesort(new_objects, worker.channel:demand(), function(a,b) return a.x < b.x and a.y < b.y end)
  -- end

  -- world.objects = new_objects
  world.objects = require("worker")(world.objects, 1, #world.objects)

love.graphics.setBackgroundColor(1, 1, 1, 1)
  print(love.timer.getFPS(), #world.objects)
  for obj in pairs(world.objects) do
    obj.memory = setmetatable(obj.memory, {__index = memory})
    love.graphics.setColor(1, obj.energy / world.energy.limit,0, 1)
    -- print('=== //')
    -- for k,v in pairs(obj) do print(k,v) end
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
    -- local count_melee,count_photosyntesis=0,0
    -- -- local arg=gene(obj.memory,obj.memory.p)
    -- -- local p,s,g,m = 0,0,0,0
    -- for i=1,world.logic_values do
    --   local gen=gene(obj.memory,i)
    --   if gen==world.logic_values/2 then
    --     count_photosyntesis=count_photosyntesis+1
    --     -- if gen==arg then
    --     --   p=p+1
    --     -- end
    --   end
    --   if gen==world.logic_values/8 then
    --     count_melee=count_melee+1
    --     -- if gen==arg then
    --     --   m=m+1
    --     -- end
    --   end
    -- end
    -- love.graphics.setColor(count_melee/world.logic_values,count_photosyntesis/world.logic_values,0, 1)
    -- love.graphics.rectangle("fill", (obj.x+world.w+20) * 3, (obj.y) * 3, 3, 3)
    -- local a = tostring(m)
    -- love.graphics.print(a,270*3,120*3,0,1,1)
  end
  if timer%750==0 then
    -- timer=0
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
  -- love.timer.sleep(1)
end
