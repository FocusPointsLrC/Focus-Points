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
  FocusPointPrefs.lua

  Purpose of this module:
  - Manages the plugin settings (storage, set, get)
  - Central place for important plugin definitions (e.g. keyboard shortcuts, URLs)
  - Provides the plugin settings dialog (called by LrPluginInfoProvider)
------------------------------------------------------------------------------]]
local FocusPointPrefs = {}

-- WIN_ENV = false -- for testing purposes only !!

-- Imported LR namespaces
local LrApplication   = import  'LrApplication'
local LrColor         = import  'LrColor'
local LrDialogs       = import  'LrDialogs'
local LrFileUtils     = import  'LrFileUtils'
local LrHttp          = import  'LrHttp'
local LrPrefs         = import  'LrPrefs'
local LrShell         = import  'LrShell'
local LrTasks         = import  'LrTasks'
local LrView          = import  'LrView'

-- Required Lua definitions
local Info            = require 'Info'
local KeyboardLayout  = require 'KeyboardLayout'
local Log             = require 'Log'
local Utils           = require 'Utils'

-- Important plugin definitions and settings -----------------------------------

-- Size options for plugin window
FocusPointPrefs.pluginWindow3XL    = 0.9
FocusPointPrefs.pluginWindowXXL    = 0.8
FocusPointPrefs.pluginWindowXL     = 0.7
FocusPointPrefs.pluginWindowL      = 0.6
FocusPointPrefs.pluginWindowM      = 0.5
FocusPointPrefs.pluginWindowS      = 0.4

-- Scaling values for size of 'pixel focus' box, relative to focus point window size
FocusPointPrefs.focusBoxSize = { 0, 0.04, 0.1 }

-- Indices to access scaling values in focusBoxSize table
FocusPointPrefs.focusBoxSizeSmall  = 1
FocusPointPrefs.focusBoxSizeMedium = 2
FocusPointPrefs.focusBoxSizeLarge  = 3
FocusPointPrefs.initfocusBoxSize   = FocusPointPrefs.focusBoxSizeMedium

-- Settings for keybopard shortcut input field
FocusPointPrefs.kbdInputInvisible  = 0
FocusPointPrefs.kbdInputSmall      = 1
FocusPointPrefs.kbdInputRegular    = 2

-- Settings for photo view base image display
FocusPointPrefs.displayModePreview = 1
FocusPointPrefs.displayModeExport  = 2
FocusPointPrefs.displayModeDirect  = 3
FocusPointPrefs.displayModeFallback= 4
FocusPointPrefs.displayModeName    = {"Preview", "Export", "Direct", "Export (fallback)" }

-- Second Screen sub-modes
FocusPointPrefs.secondScreenBehaviorFollow      = "Follow"
FocusPointPrefs.secondScreenBehaviorInteractive = "Interactive"

-- Definitions to handle Update mechanism
local previewBuildNumbers         = 8000 -- .. 8999 reserved range for preview build numbers
local preReleaseBuildNumbers      = 9000 -- .. 9999 reserved range for pre-release build numbers

local branch                  = Info.VERSION.branch
local githubRawBaseUrl        = Info.VERSION.rawBaseUrl

local masterVersionFile       = githubRawBaseUrl .. "master/Version.txt"
local masterVersionFileLegacy = githubRawBaseUrl .. "master/focuspoints.lrplugin/Version.txt"
local branchVersionFile       = githubRawBaseUrl .. branch .. "/Version.txt"
local branchVersionFileLegacy = githubRawBaseUrl .. branch .. "/focuspoints.lrplugin/Version.txt"

local versionChecked          = false
local latestVersion
local versionFileFoundUrl
local latestVersionUrl

-- URL definitions for accessing documents from the UI
FocusPointPrefs.urlUserManual       = "https://focuspointslrc.github.io/Focus-Points/docs/Focus-Points.html"
FocusPointPrefs.urlTroubleShooting  = "https://focuspointslrc.github.io/Focus-Points/docs/Troubleshooting_FAQ.html"
FocusPointPrefs.urlkbdShortcuts     = "https://focuspointslrc.github.io/Focus-Points/docs/Focus-Points.html#keyboard-shortcuts"
FocusPointPrefs.urlNewFeatures      = "https://focuspointslrc.github.io/Focus-Points/docs/V4-New-Features.html"
FocusPointPrefs.urlFAQ              = "https://focuspointslrc.github.io/Focus-Points/docs/V4-FAQ.html"

-- URL definitions for clickForHelp
local urlHelpOnScreenScaling        = FocusPointPrefs.urlUserManual  .. "#screen-scaling"
local urlHelpOnStraightenControls   = FocusPointPrefs.urlUserManual  .. "#enable-controls-for-straightening"
local urlHelpOnTaggingControls      = FocusPointPrefs.urlUserManual  .. "#enable-controls-for-tagging"
local urlHelpOnKeyboardLayout       = FocusPointPrefs.urlUserManual  .. "#keyboard-layout"
local urlHelpOnDisplayMode          = FocusPointPrefs.urlNewFeatures .. "#2-display-modes"
local urlHelpOnPerformanceControl   = FocusPointPrefs.urlUserManual  .. "#performance-control"
local urlHelpOnSecondScreenMode     = FocusPointPrefs.urlNewFeatures .. "#1-second-screen-mode"
local urlHelpOnPluginWindowScaling  = FocusPointPrefs.urlUserManual  .. "#size-of-plugin-window"
local urlHelpOnKeyboardInput        = FocusPointPrefs.urlUserManual  .. "#text-input-field-for-keyboard shortcuts"
local urlHelpOnTruncateLongText     = FocusPointPrefs.urlUserManual  .. "#truncate-or-wrap-long-strings"
local urlHelpOnViewingOptions       = FocusPointPrefs.urlUserManual  .. "#viewing-options"
local urlHelpOnLoggingLevel         = FocusPointPrefs.urlUserManual  .. "#logging"
local urlHelpOnStraighteningOptions = FocusPointPrefs.urlUserManual  .. "#straightening-options"

