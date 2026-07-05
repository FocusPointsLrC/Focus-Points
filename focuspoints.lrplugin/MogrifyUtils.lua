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
local LrApplicationView = import 'LrApplicationView'
local LrDate            = import 'LrDate'
local LrDialogs         = import 'LrDialogs'
local LrExportSession   = import 'LrExportSession'
local LrFileUtils       = import 'LrFileUtils'
local LrErrors          = import 'LrErrors'
local LrPathUtils       = import 'LrPathUtils'
local LrPrefs           = import 'LrPrefs'
local LrTasks           = import 'LrTasks'

-- Required Lua definitions
local FocusPointPrefs   = require 'FocusPointPrefs'
local Log               = require 'Log'
local Utils             = require 'Utils'

-- Forward references to local functions
local exportPhoto, exportPreview

-- Local variables -------------------------------------------------------------
local mogrifyPath = LrPathUtils.child( _PLUGIN.path, "bin" )
mogrifyPath = LrPathUtils.child( mogrifyPath, "ImageMagick" )
mogrifyPath = LrPathUtils.child( mogrifyPath, "magick.exe")

local tempFileName
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
  private string
  getImageFileName(table photo)

  Sets the 'imageFileName' variable which is used the Cleanup function
  or exportPhoto: photo-fpoints.jpg in TEMP folder
------------------------------------------------------------------------------]]
local function getImageFileName(photo)

  local ok, orgPath = LrTasks.pcall(photo.getRawMetadata, photo, "path")
  if not ok or not orgPath then
    return nil
  end

  local leafName  = LrPathUtils.leafName( orgPath )
  local leafWOExt = LrPathUtils.removeExtension( leafName )
  local tempPath  = LrPathUtils.getStandardFilePath( "temp" )
  local thumbName = LrPathUtils.child( tempPath, leafWOExt .. "-thumb.jpg" )
  tempFileName    = LrPathUtils.child( tempPath, leafWOExt .. "-fpoints.jpg" )
  return tempFileName, thumbName
end


--[[----------------------------------------------------------------------------
  public string
  createMagickScript(table photo, string params)

  Create an ImageMagick script file containing all drawing commands. This avoids
  command-line length limitations when many focus points need to be rendered.
  Returns the name of the temp script file or nil in case of errors
------------------------------------------------------------------------------]]
local function createMagickScript(photo, params)
  local scriptName = Utils.getTempFileName()
  local imageFileName = getImageFileName(photo)

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
    return nil
  end
  return scriptName
end

--[[----------------------------------------------------------------------------
  private void
  mogrifyExecute(table photo, string params, boolean script)

  Execute Mogrify with 'params' on 'imageFileName'.
  'params' are passed in a script to  avoid exceeding the maximum command line length
  when performing drawing operations involving a large number of points.
  In case Mogrify reports an error (return code ~= 0) an error message is
  issued and the the processing of the current photo is stopped.
  Returns true on success and false on failure.
------------------------------------------------------------------------------]]
local function mogrifyExecute(photo, params)

  local scriptName = createMagickScript(photo, params)
  if not scriptName then return false end

  local cmdline    = '\"' .. mogrifyPath .. '\"' .. ' -script ' .. '\"' .. scriptName .. '\"'

  Log.logDebug("Mogrify", cmdline )
  local rc = LrTasks.execute( '\"' .. cmdline .. '\"' )

  if rc ~= 0 then
    Log.logError("Mogrify", 'Error calling: ' .. cmdline .. ", return code " .. rc)
    return false
  end

  local prefs = LrPrefs.prefsForPlugin( nil )
  if prefs.loggingLevel ~= "DEBUG" then
    -- keep temporary script file for log level DEBUG
    if LrFileUtils.exists(scriptName) and not LrFileUtils.delete(scriptName) then
      Log.logWarn("Mogrify", "Error deleting mogrify script file " .. scriptName)
    end
  end

  return true
end

--[[----------------------------------------------------------------------------
  public string filename, string mode, string errorText
  writeToDisk(table photo, int xSize, int ySize)

  Writes an image of 'photo' with size 'xSize' x 'ySize' to disk

  NOTE: Major changes in V3.4
  - make 'exportPreview' more robust and in particular, avoid returning a blank preview
  - implement 'exportPhoto' approach to support Second Screen mode

  For modal dialog operation, a preview image is retrieved and written to disk.
  Note that requestJpegThumbnail() treats the size as a minimum value and that the image on disk
  may be larger than this. Any deviations will be corrected in the Mogrify step.

  #TODO - Rephrase comment
  In 'Second Screen' mode, the preview approach does not work because requestJpegThumbnail is unreliable.
  When in Develop mode, the preview image is usually blurry, or Lightroom Classic might not be able to
  to create one. Instead, an exported image using LrExportSession will be used. This takes slightly longer, but
  it delivers a reliable result.
------------------------------------------------------------------------------]]
local function writeToDisk(photo, xSize, ySize)
  local prefs = LrPrefs.prefsForPlugin( nil )
  if  prefs.displayMode == FocusPointPrefs.displayModeExport
  or (prefs.secondScreenMode and prefs.displayMode == FocusPointPrefs.displayModePreview
                            and LrApplicationView.getCurrentModuleName() == "develop") then
    return exportPhoto(photo, xSize, ySize)
  else
    return exportPreview(photo, xSize, ySize)
  end
