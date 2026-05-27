--[[
  Original work © Whizzbang Inc, ropma
  Ongoing maintenance and modifications © 2026 Karsten Gieselmann

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
--]]

--[[----------------------------------------------------------------------------
  MogrifyUtils.lua

  Purpose of this module:
  Helper functions to
  - Export a preview of the current photo to a disk file.
  - Add focus points, face/subject detection frames, etc. to this image.
------------------------------------------------------------------------------]]
local MogrifyUtils = {}

-- Imported LR namespaces
local LrExportSession = import 'LrExportSession'
local LrFileUtils     = import  'LrFileUtils'
local LrErrors        = import  'LrErrors'
local LrPathUtils     = import  'LrPathUtils'
local LrPrefs         = import  'LrPrefs'
local LrTasks         = import  'LrTasks'

-- Required Lua definitions
local Log             = require 'Log'
local _strict         = require 'strict'
local Utils           = require 'Utils'

-- Forward references to local functions
local exportViaDisk, exportViaThumbnail

local imageFileName
local mogrifyPath
local resizeParams

-- Map base colors for focus box to specific color tones to be used by Mogrify
local colorMap = {
  red     = "red",
  green   = "green1",
  blue    = "blue",
  yellow  = "yellow",
  white   = "white",
  grey    = "grey",
  black   = "black",
  orange  = "orange",
}

--[[----------------------------------------------------------------------------
  public string
  createMagickScript(table photo, string params)

  Creates a script file for Mogrify. This helps avoid exceeding the maximum command
  line length when performing drawing operations involving a large number of points.
  Returns the name of the temp file.
------------------------------------------------------------------------------]]
local function createMagickScript(photo, params)
  local scriptName = Utils.getTempFileName()

  local success, _errorCode = pcall(function()
    local file = io.open(scriptName, "w")
    if file then
      file:write('-read \"' .. imageFileName .. '\"', "\n")
      file:write(params, "\n")
      file:write('-write \"' .. imageFileName .. '\"', "\n")
      file:close()
    end
  end)
  if not success then
    local errorText = 'FATAL error creating script file ' .. scriptName
    Log.logError('Mogrify', errorText)
    LrErrors.throwUserError(
      string.format("%s\n\n%s", Utils.getPhotoFileName(photo), errorText))
  end
  return scriptName
end

--[[----------------------------------------------------------------------------
  public void
  mogrifyExecute(table photo, string params, boolean script)

  Execute Mogrify with 'params' on 'imageFileName'.
  In case Mogrify reports an error (return code ~= 0) an error message is
  issued and the the processing of the current photo is stopped.
------------------------------------------------------------------------------]]
local function mogrifyExecute(photo, params, script)
  if mogrifyPath == nil then
     mogrifyPath = LrPathUtils.child( _PLUGIN.path, "bin" )
     mogrifyPath = LrPathUtils.child( mogrifyPath, "ImageMagick" )
     mogrifyPath = LrPathUtils.child( mogrifyPath, "magick.exe")
  end

  local scriptName
  local cmdline = '\"' .. mogrifyPath .. '\" '
  if script then
    scriptName = createMagickScript(photo, params)
    cmdline = cmdline .. '-script ' .. '\"' .. scriptName .. '\"'
  else
    cmdline = cmdline .. 'mogrify ' .. params
  end

  Log.logDebug("Mogrify", cmdline )
  local rc = LrTasks.execute( '\"' .. cmdline .. '\"' )

  -- Avoid Windows process queue saturation
  if WIN_ENV then
      LrTasks.sleep(0.02)
      LrTasks.yield()
  end

  if rc ~= 0 then
    Log.logError("Mogrify", 'Error calling: ' .. cmdline .. ", return code " .. rc)
    LrErrors.throwUserError(string.format(
     "%s\n\nFATAL error calling 'mogrify.exe' (rc=%s)\nPlease check logfile",
      Utils.getPhotoFileName(photo), rc))
  end
  if script then
    local prefs = LrPrefs.prefsForPlugin( nil )
    if prefs.loggingLevel ~= "DEBUG" then
      -- keep temporary script file for log level DEBUG
      if LrFileUtils.exists(scriptName) and not LrFileUtils.delete(scriptName) then
        Log.logWarn("Mogrify", "Error deleting mogrify script file " .. scriptName)
      end
    end
  end
end