FocusPointPrefs.urlKofi             = "https://ko-fi.com/focuspoints"

-- Keyboard shortcut definitions
FocusPointPrefs.kbdShortcutsDirectMode      = "dD"
FocusPointPrefs.kbdShortcutsPreviewImage    = "vV"
FocusPointPrefs.kbdShortcutsExportImage     = "eE"
FocusPointPrefs.kbdShortcutsPrev            = "-<"
FocusPointPrefs.kbdShortcutsNext            = " +"
FocusPointPrefs.kbdShortcutsPick            = "p"
FocusPointPrefs.kbdShortcutsUnflag          = "u"
FocusPointPrefs.kbdShortcutsReject          = "x"
FocusPointPrefs.kbdShortcutsPickNext        = "P"
FocusPointPrefs.kbdShortcutsUnflagNext      = "U"
FocusPointPrefs.kbdShortcutsRejectNext      = "X"
FocusPointPrefs.kbdShortcutsStraighten      = "sS"
FocusPointPrefs.kbdShortcutsStraightenReset = "rR"
FocusPointPrefs.kbdShortcutsCheckLog        = "lL"
FocusPointPrefs.kbdShortcutsTroubleShooting = "?hH"
FocusPointPrefs.kbdShortcutsHelp            = "kK"
FocusPointPrefs.kbdShortcutsUserManual      = "mM"
FocusPointPrefs.kbdShortcutsClose           = "cC"

-- Local variables -------------------------------------------------------------

local isUpdateAvailable
local displayScaleFactor = 0.0
local LR5 = (LrApplication.versionTable().major == 5)
local bind = LrView.bind

--[[----------------------------------------------------------------------------
  public void
  InitializePrefs()

  Initialize preferences at first run after installation of plugin.
  Makes sure that newly introduced settings have a defined value (and are not nil).
------------------------------------------------------------------------------]]
function FocusPointPrefs.InitializePrefs(prefs)
  -- Set any undefined properties to their default values
  if not prefs.screenScaling                    then prefs.screenScaling              = 0 end
  if not prefs.pluginWindowScaling              then prefs.pluginWindowScaling        = FocusPointPrefs.pluginWindowL end
  if     prefs.secondScreenMode        == nil then prefs.secondScreenMode           = true      end
  if not prefs.secondScreenBehavior           then prefs.secondScreenBehavior       = FocusPointPrefs.secondScreenBehaviorInteractive end
  if not prefs.previewAspectRatio             then prefs.previewAspectRatio         = 3/2       end
  if     prefs.truncateLongText          == nil then prefs.truncateLongText           = true      end
  if not prefs.truncateLimit                    then prefs.truncateLimit              = 32        end
  if     prefs.hideKofiControl           == nil then prefs.hideKofiControl            = false     end
  if not prefs.focusBoxSize                     then prefs.focusBoxSize               = FocusPointPrefs.focusBoxSize[FocusPointPrefs.initfocusBoxSize] end
  if not prefs.focusBoxColor                    then prefs.focusBoxColor              = "red"     end
  if     prefs.straightenControls        == nil then prefs.straightenControls         = true      end
  if     prefs.taggingControls           == nil then prefs.taggingControls            = true      end
  if     prefs.keyboardLayout            == nil then prefs.keyboardLayout             = KeyboardLayout.autoDetectLayout end
  if not prefs.loggingLevel                     then prefs.loggingLevel               = "AUTO"    end
  if     prefs.overwriteCropAngle        == nil then prefs.overwriteCropAngle         = false     end
  if     prefs.overwriteCropAngleWarning == nil then prefs.overwriteCropAngleWarning  = false     end
  if     prefs.overwriteTransform        == nil then prefs.overwriteTransform         = false     end
  if     prefs.overwriteTransformWarning == nil then prefs.overwriteTransformWarning  = false     end
  if     prefs.straightenLimits          == nil then prefs.straightenLimits           = false     end
  if not prefs.straightenLimitLow               then prefs.straightenLimitLow         = -0        end
  if not prefs.straightenLimitHigh              then prefs.straightenLimitHigh        =  45       end
  if not prefs.straightenSummaryCondition       then prefs.straightenSummaryCondition = "SKIPPED" end
  if     prefs.straightenApplyBias       == nil then prefs.straightenApplyBias        = false     end
  if not prefs.straightenBias                   then prefs.straightenBias             = 0.0       end
  if     prefs.checkForUpdates           == nil then prefs.checkForUpdates            = true      end
  if     prefs.keyboardInput             == nil then prefs.keyboardInput              = FocusPointPrefs.kbdInputRegular end
  if     prefs.previewFallback           == nil then prefs.previewFallback            = true      end
  if not prefs.previewTimeout                   then prefs.previewTimeout             = 0.5       end
  if     prefs.previewShowProgress       == nil then prefs.previewShowProgress        = true      end
  if not prefs.previewProgressDelay             then prefs.previewProgressDelay       = 0.5       end

  -- OS dependent initialization: displayMode
  -- required as long as not all modes can be supported on both WIN and MAC
  if not prefs.displayMode then
    if WIN_ENV then
      prefs.displayMode = FocusPointPrefs.displayModePreview
    else
      prefs.displayMode = FocusPointPrefs.displayModeDirect
    end
  end

  -- Just to be safe - there's no choice for MAC until Mogrify support is implemented on macOS)
  if not WIN_ENV then
    prefs.displayMode = FocusPointPrefs.displayModeDirect
  end

