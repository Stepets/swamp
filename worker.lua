local memory = require "memory"

local wrld = require "world"
local world = wrld.world
local actions = wrld.actions
local directions = wrld.directions

function deep_copy(obj, tab)
  tab = tab or ''
  if type(obj) == 'table' then
    local result = {}
    for k,v in pairs(obj) do
      --print(tab, k, '= {')
      result[k] = deep_copy(v, tab .. '\t')
      --print(tab, '}')
    end
    return result
  else
    --print(tab, obj)
    return obj
  end
end

local function process(old_objects, from, to)
  -- local new_objects = {}
  for obj in pairs(world.objects) do
    -- print("worker", args[1], "processing", i)
    obj.memory = setmetatable(obj.memory, {__index = memory})
    local action = actions[gene(obj.memory, obj.memory.p)]
    if action then
      obj.memory.count = 0
      action(obj)
    else
      obj.memory.p = obj.memory.p + 1
    end
    if obj.memory:size() < obj.memory.p then
      obj.memory.p = obj.memory.p % obj.memory:size() + 1
    end
    -- world.insert({objects = new_objects}, obj)
  end
  -- world.objects = new_objects

  -- print("worker", args[1], "finished")

  for obj in pairs(world.objects)  do
    --if math.floor(world.h/10)<obj.y and obj.y<math.floor(world.h*19/20) then
    obj.energy = obj.energy - world.energy.degradation
    --end
    obj.energy = obj.energy + (1 - world.heat.depth_degradation) ^ (world.h - obj.y) * world.heat.power
    if obj.energy <= 0 then
      world:death(obj)
    end
  end

  for obj in pairs(world.objects)  do
    if world:empty(obj.x, obj.y + 1) and obj.y < world.h and math.random() < 0.1 then
      obj.y = obj.y + 1
    end
  end

  for obj in pairs(world.objects) do
    if world.energy.limit <= obj.energy then
      world:death(obj)
      local free_cells = {}
      for _, dir in ipairs(directions) do
        if 1 <= obj.x + dir[1] and obj.x + dir[1] <= world.w
        and 1 <= obj.y + dir[2] and obj.y + dir[2] <= world.h then
          if world:empty(obj.x + dir[1], obj.y + dir[2]) then
            table.insert(free_cells, {obj.x + dir[1], obj.y + dir[2]})
          end
        end
      end
      if 2 <= #free_cells then
        local child1 = deep_copy(obj)
        local child2 = deep_copy(obj)
        child1.energy = world.energy.limit / 3
        child2.energy = world.energy.limit / 3

        local idx1 = math.random(#free_cells)
        local pos1 = free_cells[idx1]
        table.remove(free_cells, idx1)
        local idx2 = math.random(#free_cells)
        local pos2 = free_cells[idx2]
        table.remove(free_cells, idx2)

        child1.x = pos1[1]
        child1.y = pos1[2]
        child2.x = pos2[1]
        child2.y = pos2[2]

        child1.memory = obj.memory:copy()
        child2.memory = obj.memory:copy()

        -- child1.name = child1.name .. "_child1"
        -- child2.name = child2.name .. "_child2"

        for i = 1, child1.memory:size() do
          if i == math.random(world.logic_values) then
            child1.memory:set(i, math.random(world.logic_values))
            break
          end
        end

        for i = 1, child2.memory:size() do
          if i == math.random(world.logic_values) then
            child2.memory:set(i, math.random(world.logic_values))
            break
          end
        end

        world:insert(child1)
        world:insert(child2)
      else
        local obj_give_energy = obj.energy/8
        local obj_l_u, obj_c_u, obj_r_u = world:find(obj.x-1,obj.y+1), world:find(obj.x, obj.y+1), world:find(obj.x+1, obj.y+1)
        local obj_l_c, obj_r_c = world:find(obj.x-1,obj.y), world:find(obj.x+1, obj.y)
        local obj_l_d, obj_c_d, obj_r_d = world:find(obj.x-1,obj.y-1), world:find(obj.x, obj.y-1), world:find(obj.x+1, obj.y-1)
        if obj_l_u then
          obj_l_u.energy = obj_l_u.energy+ obj_give_energy
        end
        if obj_c_u then
          obj_c_u.energy = obj_c_u.energy+ obj_give_energy
        end
        if obj_r_u then
          obj_r_u.energy = obj_r_u.energy+ obj_give_energy
        end
        if obj_l_c then
          obj_l_c.energy = obj_l_c.energy+ obj_give_energy
        end
        if obj_r_c then
          obj_r_c.energy = obj_r_c.energy+ obj_give_energy
        end
        if obj_r_d then
          obj_r_d.energy = obj_r_d.energy+ obj_give_energy
        end
        if obj_c_d then
          obj_c_d.energy = obj_c_d.energy+ obj_give_energy
        end
        if obj_l_d then
          obj_l_d.energy = obj_l_d.energy+ obj_give_energy
        end
      end
      -- world.objects:sort()
    end
  end
  return old_objects
end

local args = {...}
if not tonumber(args[1]) then return process end

-- print("ready", args[1])
function love.threaderror(thread, errorstr)
  print("Thread error!\n"..errorstr)
end

local channel = love.thread.getChannel("init"):demand()

while true do

  local old_objects = channel:demand()
  local from, to = channel:demand(), channel:demand()

  -- print("worker", args[1], "got", from ,to)

  channel:supply(process(old_objects, from, to))

end
