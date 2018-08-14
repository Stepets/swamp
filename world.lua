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
  size={},
  w = 250,
  h = 100,
  objects = {},
  object_count = 0,
  move = function(self,creature, x, y)
    self.size[x][y], self.size[creature.x][creature.y] = creature, nil
    creature.x, creature.y= x, y
  end,
  death = function (self, obj)
    self.size[obj.x][obj.y] = nil
    self.objects[obj]=nil
    self.object_count = self.object_count - 1
  end,
  find = function(self, x, y)
    return self.size[x] and self.size[x][y]
  end,
  empty = function(self, x, y)
    return self:find(x, y) == nil
  end,
  insert = function(self, obj)
    self.size[obj.x][obj.y]=obj
    self.objects[obj] = obj
    self.object_count = self.object_count + 1
  end,
  sun = {
    power = 15,
    depth_degradation = 0.2,
  },
  heat = {
    power = 4,
    depth_degradation = 0.1,
  },
  energy = {
    limit = 1500,
    degradation = 1,
  },
  logic_values = 64,
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

    world:move(creature, next.x, next.y)
  end,
  [math.floor(world.logic_values * 3 / 4)] = function(creature) -- проверить занятость клетки
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
    local action = actions[gene(creature.memory, creature.memory.p)]
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
  [math.floor(world.logic_values * 3 / 8)] = function(creature) -- сенсор глубины
    if 64 < creature.memory.count then
      creature.memory.p = creature.memory.p + 1
      return
    end
    local s =0
    for i=1, world.logic_values do
      s=s+gene(creature.memory, i)
    end
    if math.floor(s/world.logic_values)<creature.y then
      creature.memory.p=creature.memory.p+4
    else
      creature.memory.p=creature.memory.p+1
    end
  end,
  [math.floor(world.logic_values * 5 / 8)] = function(obj) -- отдать энергию
    local obj_give_energy = obj.energy/16
    local obj_l_u, obj_c_u, obj_r_u = world:find(obj.x-1,obj.y+1), world:find(obj.x, obj.y+1), world:find(obj.x+1, obj.y+1)
    local obj_l_c, obj_r_c = world:find(obj.x-1,obj.y), world:find(obj.x+1, obj.y)
    local obj_l_d, obj_c_d, obj_r_d = world:find(obj.x-1,obj.y-1), world:find(obj.x, obj.y-1), world:find(obj.x+1, obj.y-1)
    if obj_l_u then
      obj_l_u.energy = obj_l_u.energy+ obj_give_energy
      obj.energy=obj.energy-math.floor(obj.energy*120/128)
    end
    if obj_c_u then
      obj_c_u.energy = obj_c_u.energy+ obj_give_energy
      obj.energy=obj.energy-math.floor(obj.energy*120/128)
    end
    if obj_r_u then
      obj_r_u.energy = obj_r_u.energy+ obj_give_energy
      obj.energy=obj.energy-math.floor(obj.energy*120/128)
    end
    if obj_l_c then
      obj_l_c.energy = obj_l_c.energy+ obj_give_energy
      obj.energy=obj.energy-math.floor(obj.energy*120/128)
    end
    if obj_r_c then
      obj_r_c.energy = obj_r_c.energy+ obj_give_energy
      obj.energy=obj.energy-math.floor(obj.energy*120/128)
    end
    if obj_r_d then
      obj_r_d.energy = obj_r_d.energy+ obj_give_energy
      obj.energy=obj.energy-math.floor(obj.energy*120/128)
    end
    if obj_c_d then
      obj_c_d.energy = obj_c_d.energy+ obj_give_energy
      obj.energy=obj.energy-math.floor(obj.energy*120/128)
    end
    if obj_l_d then
      obj_l_d.energy = obj_l_d.energy+ obj_give_energy
      obj.energy=obj.energy-math.floor(obj.energy*120/128)
    end
    obj.memory.p=obj.memory.p+1
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
