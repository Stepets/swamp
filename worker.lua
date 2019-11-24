local memory = require "memory"
local actions = require "actions"
local directions = require "directions"

local worker = {}

function worker:action_creature(world)
  for obj in pairs(world.objects) do
    obj.memory = setmetatable(obj.memory, {__index = memory})
    local action = actions[obj:gene(obj.memory.p)]
    if action then
      obj.memory.count = 0
      action(obj)
    else
      obj.memory.p = obj.memory.p + 1
    end
    if obj.memory:size() < obj.memory.p then
      obj.memory.p = obj.memory.p % obj.memory:size() + 1
    end
  end
end

function worker:change_energy(world)
  for obj in pairs(world.objects)  do
    obj.energy = obj.energy - world.energy.degradation
    obj.energy = obj.energy + (1 - world.heat.depth_degradation) ^ ((math.floor(world.h / 5) - math.floor(obj.y / 5)) * 5) * world.heat.power
    if obj.energy <= 0 then
      world:death(obj)
    end
  end
end

function worker:drop(world)
  for obj in pairs(world.objects)  do
    if world:empty(obj.x, obj.y + 1) and obj.y < world.h and math.random() < 0.1 then
      world:move(obj, obj.x, obj.y + 1)
    end
  end
end

function worker:disintegration(world)
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
        local mutation = function(child)
          child.energy = world.energy.limit / 3

          local idx = math.random(#free_cells)
          local pos = free_cells[idx]
          table.remove(free_cells, idx)

          child.x, child.y = pos[1], pos[2]

          for i = 1, child.memory:size() do
            if i == math.random(world.logic_values) then
              child.memory:set(i, math.random(world.logic_values))
              break
            end
          end
        end

        world:insert(obj:clone(mutation))
        world:insert(obj:clone(mutation))
      else
        local obj_give_energy = obj.energy/8
        for _, dir in ipairs(directions) do
          local tgt = world:find(obj.x + dir[1], obj.y + dir[2])
          if tgt then
            tgt.energy = tgt.energy + obj_give_energy
          end
        end
      end
    end
  end
end


function worker:process(world)
  self:action_creature(world)
  self:change_energy(world)
  self:drop(world)
  self:disintegration(world)
  function love.keypressed(key)
    if key == "p" then
      print('keeeek')
      local line = io.read()
    end
  end
end

return worker
