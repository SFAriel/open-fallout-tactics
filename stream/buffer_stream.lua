local Object = require("lib.classic")
local ffi = require("ffi")
local ffiTypes = require("ffi.types")

local BufferStream = Object:extend()

function BufferStream:new(pointer, size)
  self.pointer = pointer
  self.size = size
  self.position = 0
end

function BufferStream.fromPointerWrapper(object)
  return BufferStream(object.pointer, object.size)
end

function BufferStream:getSize()
  return self.size
end

function BufferStream:tell()
  return self.position
end

function BufferStream:seek(position)
  if position < 0 or position >= self.size then
    return false
  end

  self.position = position

  return true
end

function BufferStream:close()
  self.position = -1
  self.pointer = nil
  self.size = 0
end

function BufferStream:skip(bytesToSkip)
  return self:seek(self.position + bytesToSkip)
end

function BufferStream:read(length)
  if length == "all" then
    length = self.size
  end

  if length <= 0 then
    error("tried to read an invalid number of bytes: " .. length)
  end

  if self.position + length > self.size then
    length = self.size - self.position
  end

  local value = ffi.string(self.pointer + self.position, length)

  self.position = self.position + length

  return value, length
end

function BufferStream:readByte()
  local value = self.pointer[self.position]

  self.position = self.position + 1

  return value
end

local uint32_t = ffiTypes.pointer.uint32_t

function BufferStream:readUint()
  local value = ffi.cast(uint32_t, self.pointer + self.position)[0]

  self.position = self.position + 4

  return value
end

local uint16_t = ffiTypes.pointer.uint16_t

function BufferStream:readUshort()
  local value = ffi.cast(uint16_t, self.pointer + self.position)[0]

  self.position = self.position + 2

  return value
end

function BufferStream:expectSignature(signature)
  local actual = self:read(#signature)

  if actual ~= signature then
    print(actual)
    print(actual:byte(1, #actual))
    error("expected signature: " .. signature)
  end
end

return BufferStream
