--[[
  Original work © Whizzbang Inc
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
  CanonDelegates.lua

  Purpose of this module:
  A collection of delegate functions to be passed into the DefaultPointRenderer when
  the camera is Canon:

  - funcModelSupported:    Does this plugin support the camera model?
  - funcMakerNotesFound:   Does the photo metadata include maker notes?
  - funcManualFocusUsed:   Was the current photo taken using manual focus?
  - funcGetAfPoints:       Provide data for visualizing focus points, faces etc.
  - funcGetImageInfo:      Provide specific information to be added to the 'Image Information' section.
  - funcGetShootingInfo:   Provide specific information to be added to the 'Shooting Information' section.
  - funcGetFocusInfo:      Provide the information to be entered into the 'Focus Information' section.
------------------------------------------------------------------------------]]
local CanonDelegates = {}

-- Imported LR namespaces
local LrView               = import  'LrView'

-- Required Lua definitions
local DefaultDelegates     = require 'DefaultDelegates'
local DefaultPointRenderer = require 'DefaultPointRenderer'
local ExifUtils            = require 'ExifUtils'
local FocusInfo            = require 'FocusInfo'
local Log                  = require 'Log'
local Utils                = require 'Utils'

-- Tag indicating that makernotes / AF section exists
local metaKeyAfInfoSection           = "Canon Firmware Version"

-- AF-relevant tags
local metaKeyAfPointsInFocus         = "AF Points In Focus"
local metaKeyAfPointsSelected        = "AF Points Selected"
local metaKeyValidAfPoints           = "Valid AF Points"
local metaKeyAfAreaWidth             = "AF Area Width"
local metaKeyAfAreaHeight            = "AF Area Height"
local metaKeyAfAreaWidths            = "AF Area Widths"
local metaKeyAfAreaHeights           = "AF Area Heights"
local metaKeyAfAreaXPositions        = "AF Area X Positions"
local metaKeyAfAreaYPositions        = "AF Area Y Positions"
local metaKeyAfImageWidth            = "AF Image Width"
local metaKeyAfImageHeight           = "AF Image Height"
local metaKeyExifImageWidth          = "Exif Image Width"
local metaKeyExifImageHeight         = "Exif Image Height"
local metaKeyCanonImageWidth         = "Canon Image Width"
local metaKeyCanonImageHeight        = "Canon Image Height"
local metaKeyFocusMode               = "Focus Mode"
local metaKeyAfAreaMode              = "AF Area Mode"
local metaKeyOneShotAfRelease        = "One Shot AF Release"
local metaKeySubjectToDetect         = "Subject To Detect"
local metaKeySubjectSwitching        = "Subject Switching"
local metaKeyEyeDetection            = "Eye Detection"
local metaKeyAfDetectedSubject       = "AF Detected Subject"
local metaKeyAfTrackingTarget        = "AF Tracking Target"
local metaKeyAfDetectedParts         = "AF Detected Parts"
local metaKeyAfTrackingArea          = "AF Tracking Area"
local metaKeyAfEyeUsed               = "AF Eye Used"
local metaKeyAfConfigPreset          = "AF Config Tool"
local metaKeyServoAfCharacteristics  = "Servo AF Characteristics"
local metaKeyCaseAutoSetting         = "Case Auto Setting"
local metaKeyTrackingSensitivity     = "AF Tracking Sensitivity"
local metaKeyAccelDecelTracking      = "AF Accel/Decel Tracking"
local metaKeyAfPointSwitching        = "AF Point Switching"
local metaKeyActionPriority          = "Action Priority"
local metaKeySportEvents             = "Sport Events"
local metaKeyServoFirstImage         = "AI Servo First Image"
local metaKeyServoSecondImage        = "AI Servo Second Image"
local metaKeyFocusDistanceUpper      = "Focus Distance Upper"
local metaKeyFocusDistanceLower      = "Focus Distance Lower"
local metaKeyDepthOfField            = "Depth Of Field"
local metaKeyHyperfocalDistance      = "Hyperfocal Distance"

-- Image and Shooting Information relevant tags
local metaKeyAspectRatio             = "Aspect Ratio"
local metaKeyContinuousDrive         = "Continuous Drive"
local metaKeyBurstShotNumber         = "Burst Shot Number"
local metaKeyImageStabilization      = "Image Stabilization"


-- Relevant metadata values
local metaValueOneShotAf             = "One-shot AF"

