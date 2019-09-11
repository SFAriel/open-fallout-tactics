local bit = require("bit")
local ffi = require("ffi")
local ffiTypes = require("ffi.types")
local zlib = require("ffi.zlib")
local PointerWrapper = require("stream.pointer_wrapper")
local BufferStream = require("stream.buffer_stream")
local Object = require("lib.classic")
local Cache = require("util.cache")
local timer = require("util.timer")
local BOSArchive = require("bos.archive")
local spriteEvents = require("sprite.event").constants

local Sprite = Object:extend()

local function worldToScreen(x, y, z)
  return 6 * (y - x), 3 * (y + x) - 7 * (z or 0)
end

local function frameParameterCount(id)
  if id == spriteEvents.stop_anim or id == spriteEvents.jump_to_frame or id == spriteEvents.time_of_display then
    return 1
  elseif id == spriteEvents.fire then
    return 3
  end
end

local BytePointer = ffiTypes.pointer.uint8_t
local ByteArray = ffiTypes.array.uint8_t

local function loadPalette(stream)
  local colorCount = stream:readUint()
  local paletteSize = colorCount * 3
  local palette = ByteArray(paletteSize)

  for colorId = 0, paletteSize - 1, 3 do
    palette[colorId + 2] = stream:readByte()
    palette[colorId + 1] = stream:readByte()
    palette[colorId] = stream:readByte()

    stream:skip(1)
  end

  return palette
end

local function loadPackedTexture(stream, palette)
  stream:expectSignature("<zar>\0")

  local zarType = stream:readByte()

  stream:skip(1)

  local width = stream:readUint()
  local height = stream:readUint()

  local image = love.image.newImageData(width, height)
  local imagePointer = ffi.cast(BytePointer, image:getPointer())
  local imagePointerOffset = 0

  local hasPalette = stream:readByte() == 1

  if hasPalette and not palette then
    palette = loadPalette(stream)
  end

  local encodedDataSize = stream:readUint()
  local paletteRef = ffi.cast(BytePointer, palette)
  local defaultColor

  if hasPalette and (zarType == 34 or zarType == 33) then
    local colorId = bit.band(encodedDataSize, 255)
    defaultColor = paletteRef + colorId * 4
  else
    defaultColor = paletteRef
  end

  local pixelCountTotal = width * height
  local pixelsProcessed = 0

  while pixelsProcessed < pixelCountTotal do
    local commandByte = stream.pointer[stream.position]
    local command = bit.band(commandByte, 3)
    local pixelCount = bit.rshift(commandByte, 2)

    stream.position = stream.position + 1

    if command == 0 then
      imagePointerOffset = imagePointerOffset + pixelCount * 4
    elseif command == 1 then
      local bufMax = (pixelCount > 127) and 127 or pixelCount - 1

      for n = 0, bufMax do
        local colorId = stream.pointer[stream.position + n] * 3

        ffi.copy(imagePointer + imagePointerOffset, paletteRef + colorId, 3)

        imagePointer[imagePointerOffset + 3] = 255
        imagePointerOffset = imagePointerOffset + 4
      end

      stream.position = stream.position + pixelCount
    elseif command == 2 then
      local bufMax = (pixelCount > 127) and 127 or pixelCount - 1

      for n = 0, bufMax do
        local pos = stream.position + n * 2
        local colorId = stream.pointer[pos] * 3
        local alpha = stream.pointer[pos + 1]

        ffi.copy(imagePointer + imagePointerOffset, paletteRef + colorId, 3)

        imagePointer[imagePointerOffset + 3] = alpha
        imagePointerOffset = imagePointerOffset + 4
      end

      stream.position = stream.position + pixelCount * 2
    else
      local bufMax = (pixelCount > 127) and 127 or pixelCount - 1

      for n = 0, bufMax do
        local alpha = stream.pointer[stream.position + n]

        ffi.copy(imagePointer + imagePointerOffset, defaultColor, 3)

        imagePointer[imagePointerOffset + 3] = alpha
        imagePointerOffset = imagePointerOffset + 4
      end

      stream.position = stream.position + pixelCount
    end

    pixelsProcessed = pixelsProcessed + pixelCount
  end

  return image, palette
