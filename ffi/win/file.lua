local ffi = require("ffi")
local Object = require("lib.classic")

ffi.cdef [[
typedef struct FILE_ FILE;

enum {
  SEEK_SET = 0,
  SEEK_CUR = 1,
  SEEK_END = 2
};

FILE* fopen (const char*, const char*);
size_t fread (void*, size_t, size_t, FILE*);
int fseek (FILE*, long, int);
long ftell (FILE*);
int fclose (FILE*);
int ferror (FILE*);
char *strerror(int);
]]

local function getSpecificError(code)
  return ffi.string(ffi.C.strerror(code))
end

local function getLastError()
  return getSpecificError(ffi.errno())
end

local File = Object:extend()

function File.open(path, mode)
  return File(path, mode or "rb")
end

function File:new(path, mode)
  self.handle = ffi.C.fopen(path, mode)

  if not self.handle then
    error("fopen(): " .. getLastError())
  end
end

function File:close()
  ffi.C.fclose(self.handle)
end

function File:tell()
  return tonumber(ffi.C.ftell(self.handle))
end

local seekModes = {
  set = ffi.C.SEEK_SET,
  cur = ffi.C.SEEK_CUR,
  ["end"] = ffi.C.SEEK_END
}

function File:seek(mode, position)
  if not seekModes[mode] then
    error("fseek(): expected valid seek mode, got " .. tostring(mode))
  end

  local errorCode = ffi.C.fseek(self.handle, position or 0, seekModes[mode])

  if errorCode ~= 0 then
    error("fseek(): " .. getLastError())
  end
end

function File:read(buffer, bufferSize, elementSize)
  local actualLength = ffi.C.fread(buffer, elementSize or 1, bufferSize, self.handle)
  local errorCode = ffi.C.ferror(self.handle)

  if errorCode ~= 0 then
    getSpecificError(errorCode)
  end

  return buffer, tonumber(actualLength)
end

return File
