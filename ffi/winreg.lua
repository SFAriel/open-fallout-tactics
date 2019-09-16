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

local HIVE = {
  HKEY_LOCAL_MACHINE = ffi.cast(HKEY, ffi.cast("uintptr_t", 0x80000002))
}

local ACCESS_TYPE = {
  KEY_READ = 0x20019
}

local VALUE_TYPES = {
  REG_SZ = 1
}

local ERROR_CODE = {
  SUCCESS = 0,
  FILE_NOT_FOUND = 2,
  MORE_DATA = 234
}

local ERROR_MESSAGE = {
  [ERROR_CODE.FILE_NOT_FOUND] = "could not find registry key",
  [ERROR_CODE.MORE_DATA] = "could not fit result into allocated buffer"
}

local function getError(code)
  if ERROR_MESSAGE[code] then
    return ERROR_MESSAGE[code]
  end

  return "error code " .. code
end

local function RegOpenKeyExA(handle, keyPath, options, accessMask)
  local keyHandle = HKEY_BUFFER()
  local result = advapi32.RegOpenKeyExA(handle, keyPath, 0, ACCESS_TYPE.KEY_READ, keyHandle)

  if result ~= ERROR_CODE.SUCCESS then
    return false, "RegOpenKeyExA failed, " .. getError(result)
  end

  return keyHandle[0]
end

local conversions = {
  [VALUE_TYPES.REG_SZ] = function(pointer, size)
    return ffi.string(pointer, size - 1) -- ignore terminating null
  end
}

local function convertRegistryValue(pointer, size, typeOfValue)
  local converter = conversions[typeOfValue]

  if not converter then
    error("no conversion found for " .. typeOfValue)
  end

  return converter(pointer, size)
end

local function RegQueryValueExA(handle, key, resultBufferSize)
  local typeOfValue = DWORD_BUFFER()
  local valueBuffer = LPBYTE_ARRAY(resultBufferSize)
  local valuePointer = ffi.cast(LPBYTE, valueBuffer)
  local bufferSize = DWORD_BUFFER()

  bufferSize[0] = resultBufferSize

  local result = advapi32.RegQueryValueExA(handle, key, nil, typeOfValue, valuePointer, bufferSize)

  if result ~= ERROR_CODE.SUCCESS then
    return false, "RegQueryValueExA failed, " .. getError(result)
  end

  return convertRegistryValue(valuePointer, bufferSize[0], typeOfValue[0])
end

local function RegCloseKey(handle)
  local result = advapi32.RegCloseKey(handle)

  if result ~= ERROR_CODE.SUCCESS then
    return false, "RegCloseKey failed, " .. getError(result)
  end
end

local function getHandleAndKeyPath(fullPath)
  local hiveName, keyPath = fullPath:match("([%a_]-)\\(.*)")
  local handle = HIVE[hiveName]

  if not handle then
    error("hive not found: " .. hiveName)
  end

  return handle, keyPath
end

local WindowsRegistry = {}

function WindowsRegistry.queryKey(fullPath, key, resultBufferSize)
  resultBufferSize = resultBufferSize or 1024

  local handle, keyPath = getHandleAndKeyPath(fullPath)
  local keyHandle, err = RegOpenKeyExA(handle, keyPath, 0, ACCESS_TYPE.KEY_READ)

  if err then
    return false, err
  end

  local value, err = RegQueryValueExA(keyHandle, key, resultBufferSize)

  RegCloseKey(keyHandle)

  if err then
    return false, err
  end

  return value
end

return WindowsRegistry
