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

for i = 1, 3000 do
  table.insert(world.objects, {
    -- name = tostring(i),
    y = math.random(world.h),
    energy = world.energy.limit / 2,
    memory = memory.new(world.logic_values),
  })
end

for i = 1, #world.objects do
  world.objects[i].x = math.floor(world.w / #world.objects * i)
  for j = 1, world.logic_values do
    world.objects[i].memory:set(j, world.logic_values / 2)
  end
end
world:sort()

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

function love.draw()
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
  for i = 1, #world.objects do
    local obj = world.objects[i]
    obj.memory = setmetatable(obj.memory, {__index = memory})
    love.graphics.setColor(melee(obj), photosyntesis(obj), obj.energy / world.energy.limit, 1)
    -- print('=== //')
    -- for k,v in pairs(obj) do print(k,v) end
    love.graphics.rectangle("fill", obj.x * 3, obj.y * 3, 3, 3)
  end
end