end

--[[----------------------------------------------------------------------------
  public float
  getWinScalingFactor()

  Retrieves the Windows DPI scaling level registry key using the REG.EXE command:
  HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics, AppliedDPI
  Returns the display scaling factor (100/scale_in_percent)
------------------------------------------------------------------------------]]
local function getWinScalingFactor()
  local output = Utils.getTempFileName()
  local cmd = "reg.exe query \"HKEY_CURRENT_USER\\Control Panel\\Desktop\\WindowMetrics\" -v AppliedDPI >\"" .. output .. "\""
  local result

  -- Query registry value by calling REG.EXE
  local rc = LrTasks.execute(cmd)
  Log.logDebug("System", "Retrieving DPI scaling level from Windosws registry using REG.EXE")
  Log.logDebug("System", "REG command: " .. cmd .. ", rc=" .. rc)

  -- Read redirected stdout from temp file and find the line that starts with "AppliedDPI"
  local regOutput = LrFileUtils.readFile(output)
  local regOutputStr = "^"
  local dpiValue, scale
  for line in string.gmatch(regOutput, ("[^\r\n]+")) do
    local item = Utils.split(line, " ")
    if item and #item >= 3 then
      if item[1] == "AppliedDPI" and item[2] == "REG_DWORD" then
        dpiValue = item[3]
        scale = math.floor(tonumber(dpiValue) * 100/96 + 0.5)
      end
    end
    regOutputStr = regOutputStr .. line .. "^"
  end
  Log.logDebug("System", "REG output: " .. regOutputStr)

  -- Set and log the result
  if dpiValue then
    result = 100 / scale
    Log.logDebug("System", string.format("DPI scaling level %s = %sdpi ~ %s%%", dpiValue, tonumber(dpiValue), scale))
  else
    result = 100 / 125
    Log.logWarn("System", "Unable to retrieve Windows scaling level, using 125% instead")
  end

  -- Clean up: remove the temp file
  if LrFileUtils.exists(output) and not LrFileUtils.delete(output) then
    Log.logWarn("System", "Unable to delete REG output file " .. output)
  end

  return result
end

--[[----------------------------------------------------------------------------
  public void
  setDisplayScaleFactor()

  Sets the displayScaleFactor to the value selected by the user in plugin settings.
  If the 'Auto' option is selected, the Windows system value is retrieved and used.
------------------------------------------------------------------------------]]
function FocusPointPrefs.setDisplayScaleFactor()
  local prefs = LrPrefs.prefsForPlugin( nil )
  if WIN_ENV then
    if prefs.screenScaling ~= 0 then
      displayScaleFactor = prefs.screenScaling
    else
      displayScaleFactor = getWinScalingFactor()
    end
  else
    -- just to be safe, normally, this branch should never be executed
    displayScaleFactor = 1.0
  end
end

--[[----------------------------------------------------------------------------
  public float
  getDisplayScaleFactor()

  Returns the current value of displayScaleFactor. In case of 'Auto' setting,
  the system scaling factor is returned.
------------------------------------------------------------------------------]]
function FocusPointPrefs.getDisplayScaleFactor()
  if displayScaleFactor == 0 then
    FocusPointPrefs.setDisplayScaleFactor()
  end
  return displayScaleFactor
end

--[[----------------------------------------------------------------------------
  public float
  getPluginWindowSize()

  Returns the sizing factor for supported plugin window sizes S..3XL
------------------------------------------------------------------------------]]
function FocusPointPrefs.getPluginWindowSize()
  local prefs = LrPrefs.prefsForPlugin( nil )
  return prefs.pluginWindowScaling
end

