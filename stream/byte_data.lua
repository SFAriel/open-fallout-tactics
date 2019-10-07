local Object = require("lib.classic")

local ByteData = Object:extend()

function ByteData:new(pointer, size)
  self.pointer = pointer
  self.size = size
end

function ByteData.fromBuffer(buffer, size)
  local byteData = ByteData(buffer + 0, size)

  byteData.reference = buffer

  return byteData
end

function ByteData:getPointer()
  return self.pointer
end

function ByteData:getSize()
  return self.size
end

return ByteData
