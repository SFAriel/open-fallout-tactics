local timer = {}
local activeTimers = {}
local getTime = love.timer.getTime

function timer.start(key)
  if activeTimers[key] then
    error("timer already exists: " .. key)
  end

  activeTimers[key] = getTime()
end

function timer.finish(key)
  if not activeTimers[key] then
    error("timer does not exist: " .. key)
  end

  local now = getTime()
  local start = activeTimers[key]

  activeTimers[key] = nil

  print("timer [" .. key .. "]: " .. string.format("%.3fms", (now - start) * 1000))
end

return timer
