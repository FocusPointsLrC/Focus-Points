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
  Metadata.lua

  Purpose of this module:
  Entry point for 'Show Metadata' menu command.
  Main control of data processing and user dialog.
------------------------------------------------------------------------------]]
local Metadata = {}

-- Imported LR namespaces
local LrApplication     = import  'LrApplication'
local LrFunctionContext = import  'LrFunctionContext'
local LrPrefs           = import  'LrPrefs'
local LrStringUtils     = import  'LrStringUtils'
local LrTasks           = import  'LrTasks'

-- Required Lua definitions
local ExifUtils         = require 'ExifUtils'
local FocusPointPrefs   = require 'FocusPointPrefs'
local Log               = require 'Log'
local MetadataDialog    = require 'MetadataDialog'
local Utils             = require 'Utils'

-- Forward references
local createParts, splitForColumns

--[[----------------------------------------------------------------------------
  private void
  showMetadata()

  Invoked when 'Focus Point Viewer -> Show Metadata' is selected.
  Reads the metadata from the selected photo's image file and displays a dialog
  for browsing and filtering by specific tags and values.
------------------------------------------------------------------------------]]
local function showMetadata()

  LrFunctionContext.callWithContext("showDialog", function(_context)

    local catalog = LrApplication.activeCatalog()
    local targetPhoto = catalog:getTargetPhoto()

    -- To avoid nil pointer errors in case of "dirty" installation (copy over old files)
    FocusPointPrefs.InitializePrefs(LrPrefs.prefsForPlugin(nil))

    -- Initialize logging
    Log.initialize()

    -- Set scale factor for sizing of dialog window
    if WIN_ENV then
      FocusPointPrefs.setDisplayScaleFactor()
      Log.logInfo("System", "Display scaling level " ..
              math.floor(100/FocusPointPrefs.getDisplayScaleFactor() + 0.5) .. "%")
    end

    -- Separate system info log from app info log
    Log.logInfo("Metadata", string.rep("=", 72))
    Log.logInfo("Metadata", "Image: " .. targetPhoto:getRawMetadata("path"))

    LrTasks.startAsyncTask(function(_context)

      LrFunctionContext.callWithContext("function", function(_dialogContext)
        local column1, column2, column3, column1Length, column2Length, column3Length, numLines

        -- Read metadata from image file.
        -- The 'Loading Data' dialog has been removed.
        local metadata = ExifUtils.readMetadata(targetPhoto, true)
        metadata = ExifUtils.filterInput(metadata)

        -- Split the text output into two columns, one for the labels and one for the values.
        column1, column2, column3, column1Length, column2Length, column3Length, numLines = splitForColumns(metadata)

        -- Present metadata in dialog
        local result = MetadataDialog.showDialog(
          targetPhoto, column1, column2, column3, column1Length, column2Length, column3Length, numLines)

        -- Check whether dialog has been left by pressing "Open as text"
        local metadataFileName = ExifUtils.getMetadataFileName()
        if result == "other" then
          -- if so, open metadata file in default application (and keep it)
          Utils.openFileInApp(metadataFileName)
        else
          -- otherwise remove the temp file
          ExifUtils.cleanup()
        end
      end)
    end)
  end)
end

--[[----------------------------------------------------------------------------
  private table labels, table values, int maxLabelLength, int maxValueLength, int numOfLines
  splitForColumns(table metadata)

  Post-process the metadata table with labels and values to pass each column
  as a string to the scrolled view element of the dialog.
  Returns labels, values, maxLabelLength, maxValueLength, numOfLines
------------------------------------------------------------------------------]]
function splitForColumns(metadata)

  local parts = createParts(metadata)
  local groups = ""
  local labels = ""
  local values = ""
  local maxGroupLength = 0
  local maxLabelLength = 0
  local maxValueLength = 0
  local numOfLines = 0
  local limitGroupLength =  32   -- to avoid long group names
  local limitLabelLength =  32   -- to avoid long tag names
  local limitValueLength = 128   -- to avoid super-long value strings that whill slow down display
  local utfEllipsis = string.char(0xE2, 0x80, 0xA6)

  for k in pairs(parts) do

    -- Get next group/label/value pair
    local g = parts[k].group or ""
    local l = parts[k].label or ""
    local v = parts[k].value or ""

    -- Limit length of a displayed value string, indicate spillover by ellipsis dots.
    -- The original text can still be examined by opening the metadata text file in an editor
    if string.len(g) > limitGroupLength then
      g = LrStringUtils.truncate(g, limitGroupLength) .. utfEllipsis
    end
    if string.len(l) > limitLabelLength then
      l = LrStringUtils.truncate(l, limitLabelLength) .. utfEllipsis
    end
    if string.len(v) > limitValueLength then
      v = LrStringUtils.truncate(v, limitValueLength) .. utfEllipsis
    end

    -- Update table dimension parameters
    maxGroupLength = math.max(maxGroupLength, string.len(g))
    maxLabelLength = math.max(maxLabelLength, string.len(l))
    maxValueLength = math.max(maxValueLength, string.len(v))
    numOfLines = numOfLines + 1

    -- Append current label/value pair to the table columns
    groups = groups .. g .. "\r"
    labels = labels .. l .. "\r"
    values = values .. v .. "\r"
  end

  Log.logDebug("ShowMetadata", "splitForColumns: Groups: " .. groups)
  Log.logDebug("ShowMetadata", "splitForColumns: Labels: " .. labels)
  Log.logDebug("ShowMetadata", "splitForColumns: Values: " .. values)
  Log.logDebug("ShowMetadata", "splitForColumns: maxGroupLength: " .. maxGroupLength)
  Log.logDebug("ShowMetadata", "splitForColumns: maxLabelLength: " .. maxLabelLength)
  Log.logDebug("ShowMetadata", "splitForColumns: maxValueLength: " .. maxValueLength)
  Log.logDebug("ShowMetadata", "splitForColumns: numOfLines: " .. numOfLines)

  return groups, labels, values, maxGroupLength, maxLabelLength, maxValueLength, numOfLines

end

--[[----------------------------------------------------------------------------
  private table
  createParts(table metadata)

  Parses ExifTool's text output to fill a table with two columns, representing
  the labels and values. Returns a table containing two columns, one with labels
  and the other with values.
------------------------------------------------------------------------------]]
function createParts(metadata)

  local parts = {}
  local num = 1;

  local function createPart(group, label, value)
    -- Takes label & value strings for a metadata tag to package them in a table element
    local p = {}
    p.group = LrStringUtils.trimWhitespace(group)
    p.label = LrStringUtils.trimWhitespace(label)
    p.value = LrStringUtils.trimWhitespace(value)
    Log.logFull("ShowMetadata", "Parsed '" .. p.group .. "  " .. p.label .. "' = '" .. p.value .. "'")
    return p
  end

  -- Parse ExifTool output line by line
  for line in metadata:gmatch("[^\r\n]+") do

    local group, label, value = line:match("^%[([^%]]+)%]%s*(.-)%s*:%s*(.*)$")
    if group then
      parts[num] = createPart(group, label, value)
      num = num + 1
    end
  end

  return parts
end

LrTasks.startAsyncTask( showMetadata )

return Metadata
