local ffi = require("ffi")

pcall(ffi.cdef, [[
typedef unsigned char BYTE;
typedef long LONG;
typedef unsigned long DWORD;
typedef DWORD ACCESS_MASK;
typedef const char * LPCSTR;
typedef DWORD * LPDWORD;
typedef BYTE * LPBYTE;

typedef LONG LSTATUS;
typedef void * HKEY;
typedef HKEY * PHKEY;
typedef const char * LPCSTR;
typedef ACCESS_MASK REGSAM;

LSTATUS RegOpenKeyExA (
  HKEY hKey,
  LPCSTR lpSubKey,
  DWORD ulOptions,
  REGSAM samDesired,
  PHKEY phkResult
);

LSTATUS RegQueryValueExA (
  HKEY    hKey,
  LPCSTR  lpValueName,
  LPDWORD lpReserved,
  LPDWORD lpType,
  LPBYTE  lpData,
  LPDWORD lpcbData
);

LSTATUS RegCloseKey (HKEY hKey);
]])

local advapi32 = ffi.load("advapi32")

local HKEY = ffi.typeof("HKEY")
local HKEY_BUFFER = ffi.typeof("HKEY[1]")
local DWORD_BUFFER = ffi.typeof("DWORD[1]")
local LPBYTE = ffi.typeof("LPBYTE")
local LPBYTE_ARRAY = ffi.typeof("LPBYTE[?]")

local HKEY_LOCAL_MACHINE = ffi.cast(HKEY, ffi.cast("uintptr_t", 0x80000002))
local KEY_READ = 0x20019

local WindowsRegistry = {}

WindowsRegistry.HKEY_LOCAL_MACHINE = HKEY_LOCAL_MACHINE

local function RegOpenKeyExA(handle, keyPath, options, accessMask)
  local keyHandle = HKEY_BUFFER()
  local result = advapi32.RegOpenKeyExA(handle, keyPath, 0, KEY_READ, keyHandle)

  assert(result == 0, "Something went wrong in RegOpenKeyExA")

  return keyHandle[0]
end

local function RegQueryValueExA(handle, key, resultBufferSize)
  local typeOf = DWORD_BUFFER()
  local valueBuffer = LPBYTE_ARRAY(resultBufferSize)
  local valuePointer = ffi.cast(LPBYTE, valueBuffer)
  local bufferSize = DWORD_BUFFER()

  bufferSize[0] = resultBufferSize

  local result = advapi32.RegQueryValueExA(handle, key, nil, typeOf, valuePointer, bufferSize)

  assert(result == 0, "Something went wrong in RegQueryValueExA")

  return valuePointer, bufferSize[0], typeOf[0]
end

local function RegCloseKey(handle)
  local result = advapi32.RegCloseKey(handle)

  assert(result == 0, "Something went wrong in RegCloseKey")
end

function WindowsRegistry.queryKey(handle, keyPath, key, resultBufferSize)
  resultBufferSize = resultBufferSize or 1024

  local keyHandle = RegOpenKeyExA(handle, keyPath, 0, KEY_READ)
  local valuePointer, valueSize = RegQueryValueExA(keyHandle, key, resultBufferSize)

  RegCloseKey(keyHandle)

  return ffi.string(valuePointer, valueSize)
end

return WindowsRegistry
