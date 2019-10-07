local ffi = require("ffi")

pcall(ffi.cdef, [[
  #pragma pack(push)
  #pragma pack(1)
  struct WIN32_FIND_DATAW {
    uint32_t dwFileAttributes;
    uint64_t ftCreationTime;
    uint64_t ftLastAccessTime;
    uint64_t ftLastWriteTime;
    uint32_t dwReserved[4];
    char cFileName[520];
    char cAlternateFileName[28];
  };
  #pragma pack(pop)

  void* FindFirstFileW(const char* pattern, struct WIN32_FIND_DATAW* fd);
  bool FindNextFileW(void* ff, struct WIN32_FIND_DATAW* fd);
  bool FindClose(void* ff);

  int MultiByteToWideChar(unsigned int CodePage, uint32_t dwFlags, const char* lpMultiByteStr,
    int cbMultiByte, const char* lpWideCharStr, int cchWideChar);
  int WideCharToMultiByte(unsigned int CodePage, uint32_t dwFlags, const char* lpWideCharStr,
    int cchWideChar, const char* lpMultiByteStr, int cchMultiByte,
    const char* default, int* used);
]])

local UTF8_CODEPAGE_ID = 65001
local WIN32_FIND_DATA = ffi.typeof("struct WIN32_FIND_DATAW")
local INVALID_HANDLE = ffi.cast("void *", -1)

local VarChar = ffi.typeof("char[?]")

local function stringToWideString(str, code)
  code = code or UTF8_CODEPAGE_ID

  local size = ffi.C.MultiByteToWideChar(code, 0, str, #str, nil, 0)
  local bufferSize = size * 2
  local buffer = VarChar(bufferSize + 2) -- null characters

  ffi.C.MultiByteToWideChar(code, 0, str, #str, buffer, bufferSize)

  return buffer
end

local function wideStringToString(wstr, code)
  code = code or UTF8_CODEPAGE_ID

  local size = ffi.C.WideCharToMultiByte(code, 0, wstr, -1, nil, 0, nil, nil)
  local buffer = VarChar(size + 1) -- null character

  size = ffi.C.WideCharToMultiByte(code, 0, wstr, -1, buffer, size, nil, nil)

  return ffi.string(buffer, size - 1)
end

local FILE_ATTRIBUTE_ARCHIVE = 32
local FILE_ATTRIBUTE_DIRECTORY = 16
local FILE_ATTRIBUTE_READONLY = 1

local function isDirectory(findData)
  return findData.dwFileAttributes == FILE_ATTRIBUTE_DIRECTORY or
         findData.dwFileAttributes == FILE_ATTRIBUTE_DIRECTORY + FILE_ATTRIBUTE_READONLY
end

local function isFile(findData)
  return findData.dwFileAttributes == FILE_ATTRIBUTE_ARCHIVE
end

local function normalizePath(path)
  return path:gsub("/", "\\")
end

local dir = {}

function dir.list(absolutePath)
  local items = {}
  local findData = ffi.new(WIN32_FIND_DATA)
  local fileHandle = ffi.C.FindFirstFileW(stringToWideString(normalizePath(absolutePath) .. "\\*"), findData)

  ffi.gc(fileHandle, ffi.C.FindClose)

  if fileHandle ~= INVALID_HANDLE then
    repeat
      if isDirectory(findData) or isFile(findData) then
        local name = wideStringToString(findData.cFileName)

        if name ~= "." and name ~= ".." then
          table.insert(items, name)
        end
      end
    until not ffi.C.FindNextFileW(fileHandle, findData)
  end

  ffi.C.FindClose(ffi.gc(fileHandle, nil))

  return items
end

return dir