--[[----------------------------------------------------------------------------
  public table
  getAfPoints(table photo, table metadata)

  Retrieve the autofocus points from the metadata of the photo.
------------------------------------------------------------------------------]]
function CanonDelegates.getAfPoints(photo, metadata)
  local cameraModel = string.lower(photo:getFormattedMetadata("cameraModel"))

  local imageWidth
  local imageHeight

  -- ATTENTION!!!
  -- Searching for ImageWidth/Height tags in a simplified listing output may result in unusable information!
  if cameraModel == "canon eos 5d" then
    -- For some reason for this camera, the AF Image Width/Height has to be replaced by Canon Image Width/Height
    imageWidth  = ExifUtils.findFirstMatchingValue(metadata,{ metaKeyCanonImageWidth , metaKeyExifImageWidth  })
    imageHeight = ExifUtils.findFirstMatchingValue(metadata,{ metaKeyCanonImageHeight, metaKeyExifImageHeight })
  else
    imageWidth  = ExifUtils.findFirstMatchingValue(metadata,{ metaKeyAfImageWidth    , metaKeyExifImageWidth  })
    imageHeight = ExifUtils.findFirstMatchingValue(metadata,{ metaKeyAfImageHeight   , metaKeyExifImageHeight })
  end

  -- Sanity check
  if imageWidth == nil or imageHeight == nil then
    Log.logError("Canon",
      string.format("Required image size tags '%s' / '%s' not found",
        metaKeyExifImageWidth, metaKeyExifImageHeight))
    Log.logWarn("Canon", FocusInfo.msgImageFileNotOoc)
    FocusInfo.makerNotesFound = false
    return nil
  end

  local orgPhotoWidth, orgPhotoHeight = DefaultPointRenderer.getNormalizedDimensions(photo, metadata)
  local xScale = orgPhotoWidth / imageWidth
  local yScale = orgPhotoHeight / imageHeight

  local afPointWidth   = ExifUtils.findValue(metadata, metaKeyAfAreaWidth  )
  local afPointHeight  = ExifUtils.findValue(metadata, metaKeyAfAreaHeight )
  local afPointWidths  = ExifUtils.findValue(metadata, metaKeyAfAreaWidths )
  local afPointHeights = ExifUtils.findValue(metadata, metaKeyAfAreaHeights)

  if (afPointWidth == nil and afPointWidths == nil) or (afPointHeight == nil and afPointHeights == nil) then
    Log.logError("Canon", "Information on 'AF Area Width/Height' not found")
    Log.logWarn("Canon", FocusInfo.msgImageFileNotOoc)
    FocusInfo.makerNotesFound = false
    return nil
  end
  if afPointWidths == nil then
    afPointWidths = {}
  else
    afPointWidths = Utils.split(afPointWidths, " ")
  end
  if afPointHeights == nil then
    afPointHeights = {}
  else
    afPointHeights = Utils.split(afPointHeights, " ")
  end

  local afAreaXPositions = ExifUtils.findValue(metadata, metaKeyAfAreaXPositions)
  local afAreaYPositions = ExifUtils.findValue(metadata, metaKeyAfAreaYPositions)
  if afAreaXPositions == nil or afAreaYPositions == nil then
    Log.logError("Canon", "Information on 'AF Area X/Y Positions' not found")
    Log.logWarn("Canon", FocusInfo.msgImageFileNotOoc)
    FocusInfo.makerNotesFound = false
    return nil
  end

  afAreaXPositions = Utils.split(afAreaXPositions, " ")
  afAreaYPositions = Utils.split(afAreaYPositions, " ")

  -- Get necessary AF Point information
  -- Hint: ExifUtils filters '(none)' and returns nil instead.
  local afPointsInFocus  = ExifUtils.findValue(metadata, metaKeyAfPointsInFocus)
  local afPointsSelected = ExifUtils.findValue(metadata, metaKeyAfPointsSelected)

  -- Valid AF Points is the decisive information whether AF Point
  -- information is available to process or not.
  local validAfPoints = tonumber(ExifUtils.findValue(metadata, metaKeyValidAfPoints))
  if not validAfPoints or validAfPoints == 0 then
    Log.logWarn("Canon",
      string.format("Tag '%s' not found or contains no valid AF points", metaKeyValidAfPoints))
    return nil
  end

  -- AFPointsInFocus: comma-separated, zero-based indexes of AF points in focus
  if afPointsInFocus then
    Log.logInfo("Canon",
      string.format("Focus point tag '%s' found: '%s'", metaKeyAfPointsInFocus, afPointsInFocus))
    afPointsInFocus = Utils.split(afPointsInFocus, ",")
  else
    afPointsInFocus = {}
  end

  -- AFPointsSelected: comma-separated, zero-based indexes of selected AF points
  if afPointsSelected then
    Log.logInfo("Canon",
      string.format("Focus point tag '%s' found: '%s'", metaKeyAfPointsSelected, afPointsSelected))
    afPointsSelected = Utils.split(afPointsSelected, ",")
  else
    afPointsSelected = {}
  end

  local result = {
    pointTemplates = DefaultDelegates.pointTemplates,
    points = {}
  }

  -- it seems Canon Point and Shoot cameras are reversed on the y-axis
  local exifCameraType = ExifUtils.findValue(metadata, "Camera Type")
  if (exifCameraType == nil) then
    exifCameraType = ""
  end

  local yDirection = -1
  if string.lower(exifCameraType) == "compact" then
    yDirection = 1
  end

  -- Loop over all given focus point positions
  for key, _ in ipairs(afAreaXPositions) do

    -- Calculate the AF point coordinates and dimensions.
    -- On Canon, everything is referenced from the center
    local x = (imageWidth/2 + afAreaXPositions[key]) * xScale
    local y = (imageHeight/2 + (afAreaYPositions[key] * yDirection)) * yScale
    local width = 0.0
    local height = 0.0
    if afPointWidths[key] == nil then
      width = afPointWidth * xScale
    else
      width = afPointWidths[key] * xScale
    end
    if afPointHeights[key] == nil then
      height = afPointHeight * yScale
    else
      height = afPointHeights[key] * yScale
    end

    -- Determine the AF point type: in focus, selected, or inactive
    local pointType  = DefaultDelegates.POINTTYPE_AF_INACTIVE
    local isInFocus  = Utils.arrayKeyOf(afPointsInFocus,  tostring(key - 1)) ~= nil
    local isSelected = Utils.arrayKeyOf(afPointsSelected, tostring(key - 1)) ~= nil
    if isInFocus then
      pointType = DefaultDelegates.POINTTYPE_AF_FOCUS_BOX
      FocusInfo.focusPointsDetected = true
      Log.logInfo("Canon", string.format("AF point in focus detected at [x=%s, y=%s, w=%s, h=%s]",
        math.floor(x), math.floor(y), math.floor(width), math.floor(height)))
    elseif isSelected then
      pointType = DefaultDelegates.POINTTYPE_AF_SELECTED
      Log.logInfo("Canon", string.format("Selected AF point detected at [x=%s, y=%s, w=%s, h=%s]",
        math.floor(x), math.floor(y), math.floor(width), math.floor(height)))
    end

    -- Add the AF point to the rendering table
    if width > 0 and height > 0 then
      table.insert(result.points, {
        pointType = pointType,
        x = x,
        y = y,
        width = width,
        height = height
      })
    end
  end

  -- Check whether AF Tracking Area is available
  local afTrackingArea = ExifUtils.findValue(metadata, metaKeyAfTrackingArea )
  if afTrackingArea then
    Log.logInfo("Canon",
      string.format("AF Tracking Area found: '%s'", afTrackingArea))
    --
    local x, y, w, h = afTrackingArea:match("(%S+)%s+(%S+)%s+(%S+)%s+(%S+)")
    x, y, w, h = tonumber(x), tonumber(y), tonumber(w), tonumber(h)

    if x and y and w and h and x>0 and y>0 and w>0 and h>0 then
      table.insert(result.points, {
        pointType = DefaultDelegates.POINTTYPE_FACE,
        x = x,
        y = y,
        width = w,
        height = h
      })
    else
      Log.logError("Canon", "Invalid AFTrackingArea content, should be 'x y width height'")
    end
  end
  return result
