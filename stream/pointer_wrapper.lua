local Object = require("lib.classic")
local ffiTypes = require("ffi.types")

local PointerWrapper = Object:extend()

function PointerWrapper:new(pointer, size, reference)
  self.pointer = pointer
  self.size = size
  self.reference = reference
end

function PointerWrapper.fromFFIArray(array, size)
  return PointerWrapper(array + 0, size, array)
end

local uint8_t = ffiTypes.pointer.uint8_t

function PointerWrapper.fromByteData(byteData)
  return PointerWrapper(uint8_t(byteData:getPointer()), byteData:getSize(), byteData)
end

return PointerWrapper
