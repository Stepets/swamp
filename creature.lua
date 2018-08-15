local creature = {}

local memory = require "memory"
local world = require "world"
local util = require "util"

function creature.new()
  local obj = {
    x = math.random(world.w),
    y = math.random(world.h),
    energy = world.energy.limit / 2,
    memory = memory.new(world.logic_values),
  }
  return setmetatable(obj, {__index = creature})
end

function creature:photosyntesis()
  return self:gene(1) / world.logic_values
end

function creature:melee()
  return self:gene(math.floor(world.logic_values / 2)) / world.logic_values
end

function creature:gene(idx)
  if idx > world.logic_values then
    return self.memory:get(idx % world.logic_values + 1)
  else
    return self.memory:get(idx)
  end
end

function creature:clone(mutator)
  local clone = setmetatable(util.deep_copy(self), {__index = creature})
  clone.memory = self.memory:copy()
  if mutator then
    mutator(clone)
  end
  return clone
end

return creature