end

local BUFFER_COLL = false

local function getChunkSize(self, defaultSize)
  return (self.cursorEnd or defaultSize) - self.cursor
end

local function readCollectionData(self)
  local stream, streamSize = BOSArchive.stream(self.contentPath)

  stream:seek(self.cursor + stream:tell())
  stream:expectSignature("<spranim_img>\0")

  local isCompressed = stream:readUshort() == 50
  local chunk

  if isCompressed then
    local uncompressedSize = stream:readUint()
    local byteData = stream:readByteData(getChunkSize(self, streamSize))

    chunk = PointerWrapper.fromFFIArray(assert(zlib.uncompress(byteData, uncompressedSize)))
  else
    chunk = PointerWrapper.fromByteData(stream:readByteData(getChunkSize(self, streamSize)))
  end

  stream:close()

  return chunk
end

local function getCollectionData(self)
  if self.rawChunk then
    return self.rawChunk
  end

  self.rawChunk = readCollectionData(self)

  return self.rawChunk
end

local Collection = Object:extend()

local math_ceil = math.ceil

function Collection:decodeImages()
  local stream = BufferStream.fromPointerWrapper(getCollectionData(self))
  local palettes = self.palettes
  local images = self.images
  local points = self.points

  for layerId = 1, 4 do
    palettes[layerId] = loadPalette(stream)
  end

  local imageCount = self.frameCount * self.dirCount
  local totalImageCount = imageCount * 4

  for imageId = 1, totalImageCount do
    local zarType = stream:readByte()

    if zarType == 1 then
      local paletteId = math_ceil(imageId / imageCount)

      points[imageId] = {
        stream:readUint(),
        stream:readUint()
      }
      images[imageId] = loadPackedTexture(stream, palettes[paletteId])
    else
      if zarType == 60 then
        break
      end
    end
  end

  stream:close()
end

function Collection:preLoad()
  local stream = BufferStream.fromPointerWrapper(getCollectionData(self))
  local palettes = self.palettes
  local images = self.images
  local points = self.points

  for layerId = 1, 4 do
    palettes[layerId] = loadPalette(stream)
  end

  local imageCount = self.frameCount * self.dirCount
  local totalImageCount = imageCount * 4

  local imageCursors = {}

  for imageId = 1, totalImageCount do
    local blockType = stream:readByte()

    if blockType == 1 then
      imageCursors[imageId] = stream:tell()
      points[imageId] = 0
      images[imageId] = 0

      stream:skip(8)
      stream:expectSignature("<zar>\0")
      stream:skip(10)

      local hasPalette = stream:readByte() == 1

      if hasPalette then
        stream:skip(stream:readUint())
      end

      local size = stream:readUint()
      stream:skip(size)
    else
      if blockType == 60 then
        break
      end
    end
  end

  self.imageCursors = imageCursors

  stream:close()
end

function Collection:decodeImage(imageId)
  local stream = BufferStream.fromPointerWrapper(getCollectionData(self))
  local cursor = self.imageCursors[imageId]
  local imageCount = self.frameCount * self.dirCount
  local paletteId = math_ceil(imageId / imageCount)

  stream:seek(cursor)

  self.points[imageId] = {
    stream:readUint(),
    stream:readUint()
  }
  self.images[imageId] = loadPackedTexture(stream, self.palettes[paletteId])
end

local META_WEAK_VALUES = {
  __mode = "v"
}

local function swap(array, index1, index2)
  array[index1], array[index2] = array[index2], array[index1]
end