end

function exportPreview(photo, xSize, ySize)
  -- Request a preview image from Lightroom and write it to a temporary file.
  -- Same input and output parameters as the calling function

  -- Polling interval used while waiting for Lightroom to provide a preview
  local POLL_INTERVAL = 0.2
  local RETRY_DELAY   = 1.0
  local RETRY_TIMEOUT = 15

  -- Minimum size of preview. Smaller images will not be accepted as valid preview.
  -- This case can occur when switching from Develop to Library, where the plugin
  -- appears to be stuck between different rendering systems.
  local MIN_SIZE      = 250

  local prefs     = LrPrefs.prefsForPlugin(nil)
  local fallback  = prefs.previewFallback
  local timeout   = prefs.previewTimeout
  local thumbRequest
  local callbackReceived
  local errorText

  local previewFileName, thumbName = getImageFileName(photo)
  if not previewFileName then
    -- getImageFileName can return w/o result if the current file has been deleted in Second Screen mode
    errorText = "Internal error: Preview cannot be obtained for a deleted photo."
    Log.logWarn("Mogrify", errorText)
    return nil, FocusPointPrefs.displayModePreview, errorText
  end

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

  local function showProgress()
    -- Helper: display preview generation progress notification
    local startTime = LrDate.currentTime()
    if prefs.previewShowProgress then
      LrTasks.startAsyncTask(function()
        LrTasks.sleep(prefs.previewProgressDelay)
        local fadeDelay = 1.0
        local iteration = 0
        local frames = { "/", "\\" }  -- nothing fancy, just a classical simple spinner
        while not previewReady and not timeoutReached(startTime, RETRY_TIMEOUT) do
          iteration = iteration + 1
          local i = (iteration - 1) % #frames + 1
          LrDialogs.showBezel(string.format("Preparing preview... %s", frames[i]), fadeDelay)
          LrTasks.sleep(fadeDelay)
        end
      end)
    end
  end

  -- Start overall timeout timer and request counter
  local startTime = LrDate.currentTime()

  -- Check whether the user has specified that they do not want to use Previews, but rather Export right away
  if fallback and (timeout == 0) then
    Log.logInfo("Mogrify", "Preview timeout is 0. Using Export immediately.")
    return exportPhoto(photo, xSize, ySize)
  end

  -- State variables for handling retries
  previewReady = false

  -- Display preview generation progress notification
  showProgress()

  while not previewReady do
    callbackReceived = false
    thumbRequest = photo:requestJpegThumbnail(xSize, ySize, function(data, errorMsg)
      --[[
        Request a JPEG thumbnail of the current photo.
        Two different situations exist:

        1. Lightroom is already generating the preview.
           requestJpegThumbnail() returns after some time with a valid image.

        2. The preview pipeline is not yet ready (typically immediately after
           switching from Develop to Library). The callback returns quickly but
           the image is blank. In this case we deliberately wait before issuing
           another request, because repeated requestJpegThumbnail() calls appear
           to consume excessive memory inside Lightroom.
      --]]
      callbackReceived = true
      if not data then
        -- Callback received but no data. Normally, this situation should not occur, so flag is as warning
        Log.logWarn('Mogrify', string.format(
          "Callback with empty data (%s) after %.1fs",
          errorMsg or "no error message", LrDate.currentTime() - startTime))
        --> retry!
      else
        -- Lightroom returned data, but it may still represent an incomplete or invalid preview image
        local w, h = getJpegDimensions(data)
        if w == nil or w == 0 or h == 0 or isBlankImage(data) then
          -- couldn't parse dimensions, retry
          Log.logDebug('Mogrify', string.format(
            "Preview content not valid after %.1fs", LrDate.currentTime() - startTime))
          --> retry!
        elseif w < MIN_SIZE or h < MIN_SIZE then
          -- tiny preview, retry
          Log.logDebug('Mogrify', string.format(
            "Preview obtained but much too small (%s x %s) after %.1fs",
            w, h, LrDate.currentTime() - startTime))
          --> retry!
        else
          -- Dimensions look right and preview image is not blank -> write to disk!
          previewReady = true
          Log.logInfo('Mogrify', string.format(
            "Preview (%s x %s) obtained after %.1f seconds", w, h, LrDate.currentTime() - startTime))

          -- Write image to disk
          local ok = false
          local localFile, fileError = io.open(previewFileName, "wb")
          if localFile then
            ok, fileError = localFile:write(data)
            localFile:close()
          end

          -- In debugging mode, save a copy of the response from requestJpegThumbnail()
          if prefs.loggingLevel == "DEBUG" then
            local thumbFile = io.open(thumbName, "wb")
            if thumbFile then
              ok, fileError = thumbFile:write(data)
              thumbFile:close()
            end
          end

          if ok then
            Log.logInfo('Mogrify', string.format(
              "Temporary image written to %s", previewFileName))
          else
            -- I/O error. Returning a nil filename will cause the caller to handle this properly
            errorText = string.format(
              "Error creating image file: %s", previewFileName, fileError)
            Log.logError('Mogrify', errorText)
            -- reset filename to indicate there is result (due to the I/O error)
            previewFileName = nil
          end
          -- Retrying will not make the I/O error disappear if the preview has not been written to file
        end
      end
    end)

    while not callbackReceived do
      if fallback and timeoutReached(startTime, timeout) then
        Log.logInfo("Mogrify", string.format(
          "Preview timeout reached after %.1f seconds. Using Export.",
          LrDate.currentTime() - startTime))
        return exportPhoto(photo, xSize, ySize)
      end
      LrTasks.sleep(POLL_INTERVAL)
    end

    -- The callback has been received and handled. Release the object and the memory allocated to it.
     thumbRequest = nil

    if previewReady then
      return previewFileName, FocusPointPrefs.displayModePreview, errorText
    else
      -- Although the previous request to generate a JPEG thumbnail was completed, no image was returned.
      -- Delay the next request when retrying, since the preview will take a few seconds to become available anyway.
      local retryStart = LrDate.currentTime()
      while LrDate.currentTime() - retryStart < RETRY_DELAY do
        if fallback and timeoutReached(startTime, timeout) then
          Log.logInfo("Mogrify", string.format(
            "Preview timeout reached after %.1f seconds. Using Export.",
            LrDate.currentTime() - startTime))
          return exportPhoto(photo, xSize, ySize)
        end
        LrTasks.sleep(POLL_INTERVAL)
      end
      if timeoutReached(startTime, RETRY_TIMEOUT) then
        errorText = string.format(
          "Preview could not be obtained within the maximum waiting time of %.1f seconds",
          RETRY_TIMEOUT)
        Log.logInfo("Mogrify", errorText)
        previewReady = true  -- not really, but this is required to make the progress indicator disappear
        return nil, FocusPointPrefs.displayModePreview, errorText
      end
    end
  end