end

--[[----------------------------------------------------------------------------
  private table
  addInfo(string title, string key, table props, table metadata)

  Generate a row element to be added to the current view container.
------------------------------------------------------------------------------]]
local function addInfo(title, key, props, metadata)
  local f = LrView.osFactory()

  -- returns true if focus mode is Servo AF
  local function isServoAF()
    return (props[metaKeyFocusMode]:match("Servo"))
  end

  -- returns true if focus mode is One-shot AF
  local function isOneShotAF()
    return (props[metaKeyFocusMode]:match("One-shot"))
  end


  -- Only add the 'title' as left aligned text (header)
  if not props then
    return FocusInfo.addRow(title)
  end

  -- Creates and populates the property corresponding to metadata key
  local function populateInfo(key)
    local value = ExifUtils.findValue(metadata, key)

    if (value == nil) then
      props[key] = ExifUtils.metaValueNA

    elseif (key == metaKeyAspectRatio) then
      if (value == "3:2 (APS-C crop)") then
        FocusInfo.cropMode = true
        props[key] = "APS-C"
      elseif value == "3:2 (APS-H crop)" then
        FocusInfo.cropMode = true
        props[key] = "APS-H"
      else
        -- ignore crops like 1:1, 4:3, 16:9 etc
        props[key] = ExifUtils.metaValueNA
      end

    elseif key == metaKeyEyeDetection and value == "Off" then
      -- we don't display the entry if it's disabled
      props[key] = ExifUtils.metaValueNA

    elseif key == metaKeyAfPointSwitching and value == "-1" then
      -- valid user settings are 0, 1, 2
      props[key] = ExifUtils.metaValueNA

    elseif key == metaKeyOneShotAfRelease and not isOneShotAF() then
      -- only relevant for One-shot AF modes
      props[key] = ExifUtils.metaValueNA

    elseif (key == metaKeyAfConfigPreset
         or key == metaKeyTrackingSensitivity
         or key == metaKeyAccelDecelTracking
         or key == metaKeyAfPointSwitching
         or key == metaKeyServoFirstImage
         or key == metaKeyServoSecondImage)
         and not isServoAF() then
      -- only relevant for Servo AF modes
      props[key] = ExifUtils.metaValueNA

    elseif key == metaKeyActionPriority and value == "Off" then
      props[key] = ExifUtils.metaValueNA

    elseif key == metaKeyAfDetectedSubject and value == "None" then
      props[key] = ExifUtils.metaValueNA

    elseif key == metaKeyAfTrackingTarget and value == "None" then
      props[key] = ExifUtils.metaValueNA

    elseif key == metaKeyBurstShotNumber and tonumber(value) < 1 then
      props[key] = ExifUtils.metaValueNA

    -- everything else is the default case!
    else
      props[key] = value
    end
  end

  -- Avoid issues with implicite followers that do not exist for all models
  if not key then return nil end

  -- Create and populate property with designated value
  populateInfo(key)

  -- Check if there is (meaningful) content to add
  if props[key] and props[key] ~= ExifUtils.metaValueNA then

    -- compose the row to be added
    local result = FocusInfo.addRow(title, props[key])

    -- in case of existing AF Tracking metadata, add 'AF Tracking' as a header
    if key == metaKeyAfDetectedSubject then
      return f:column {
        fill = 1, spacing = 2,
        addInfo("AF Tracking"),
        result
      }
    end

    -- check if the entry to be added has implicit followers (eg. Priority for AF modes)
    if (props[key] == metaValueOneShotAf) then
      return f:column{
        fill = 1, spacing = 2, result,
        addInfo("One Shot AF Release", metaKeyOneShotAfRelease, props, metadata) }

    elseif (key == metaKeyServoAfCharacteristics) and props[key] == "Case Auto" then
      return f:column{
        fill = 1, spacing = 2, result,
        addInfo("- Case Auto Setting", metaKeyCaseAutoSetting, props, metadata) }

    elseif (key == metaKeyActionPriority) and props[key] ~= "Off" then
      return f:column{
        fill = 1, spacing = 2, result,
        addInfo("Sport Events", metaKeySportEvents, props, metadata) }

    elseif (key == metaKeyContinuousDrive) and not props[key]:find("Single", 1, true) then
      return f:column{
        fill = 1, spacing = 2, result,
        addInfo("Burst Shot Number"  , metaKeyBurstShotNumber , props, metadata) }

    else
      -- add row as composed
      return result
    end
  else
    -- we won't display any "N/A" entries - return empty row
    return FocusInfo.emptyRow()
  end
