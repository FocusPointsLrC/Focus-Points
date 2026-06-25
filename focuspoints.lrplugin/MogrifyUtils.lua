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
  - Export a preview image of the current photo to a disk file
  - Add focus points, face/subject detection frames, etc. to this image.
------------------------------------------------------------------------------]]
local MogrifyUtils = {}

-- Imported LR namespaces
local LrDate          = import 'LrDate'
local LrDialogs       = import 'LrDialogs'
local LrExportSession = import 'LrExportSession'
local LrFileUtils     = import 'LrFileUtils'
local LrErrors        = import 'LrErrors'
local LrPathUtils     = import 'LrPathUtils'
local LrPrefs         = import 'LrPrefs'
local LrTasks         = import 'LrTasks'

-- Required Lua definitions
local Log             = require 'Log'
local Utils           = require 'Utils'

-- Forward references to local functions
local exportPhoto, exportPreview

local imageFileName
local mogrifyPath
local resizeParams
local previewReady

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

  Create an ImageMagick script file containing all drawing commands. This avoids
  command-line length limitations when many focus points need to be rendered.
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
  public string filename, string method, string errorText
  writeToDisk(table photo, int xSize, int ySize)

  Writes an image of 'photo' with size 'xSize' x 'ySize' to disk

  NOTE: Major changes in V3.4
  - make 'exportPreview' more robust and in particular, avoid returning a blank preview
  - implement 'exportPhoto' approach to support Second Screen mode

  For modal dialog operation, a preview image is retrieved and written to disk.
  Note that the requestJpegThumbnail() method treats the size as a minimum value and that the image on disk
  may be larger than this. Any deviations will be corrected in the Mogrify step.
  If the preview does not become available after a certain timeout, the image will be created using Export.
------------------------------------------------------------------------------]]
local function writeToDisk(photo, xSize, ySize)
  return exportPreview(photo, xSize, ySize)
end

function exportPreview(photo, xSize, ySize)
  -- Request a preview image from Lightroom and write it to a temporary file.
  -- Same input and output parameters as the calling function

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
    local sosPos
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

  local function timeoutReached(startTime, timeout)
    -- Helper function
    return (LrDate.currentTime() - startTime) >= timeout
  end

  local orgPath   = photo:getRawMetadata("path")
  local leafName  = LrPathUtils.leafName(orgPath)
  local leafWOExt = LrPathUtils.removeExtension(leafName)
  local tempPath  = LrPathUtils.getStandardFilePath("temp")
  imageFileName   = LrPathUtils.child(tempPath, leafWOExt .. "-fpoints.jpg")

  local prefs     = LrPrefs.prefsForPlugin(nil)
  local fallback  = prefs.previewFallback
  local timeout   = prefs.previewTimeout
  local errorText

  -- Polling parameters used while waiting for Lightroom to provide a preview
  local POLL_INTERVAL = 0.2
  local POLL_TIMEOUT  = 0.8

  -- Start overall timeout timer and request counter
  local startTime = LrDate.currentTime()
  local requests = 0

  -- Check whether the user has specified that they do not want to use the previews, but rather Export right away
  if fallback and (timeout == 0) then
    Log.logInfo("Mogrify", "Preview timeout is 0. Using Export immediately.")
    return exportPhoto(photo, xSize, ySize)
  end

  -- Display preview generation progress notification
  previewReady = false
  if prefs.previewShowProgress then
    LrTasks.startAsyncTask(function()
      LrTasks.sleep(prefs.previewProgressDelay)
      local fadeDelay = 1.0
      local iteration = 0
      local frames = { "/", "\\" }  -- nothing fancy, just a classical simple spinner
      while not previewReady do
        iteration = iteration + 1
        local i = (iteration - 1) % #frames + 1
        LrDialogs.showBezel(string.format("Preparing preview... %s", frames[i]), fadeDelay)
        LrTasks.sleep(fadeDelay)
      end
    end)
  end

  -- Polling loop to obtain a Preview for the current photo
  while true do

    -- State variables for the current preview request attempt
    local done       = false
    local succeeded  = false

    -- Fallback to Export if Preview generation takes too long
    if fallback and timeoutReached(startTime, timeout) then
      Log.logInfo("Mogrify",
        string.format(
          "Preview timeout set to 0: no preview acquisition, immediately start export.",
          LrDate.currentTime() - startTime))
      return exportPhoto(photo, xSize, ySize)
    end

    --[[
    Request a JPEG thumbnail of the current photo.
    If the preview system does not already contain a preview for this photo, one will be rendered.
    The behaviour of this SDK function is not straightforward, as it may return 'data' which is not valid.
    --]]
    requests = requests + 1
    photo:requestJpegThumbnail(xSize, ySize, function(data, errorMsg)
      if not data then
        -- Preview not ready yet; will retry after callback returns
        Log.logDebug('Mogrify', string.format(
          "Preview not available (%s) after %.1fs",
           errorMsg or "no error message", LrDate.currentTime() - startTime))

      else
        -- Lightroom returned data, but it may still represent an incomplete or invalid preview image

        -- Retrieve dimensions of preview image
        local w, h = getJpegDimensions(data)

        -- Check preview dimensions against what was requested
        if w == nil or w == 0 or h == 0 then
          -- couldn't parse dimensions, retry
          Log.logDebug('Mogrify', string.format(
            "Invalid preview dimensions after %.1fs (%dx%d, requested=%dx%d)",
            LrDate.currentTime() - startTime, w or 0, h or 0, xSize, ySize))
          -- retry!

        -- Does data contain a blank preview?
        elseif isBlankImage(data) then
          -- this identifies instances where LR returns an empty preview with the original photo's dimensions
          Log.logDebug('Mogrify', string.format(
            "Preview content not valid after %.1fs", LrDate.currentTime() - startTime))
          -- retry!

        else
          -- Dimensions look right and preview image is not blank -> write to disk!
          succeeded = true
          previewReady = true

          Log.logInfo('Mogrify', string.format(
          "Preview obtained after %.1f seconds (after %s requests)",
          LrDate.currentTime() - startTime, requests))

          -- Write image to disk
          local ok = false
          local localFile, fileError = io.open(imageFileName, "wb")
          if localFile then
            ok, fileError = localFile:write(data)
            localFile:close()
          end

          if ok then
            Log.logInfo('Mogrify', string.format(
              "Temporary preview written to %s", imageFileName))
          else
            -- I/O error. Returning a nil filename will cause the caller to handle this properly
            errorText = string.format(
              "Error creating image file: %s", imageFileName, fileError)
            Log.logError('Mogrify', errorText)
            -- reset filename to indicate there is result (due to the I/O error)
            imageFileName = nil
          end
        end
        done = true
      end
    end)

    -- Wait for this attempt's callback, but don't wait forever
    local waited = 0
    while not done and waited < POLL_TIMEOUT do

      if fallback and timeoutReached(startTime, timeout) then
        Log.logInfo("Mogrify", string.format(
         "Preview timeout reached after %.1f seconds. Using Export.",
          LrDate.currentTime() - startTime))
        return exportPhoto(photo, xSize, ySize)
      end

      LrTasks.sleep(POLL_INTERVAL)
      waited = waited + POLL_INTERVAL
    end

    if not done then
      -- Callback never fired — LrC may be hung; treat like a nil-data retry
      Log.logDebug('Mogrify', string.format(
        "Timed out  after %.1f seconds waiting for thumbnail callback",
        LrDate.currentTime() - startTime))
    end

    if succeeded then
      return imageFileName, "Preview", errorText
    end
  end
