local Object = require("lib.classic")

local Cache = Object:extend()

function Cache:new(getter, mode)
  self.getter = getter
  self.container = setmetatable({}, {
    __mode = mode
  })
end

function Cache.weakValues(getter)
  return Cache(getter, "v")
end

function Cache:get(key)
  local value = self.container[key]

  if value == nil then
    value = self.getter(key)

    assert(value ~= nil, "unexpected nil from getter in cache")

    self.container[key] = value
  end

  return value
end

return Cache