end

--[[----------------------------------------------------------------------------
  public boolean
  modelSupported(string model)

  Indicate whether the given camera model is supported or not.
------------------------------------------------------------------------------]]
function CanonDelegates.modelSupported(model)
  -- extract the model ID for comparison
  local makeID  = "canon eos "
  local modelID = string.sub(model,#makeID+1, #model)
  return not (modelID == "300d" or
              modelID == "10d"  or
              modelID == "1ds"  or
              modelID == "d60"  or
              modelID == "1d"   or
              modelID == "d30")
end

--[[----------------------------------------------------------------------------
  public boolean
  makerNotesFound(table photo, table metadata)

  Check if the metadata for the current photo includes a 'Makernotes' section.
------------------------------------------------------------------------------]]
function CanonDelegates.makerNotesFound(_photo, metadata)
  local result = ExifUtils.findValue(metadata, metaKeyAfInfoSection)
  if not result then
    Log.logWarn("Canon",
      string.format("Tag '%s' not found", metaKeyAfInfoSection))
  end
  return (result ~= nil)
end

--[[----------------------------------------------------------------------------
  public boolean
  manualFocusUsed(table photo, table metadata)

  Indicate whether the photo was taken using manual focus.
------------------------------------------------------------------------------]]
function CanonDelegates.manualFocusUsed(_photo, metadata)
-- #TODO no test samples!
  local mfName = "Manual Focus"
  local focusMode = ExifUtils.findValue(metadata, metaKeyFocusMode)
  return focusMode and (string.sub(focusMode, 1, #mfName) == mfName )
end

--[[----------------------------------------------------------------------------
  public table
  function getImageInfo(table photo, table props, table metadata)

  Called by FocusInfo.createInfoView to append maker-specific entries to the
  'Image Information' section, if applicable; otherwise, returns an empty column.
------------------------------------------------------------------------------]]
function CanonDelegates.getImageInfo(_photo, props, metadata)
  local f = LrView.osFactory()
  local imageInfo = f:column {
    fill = 1,
    spacing = 2,
    addInfo("Crop Mode", metaKeyAspectRatio, props, metadata),
  }
  return imageInfo
end

--[[----------------------------------------------------------------------------
  public table
  function getShootingInfo(table photo, table props, table metadata)

  Called by FocusInfo.createInfoView to append maker-specific entries to the
  'Shooting Information' section, if applicable; otherwise, returns an empty column.
------------------------------------------------------------------------------]]
function CanonDelegates.getShootingInfo(_photo, props, metadata)
  local f = LrView.osFactory()
  local shootingInfo = f:column {
    fill = 1,
    spacing = 2,
    addInfo("Image Stabilization", metaKeyImageStabilization, props, metadata),
    addInfo("Continuous Drive"   , metaKeyContinuousDrive   , props, metadata),
  }
  return shootingInfo
end

--[[----------------------------------------------------------------------------
  public table
  function getFocusInfo(table photo, table props, table metadata)

  Called by FocusInfo.createInfoView to fetch the items in the 'Focus Information'
  section (which is entirely maker-specific).
------------------------------------------------------------------------------]]
function CanonDelegates.getFocusInfo(_photo, props, metadata)
  local f = LrView.osFactory()
  local focusInfo = f:column {
    fill = 1,
    spacing = 2,
    addInfo("Focus Mode"               , metaKeyFocusMode             , props, metadata),
    addInfo("AF Area Mode"             , metaKeyAfAreaMode            , props, metadata),
    addInfo("One Shot AF Release"      , metaKeyOneShotAfRelease      , props, metadata),
    addInfo("Servo First Image"        , metaKeyServoFirstImage       , props, metadata),
    addInfo("Servo Second Image"       , metaKeyServoSecondImage      , props, metadata),
    addInfo("Servo AF Preset"          , metaKeyAfConfigPreset        , props, metadata),
    addInfo("Servo AF Characteristics" , metaKeyServoAfCharacteristics, props, metadata),
    addInfo("- Tracking Sensitivity"   , metaKeyTrackingSensitivity   , props, metadata),
    addInfo("- Accel/Decel Tracking"   , metaKeyAccelDecelTracking    , props, metadata),
    addInfo("Subject To Detect"        , metaKeySubjectToDetect       , props, metadata),
    addInfo("Subject Switching"        , metaKeySubjectSwitching      , props, metadata),
    addInfo("Eye Detection"            , metaKeyEyeDetection          , props, metadata),
    addInfo("AF Point Auto-Switching"  , metaKeyAfPointSwitching      , props, metadata),
    addInfo("Action Priority"          , metaKeyActionPriority        , props, metadata),
    addInfo("- Detected Subject"       , metaKeyAfDetectedSubject     , props, metadata),
    addInfo("- Detected Parts"         , metaKeyAfDetectedParts       , props, metadata),
    addInfo("- Tracking Target"        , metaKeyAfTrackingTarget      , props, metadata),
    addInfo("- Eye Used"               , metaKeyAfEyeUsed             , props, metadata),
    FocusInfo.addSpace(),
    FocusInfo.addSeparator(),
    FocusInfo.addSpace(),
    addInfo("Focus Distance (Upper)"   , metaKeyFocusDistanceUpper    , props, metadata),
    addInfo("Focus Distance (Lower)"   , metaKeyFocusDistanceLower    , props, metadata),
    addInfo("Depth of Field"           , metaKeyDepthOfField          , props, metadata),
    addInfo("Hyperfocal Distance"      , metaKeyHyperfocalDistance    , props, metadata),
    }
  return focusInfo
end

return CanonDelegates -- ok