--[[----------------------------------------------------------------------------
  public string
  exportToDisk(table photo, int xSize, int ySize)

  Export a preview of 'photo' with size 'xSize' x 'ySize' to disk
  NOTE: Major adjustments in V3.4 to
  - implement 'exportViaDisk' approach to support Second Screen mode
  - make 'exportViaThumbnail' more robust and avoid empty previews

  For modal dialog operation, a preview image is retrieved and written to disk.
  Note that the requestJpegThumbnail() method treats the size as a minimum value and that the image on disk
  may be larger than this. Any deviations will be corrected in the Mogrify step.

  In 'Second Screen' mode, the preview approach does not work because requestJpegThumbnail is unreliable.
  When in Develop mode, the preview image is usually blurry, or Lightroom Classic might not be able to
  to create one. Instead, an exported image using LrExportSession will be used. This takes slightly longer, but
  it delivers a reliable result.
------------------------------------------------------------------------------]]
local function exportToDisk(photo, xSize, ySize)
  local prefs = LrPrefs.prefsForPlugin( nil )

  if prefs.secondScreenMode or prefs.exportViaDisk then
    -- Preview cache is unreliable in Develop mode; need to use an 'exported' JPG
    return exportViaDisk(photo, xSize, ySize)
  else
    -- We're in Library: use thumbnails (which are basically previews)
    return exportViaThumbnail(photo, xSize, ySize)
  end
end

