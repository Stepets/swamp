local world = {
  size = {},
  w = 250,
  h = 100,
  objects = {},
  object_count = 0,
  move = function(self, creature, x, y)
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
    power = 20,
    depth_degradation = 0.2,
  },
  heat = {
    power = 5,
    depth_degradation = 0.05,
  },
  energy = {
    limit = 1500,
    degradation = 1,
  },
  logic_values = 64,
}

return world
