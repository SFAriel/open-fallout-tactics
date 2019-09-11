local colors = require("colors")
local timer = require("util.timer")
local BOSArchive = require("bos.archive")
local Sprite = require("sprite")
local spriteEvent = require("sprite.event")

local G = love.graphics

G.setDefaultFilter("nearest", "nearest")
G.setBackgroundColor(colors.test.backdrop)

local ONE_FRAME_DURATION_IN_SECONDS = 1/15

local greyShader = G.newShader("shaders/grey.c")
local testObjects = {}

function love.load()
  BOSArchive.build()

  timer.start("parse_sprite")
  local testSprite = Sprite.loadFromArchive("characters/LeatherMale.spr")
  timer.finish("parse_sprite")

  print("bbox:", unpack(testSprite.bbox))
  print("offset:", unpack(testSprite.offset))
  print("sequences:", #testSprite.sequences)
  print("frames:", #testSprite.frames)
  print("collections:", #testSprite.collections)
  local imageCount = 0
  for k, v in pairs(testSprite.collections) do
    imageCount = imageCount + 4 * v.frameCount * v.dirCount
  end
  print("image count:", imageCount)
  local rectCount = 0
  for k, v in pairs(testSprite.collections) do
    rectCount = rectCount + #v.rects
  end
  print("rects:", rectCount)

  table.insert(testObjects, {
    sprite = testSprite,
    sequenceId = testSprite.sequenceIdLookup["default"] or 1,
    dirId = 0,
    frameId = 0,
    colors = {
      colors.skin.light,
      colors.hair.brown,
      colors.gear.orange
    }
  })
end

function love.draw()
  G.push()
  G.translate(350, 350)
  G.scale(1, 1)
  G.push()

  local seqInfo = {}

  for _, object in pairs(testObjects) do
    local sprite = object.sprite
    local offset = sprite.offset
    local sequence = sprite.sequences[object.sequenceId]
    local firstFrame = sequence.firstFrame
    local seqFrameCount = sequence.frameCount
    local collection = sprite.collections[sequence.collectionId]
    local textures = collection.textures

    local frameCount, dirCount = collection.frameCount, collection.dirCount
    local imageCount = dirCount * frameCount

    if #collection.images == 0 then
      collection:preLoad()
    end

    local seqFrameId = object.frameId
    local dirId = object.dirId
    local frame = sprite.frames[firstFrame + seqFrameId]
    local frameId = frame.id
    local rectId = frameId * dirCount + dirId + 1
    local rect = collection.rects[rectId]

    for layerId = 0, 3 do
      local texId = dirId * frameCount + layerId * imageCount + frameId + 1

      if collection.images[texId] == 0 then
        collection:decodeImage(texId)
      end

      local tex = collection.images[texId]

      if tex then
        G.push()

        textures[texId] = textures[texId] or G.newImage(tex)

        local tex = textures[texId]
        local point = collection.points[texId]

        G.translate(point[1] + rect[1] - offset[1], point[2] + rect[2] - offset[2])

        local color = object.colors and object.colors[layerId]

        if color then
          G.setColor(color)
          G.setShader(greyShader)
        else
          G.setColor(colors.white)
        end

        G.draw(tex)
        G.setShader()
        G.pop()
      end
    end

    G.setColor(colors.white)

    if object.overlayFrameId then
      local sequence = sprite.sequences[sequence.overlayId]
      local firstFrame = sequence.firstFrame
      local seqFrameCount = sequence.frameCount
      local collection = sprite.collections[sequence.collectionId]
      local textures = collection.textures

      local frameCount, dirCount = collection.frameCount, collection.dirCount
      local imageCount = dirCount * frameCount

      if #collection.images == 0 then
        collection:preLoad()
      end

      local seqFrameId = object.overlayFrameId
      local frame = sprite.frames[firstFrame + seqFrameId]
      local frameId = frame.id
      local rectId = frameId * dirCount + dirId + 1
      local rect = collection.rects[rectId]

      for layerId = 0, 3 do
        local texId = dirId * frameCount + layerId * imageCount + frameId + 1

        if collection.images[texId] == 0 then
          collection:decodeImage(texId)
        end

        local tex = collection.images[texId]

        if tex then
          G.push()

          textures[texId] = textures[texId] or G.newImage(tex)

          local tex = textures[texId]
          local point = collection.points[texId]

          G.translate(point[1] + rect[1] - offset[1], point[2] + rect[2] - offset[2])
          G.draw(tex)
          G.pop()
        end
      end
    end
  end

  G.pop()
  G.pop()

  local testObject = testObjects[1]
  local sprite = testObject.sprite
  local sequence = sprite.sequences[testObject.sequenceId]
  local seqFrameCount = sequence.frameCount
  local frameId = testObject.frameId

  G.print(sequence.name, 6, 6)

  for i = 1, seqFrameCount do
    local frame = sprite.frames[sequence.firstFrame + i - 1] or {}

    if (i - 1) == frameId then
      G.setColor(colors.red)
    end

    local eventIdOrFrameId = spriteEvent.getName(frame.id)
    local params = frame.params and table.concat(frame.params, ", ")
    params = params and table.concat({" (", params, ")"}, "") or ""

    G.print(table.concat({i, ": ", eventIdOrFrameId, params, ""}), 6, 6 + i * 12)
    G.setColor(colors.white)
  end

  if sequence.overlayId then
    local sequence = sprite.sequences[sequence.overlayId]
    local seqFrameCount = sequence.frameCount
    local frameId = testObject.overlayFrameId or -1

    G.print(sequence.name, 86, 6)

    for i = 1, seqFrameCount do
      local frame = sprite.frames[sequence.firstFrame + i - 1] or {}

      if (i - 1) == frameId then
        G.setColor(colors.red)
      end

      local eventIdOrFrameId = spriteEvent.getName(frame.id)
      local params = frame.params and table.concat(frame.params, ", ")
      params = params and table.concat({" (", params, ")"}, "") or ""

      G.print(table.concat({i, ": ", eventIdOrFrameId, params, ""}), 86, 6 + i * 12)
      G.setColor(colors.white)
    end
  end
end

function love.update()
  local dt = love.timer.getDelta()
  for _, obj in pairs(testObjects) do
    local sprite = obj.sprite

    local sequence = sprite.sequences[obj.sequenceId]
    local seqFrameCount = sequence.frameCount
    local firstFrame = sequence.firstFrame
    local collection = sprite.collections[sequence.collectionId]
    local dirCount, frameCount = collection.dirCount, collection.frameCount

    local seqFrameId = obj.frameId

    obj.nextFrame = (obj.nextFrame or ONE_FRAME_DURATION_IN_SECONDS) - dt

    if obj.nextFrame <= 0 then
      seqFrameId = (seqFrameId or 0) + 1
      obj.nextFrame = obj.nextFrame + ONE_FRAME_DURATION_IN_SECONDS
      if obj.overlayFrameId then
        obj.overlayFrameId = obj.overlayFrameId + 1
        local overlay = sprite.sequences[sequence.overlayId]
        if obj.overlayFrameId >= overlay.frameCount then
          obj.overlayFrameId = overlay.frameCount - 1
        end
      end
    end

    if seqFrameId >= seqFrameCount then seqFrameId = seqFrameCount - 1 end

    local dirId = obj.dirId
    if dirId >= dirCount then dirId = dirCount - 1 end

    local frame = sprite.frames[firstFrame + seqFrameId]
    local frameId = frame.id
    while frameId < 0 and seqFrameId <= seqFrameCount do
      if frameId == spriteEvent.constants.repeat_all then
        seqFrameId = 0
      elseif frameId == spriteEvent.constants.jump_to_frame then
        seqFrameId = frame.params[1]
      else
        if frameId <= spriteEvent.constants.first_specific then
          -- hit, fire, step, sound, pickup
        elseif frameId == spriteEvent.constants.overlay then
          obj.overlayFrameId = 0
        end
        seqFrameId = seqFrameId + 1
      end

      frame = sprite.frames[firstFrame + seqFrameId]
      frameId = frame.id
    end

    obj.frameId = seqFrameId

    if obj.overlayFrameId then
      local sequence = sprite.sequences[sequence.overlayId]
      local seqFrameCount = sequence.frameCount
      local firstFrame = sequence.firstFrame
      local collection = sprite.collections[sequence.collectionId]
      local dirCount, frameCount = collection.dirCount, collection.frameCount
      local seqFrameId = obj.overlayFrameId

      local frame = sprite.frames[firstFrame + seqFrameId]
      local frameId = frame.id
      while frameId < 0 and seqFrameId <= seqFrameCount do
        if frameId == spriteEvent.constants.repeat_all then
          seqFrameId = 0
        elseif frameId == spriteEvent.constants.jump_to_frame then
          seqFrameId = frame.params[1]
        else
          seqFrameId = seqFrameId + 1
        end

        frame = sprite.frames[firstFrame + seqFrameId]
        frameId = frame.id
      end

      obj.overlayFrameId = seqFrameId
    end
  end
end

function love.keypressed(key)
  if key == "right" then
    for _, obj in pairs(testObjects) do
      local sprite = obj.sprite
      local coll = sprite.collections[sprite.sequences[obj.sequenceId or -1].collectionId or -1]
      local maxDir = coll and coll.dirCount or 0

      obj.dirId = obj.dirId + 1
      if obj.dirId >= maxDir then obj.dirId = 0 end
    end
  elseif key == "left" then
    for _, obj in pairs(testObjects) do
      local sprite = obj.sprite
      local coll = sprite.collections[sprite.sequences[obj.sequenceId or -1].collectionId or -1]
      local maxDir = coll and coll.dirCount or 0

      obj.dirId = obj.dirId - 1
      if obj.dirId < 0 then obj.dirId = maxDir - 1 end
    end
  elseif key == "up" then
    for _, obj in pairs(testObjects) do
      local sprite = obj.sprite

      repeat
        obj.sequenceId = obj.sequenceId + 1
        if obj.sequenceId > #sprite.sequences then
          obj.sequenceId = 1
        end
      until (not sprite.sequences[obj.sequenceId].isOverlay)

      obj.overlayFrameId = nil

      local coll = sprite.collections[sprite.sequences[obj.sequenceId].collectionId or -1]
      local maxDir = coll and coll.dirCount or 0

      if obj.dirId >= maxDir then obj.dirId = maxDir - 1 end

      obj.frameId = 0

      obj.nextFrame = ONE_FRAME_DURATION_IN_SECONDS
    end
  elseif key == "down" then
    for _, obj in pairs(testObjects) do
      local sprite = obj.sprite

      repeat
        obj.sequenceId = obj.sequenceId - 1
        if obj.sequenceId < 1 then
          obj.sequenceId = #sprite.sequences
        end
      until (not sprite.sequences[obj.sequenceId].isOverlay)

      obj.overlayFrameId = nil

      local coll = sprite.collections[sprite.sequences[obj.sequenceId].collectionId or -1]
      local maxDir = coll and coll.dirCount or 0

      if obj.dirId >= maxDir then obj.dirId = maxDir - 1 end

      obj.frameId = 0

      obj.nextFrame = ONE_FRAME_DURATION_IN_SECONDS
    end
  elseif key == "c" then
    collectgarbage("collect")
  end
end