function exportViaThumbnail(photo, xSize, ySize)
  -- New code for V3.4 that includes a retry mechanism and a check for 'invalid' (blank) previews

  local function getJpegDimensions(data)
    -- Helper function to retrieve the dimensions of the image returned by requestJpegThumbnail()
    if #data < 4 then return nil, nil end

    -- verify JPEG SOI marker
    if data:byte(1) ~= 0xFF or data:byte(2) ~= 0xD8 then
      return nil, nil
    end

    local i = 3  -- skip SOI marker, start at first segment
    while i < #data - 8 do
      -- each segment must start with 0xFF
      if data:byte(i) ~= 0xFF then
        return nil, nil  -- lost sync, invalid JPEG
      end

      local marker = data:byte(i + 1)

      -- skip any 0xFF padding bytes
      if marker == 0xFF then
        i = i + 1
      -- skip standalone markers with no length field
      elseif marker == 0xD8 or marker == 0xD9 or
             (marker >= 0xD0 and marker <= 0xD7) then
        i = i + 2
      -- SOF markers contain dimensions
      elseif (marker >= 0xC0 and marker <= 0xCF) and
              marker ~= 0xC4 and marker ~= 0xC8 and marker ~= 0xCC then
        -- SOF structure: FF, marker, length(2), precision(1), height(2), width(2)
        if i + 8 <= #data then
          local h = data:byte(i + 5) * 256 + data:byte(i + 6)
          local w = data:byte(i + 7) * 256 + data:byte(i + 8)
          return w, h
        end
        return nil, nil
      else
        -- regular segment: skip over it using its length field
        if i + 3 > #data then return nil, nil end
        local segLen = data:byte(i + 2) * 256 + data:byte(i + 3)
        if segLen < 2 then return nil, nil end  -- sanity check
        i = i + 2 + segLen
      end
    end

    return nil, nil
  end

  local function isBlankImage(data)
    -- Helper function that determines whether the image returned by requestJpegThumbnail() is a valid preview
    -- invalid previews are blank/white images with the same 16-byte pattern cycling endlessly, with only
    -- 24 unique byte values out of 256. A real photo would have 200+ unique values and no such repetition.
    -- This function performs a byte entropy check on 'data' to detect such low-entropy content

    -- Find SOS marker (FF DA) to locate start of scan data
    local sosPos = nil
    for i = 1, #data - 1 do
      if data:byte(i) == 0xFF and data:byte(i+1) == 0xDA then
        sosPos = i
        break
      end
    end
    if not sosPos then return false end

    -- Skip SOS header to get to actual scan data
    local sosHeaderLen = data:byte(sosPos+2) * 256 + data:byte(sosPos+3)
    local scanStart = sosPos + 2 + sosHeaderLen

    -- Sample up to 2000 bytes of scan data
    local sampleEnd = math.min(scanStart + 2000, #data)
    local seen = {}
    local count = 0
    for i = scanStart, sampleEnd do
      local b = data:byte(i)
      if not seen[b] then
        seen[b] = true
        count = count + 1
      end
    end

    -- A blank/white image has very low byte entropy (24 unique values observed)
    -- A real photo will have 100+ unique byte values
    return count < 50
  end

  local orgPath   = photo:getRawMetadata("path")
  local leafName  = LrPathUtils.leafName(orgPath)
  local leafWOExt = LrPathUtils.removeExtension(leafName)
  local tempPath  = LrPathUtils.getStandardFilePath("temp")
  local thumbName = LrPathUtils.child(tempPath, leafWOExt .. "-thumb.jpg")
  imageFileName   = LrPathUtils.child(tempPath, leafWOExt .. "-fpoints.jpg")

  -- Retry configuration parameters
  local MAX_RETRIES    = 10    -- maximum number of retries
  local RETRY_DELAY    = 0.5   -- seconds between retries
  local POLL_INTERVAL  = 0.2   -- seconds between done-checks
  local POLL_TIMEOUT   = 1.0   -- max seconds to wait per attempt

  for attempt = 1, MAX_RETRIES do
    local done       = false
    local succeeded  = false

    photo:requestJpegThumbnail(xSize, ySize, function(data, errorMsg)
      if not data then
        -- Preview not ready yet; will retry after callback returns
        Log.logInfo('Mogrify', string.format(
          "Attempt %d: thumbnail not available (%s), retrying...",
          attempt, errorMsg or "no error message"))
      else
        -- Retrieve dimensions of preview image
        local w, h = getJpegDimensions(data)
        Log.logInfo('Mogrify', string.format(
          "Attempt %d: thumbnail dimensions=%dx%d (requested=%dx%d)",
          attempt, w or 0, h or 0, xSize, ySize))
        -- Check preview dimensions against what was requested
        if w == nil or w == 0 or h == 0 then
          -- couldn't parse dimensions, retry
          Log.logInfo('Mogrify', string.format(
            "Attempt %d: invalid dimensions, retrying...", attempt))
          -- blank preview, retry
        elseif isBlankImage(data) then
          -- this identifies instances where LR returns an empty preview with the original photo's dimensions
          Log.logInfo('Mogrify', string.format(
            "Attempt %d: invalid thumbnail, retrying...", attempt))
          -- blank preview, retry
        else
          -- Dimensions look right, write image to disk and proceed
          local ok, errorCode = pcall(function()
            local localFile = io.open(imageFileName, "w+b")
            if localFile then
              localFile:write(data)
              localFile:close()
            end
          end)
          if ok then
            Log.logInfo('Mogrify', string.format(
              "Attempt %d: image exported to %s", attempt, imageFileName))
            succeeded = true
            -- in Debug mode, save a separate copy of the thumbnail image for later analysis
            local prefs = LrPrefs.prefsForPlugin( nil )
            if prefs.loggingLevel == "DEBUG" then
              ok, errorCode = pcall(function()
                local localFile = io.open(thumbName, "w+b")
                if localFile then
                  localFile:write(data)
                  localFile:close()
                end
              end)
            end
          else
            -- I/O failure is fatal — no point retrying a disk error
            local errorText = string.format(
              "FATAL error creating image file %s (rc=%s)", imageFileName, errorCode)
            Log.logError('Mogrify', errorText)
            LrErrors.throwUserError(
              string.format("%s\n\n%s", Utils.getPhotoFileName(photo), errorText))
          end
        end
        done = true
      end
    end)

    -- Wait for this attempt's callback, but don't wait forever
    local waited = 0
    while not done and waited < POLL_TIMEOUT do
      LrTasks.sleep(POLL_INTERVAL)
      waited = waited + POLL_INTERVAL
    end

    if not done then
      -- Callback never fired — LrC may be hung; treat like a nil-data retry
      Log.logInfo('Mogrify', string.format(
        "Attempt %d: timed out waiting for thumbnail callback", attempt))
    end

    if succeeded then
      return imageFileName   -- ← expose the path to the caller if useful
    end

    -- Back off before the next attempt so LrC has time to build the preview
    if attempt < MAX_RETRIES then
      LrTasks.sleep(RETRY_DELAY * attempt)  -- progressive back-off: 1s, 2s, 3s…
    end
  end  -- for

  -- All retries exhausted
  local errorText = string.format(
    "FATAL error: Lightroom preview not available after %d attempts", MAX_RETRIES)
  Log.logError('Mogrify', errorText)
  LrErrors.throwUserError(string.format(
    "%s\n\n%s", Utils.getPhotoFileName(photo), errorText))
end

function exportViaDisk(photo, xSize, ySize)
  local orgPath = photo:getRawMetadata("path")
  local leafName = LrPathUtils.leafName(orgPath)
  local leafWOExt = LrPathUtils.removeExtension(leafName)
  local tempPath = LrPathUtils.getStandardFilePath("temp")
  local exportedFile  = LrPathUtils.child(tempPath, leafWOExt .. ".jpg")
  imageFileName = LrPathUtils.child(tempPath, leafWOExt .. "-fpoints.jpg")

  -- Clean up any leftover temp file from a previous run
  if LrFileUtils.exists(imageFileName) then
    LrFileUtils.delete(imageFileName)
  end

  local exportSettings = {
    LR_collisionHandling            = 'overwrite',
    LR_export_destinationType       = 'specificFolder',
    LR_export_destinationPathPrefix = tempPath,
    LR_export_useSubfolder          = false,
    LR_format                       = 'JPEG',
    LR_jpeg_quality                 = 0.8,
    LR_minimizeEmbeddedMetadata     = true,
    LR_outputSharpeningOn           = true,
    LR_outputSharpeningMedia        = 'screen',
    LR_outputSharpeningLevel        = 2,  -- 1=low, 2=standard, 3=high
    LR_size_doConstrain             = true,
    LR_size_resizeType              = 'longEdge',
    LR_size_maxWidth                = math.max(xSize, ySize),
    LR_size_maxHeight               = math.max(xSize, ySize),
    LR_size_units                   = 'pixels',
    LR_tokens_left                  = nil,
    LR_tokenCustomFilename          = nil,
    LR_renamingTokensOn             = nil,
  }

  local exportSession = LrExportSession({
    photosToExport  = { photo },
    exportSettings  = exportSettings,
  })

  exportSession:doExportOnCurrentTask()

  if not LrFileUtils.exists(exportedFile) then
    local errorText = "FATAL error: exported file not found at " .. exportedFile
    Log.logError('Mogrify', errorText)
    LrErrors.throwUserError(string.format(
      "%s\n\n%s", Utils.getPhotoFileName(photo), errorText))
  end

  local ok, err = LrFileUtils.move(exportedFile, imageFileName)
  if not ok then
    local errorText = string.format("FATAL error renaming exported file: %s", err)
    Log.logError('Mogrify', errorText)
    LrErrors.throwUserError(string.format(
      "%s\n\n%s", Utils.getPhotoFileName(photo), errorText))
  end

  Log.logInfo('Mogrify', "Image exported to " .. imageFileName)
  return imageFileName
end

--[[----------------------------------------------------------------------------
  public void
  mogrifyResize(_photo, int xSize, int ySize)

  Resize the disk image to the given size:
  xSize: width in pixel
  ySize: height in pixel

  Note:
  This was a separate call to Mogrify earlier. Now it's executed along with the
  draw commands to save one extra call to Mogrify and a little bit of runtime.
------------------------------------------------------------------------------]]
local function mogrifyResize(_photo, xSize, ySize)
  resizeParams = '-resize ' .. math.floor(xSize) .. 'x' .. math.floor(ySize) .. ' '
end

--[[----------------------------------------------------------------------------
  public int strokewidth, string color
  mapIconToStrokewidthAndColor(string name)

  Get color and strokewith from the icon name.
------------------------------------------------------------------------------]]
local function mapIconToStrokewidthAndColor(name)
  -- strokewidth:
  local sw = 2
  if string.match(name, 'fat') == 'fat' then
    sw = 3
  end
  -- color:
  -- if filename contains color placeholder, fill with user-defined color setting
  local prefs = LrPrefs.prefsForPlugin( nil )
  local nameWithColor = string.format(name, prefs.focusBoxColor, "0")
  local color = string.match(nameWithColor, 'assets/imgs/corner/(%a+)/.*')
  if not color then
    color = string.match(nameWithColor, 'assets/imgs/center/(%a+)/.*')
  end
  -- map base color to Mogrify specific tone
  color = colorMap[color]
  return sw, color
end

--[[----------------------------------------------------------------------------
  public string
  buildDrawParams(table focuspointsTable)

  Build the mogrify draw parameters based on the focuspointsTable.
  Returns a string containing the draw parameters.
------------------------------------------------------------------------------]]
local function buildDrawParams(focuspointsTable)
  local para
  local sw
  local color
  local params = '-fill none '

  if (focuspointsTable ~= nil) then
    for i, fpPoint in ipairs(focuspointsTable) do
      if fpPoint.template.center ~= nil then
        sw, color = mapIconToStrokewidthAndColor(fpPoint.template.center.fileTemplate)
        local x = math.floor(tonumber(fpPoint.points.center.x))
        local y = math.floor(tonumber(fpPoint.points.center.y))
        para = '-stroke ' .. color .. ' -fill ' .. color .. ' -draw \"circle ' ..x .. ',' .. y .. ' ' .. x+3 .. ',' .. y  .. '\" -fill none '
        Log.logDebug("Mogrify", "Building command line: " .. '[' .. i .. '] ' .. para )
        params = params .. para
      end
      if fpPoint.template.corner ~= nil then
        sw, color = mapIconToStrokewidthAndColor(fpPoint.template.corner.fileTemplate)
        para = '-strokewidth ' .. sw .. ' -stroke ' .. color .. ' '
        local tlx = math.floor(tonumber(fpPoint.points.tl.x))
        local tly = math.floor(tonumber(fpPoint.points.tl.y))
        local brx = math.floor(tonumber(fpPoint.points.br.x))
        local bry = math.floor(tonumber(fpPoint.points.br.y))
        -- normalize
        if tlx > brx and ( fpPoint.rotation == 0 or fpPoint.rotation == 360) then
          local x = tlx
          tlx = brx
          brx = x
        end
        if fpPoint.rotation == 0 or fpPoint.rotation == 360 then
          para = para .. '-draw \"roundRectangle ' .. tlx .. ',' .. tly .. ' ' .. brx .. ',' .. bry .. ' 1,1\" '
        else
          local trx = math.floor(tonumber(fpPoint.points.tr.x))
          local try = math.floor(tonumber(fpPoint.points.tr.y))
          local blx = math.floor(tonumber(fpPoint.points.bl.x))
          local bly = math.floor(tonumber(fpPoint.points.bl.y))
          para = para .. '-draw \"polyline ' .. trx .. ',' .. try .. ' ' .. tlx .. ',' .. tly .. ' '
                  .. blx .. ',' .. bly .. ' ' .. brx .. ',' .. bry .. ' ' .. trx .. ',' .. try .. '\" '
        end
        Log.logDebug("Mogrify", "Building command line: " .. '[' .. i .. '] ' .. para .. ' ' .. fpPoint.template.corner.fileTemplate)
        params = params .. para
      end
      -- To prevent UI freeze and keep plugin responsive
      LrTasks.yield()
    end
    return params
  else
    return nil
  end
end

--[[----------------------------------------------------------------------------
  public string
  createDiskImage(photo, xSize, ySize)

  Create a temporary disk impage for 'photo'.
  xSize: width in pixel of the create temporary photo
  ySize: height in pixel of the create temporary photo
------------------------------------------------------------------------------]]
function MogrifyUtils.createDiskImage(photo, xSize, ySize)
  exportToDisk (photo, xSize, ySize)
  mogrifyResize(photo, xSize, ySize)  -- this only determines the resize params!
  return imageFileName
end

--[[----------------------------------------------------------------------------
  public void
  drawFocusPoints(table photo, table focuspointsTable)

  Execute Mogrify to draw the focus points in focuspointsTable.
  See 'DefaultPointRenderer.prepareRendering' for a description of the table)
------------------------------------------------------------------------------]]
function MogrifyUtils.drawFocusPoints(photo, focuspointsTable)
  local params = buildDrawParams(focuspointsTable)
  if params ~= nil then
    params = resizeParams .. params
    Log.logInfo("Mogrify", "Resizing image, drawing focus points and visualization frames")
    mogrifyExecute(photo, params, true)
  else
    Log.logInfo("Mogrify", "Nothing to draw - no focus points or visualization frames found")
  end
end

--[[----------------------------------------------------------------------------
  public void
  cleanup()

  Delete the temporary file (created by 'MogrifyUtils.exportToDisk')
------------------------------------------------------------------------------]]
function MogrifyUtils.cleanup()
  --[[ @Todo
  if LrFileUtils.exists(imageFileName) then
    local _resultOK, errorMsg = LrFileUtils.delete( imageFileName )
    if errorMsg ~= nil then
      Log.logWarn('Mogrify', "Unable to delete Mogrify temp file " .. imageFileName .. ": " .. errorMsg)
    end
  end
  --]]
end

return MogrifyUtils
