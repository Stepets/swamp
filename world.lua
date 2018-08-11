local function binsearch(tbl, cmp, l, r)
  l = l or 0
  r = r or #tbl

  if r - 1 <= l then return l end

  local mid = math.floor((l + r) / 2)
  if cmp(tbl[mid]) then
    l = mid
  else
    r = mid
  end
  return binsearch(tbl, cmp, l, r)
end

local world = {
  w = 250,
  h = 100,
  objects = {},
  find = function(self, x, y)
    local idx = binsearch(self.objects, function(o) return o.x < x end) + 1
    while self.objects[idx] and self.objects[idx].x <= x do
      if self.objects[idx].x == x and self.objects[idx].y == y then return self.objects[idx] end
      idx = idx + 1
    end
    return nil
    -- for idx = 1, #self do
    --   if self[idx].x == x and self[idx].y == y then return self[idx] end
    -- end
  end,
  empty = function(self, x, y)
    return self:find(x, y) == nil
  end,
  sort = function(self)
    table.sort(self.objects, function(o1, o2) return o1.x < o2.x and o1.y < o2.y end)
  end,
  insert = function(self, obj)
    local idx = binsearch(self.objects, function(o) return o.x < obj.x end) + 1
    while self.objects[idx] and self.objects[idx].x <= obj.x and self.objects[idx].y <= obj.y do
      idx = idx + 1
    end
    table.insert(self.objects, idx, obj)
  end,
  sun = {
    power = 100,
    depth_degradation = 0.1,
  },
  heat = {
    power = 2,
    depth_degradation = 0.05,
  },
  energy = {
    limit = 1000,
    degradation = 1,
  },
  logic_values = 128,
}

local directions = {
  {-1,-1}, {0,-1}, {1,-1},
  {-1, 0}, --[[{0, 0},]] {1, 0},
  {-1, 1}, {0, 1}, {1, 1},
}

local actions
actions = {
  [math.floor(world.logic_values / 2)] = function(creature) -- фотосинтезировать
    creature.memory.p = creature.memory.p + 1
    creature.energy = creature.energy +
      photosyntesis(creature) *
      (1 - world.sun.depth_degradation) ^ (creature.y - 1) * world.sun.power
  end,
  [math.floor(world.logic_values / 4)] = function(creature, idx) -- плыть в сторону
    local arg = gene(creature.memory, creature.memory.p + 1)
    creature.memory.p = creature.memory.p + 2

    local dir = directions[arg % 8 + 1]

    local next = {
      x = creature.x + dir[1],
      y = creature.y + dir[2]
    }

    if not (1 <= next.x and next.x <= world.w
    and 1 <= next.y and next.y <= world.h) then return end

    if not world:empty(next.x, next.y) then return end

    creature.x = next.x
    creature.y = next.y
  end,
  [math.floor(world.logic_values * 3 / 4)] = function(creature) -- проверить занятость клетки
    creature.memory.count = creature.memory.count or 0
    if 64 < creature.memory.count then
      creature.memory.p = creature.memory.p + 1
      return
    end

    local arg = gene(creature.memory, creature.memory.p + 1)

    local dir = directions[arg % 8 + 1]

    local next = {
      x = creature.x + dir[1],
      y = creature.y + dir[2]
    }

    creature.memory.count = creature.memory.count + 1
    local jump
    if world:empty(next.x, next.y) then
      jump = gene(creature.memory, creature.memory.p + 2)
    else
      jump = gene(creature.memory, creature.memory.p + 3)
    end
    creature.memory.p = creature.memory.p + jump
    local action = actions[gene(creature.memory, creature.memory.p + 4)]
    if action then action(creature) end
  end,
  [math.floor(world.logic_values / 8)] = function(creature) -- атаковать в сторону
    local arg = gene(creature.memory, creature.memory.p + 1)
    creature.memory.p = creature.memory.p + 2

    local dir = directions[arg % 8 + 1]

    local next = {
      x = creature.x + dir[1],
      y = creature.y + dir[2]
    }

    local tgt = world:find(next.x, next.y)
    if not tgt then return end

    local power = creature.energy * 0.1 * melee(creature)
    creature.energy = creature.energy + power / 4
    tgt.energy = tgt.energy - power
  end,
  [math.floor(world.logic_values * 3 / 8)] = function(creature) -- сравнить две последовательности
    creature.memory.count = creature.memory.count or 0
    if 64 < creature.memory.count then
      creature.memory.p = creature.memory.p + 1
      return
    end
    local len = gene(creature.memory, creature.memory.p + 1)
    local dir = gene(creature.memory, creature.memory.p + 2)
    local data = gene(creature.memory, creature.memory.p + 3)
    local jump_true = gene(creature.memory, creature.memory.p + 2)
    local jump_false = gene(creature.memory, creature.memory.p + 2)

    local equals = true
    for i = 1, len do
      if gene(creature.memory, data1 + i) ~= gene(creature.memory, data2 + i) then
        equals = false
        break
      end
    end

    if equals then
      creature.memory.p = creature.memory.p + jump_true
    else
      creature.memory.p = creature.memory.p + jump_false
    end

    creature.memory.count = creature.memory.count + 1
    local action = actions[gene(creature.memory, creature.memory.p)]
    if action then action(creature) end
  end,
}

photosyntesis = function(self)
  return gene(self.memory, 1) / world.logic_values
end

melee = function(self)
  return gene(self.memory, math.floor(world.logic_values / 2)) / world.logic_values
end

gene = function(mem, idx)
  if idx > world.logic_values then
    return mem:get(idx % world.logic_values + 1)
  else
    return mem:get(idx)
  end
end

return {
  world = world,
  actions = actions,
  directions = directions,
}
