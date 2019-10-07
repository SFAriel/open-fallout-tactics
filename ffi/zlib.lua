local ffi = require("ffi")

ffi.cdef [[
const char* zlibVersion();
const char* zError(int);

int uncompress(uint8_t *dest, unsigned long *destLen, const uint8_t *source, unsigned long sourceLen);
]]

local ffiZlib = ffi.load(ffi.abi("win") and (ffi.abi("64bit") and "zlib123_x64" or "zlib123") or "z")

local Z_OK = 0

local zlib = {}

function zlib.version()
  return ffi.string(ffiZlib.zlibVersion())
end

local function translateErrorCode(err)
  return ffi.string(ffiZlib.zError(err))
end

local uint8Array = ffi.typeof("uint8_t[?]")
local lengthBuffer = ffi.new("unsigned long[1]")

function zlib.uncompress(pointer, size, originalLength)
  local buffer = uint8Array(originalLength)

  lengthBuffer[0] = originalLength

  local returnCode = ffiZlib.uncompress(buffer, lengthBuffer, pointer, size)

  if returnCode ~= Z_OK then
    return false, translateErrorCode(returnCode)
  end

  return buffer, lengthBuffer[0]
end

return zlib
