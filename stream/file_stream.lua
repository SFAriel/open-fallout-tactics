local Object = require("lib.classic")
local ffi = require("ffi")
local ffiTypes = require("ffi.types")
local ByteData = require("stream.byte_data")
local File = ffi.abi("win") and require("ffi.win.file") or require("ffi.posix.file")

local FileStream = Object:extend()

function FileStream:new(path, mode)
  self.file = File.open(path, mode)
end

function FileStream.open(path, mode)
  return FileStream(path, mode)
end

function FileStream:getSize()
  if self.size then
    return self.size
  end

  local position = self.file:tell()

  self.file:seek("end")

  self.size = self.file:tell()

  self.file:seek("set", position)

  return self.size
end

function FileStream:tell()
  return self.file:tell()
end

function FileStream:seek(position)
  self.file:seek("set", position)
end

function FileStream:close()
  self.file:close()
end

function FileStream:skip(bytesToSkip)
  self.file:seek("cur", bytesToSkip)
end

local function getValidLengthToRead(self, length)
  local pos = self:tell()

  if pos + length > self:getSize() then
    length = self:getSize() - pos
  end

  if length < 1 then
    error("tried to read " .. length .. " bytes")
  end

  return length
end

function FileStream:readByteData(length)
  length = getValidLengthToRead(self, length)

  return ByteData.fromBuffer(self.file:read(ffiTypes.array.uint8_t(length), length))
end

function FileStream:readBuffer(length)
  length = getValidLengthToRead(self, length)

  return self.file:read(ffiTypes.array.uint8_t(length), length)
end

function FileStream:read(length)
  return ffi.string(self:readBuffer(length))
end

local elementReaders = {
  readByte = "uint8_t",
  readUint = "uint32_t",
  readUshort = "uint16_t",
  readShort = "int16_t"
}

for funcName, cType in pairs(elementReaders) do
  local persistentBuffer = ffi.new(cType .. "[1]")
  local elementSize = ffi.sizeof(persistentBuffer)

  local function reader(self)
    local buffer, length = self.file:read(persistentBuffer, 1, elementSize)

    return length > 0 and buffer[0] or nil
  end

  FileStream[funcName] = reader
end

function FileStream:expectSignature(signature)
  local actual = self:read(#signature)

  if actual ~= signature then
    error("expected signature: " .. signature)
  end
end

return FileStream
