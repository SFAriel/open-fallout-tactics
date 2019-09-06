local Object = require("lib.classic")
local ffi = require("ffi")
local ffiTypes = require("ffi.types")

local FileStream = Object:extend()

function FileStream:new(file)
  self.file = file
end

function FileStream.open(path, mode)
  local file = assert(love.filesystem.newFile(path, mode or "r"))

  return FileStream(file)
end

function FileStream:getSize()
  return self.file:getSize()
end

function FileStream:tell()
  return self.file:tell()
end

function FileStream:seek(position)
  return self.file:seek(position)
end

function FileStream:close()
  self.file:close()
end

function FileStream:skip(bytesToSkip)
  return self.file:seek(self.file:tell() + bytesToSkip)
end

function FileStream:read(length)
  return self.file:read(length)
end

function FileStream:readByteData(length)
  return self.file:read("data", length)
end

local uint8_t = ffiTypes.pointer.uint8_t

function FileStream:readByte()
  local byteData = self.file:read("data", 1)

  return uint8_t(byteData:getPointer())[0]
end

local uint32_t = ffiTypes.pointer.uint32_t

function FileStream:readUint()
  local byteData = self.file:read("data", 4)

  return ffi.cast(uint32_t, byteData:getPointer())[0]
end

local uint16_t = ffiTypes.pointer.uint16_t

function FileStream:readUshort()
  local byteData = self.file:read("data", 2)

  return ffi.cast(uint16_t, byteData:getPointer())[0]
end

local int16_t = ffiTypes.pointer.int16_t

function FileStream:readShort()
  local byteData = self.file:read("data", 2)

  return ffi.cast(int16_t, byteData:getPointer())[0]
end

function FileStream:expectSignature(signature)
  local actual = self:read(#signature)

  if actual ~= signature then
    error("expected signature: " .. signature)
  end
end

return FileStream