--[[----------------------------------------------------------------------------
  public string
  startVersionCheck()

  Starts an asynchronous check for the latest plug-in release.
  The current release information is stored in a text file 'Version.txt' on Github.
  The retrieved information is cached for the remainder of the Lightroom session:
  - versionChecked
  - isUpdateAvailable
  - latestVersion
------------------------------------------------------------------------------]]
function FocusPointPrefs.startVersionCheck()
  local prefs = LrPrefs.prefsForPlugin( nil )

  -- If update check is not wanted, don't even try to fetch the version information from server
  if not prefs.checkForUpdates then return end

  -- If a version check has already been performed in this plugin lifecycle we don't need another
  if versionChecked then return end
  versionChecked = true

  local function getVersionFile(urlNew, urlLegacy)
    -- Helper to retrieve the Version.txt file.
    -- Returns file content and source where the file was found.

    local function tryUrl(url)
      Log.logDebug("System", "Update Check: trying to retrieve Version.txt from " .. url)

      local body, headers = LrHttp.get(url)

      if not headers then
      -- No HTTP response at all (timeout, DNS, connection failure, etc.).
        Log.logWarn("System",
          "Update Check: no HTTP response received from " .. url)
        return nil
      end

      if headers.status ~= 200 then
      -- Server responded, but with an error (404, 403, 503, ...).
        Log.logWarn("System",
          "Update Check: HTTP " .. tostring(headers.status) ..
          " returned for " .. url)
        return nil
      end

      if not body or body == "" then
      -- The request succeeded but the downloaded file is unusable.
        Log.logWarn("System",
          "Update Check: empty Version.txt received from " .. url)
        return nil
      end

      if not (body:find("v%d+%.%d+%.%d+") or body:find("v%d+%.%d+%.%d+%.%d+")) then
      -- The request succeeded but the downloaded file has invalid content
        Log.logWarn("System",
            "Update Check: invalid Version.txt received from " .. url)
        return nil
      end

      -- Success
      return body
    end

    local body = tryUrl(urlNew)
    if body then
      return body, urlNew
    end

    body = tryUrl(urlLegacy)
    if body then
      return body, urlLegacy
    end

    return nil
  end

  local function parseVersionInfo(body)
    -- Helper to parse contents
    if not body then return nil end

    -- Parse version information
    local version = string.match(body, "v%d+%.%d+%.%d+%.%d+") or
                    string.match(body, "v%d+%.%d+%.%d+")

    -- Normalize to four components
    if version and not version:match("^v%d+%.%d+%.%d+%.%d+$") then
      version = version .. ".0"
    end
    local url = string.match(body, "https?://%S+")

    return version, url
  end

  local function checkIfUpdateAvailable()
    local result = false

    if latestVersion then
      -- valid information regarding the latest released version has been retrieved from server
      Log.logDebug("System", string.format(
        "Update Check: latest version '%s' retrieved from %s", latestVersion, versionFileFoundUrl))
      Log.logDebug("System", string.format(
        "Update Check: latest version at %s", latestVersionUrl))
      local major, minor, revision, build = latestVersion:match("v(%d+)%.(%d+)%.(%d+)%.(%d+)")
      if major and minor and revision then
        -- we have a valid version number from the URL
        local pluginVersion = Info.VERSION
        if tonumber(major) > pluginVersion.major then
          -- new major version available
          result = true
        elseif tonumber(major) == pluginVersion.major then
          if  tonumber(minor) > pluginVersion.minor then
            -- new minor version available
            result = true
          elseif tonumber(minor) == pluginVersion.minor then
            if tonumber(revision) > pluginVersion.revision then
              -- new revision available
              result = true
            elseif tonumber(revision) == pluginVersion.revision then
              -- major, minor versions and revision numbers are the same, so check the build version
              if build then
                if tonumber(build) >= preReleaseBuildNumbers then
                  -- latest release is a pre-release
                  if  pluginVersion.build
                  and pluginVersion.build >= preReleaseBuildNumbers
                  and pluginVersion.build < tonumber(build) then
                    -- new pre-release available
                    result = true
                  end
                elseif tonumber(build) < previewBuildNumbers then
                  -- latest release is a regular release
                  if pluginVersion.build then
                    if tonumber(pluginVersion.build) >= preReleaseBuildNumbers then
                      -- release available for local pre-release version
                      result = true
                    elseif tonumber(build) > pluginVersion.build then
                      -- new build available
                      result = true
                    end
                  end
                else
                  -- no update mechanism for preview builds
                end
              end
            end
          end
        end
      else
        Log.logWarn("System", "Update check failed, no valid combination of major, minor and revision number")
      end
    end
    return result
  end

  -- Need to execute this as a collaborative task
  Log.logInfo("System", "Update Check: started")

  LrTasks.startAsyncTask( function()
    local body, url

    -- By default, if an error occurs, it is assumed that there is no update available
    isUpdateAvailable   = false
    versionFileFoundUrl = nil
    latestVersion       = nil
    latestVersionUrl    = nil

    -- Read the contents of the 'latest version' file
    body, url = getVersionFile(branchVersionFile, branchVersionFileLegacy)
    versionFileFoundUrl = url
    if not body and branch ~= "master" then
      -- Branch no longer available.
      -- Try the public release on master instead.
      body, url = getVersionFile(masterVersionFile, masterVersionFileLegacy)
      versionFileFoundUrl = url
    end

    if not body then
      -- for some reason (e.g. no access to GitHub) there is no valid information available
      Log.logWarn("System", "Update Check: finished. Unable to retrieve version information.")
      return
    end

    -- Parse the retrieved version information
    latestVersion, latestVersionUrl = parseVersionInfo(body)
    if latestVersion then
      -- Perform the actual update check
      isUpdateAvailable = checkIfUpdateAvailable()
    else
      Log.logWarn("System", "Update Check: invalid version information in Version.txt")
    end

    -- Log end of check and result
    local resultOfCheck = "No update available"
    if isUpdateAvailable then
      resultOfCheck = "Update to version " .. latestVersion .. " available"
    end
    Log.logInfo("System", "Update Check: finished. " .. resultOfCheck)
  end)

end

--[[----------------------------------------------------------------------------
  public boolean, string latestVersion
  isUpdateAvailable()

  Checks whether an updated version of the plug-in is available
  Returns
  - true if so, otherwise false
  - the version number of the latest plug-in release as a string eg. 'v3.1.3'
------------------------------------------------------------------------------]]
function FocusPointPrefs.isUpdateAvailable()
  return isUpdateAvailable, latestVersion
