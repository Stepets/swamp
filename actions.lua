local directions = require "directions"
local world = require "world"

local actions

local function simple(offset, real_func)
  return function(creature)
    real_func(creature)
    creature.memory.p = creature.memory.p + offset
  end
end

local function logical(real_func)
  return function(creature)
    if 64 < creature.memory.count then
      creature.memory.p = creature.memory.p + 1
      return
    end
    real_func(creature)
    creature.memory.count = creature.memory.count + 1
    local action = actions[creature:gene(creature.memory.p)]
    if action then action(creature) end
  end
end

actions = {
  [math.floor(world.logic_values / 2)] = simple(1, function(creature) -- фотосинтезировать
    creature.energy = creature.energy +
      creature:photosyntesis() *
      (1 - world.sun.depth_degradation) ^ (creature.y - 1) * world.sun.power
  end),
  [math.floor(world.logic_values / 4)] = simple(2, function(creature, idx) -- плыть в сторону
    local arg = creature:gene(creature.memory.p + 1)

    local dir = directions[arg % 8 + 1]

    local next = {
      x = creature.x + dir[1],
      y = creature.y + dir[2]
    }

    if not (1 <= next.x and next.x <= world.w
    and 1 <= next.y and next.y <= world.h) then return end

    if not world:empty(next.x, next.y) then return end

    world:move(creature, next.x, next.y)
  end),
  [math.floor(world.logic_values * 3 / 4)] = logical(function(creature) -- проверить занятость клетки
    local arg = creature:gene(creature.memory.p + 1)

    local dir = directions[arg % 8 + 1]

    local next = {
      x = creature.x + dir[1],
      y = creature.y + dir[2]
    }

    local jump
    if world:empty(next.x, next.y) then
      jump = creature:gene(creature.memory.p + 2)
    else
      jump = creature:gene(creature.memory.p + 3)
    end
  end),
  [math.floor(world.logic_values / 8)] = simple(2, function(creature) -- атаковать в сторону
    local arg = creature:gene(creature.memory.p + 1)

    local dir = directions[arg % 8 + 1]

    local next = {
      x = creature.x + dir[1],
      y = creature.y + dir[2]
    }

    local tgt = world:find(next.x, next.y)
    if not tgt then return end

    local power = creature.energy * 0.1 * creature:melee()
    creature.energy = creature.energy + power / 4
    tgt.energy = tgt.energy - power
  end),
  [math.floor(world.logic_values * 3 / 8)] = logical(function(creature) -- сенсор глубины
    local s =0
    for i=1, world.logic_values do
      s = s + creature:gene(i)
    end
    if math.floor(s/world.logic_values)<creature.y then
      creature.memory.p=creature.memory.p+4
    else
      creature.memory.p=creature.memory.p+1
    end
  end),
  [math.floor(world.logic_values * 5 / 8)] = simple(1, function(obj) -- отдать энергию
    local obj_give_energy = obj.energy/16
    for _, dir in ipairs(directions) do
      local tgt = world:find(obj.x + dir[1], obj.y + dir[2])
      if tgt then
        tgt.energy = tgt.energy + obj_give_energy
        obj.energy = obj.energy - math.floor(obj.energy * 3/32)
      end
    end
  end),
  [math.floor(world.logic_values * 7 / 8)] = simple(1, function(obj) -- деление
    if obj.energy>512 then
      local free_cells = {}
      for _, dir in ipairs(directions) do
        if 1 <= obj.x + dir[1] and obj.x + dir[1] <= world.w
        and 1 <= obj.y + dir[2] and obj.y + dir[2] <= world.h then
          if world:empty(obj.x + dir[1], obj.y + dir[2]) then
            table.insert(free_cells, {obj.x + dir[1], obj.y + dir[2]})
          end
        end
      end
      if 1 <= #free_cells then
        local mutation = function(child)
          child.energy = obj.energy / 64
          obj.energy = obj.energy / 64

          local pos = free_cells[math.random(#free_cells)]
          child.x, child.y = pos[1], pos[2]

          for i = 1, child.memory:size() do
            if i == math.random(world.logic_values) then
              child.memory:set(i, math.random(world.logic_values))
              break
            end
          end
        end

        world:insert(obj:clone(mutation))
      end
    end
  end),
}

return actions