function Sprite:preLoad(contentPath)
  local stream = BOSArchive.stream(contentPath)

  stream:expectSignature("<sprite>\x004\0")

  local bbox = {
    stream:readByte(),
    stream:readByte(),
    stream:readByte()
  }

  swap(bbox, 2, 3)

  local offsetX, offsetY = stream:readUint(), stream:readUint()
  local bboxScreenX, bboxScreenY = worldToScreen(bbox[1], bbox[2])
  local offset = {
    offsetX - bboxScreenX,
    offsetY - bboxScreenY
  }

  stream:skip(3)

  local frames = {}
  local totalFrameCount = 0
  local sequences = {}
  local sequenceCount = stream:readUint()
  local sequenceIdLookup = {}

  for sequenceId = 1, sequenceCount do
    local firstFrame = totalFrameCount + 1
    local frameCount = stream:readUshort()
    local frameDataCount = frameCount

    stream:skip(2)

    local frameData = {}

    for frameDataId = 1, frameDataCount do
      frameData[frameDataId] = stream:readShort()
    end

    stream:skip(4 * frameDataCount)

    local sequenceName = stream:read(stream:readUint())
    local collectionId = stream:readUshort() + 1
    local frameDataId = 1

    while frameDataId <= frameDataCount do
      local frameId = frameData[frameDataId]
      local frame = { id = frameId }

      totalFrameCount = totalFrameCount + 1
      frames[totalFrameCount] = frame

      local paramCount = frameParameterCount(frameId)

      if paramCount then
        frame.params = {}

        for paramId = 1, paramCount do
          frame.params[paramId] = frameData[frameDataId + paramId + 1 - 1]
        end

        frameCount = frameCount - paramCount
        frameDataId = frameDataId + paramCount
      end

      frameDataId = frameDataId + 1
    end

    sequenceIdLookup[sequenceName] = sequenceId

    sequences[sequenceId] = {
      name = sequenceName,
      collectionId = collectionId,
      frameCount = frameCount,
      firstFrame = firstFrame
    }
  end

  local collections = {}
  local collectionCount = stream:readUint()

  for collectionId = 1, collectionCount do
    stream:expectSignature("<spranim>\x001\0")

    local cursor = stream:readUint()
    local name = stream:read(stream:readUint())
    local frameCount = stream:readUint()
    local dirCount = stream:readUint()

    local rects = {}
    local rectCount = dirCount * frameCount

    for rectId = 1, rectCount do
      rects[rectId] = {
        stream:readUint(),
        stream:readUint(),
        stream:readUint(),
        stream:readUint()
      }
    end

    collections[collectionId] = setmetatable({
      id = collectionId,
      contentPath = contentPath,
      cursor = cursor,
      name = name,
      frameCount = frameCount,
      dirCount = dirCount,
      rects = rects,
      points = {},
      palettes = {},
      images = {},
      textures = setmetatable({}, META_WEAK_VALUES)
    }, Collection)

    local previousCollection = collections[collectionId - 1]

    if previousCollection then
      previousCollection.cursorEnd = cursor
    end
  end

  for sequenceId = 1, sequenceCount do
    local sequence = sequences[sequenceId]
    local seqName = sequence.name

    if seqName:find("gui") then
      sequence.isGui = true
    end

    local overlayName = seqName .. "Overlay"
    local overlayId = sequenceIdLookup[overlayName]

    if overlayId then
      local overlaySequence = sequences[overlayId]

      overlaySequence.isOverlay = true

      if collections[overlaySequence.collectionId].dirCount == collections[sequence.collectionId].dirCount then
        sequence.overlayId = overlayId
      end
    end
  end

  stream:close()

  self.bbox = bbox
  self.offset = offset
  self.sequences = sequences
  self.sequenceIdLookup = sequenceIdLookup
  self.frames = frames
  self.collections = collections
end

local spriteCache = Cache.weakValues(function(contentPath)
  local sprite = Sprite()

  sprite:preLoad("sprites/" .. contentPath)

  return sprite
end)

function Sprite.loadFromArchive(contentPath)
  return spriteCache:get(contentPath)
end

return Sprite