end

--[[----------------------------------------------------------------------------
  public boolean
  getReleaseURL()

  For a pre-release,    returns ./releases
  For a public release, returns ./releases/latest
------------------------------------------------------------------------------]]
function FocusPointPrefs.getReleaseURL()
  if latestVersionUrl then
    -- link to release from version.txt file
    return latestVersionUrl
  else
    local pluginVersion = Info.VERSION
    if tonumber(pluginVersion.build) >= preReleaseBuildNumbers then
      -- pre-release
      return FocusPointPrefs.urlReleases
    else
      -- public release
      return FocusPointPrefs.urlLatestRelease
    end
  end
end

--[[----------------------------------------------------------------------------
  public table
  genSectionsForBottomOfDialog( table viewFactory, propertyTable )

  Called by Lightroom's Plugin Manager when the plugin is loaded.
  This creates the bottom section of the dialogue box on the plugin settings page.
  This section contains the plugin-specific settings that the user can modify.
------------------------------------------------------------------------------]]
function FocusPointPrefs.genSectionsForBottomOfDialog( f )
  local prefs = LrPrefs.prefsForPlugin( nil )

  -- Set the defaults
  FocusPointPrefs.InitializePrefs(prefs)

  -- Helper to link a setting to user manual explanation for quick help
  local function clickForHelp(url, text)
    local info = "[?]"
    if url then
      if not text then text = info end
      return
        f:static_text {
          title = text,
          text_color = LrColor(0, 0.25, 1),
          immediate = true,
          mouse_down = function()
            LrTasks.startAsyncTask(function()
              LrHttp.openUrlInBrowser(url)
            end)
          end,
        }
      else
        return LrView.kIgnoredView
      end
  end

  -- Check for updates
  local updateMessage
  if prefs.checkForUpdates and FocusPointPrefs.isUpdateAvailable() then
    updateMessage =
      f:row {
        f:static_text {title = "Update available!", text_color=LrColor("red")},
        f:spacer{fill_horizontal = 1},
        f:push_button {
          title = "Open URL",
          action = function() LrHttp.openUrlInBrowser( FocusPointPrefs.getReleaseURL() ) end,
        },
      }
  else
    updateMessage = f:static_text{ title = "" }
  end

  -- Width of the drop-down lists in px, to make the naming aligned across rows
  local dropDownWidth = 6

  local function sectionScreenScaling()
    if not WIN_ENV then return nil end
    return {
      title = "Screen Scaling",
      f:row {
        bind_to_object = prefs,
        spacing = f:control_spacing(),
        f:popup_menu {
          title = "Scaling",
          value = bind("screenScaling"),
          width_in_chars = dropDownWidth,
          items = {
            { title = "Auto", value = 0    },
            { title = "100%", value = 1.0  },
            { title = "125%", value = 0.8  },
            { title = "150%", value = 0.67 },
            { title = "175%", value = 0.57 },
            { title = "200%", value = 0.5  },
            { title = "250%", value = 0.4  },
          }
        },
        f:static_text {
          title = 'Select "Auto" for same display scale factor as on Windows OS (Display Settings -> Scale)'
        },
        f:spacer { fill_horizontal = 1 },
        clickForHelp( urlHelpOnScreenScaling ),
      },
    }
  end
  local function sectionUserInterface()
    local function straightenControlsSetting()
      if LR5 then return LrView.kIgnoredView end
      return f:row {
        bind_to_object = prefs,
        spacing = f:control_spacing(),
        f:popup_menu {
          title = "straightenControls",
          value = bind("straightenControls"),
          width_in_chars = dropDownWidth,
          items = {
            { title = "On",  value = true  },
            { title = "Off", value = false },
          }
        },
        f:static_text {
          title = "Enable controls to straighten a photo (mouse and keyboard)"
        },
        clickForHelp( urlHelpOnStraightenControls ),
      }
    end
    local function taggingControlsSetting()
      if LR5 then return LrView.kIgnoredView end
      return f:row {
        bind_to_object = prefs,
        spacing = f:control_spacing(),
        f:popup_menu {
          title = "taggingControls",
          value = bind("taggingControls"),
          width_in_chars = dropDownWidth,
          items = {
            { title = "On",  value = true  },
            { title = "Off", value = false },
          }
        },
        f:static_text {
          title = "Enable controls for flagging, rating and coloring a photo (mouse and keyboard)"
        },
        clickForHelp( urlHelpOnTaggingControls ),
      }
    end
    local function keyboardLayoutSetting()
      if LR5 then return LrView.kIgnoredView end
      return f:row {
        bind_to_object = prefs,
        spacing = f:control_spacing(),
        f:popup_menu {
          title = "keyboardLayout",
          value = bind("keyboardLayout"),
          width_in_chars = dropDownWidth,
          items = KeyboardLayout.buildDropdownItems(),
        },
        f:static_text {
            title = "Keyboard layout. Required to process shortcuts 0..9 for rating and coloring"
        },
        clickForHelp( urlHelpOnKeyboardLayout ),
      }
    end
    local function displayModeSetting()
      if not WIN_ENV then return LrView.kIgnoredView end
      return
        f:row {
          bind_to_object = prefs,
          spacing = f:control_spacing(),
          f:popup_menu {
            title = "displayMode",
            value = bind("displayMode"),
            width_in_chars = dropDownWidth,
            items = {
              { title = "Preview Image (Fast)",    value = FocusPointPrefs.displayModePreview  },
              { title = "Export Image (Reliable)", value = FocusPointPrefs.displayModeExport },
              { title = "Direct View (Live)",      value = FocusPointPrefs.displayModeDirect    },
            },
          },
          f:static_text {
            title = "Display mode. For details on the available modes, please refer to"
          },
          clickForHelp( urlHelpOnDisplayMode ),
        }
    end
    local function previewGenerationSettings()
      if not WIN_ENV then return nil end
      return f:column{
        spacing = f:control_spacing(),
        f:row {
          bind_to_object = prefs,
          spacing = f:control_spacing(),
          f:popup_menu {
            title = "previewFallback",
            value = bind("previewFallback"),
            width_in_chars = dropDownWidth,
            items = {
              { title = "On", value = true },
              { title = "Off", value = false },
            },
          },
          f:static_text {
            title = "Preview Image: Use Export Image if no preview becomes available within"
          },
          f:edit_field {
            value = bind("previewTimeout"),
            width_in_chars = 3,
            min = 0,
            max = 10,
            precision = 1,
          },
          f:static_text {
            title = "seconds",
          },
          clickForHelp( urlHelpOnPerformanceControl ),
        },
        f:row {
          bind_to_object = prefs,
          spacing = f:control_spacing(),
          f:popup_menu {
            title = "previewShowProgress",
            value = bind("previewShowProgress"),
            width_in_chars = dropDownWidth,
            items = {
              { title = "On", value = true },
              { title = "Off", value = false },
            },
          },
          f:static_text {
            title = "Preview Image: Show progress notification after "
          },
          f:edit_field {
            value = bind("previewProgressDelay"),
            width_in_chars = 3,
            min = 0,
            max = 10,
            precision = 1,
          },
          f:static_text {
            title = "seconds",
          },
        },
      }
    end

    return {
      title = "User Interface",

      --------------------------------------------------------------------------
      -- Second Screen
      --------------------------------------------------------------------------
      f:row {

        f:column {
          spacing = 6,

          ----------------------------------------------------------------------
          -- Main row
          ----------------------------------------------------------------------
          f:row {
            bind_to_object = prefs,
            spacing = f:control_spacing(),

            f:popup_menu {
              title = "secondScreenMode",
              value = bind("secondScreenMode"),
              width_in_chars = dropDownWidth,
              items = {
                { title = "On", value = true },
                { title = "Off", value = false },
              },
            },

            f:static_text {
              title = "Second Screen. Fixed aspect ratio of photo view:"
            },

            f:popup_menu {
              title = "previewAspectRatio",
              value = bind("previewAspectRatio"),
              items = {
                { title = "1 x 1",  value = 1.0    },
                { title = "4 x 3",  value = 1.3333 },
                { title = "3 x 2",  value = 1.5    },
                { title = "16 x 9", value = 1.7778 },
              },
            },
          },

          ----------------------------------------------------------------------
          -- Second Screen sub-mode
          ----------------------------------------------------------------------
          f:row {
            bind_to_object = prefs,
            enabled = bind("secondScreenMode"),

            -- Align with the "S" in "Second Screen"
            f:spacer { width = 76 },

            f:radio_button {
              title = "Interactive",
              value = bind("secondScreenBehavior"),
              checked_value = "Interactive",
            },

            f:spacer { width = 8 },

            f:radio_button {
              title = "Follow Lightroom",
              value = bind("secondScreenBehavior"),
              checked_value = "Follow",
--            enabled = WIN_ENV,
            },
          },

        },

        f:spacer { fill_horizontal = 1 },
        clickForHelp(urlHelpOnSecondScreenMode),
      },

      f:row {
        bind_to_object = prefs,
        spacing = f:control_spacing(),
        f:popup_menu {
          title = "pluginWindowScaling",
          value = bind("pluginWindowScaling"),
          width_in_chars = dropDownWidth,
          items = {
            { title = "3XL", value = FocusPointPrefs.pluginWindow3XL },
            { title = "XXL", value = FocusPointPrefs.pluginWindowXXL },
            { title = "XL",  value = FocusPointPrefs.pluginWindowXL  },
            { title = "L",   value = FocusPointPrefs.pluginWindowL   },
            { title = "M",   value = FocusPointPrefs.pluginWindowM   },
            { title = "S",   value = FocusPointPrefs.pluginWindowS   },
          }
        },
        f:static_text {
          title = "Size of plugin window"
        },
        clickForHelp( urlHelpOnPluginWindowScaling ),
      },
      f:row {
        bind_to_object = prefs,
        spacing = f:control_spacing(),
        f:popup_menu {
          title = "keyboardInput",
          value = bind("keyboardInput"),
          width_in_chars = dropDownWidth,
          items = {
            { title = "Invisible",  value = FocusPointPrefs.kbdInputInvisible },
            { title = "Small",      value = FocusPointPrefs.kbdInputSmall     },
            { title = "Regular",    value = FocusPointPrefs.kbdInputRegular   },
          }
        },
        f:static_text {
            title = "Appearance of text input field for keyboard shortcuts"
        },
        clickForHelp( urlHelpOnKeyboardInput ),
      },
      f:row {
        bind_to_object = prefs,
        spacing = f:control_spacing(),
        f:popup_menu {
          title = "truncateLongText",
          value = bind("truncateLongText"),
          width_in_chars = dropDownWidth,
          items = {
            { title = "On",  value = true  },
            { title = "Off", value = false },
          },
        },
        f:static_text {
            title = "Truncate or wrap strings after"
        },
        f:edit_field {
          value = bind("truncateLimit"),
          width_in_chars = 3,
          min = 10,
          max = 100,
          precision = 0,
        },
        f:static_text {
          title = "characters",
        },
        clickForHelp( urlHelpOnTruncateLongText ),
      },
      straightenControlsSetting(), -- empty for LR5
      taggingControlsSetting(),    -- empty for LR5
      keyboardLayoutSetting(),     -- empty for LR5
      displayModeSetting(),        -- empty for MAC and later also for WIN < SDK Vx
      previewGenerationSettings(), -- empty for MAC
    }
  end
  local function sectionViewingOptions()
    return
    {
      title = "Viewing Options",
      f:row {
        bind_to_object = prefs,
        spacing = f:control_spacing(),
        f:popup_menu {
          title = "focusBoxColor",
          value = bind("focusBoxColor"),
          width_in_chars = dropDownWidth,
          items = {
            { title = "Red",   value = "red" },
            { title = "Green", value = "green" },
            { title = "Blue",  value = "blue" },
          }
        },
        f:static_text {
          title = "Color for in-focus points",
        },
        f:spacer{fill_horizontal = 1},
        clickForHelp( urlHelpOnViewingOptions ),
      },
      f:row {
        bind_to_object = prefs,
        f:popup_menu {
          title = "focusBoxSize",
          value = bind("focusBoxSize"),
          width_in_chars = dropDownWidth,
          items = {
            { title = "Small",  value = FocusPointPrefs.focusBoxSize[FocusPointPrefs.focusBoxSizeSmall]  },
            { title = "Medium", value = FocusPointPrefs.focusBoxSize[FocusPointPrefs.focusBoxSizeMedium] },
            { title = "Large",  value = FocusPointPrefs.focusBoxSize[FocusPointPrefs.focusBoxSizeLarge]  },
          }
        },
        f:static_text {
          title = "  Size of focus box for 'focus pixel' points ",
        },
      },
    }
  end
  local function sectionLogging()
    return
    {
      title = "Logging",
      f:row {
        bind_to_object = prefs,
        spacing = f:control_spacing(),
        f:popup_menu {
          title = "Logging level",
          value = bind("loggingLevel"),
          width_in_chars = dropDownWidth,
          items = {
            { title = "Auto",  value = "AUTO"  },
            { title = "Full",  value = "FULL"  },
            { title = "Debug", value = "DEBUG" },
            { title = "Info",  value = "INFO"  },
            { title = "Warn",  value = "WARN"  },
            { title = "Error", value = "ERROR" },
            { title = "None",  value = "NONE"  },
          }
        },
        f:static_text {
          title = 'Level of information to be logged (Recommended: "Auto")'
        },
        f:spacer{fill_horizontal = 1},
        f:static_text {
          title = "Plugin log:",
          alignment = "right",
          fill_horizontal = 1,
        },
        f:push_button {
          title = "Show file",
          action = function()
            local logFileName = Log.getLogFileName()
            if LrFileUtils.exists(logFileName)then
              LrShell.revealInShell(logFileName)
            else
              LrDialogs.message('No log file written. Set logging level other than "None".')
            end
          end,
        },
        f:spacer{fill_horizontal = 1},
        clickForHelp( urlHelpOnLoggingLevel ),
      },
    }
  end
  local function sectionStraighteningOptions()
    return
    {
      title = "Straightening Options",
      bind_to_object = prefs,
      spacing = f:control_spacing(),
      f:row {
        bind_to_object = prefs,
        spacing = f:control_spacing(),
        f:popup_menu {
          title = "overwriteCropAngle",
          value = bind("overwriteCropAngle"),
          width_in_chars = dropDownWidth,
          items = {
            { title = "On", value = true },
            { title = "Off", value = false },
          }
        },
        f:static_text {
          title = "Overwrite existing crop angle setting ",
        },
        f:row {
          f:checkbox {
            title = "Display warning",
            value = bind("overwriteCropAngleWarning"),
          },
        },
        f:spacer{fill_horizontal = 1},
        clickForHelp( urlHelpOnStraighteningOptions ),
      },
      f:row {
        bind_to_object = prefs,
        spacing = f:control_spacing(),
        f:popup_menu {
          title = "overwriteTransform",
          value = bind("overwriteTransform"),
          width_in_chars = dropDownWidth,
          items = {
            { title = "On", value = true },
            { title = "Off", value = false },
          }
        },
        f:static_text {
          title = "Overwrite existing Transform settings",
        },
        f:row {
          f:checkbox {
            title = "Display warning",
            value = bind("overwriteTransformWarning")
          },
        },
      },
      f:row {
        bind_to_object = prefs,
        spacing = f:control_spacing(),
        f:popup_menu {
          title = "straightenLimits",
          value = bind("straightenLimits"),
          width_in_chars = dropDownWidth,
          items = {
            { title = "On", value = true },
            { title = "Off", value = false },
          },
        },
        f:static_text {
          title = "Apply straightening only for angles between"
        },
        f:edit_field {
          value = bind("straightenLimitLow"),
          width_in_chars = 3,
          min = 0,
          max = 45,
          precision = 1,
        },
        f:static_text {
          title = "and",
        },
        f:edit_field {
          value = bind("straightenLimitHigh"),
          width_in_chars = 3,
          min = 0,
          max = 45,
          precision = 1,
        },
        f:static_text {
          title = "degrees (in any direction)",
        },
      },
      f:row {
        bind_to_object = prefs,
        spacing = f:control_spacing(),
        f:popup_menu {
          title = "straightenApplyBias",
          value = bind("straightenApplyBias"),
          width_in_chars = dropDownWidth,
          items = {
            { title = "On", value = true },
            { title = "Off", value = false },
          },
        },
        f:static_text {
          title = "Apply calibration offset of"
        },
        f:edit_field {
          value = bind("straightenBias"),
          width_in_chars = 4,
          min = -5,
          max = 5,
          precision = 2,
        },
        f:static_text {
          title = "degrees to roll angle",
        },
      },
      f:row {
        bind_to_object = prefs,
        spacing = f:control_spacing(),
        f:popup_menu {
          title = "Straighten Summary Condition",
          value = bind("straightenSummaryCondition"),
          width_in_chars = dropDownWidth,
          items = {
            { title = "Always", value = "ALWAYS" },
            { title = "Skipped Images", value = "SKIPPED" },
            { title = "Warnings", value = "WARNINGS" },
            { title = "Errors", value = "ERRORS" },
            { title = "Never", value = "NEVER" },
          }
        },
        f:static_text {
          title = "Condition to open the summary dialog when straightening is complete"
        },
      },
    }
  end
  local function sectionUpdates()
    return
    {
      title = "Updates",
      bind_to_object = prefs,
      spacing = f:control_spacing(),
      f:row {
        f:checkbox {
          title = "Check for updates",
          value = bind("checkForUpdates")
        },
        f:spacer{fill_horizontal = 1},
        updateMessage,
      },
    }
  end
  local function sectionSupport()
    return
    {
      title = "Support the Author",
      bind_to_object = prefs,
      spacing = f:control_spacing(),
      f:row{
        fill_horizontal = 1,
        spacing = f:control_spacing(),
        f:picture {
          value = _PLUGIN:resourceId("assets/icons/kofi.png")
        },
        f:static_text {
          title = "Buy me a coffee on Ko-fi.com!",
          text_color = LrColor("blue"),
          immediate = true,
          mouse_down = function()
            LrTasks.startAsyncTask(function() LrHttp.openUrlInBrowser(FocusPointPrefs.urlKofi) end)
          end,
        },
        f:spacer{fill_horizontal = 1},
        f:checkbox {
          title = "I have already donated. Hide Ko-fi icon and link from the plugin window.",
          value = bind("hideKofiControl")
        },
      },
    }
  end
  local function sectionAcknowledgements()
    return
    {
      title = "Acknowledgements",
      f:row {
        fill_horizontal = 1,
        f:column {
          fill_horizontal = 1,
          f:static_text {
            font = "<system/bold>",
            title = "ImageMagick Studio LLC"
          },
          f:spacer{ height = 5 },
          f:static_text {
            title = "This plugin uses ImageMagick mogrify"
          }
        },
        f:column {
          f:static_text {
            title = "https://imagemagick.org/index.php",
            text_color = LrColor(0, 0.25, 1),
            immediate = true,
            mouse_down = function()
              LrTasks.startAsyncTask(function()
                LrHttp.openUrlInBrowser("https://imagemagick.org/index.php")
              end)
            end,
          },
        },
      },
      f:spacer{fill_horizontal = 1},
      f:row {
        fill_horizontal = 1,
        f:column {
          fill_horizontal = 1,
          f:static_text {
            font = "<system/bold>",
            title = "ExifTool"
          },
          f:spacer{ height = 5 },
          f:static_text {
            title = "This plugin relies on Phil Harvey's ExifTool to read and decode metadata"
          }
        },
        f:column {
          f:static_text {
            title = "https://exiftool.org/",
            text_color = LrColor(0, 0.25, 1),
            immediate = true,
            mouse_down = function()
              LrTasks.startAsyncTask(function()
                LrHttp.openUrlInBrowser("https://exiftool.org/")
              end)
            end,
          },
        },
      },
      f:spacer{fill_horizontal = 1},
      f:row {
        fill_horizontal = 1,
        f:column {
          fill_horizontal = 1,
          f:static_text {
            font = "<system/bold>",
            title = "John R. Ellis"
          },
          f:spacer{ height = 5 },
          f:static_text {
            title = "Permission to use code to crop an image while maintaining its aspect ratio"
          }
        },
        f:column {
          f:static_text {
            title = "https://johnrellis.com/lightroom/allplugins.htm",
            text_color = LrColor(0, 0.25, 1),
            immediate = true,
            mouse_down = function()
              LrTasks.startAsyncTask(function()
                LrHttp.openUrlInBrowser("https://johnrellis.com/lightroom/allplugins.htm")
              end)
            end,
          },
        },
      },
    }
  end

  -- Non-relevant sections (e.g. not relevant to LR5) need to be omitted from the table
  local sections = {}
  local function add(section)
    if section then
      sections[#sections + 1] = section
    end
  end

  add(sectionScreenScaling())
  add(sectionUserInterface())
  add(sectionViewingOptions())
  add(sectionLogging())
  add(sectionStraighteningOptions())
  add(sectionUpdates())
  add(sectionSupport())
  add(sectionAcknowledgements())

  return sections

end

return FocusPointPrefs