end

function exportPhoto(photo, xSize, ySize)
  -- Exports an image of the photo to disk file via Lightroom's Export interfacce
  -- Same input and output parameters as the calling function

  local orgPath = photo:getRawMetadata("path")
  local leafName = LrPathUtils.leafName(orgPath)
  local leafWOExt = LrPathUtils.removeExtension(leafName)
  local tempPath = LrPathUtils.getStandardFilePath("temp")
  local exportedFile  = LrPathUtils.child(tempPath, leafWOExt .. "-fpoints.jpg")
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
 -- Filename
    LR_renamingTokensOn             = true,
    LR_tokens                       = "{{image_name}}-fpoints",
    LR_extensionCase                = "lowercase",
    LR_tokenCustomString            = "",
  }

  local exportSession = LrExportSession({
    photosToExport  = { photo },
    exportSettings  = exportSettings,
  })

  exportSession:doExportOnCurrentTask()

  -- Trigger the progress notification to disappear
  previewReady = true

  -- Check whether Export was successful
  if not LrFileUtils.exists(exportedFile) then
    local errorText = "Error on export: exported file not found at " .. exportedFile
    Log.logError('Mogrify', errorText)
    return nil, "Export", errorText
  end

  Log.logInfo('Mogrify', "Temporary export written to " .. exportedFile)
  return exportedFile, "Export"
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

        -- Ensure left/right coordinates are ordered correctly before drawing
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
  local filename, displayMethod, errorText = writeToDisk (photo, xSize, ySize)
  if filename then
    mogrifyResize(photo, xSize, ySize)  -- this only determines the resize params!
  end
  return filename, displayMethod, errorText
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
  if LrFileUtils.exists(imageFileName) then
    local _resultOK, errorMsg = LrFileUtils.delete( imageFileName )
    if errorMsg ~= nil then
      Log.logWarn('Mogrify', "Unable to delete Mogrify temp file " .. imageFileName .. ": " .. errorMsg)
    end
  end
end

return MogrifyUtils
