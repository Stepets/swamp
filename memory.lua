local ffi = require "ffi"
local memory = {}

function memory.new(size)
  local mem = setmetatable({
    p = 1,
    data = love.data.newByteData((size+1) * 4)
  }, {__index = memory})
  mem.ptr = ffi.cast("uint32_t*", mem.data:getPointer())
  return mem
end

function memory:size()
  return self.data:getSize()/4 - 1
end

function memory:get(idx)
  return self.ptr[idx]
end

function memory:set(idx, val)
  self.ptr[idx] = val
end

function memory:copy()
  local mem = memory.new(self:size())
  ffi.copy(mem.ptr, self.ptr, self.data:getSize())
  return mem
end

return memory
