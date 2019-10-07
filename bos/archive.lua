local ffi = require("ffi")
local zlib = require("ffi.zlib")
local dir = ffi.abi("win") and require("ffi.win.dir") or require("ffi.posix.dir")
local FileStream = require("stream.file_stream")
local GameLocator = require("bos.game_locator")
local timer = require("util.timer")

local ZIP_SIGNATURE = "\x50\x4b\x03\x04" -- 0x04034b50
local CORE_PATH = (GameLocator.getAbsolutePath() or "FalloutTactics") .. "/core"

local Archive = {}

local function getArchiveContentInfo(pathToArchive)
  local stream = FileStream.open(pathToArchive)
  local archiveMap = {}

  while stream:read(4) == ZIP_SIGNATURE do
    stream:skip(2 + 2) -- skip version, skip flags

    local compressionMethod = stream:readUshort()

    stream:skip(2 + 2 + 4) -- skip mod time, mod date, crc32

    local compressedSize = stream:readUint()
    local originalSize = stream:readUint()
    local filePathLength = stream:readUshort()
    local extraFieldLength = stream:readUshort()
    local filePath = stream:read(filePathLength)

    if extraFieldLength > 0 then
      stream:skip(extraFieldLength) -- skip extra field
    end

    if compressedSize > 0 then
      local offsetOfRawData = stream:tell()

      stream:skip(compressedSize) -- skip compressed data

      archiveMap[filePath] = {
        pathToArchive = pathToArchive,
        compressionMethod = compressionMethod,
        compressedSize = compressedSize,
        originalSize = originalSize,
        offsetOfRawData = offsetOfRawData
      }
    end
  end

  stream:close()

  return archiveMap
end

local function getArchives()
  local archiveList = {}

  for _, path in pairs(dir.list(CORE_PATH)) do
    if path:sub(-4) == ".bos" then
      table.insert(archiveList, CORE_PATH .. "/" .. path)
    end
  end

  assert(#archiveList > 0, "could not find .bos archives")

  return archiveList
end

local allArchivedFiles

function Archive.build()
  timer.start("explore")

  allArchivedFiles = {}

  for _, archivePath in pairs(getArchives()) do
    for filePath, fileMeta in pairs(getArchiveContentInfo(archivePath)) do
      allArchivedFiles[filePath] = fileMeta
    end
  end

  timer.finish("explore")
end

function Archive.stream(filePath)
  local fileMeta = allArchivedFiles[filePath]

  if not fileMeta then
    error("could not find archived file: " .. filePath)
  end

  local stream = FileStream.open(fileMeta.pathToArchive)

  stream:seek(fileMeta.offsetOfRawData)

  return stream, fileMeta.compressedSize
end

return Archive