end

function exportPhoto(photo, xSize, ySize)
  -- Exports an image of the photo to disk file via Lightroom's Export interfacce
  -- Same input and output parameters as the calling function

  local tempPath  = LrPathUtils.getStandardFilePath( "temp" )

  local exportFileName  = getImageFileName(photo)
  if not exportFileName then
    -- getImageFileName can return w/o result if the current file has been deleted in Second Screen mode
    local errorText = "Internal error: Image of deleted photo cannot be exported."
    Log.logWarn("Mogrify", errorText)
    return nil, FocusPointPrefs.displayModeExport, errorText
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

  local imageSource = FocusPointPrefs.displayModeExport
  local prefs = LrPrefs.prefsForPlugin( nil )
  if prefs.displayMode ~= FocusPointPrefs.displayModeExport then
    imageSource = FocusPointPrefs.displayModeFallback
  end

  -- Check whether Export was successful
  if not LrFileUtils.exists(exportFileName) then
    local errorText = "Error on export: exported file not found at " .. exportFileName
    Log.logError('Mogrify', errorText)
    return nil, imageSource, errorText
  end

  Log.logInfo('Mogrify', "Temporary image exported to " .. exportFileName)
  return exportFileName, imageSource
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
  local fileName, displayMode, errorText = writeToDisk (photo, xSize, ySize)
  if fileName then
    mogrifyResize(photo, xSize, ySize)  -- this only determines the resize params!
  end
  return fileName, displayMode, errorText
end

--[[----------------------------------------------------------------------------
  public void
  drawFocusPoints(table photo, table focuspointsTable)

  Execute Mogrify to draw the focus points in focuspointsTable.
  See 'DefaultPointRenderer.prepareRendering' for a description of the table)
------------------------------------------------------------------------------]]
function MogrifyUtils.drawFocusPoints(photo, focuspointsTable)
  local params = buildDrawParams(focuspointsTable)
  local jpegQuality = "-quality 85"  -- 85 produces file sizes close to the requestJpegThumbnail() result
  if params ~= nil then
    params = resizeParams .. params .. jpegQuality
    Log.logInfo("Mogrify", "Resizing image, drawing focus points and visualization frames")
    if not mogrifyExecute(photo, params, true) then
      Log.logError("Mogrify", "Errors occured. No markings applied")
    end
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
  if LrFileUtils.exists(tempFileName) then
    local _resultOK, errorMsg = LrFileUtils.delete( tempFileName )
    if errorMsg ~= nil then
      Log.logWarn('Mogrify', "Unable to delete Mogrify temp file " .. tempFileName .. ": " .. errorMsg)
    end
  end
end

return MogrifyUtils
