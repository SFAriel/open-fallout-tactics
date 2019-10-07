local Object = require("lib.classic")

local File = Object:extend()

function File.open(path, mode)
  return File(path, mode or "rb")
end

function File:new(path, mode)
  error("not implemented")
end

function File:close()
  error("not implemented")
end

function File:tell()
  error("not implemented")
end

function File:seek(mode, position)
  error("not implemented")
end

function File:read(buffer, bufferSize, elementSize)
  error("not implemented")
end

return File
