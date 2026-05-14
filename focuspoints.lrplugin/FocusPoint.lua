--[[
  Copyright 2016 Whizzbang Inc

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
  FocusPoint.lua

  Purpose of this module:
  Entry point for 'Show Focus Point' menu command.
  Main control of data processing and user dialog.
------------------------------------------------------------------------------]]
local FocusPoint = {}

-- Imported LR namespaces
local LrApplication         = import  'LrApplication'
local LrApplicationView    -- import only for SDK 7.4 and later
local LrBinding             = import  'LrBinding'
local LrColor               = import  'LrColor'
local LrDialogs             = import  'LrDialogs'
local LrFunctionContext     = import  'LrFunctionContext'
local LrHttp                = import  'LrHttp'
local LrPrefs               = import  'LrPrefs'
local LrTasks               = import  'LrTasks'
local LrView                = import  'LrView'
local LrSelection          -- import only for SDK 6.0 and later

-- Required Lua definitions
local ExifUtils             = require 'ExifUtils'
local FocusInfo             = require 'FocusInfo'
local FocusPointDialog      = require 'FocusPointDialog'
local FocusPointPrefs       = require 'FocusPointPrefs'
local GlobalDefs            = require 'GlobalDefs'
local KeyboardLayout        = require 'KeyboardLayout'
local Log                   = require 'Log'
local PointsRendererFactory = require 'PointsRendererFactory'
local _strict               = require 'strict'
local Utf8                  = require 'Utf8'
local Utils                 = require 'Utils'

--[[----------------------------------------------------------------------------
  private void
  showFocusPoint()

  Invoked when 'Focus Point Viewer -> Show Focus Points' is selected.
  Reads the metadata from the selected photo's image file, processes autofocus
  information, and displays a dialog to:
  - visualize focus points
  - display relevant image/shooting/focus information
  - tag (flag, rate or color) the current image
------------------------------------------------------------------------------]]
local function showFocusPoint()

  LrFunctionContext.callWithContext("showFocusPointDialog", function(context)

    local catalog = LrApplication.activeCatalog()
    local current
    local errorMsg
    local photoView, infoView
    local dialogScope
    local rendererTable
    local metadata
    local switchedToLibrary
    local userResponse
    local exitPlugin
    local exitDialog        -- per-iteration flag: end wait loop / close floating dialog
    local pendingNewPhoto   -- target photo set from selectionChangeObserver (auto-refresh on photo change in Library)
    local dialogIteration = 0  -- generation counter to ignore stale callbacks from previous iterations
    local floatingDialogClose  -- function to programmatically close the current floating dialog (set by onShow)
    local clicked
    local prefs = LrPrefs.prefsForPlugin( nil )

    local floatingDialog = (prefs.secondScreenMode == true)

    --[[----------------------------------------------------------------------------
      Helper used by all callbacks (keyboard shortcuts, navigation buttons,
      tagging-and-next, etc.) that previously closed the modal dialog via
      LrDialogs.stopModalWithResult(...).
      In the non-modal/floating dialog mode we set state variables that the wait
      loop in the main flow checks AND call the close handle that was provided by
      the onShow callback to actually dismiss the floating dialog window.
      (Without calling the close handle the window would stay open and a new one
      would be added on top with each iteration.)
    ------------------------------------------------------------------------------]]
    local function closeDialog(view, response)
      if floatingDialog then
        userResponse = response
        exitDialog = true
        if floatingDialogClose then
          local closeFn = floatingDialogClose
          floatingDialogClose = nil
          closeFn()
        end
      else
        LrDialogs.stopModalWithResult(view, response)
      end
    end

    local props = LrBinding.makePropertyTable(context)
    local LR5 = (LrApplication.versionTable().major == 5) -- or true -- to simulate running on LR5
    local LrC = (LrApplication.versionTable().major >= 8) -- or true -- to simulate running on LR < 7.4

    -- special Unicode characters used as replacement for icons
    local utfRightPointingTriangle = string.char(0xe2, 0x96, 0xb6)
    local utfLeftPointingTriangle  = string.char(0xe2, 0x97, 0x80)
    local utfLinkSymbol            = string.char(0xF0, 0x9F, 0x94, 0x97)
    local utfWhiteHeavyCheckMark   = string.char(0xE2, 0x9C, 0x85)
    local utfHeavyCheckMark        = string.char(0xE2, 0x9C, 0x94)
    local utfCrossMark             = string.char(0xE2, 0x9D, 0x8C)
    local utfKeycapDigitOne        = string.char(0x31, 0xef, 0xb8, 0x8f, 0xe2, 0x83, 0xa3)
    local utfKeycapDigitTwo        = string.char(0x32, 0xef, 0xb8, 0x8f, 0xe2, 0x83, 0xa3)
    local utfKeycapDigitThree      = string.char(0x33, 0xef, 0xb8, 0x8f, 0xe2, 0x83, 0xa3)
    local utfKeycapDigitFour       = string.char(0x34, 0xef, 0xb8, 0x8f, 0xe2, 0x83, 0xa3)
    local utfKeycapDigitFive       = string.char(0x35, 0xef, 0xb8, 0x8f, 0xe2, 0x83, 0xa3)
    local utfBlackLargeSquare      = string.char(0xe2, 0xac, 0x9b)
    local utfRedLargeSquare        = string.char(0xf0, 0x9f, 0x9f, 0xa5)
    local utfYellowLargeSquare     = string.char(0xf0, 0x9f, 0x9f, 0xa8)
    local utfGreenLargeSquare      = string.char(0xf0, 0x9f, 0x9f, 0xa9)
    local utfBlueLargeSquare       = string.char(0xf0, 0x9f, 0x9f, 0xa6)
    local utfPurpleLargeSquare     = string.char(0xf0, 0x9f, 0x9f, 0xaa)
    local buttonNextImage = "Next image " .. utfRightPointingTriangle
    local buttonPreviousImage      =  utfLeftPointingTriangle .. " Previous image"
    local taggingSymbols = {
      checkMark   = { WIN = utfHeavyCheckMark,   MAC = utfWhiteHeavyCheckMark },
      crossMark   = { WIN = utfCrossMark,        MAC = utfCrossMark           },
      digitOne    = { WIN = "1",                 MAC = utfKeycapDigitOne      },
      digitTwo    = { WIN = "2",                 MAC = utfKeycapDigitTwo      },
      digitThree  = { WIN = "3",                 MAC = utfKeycapDigitThree    },
      digitFour   = { WIN = "4",                 MAC = utfKeycapDigitFour     },
      digitFive   = { WIN = "5",                 MAC = utfKeycapDigitFive     },
      colorRed    = { WIN = utfBlackLargeSquare, MAC = utfRedLargeSquare      },
      colorYellow = { WIN = utfBlackLargeSquare, MAC = utfYellowLargeSquare   },
      colorGreen  = { WIN = utfBlackLargeSquare, MAC = utfGreenLargeSquare    },
      colorBlue   = { WIN = utfBlackLargeSquare, MAC = utfBlueLargeSquare     },
      colorPurple = { WIN = utfBlackLargeSquare, MAC = utfPurpleLargeSquare   },
    }

    local function taggingSymbol(key, overridePlatform)
      local platform = WIN_ENV and "WIN" or "MAC"
      local os = overridePlatform or platform
      local entry = taggingSymbols[key]
      if not entry then return "#" end
      return entry[os]
    end

    local function logAppInfo()
      -- Extend logfile header with application level information
      if FocusPointPrefs.isUpdateAvailable() then
        Log.logInfo("System", "Update to version " .. FocusPointPrefs.getlatestVersion() .. " available")
      end
      if WIN_ENV then
        Log.logInfo("System", "Display scaling level " ..
                math.floor(100/FocusPointPrefs.getDisplayScaleFactor() + 0.5) .. "%")
      end
      Log.logInfo("System", string.format(
       "Application window size: %s x %s. Plugin window size: %sx",
          GlobalDefs.appWidth, GlobalDefs.appHeight, prefs.pluginWindowScaling))
    end

    -- Get the active photo plus additionally selected photos
    local targetPhoto    = catalog:getTargetPhoto()
    local selectedPhotos = catalog:getTargetPhotos()

    -- LrSelection namespace is supported only in SDK 6.0
    if not LR5 then LrSelection = import "LrSelection" end

    local function getPositionInSelection(target, selected)
      -- Find 'current' index of 'target' photo in 'selected' photos
      for i, photo in ipairs(selected) do
        if photo == target then
         current = i
         break
        end
      end
      return current
    end
    local function needSyncWithFilmStrip()
      local result = false
      local activePhoto = catalog:getTargetPhoto()
      if targetPhoto ~= activePhoto then
        -- plugin and film strip are out of sync (e.g. after a shift-digit shortcut operation)
        -- -> make the film strip's photo the 'next' one for the plugin
        targetPhoto = activePhoto
        result = true
      end
      return result
    end
    local function nextPhoto()
      -- Advance to the next photo of user selection or film strip (if only a single image was selected)
      local function nextPhotoOfSelection()
        current = (current % #selectedPhotos) + 1
        targetPhoto = selectedPhotos[current]
      end
      local function nextPhotoOfFilmStrip()
        local activePhoto = catalog:getTargetPhoto()
        if targetPhoto ~= activePhoto then
          -- plugin and film strip are out of sync (e.g. after a shift-digit shortcut operation)
          -- -> make the film strip's photo the 'next' one for the plugin
          targetPhoto = activePhoto
        else
          -- Advance to the next photo in film strip
          LrSelection.nextPhoto()
          targetPhoto = catalog:getTargetPhoto()
        end
      end
      if #selectedPhotos > 1 then
        nextPhotoOfSelection()
      elseif not LR5 then
        nextPhotoOfFilmStrip()
      end
    end
    local function previousPhoto()
      -- Advance to the previous photo of user selection or film strip (if only a single image was selected)
      local function previousPhotoOfSelection()
        current = (current - 2) % #selectedPhotos + 1
        targetPhoto = selectedPhotos[current]
      end
      local function previousPhotoOfFilmStrip()
        local activePhoto = catalog:getTargetPhoto()
        if targetPhoto ~= activePhoto then
          -- plugin and film strip are out of sync (e.g. after a shift-digit shortcut operation)
          -- -> make the film strip's photo the 'next' one for the plugin
          targetPhoto = activePhoto
        else
          -- Advance to the previous photo in film strip
          LrSelection.previousPhoto()
          targetPhoto = catalog:getTargetPhoto()
        end
      end
      if #selectedPhotos > 1 then
        previousPhotoOfSelection()
      elseif not LR5 then
        previousPhotoOfFilmStrip()
      end
    end
    -- To avoid nil pointer errors in case of "dirty" installation (copy new over old files)
    FocusPointPrefs.InitializePrefs(prefs)
    -- Initialize logging, log system level information
    Log.initialize()

    -- Set scale factor for sizing of dialog window
    if WIN_ENV then
      FocusPointPrefs.setDisplayScaleFactor()

    end

    -- Log applicaton level information (includes scale factor and app window size)
    logAppInfo()
    -- only on WIN (issue #199):
    -- if launched in Develop module switch to Library to enforce that a preview of the image is available
    -- must switch to loupe view because only in this view previews will be rendered
    -- perform module switch as early as possible to give Library time to create a preview if none exists
    if WIN_ENV and LrC and not floatingDialog then
        LrApplicationView = import 'LrApplicationView'
        local moduleName = LrApplicationView.getCurrentModuleName()
        if moduleName == "develop" then
          LrApplicationView.switchToModule("library")
          LrApplicationView.showView("loupe")
          switchedToLibrary = true

          local waited = 0
          while LrApplicationView.getCurrentModuleName() ~= "library" and waited < 5.0 do
            LrTasks.sleep(0.2)
            waited = waited + 0.2
          end
        end
    end

    local function inputFieldWidth()
      if     prefs.keyboardInput == FocusPointPrefs.kbdInputInvisible then return 1
      elseif prefs.keyboardInput == FocusPointPrefs.kbdInputSmall     then return 25
      else                                                                 return 100
      end
    end

    local function inputFieldHeight()
      if prefs.keyboardInput == FocusPointPrefs.kbdInputInvisible then
        return 1  -- minimum height in px
      else
        return nil -- automatic
      end
    end

    local function kbdShortcutInputField()
      local f = LrView.osFactory()
      local previewText  = ""
      local prevTextLen  = 0
      props.shortcutText = ""
      return f:edit_field {
        value = LrView.bind('shortcutText', props),
        width = inputFieldWidth(),
        height = inputFieldHeight(),
        border_enabled = false, -- optionally suppress borders
        immediate = true,
            validate = function(view, text)
          --[[
            Use the validate() function to interpret user keystrokes as shortcuts
            BUT, attention: for each keystoke, validate() is called twice!!
            1. "Preview" validation - non-committal check, to preview the proposed change of text
            2. "Commit"  validation - actual update, to commit the change in the UI
            3. Having two phases is pointless, because 'text' is the same and function result doesn't make a difference
            => need to detect "Preview" vs "Commit" and skip one if this, otherwise shortcuts will be executed twice
                   e.g. 'next' will go the next but one, 'previous' to the penultimate image.
          --]]
          if text == previewText then
            -- call for "Commit" validation -> exit (because shortcut has already been processed in "Preview")
            Log.logDebug("FocusPoint",
              string.format("Shortcut input: Commit called with '%s'. Preview '%s'", text, previewText))
            previewText = ""  -- reset for next Preview
            return true
          else
            -- call for "Preview" validation -> save text and process
            Log.logDebug("FocusPoint",
                string.format("Shortcut input: Preview called with '%s'. Preview '%s'", text, previewText))
            previewText = text
          end

          -- Get the most recently entered character
          local char = Utf8.last_char(text)
          Log.logDebug("FocusPoint", string.format("Shortcut input: c = '%s'", char))
          Log.logDebug("FocusPoint", string.format("Text length: text = '%s', previous = '%s'", string.len(text), prevTextLen))
          if not char or char == "" or string.len(text) < prevTextLen then
            prevTextLen = string.len(text)
            return true
          end
          prevTextLen = string.len(text)
          --------------------------------------------------------------------------------------
          -- Parse character and perform designated operation if it is a shortcut
          -- Tagging operations: flagging / rating / coloring
          -- Note: this is not supported for LR5 (no LrSelection before SDK 6.0)
          --
          -- IMPORTANT:
          -- Do this before parsing other shortcut characters, to prioritize flagging!
          -- E.g. on German-Swiss keyboards, Shift-1 produces '+' which collides with 'next'.
          -- There are other options for the 'next' keyboard shortcut, but not for Shift-1.
          --
          -- ATTENTION:
          -- Shift-digit combinations must not be used when the plugin is run on a single photo !!!
          -- The triggered action causes LR to shift the selection focus to the next photo in the
          -- film strip, while the plugin remains on the photo that was selected at the start.
          --------------------------------------------------------------------------------------
          if prefs.taggingControls and not LR5 then

            -- Pick photo
            if string.find(FocusPointPrefs.kbdShortcutsPick, char, 1, true) then
              LrSelection.flagAsPick()
              return true  -- done
            -- Pick photo and advance to next
            elseif string.find(FocusPointPrefs.kbdShortcutsPickNext, char, 1, true) then
              LrSelection.flagAsPick()
              closeDialog(view,"next")
            -- Reject photo
            elseif string.find(FocusPointPrefs.kbdShortcutsReject, char, 1, true) then
              if LrSelection.getFlag() ~= -1 then   -- reject
                LrSelection.flagAsReject()
              end
              return true  -- done
            -- Reject photo and advance to next
            elseif string.find(FocusPointPrefs.kbdShortcutsRejectNext, char, 1, true) then
              if LrSelection.getFlag() ~= -1 then   -- reject
                LrSelection.flagAsReject()
              end
              closeDialog(view,"next")
            -- Unflag photo
            elseif string.find(FocusPointPrefs.kbdShortcutsUnflag, char, 1, true) then
              LrSelection.removeFlag()
              return true  -- done
            -- Unflag photo and advance to next
            elseif string.find(FocusPointPrefs.kbdShortcutsUnflagNext, char, 1, true) then
              LrSelection.removeFlag()
              closeDialog(view,"next")
            end

            -- Input of digits (unshifted/shifted top row keys) depends on intl keyboard layout!
            local digit, shifted = KeyboardLayout.mapTypedCharToDigit(char, prefs.keyboardLayout)
            Log.logDebug("FocusPoint",
              string.format(
                "Map char to digit: char '%s', digit '%s', shifted '%s' ", char, digit, shifted))
            if digit then
              if digit <= 5 then
                -- Rating
                LrSelection.setRating(digit)
              else
                -- Coloring
                if     digit == 6 then LrSelection.toggleRedLabel()
                elseif digit == 7 then LrSelection.toggleYellowLabel()
                elseif digit == 8 then LrSelection.toggleGreenLabel()
                elseif digit == 9 then LrSelection.toggleBlueLabel()
                end
              end
              if shifted then
                closeDialog(view, "next")
              elseif needSyncWithFilmStrip() then
                closeDialog(view, "sync")
              else
              end
              return true  -- done
            end
          end

          --------------------------------------------------------------------------------------
          -- Parse character and perform designated operation if it is a shortcut
          -- Basic operations: Next, Previous, User Manual, Troubleshooting, Check Log, Close
          --------------------------------------------------------------------------------------
          -- Next image
          if string.find(FocusPointPrefs.kbdShortcutsNext, char, 1, true) then
            closeDialog(view, "next")
            return true  -- done
          -- Previous image
          elseif string.find(FocusPointPrefs.kbdShortcutsPrev, char, 1, true) then
            closeDialog(view,"previous")
            return true  -- done
          -- Open user manual
          elseif string.find(FocusPointPrefs.kbdShortcutsUserManual, char, 1, true) then
            LrTasks.startAsyncTask(function() LrHttp.openUrlInBrowser(FocusPointPrefs.urlUserManual) end)
            return true  -- done
          -- Keyboard shortcuts overview
          elseif string.find(FocusPointPrefs.kbdShortcutsHelp, char, 1, true) then
            LrTasks.startAsyncTask(function() LrHttp.openUrlInBrowser(FocusPointPrefs.urlkbdShortcuts) end)
            return true  -- done
          -- Troubleshooting
          elseif string.find(FocusPointPrefs.kbdShortcutsTroubleShooting, char, 1, true) then
            FocusInfo.openTroubleShooting()
            return true  -- done
          -- Check log
          elseif string.find(FocusPointPrefs.kbdShortcutsCheckLog, char, 1, true) then
            if prefs.loggingLevel ~= "NONE" then
              Utils.openFileInApp(Log.getLogFileName())
            end
            return true  -- done
          -- Close
          elseif string.find(FocusPointPrefs.kbdShortcutsClose, char, 1, true)
          or (MAC_ENV and char == ".") then
            closeDialog(view,"ok")
          end
          -- always return true; in case of false the entire text is displayed in red color if visible
          return true
          end,
      }
    end

    local function buildKbdShortcutInput()
      local f = LrView.osFactory()
      if prefs.keyboardInput == FocusPointPrefs.kbdInputInvisible
      or prefs.keyboardInput == FocusPointPrefs.kbdInputSmall then
        -- display only the input field
        return f:row {
          kbdShortcutInputField()
        }
      else
        return f:row{
          -- display the input field and text label as explanation
          spacing = 0,
          kbdShortcutInputField(),
          f:static_text{
            title = " <- Input for",
            font  = "<system/small>",
          },
          f:static_text {
            title = "keyboard shortcuts " .. utfLinkSymbol,
            font  = "<system/small>",
            tooltip = "Learn how to use the plugin's keyboard shortcuts and familiarize yourself with its limitations and restrictions",
            text_color = LrColor(0, 0.25, 1),
            immediate = true,
            mouse_down = function(_view)
              LrTasks.startAsyncTask(function()
                LrHttp.openUrlInBrowser(FocusPointPrefs.urlkbdShortcuts)
              end)
            end,
          },
        }
      end
    end

    local function navigationControls()
      local f = LrView.osFactory()
      return f:row {
        margin = 0,
        spacing = 0,     -- removes uniform spacing; we control it manually
        f:push_button {
          title = buttonPreviousImage,
          tooltip = "Load previous image from selection (-, <)",
          enabled = #selectedPhotos > 1 or not LR5,
          action = function(button)
            -- Prevent multiple executions - known LrC SDK quirk!
            if clicked then return else clicked = true end
            closeDialog(button,"previous")
          end
        },
        f:spacer { width = 10 }, -- space before the file name
        f:static_text {
          margin = 0,
          title   = LrView.bind {key = "fileName",        object = props},
          tooltip = LrView.bind {key = "fileNameTooltip", object = props},
        },
        f:spacer { width = 5 },  -- space before the next button
        f:push_button {
          title = buttonNextImage,
          tooltip = "Load next image from selection (Space bar, +)",
          enabled = #selectedPhotos > 1 or not LR5,
          margin = 0,
          action = function(button)
            -- Prevent multiple executions - known LrC SDK quirk!
            if clicked then return else clicked = true end
            -- set index to next image, wrap around at end of list
            closeDialog(button,"next")
          end
        },
      }
    end

    local function taggingControls()
      local f = LrView.osFactory()

      local function setRating (rating)
        if rating == LrSelection.getRating() then
          -- clear existing rating
          rating = 0
        end
        LrSelection.setRating(rating)
      end

      if not prefs.taggingControls or LR5 then
        return f:spacer{width = 10}
      end
      return f:row{
        spacing = 0,
        --------------------------------------------------------------------
        -- Flagging controls
        --------------------------------------------------------------------
        f:static_text {
          title = taggingSymbol("checkMark"),
          text_color = LrColor(0, 0.66, 0),
          font = "<system/bold>",
          tooltip = "Flag as Pick (P)",
          mouse_down = function()
            if LrSelection.getFlag() == 1 then   -- pick
              LrSelection.removeFlag()
            else
              LrSelection.flagAsPick()
            end
          end,
        },
        f:static_text {
          title = taggingSymbol("crossMark"),
          text_color = LrColor("red"),
          font = "<system/bold>",
          tooltip = "Set as Rejected (X)",
          mouse_down = function()
            if LrSelection.getFlag() == -1 then  -- reject
              LrSelection.removeFlag()
            else
              LrSelection.flagAsReject()
            end
          end,
        },
        --------------------------------------------------------------------
        -- Rating controls
        --------------------------------------------------------------------
        f:spacer { width = 10 },
        f:static_text {
          title = taggingSymbol("digitOne"),
          tooltip = "Set rating (1)",
          mouse_down = function() setRating(1) end,
        },
        f:static_text {
          title = taggingSymbol("digitTwo"),
          tooltip = "Set rating (2)",
          mouse_down = function() setRating(2) end,
        },
        f:static_text {
          title = taggingSymbol("digitThree"),
          tooltip = "Set rating (3)",
          mouse_down = function() setRating(3) end,
        },
        f:static_text {
          title = taggingSymbol("digitFour"),
          tooltip = "Set rating (4)",
          mouse_down = function() setRating(4) end,
        },
        f:static_text {
          title = taggingSymbol("digitFive"),
          tooltip = "Set rating (5)",
          mouse_down = function() setRating(5) end,
        },
        --------------------------------------------------------------------
        -- Color controls
        --------------------------------------------------------------------
        f:spacer { width = 10 },
        f:static_text {
          title = taggingSymbol("colorRed"),
          text_color = LrColor(240/255, 80/255, 80/255),
          tooltip = "Set red label (6)",
          mouse_down = function()
            LrSelection.toggleRedLabel()
          end,
        },
        f:static_text {
          title = taggingSymbol("colorYellow"),
          text_color = LrColor(240/255, 230/255, 0),
          tooltip = "Set yellow label (7)",
          mouse_down = function()
            LrSelection.toggleYellowLabel()
          end,
        },
        f:static_text {
          title = taggingSymbol("colorGreen"),
          text_color = LrColor(90/255, 200/255, 75/255),
          tooltip = "Set green label (8)",
          mouse_down = function()
            LrSelection.toggleGreenLabel()
          end,
        },
        f:static_text {
          title = taggingSymbol("colorBlue"),
          text_color = LrColor(70/255, 135/255, 230/255),
          tooltip = "Set blue label (9)",
          mouse_down = function()
            LrSelection.toggleBlueLabel()
          end,
        },
        f:static_text {
          title = taggingSymbol("colorPurple"),
          text_color = LrColor(120/255, 80/255, 255/255),
          tooltip = "Set purple label",
          mouse_down = function()
            LrSelection.togglePurpleLabel()
          end,
        },
      }
    end

    local function kofiControl()
      local f = LrView.osFactory()
      if prefs.hideKofiControl then
        return f:spacer{width = 10}
      end
      return f:row{
        spacing = 0,
        f:picture {
          value = _PLUGIN:resourceId("assets/icons/kofi.png")
        },
        f:spacer { width = 5 },
        f:static_text {
          title = "Buy me a coffee! " .. utfLinkSymbol,
          text_color = LrColor("blue"),
          tooltip = "Click to make a donation on Ko-fi",
          immediate = true,
          mouse_down = function(_view)
            LrTasks.startAsyncTask(function() LrHttp.openUrlInBrowser(FocusPointPrefs.urlKofi) end)
          end,
        },
      }
    end

    local function userManualControl()
      local f = LrView.osFactory()
      return f:row{
        spacing = 0,
        f:spacer{fill_horizontal = 1},  -- make the control appear right next to Close button
        f:static_text {
          title = "User Manual " .. utfLinkSymbol,
          text_color = LrColor("blue"),
            tooltip = "Click to open user documentation (M)",
          immediate = true,
          mouse_down = function(_view)
            LrTasks.startAsyncTask(function() LrHttp.openUrlInBrowser(FocusPointPrefs.urlUserManual) end)
          end,
        },
      }
    end

    local function buildControlPanel()
      local f = LrView.osFactory()
      local result = f:row {
        margin_left = 0,
        spacing = 0,     -- removes uniform spacing; we control it manually
        navigationControls(),
        f:spacer { width = 20 },
        taggingControls(),
        f:spacer { width = 20 },
        kofiControl(),
        f:spacer { width = 20 },
        userManualControl(),
        f:spacer { width = 5 },    -- space before 'Close' button
      }
      return result
    end

    local function setFileName(photo)
      local utfEllipsis = string.char(0xE2, 0x80, 0xA6)
      local fileName = Utils.getPhotoFileName(photo)
      local tooltip
      if prefs.truncateLongText and Utf8.len(fileName) > FocusInfo.maxValueLen then
          tooltip  = fileName
          fileName = string.sub(fileName, 1, FocusInfo.maxValueLen-1) .. utfEllipsis
        end
      if #selectedPhotos > 1 then
        fileName = fileName .. " (" .. current .. "/" .. #selectedPhotos .. ")"
      end
      props.fileName = fileName
      props.fileNameTooltip = tooltip or ""
    end

    local function runModalDialog()
      -- Create static containers for use in dialog
      local kbdShortcutInput = buildKbdShortcutInput()
      local controlPanel     = buildControlPanel()

      userResponse = LrDialogs.presentModalDialog {
        title = "Focus-Points (Version " .. GlobalDefs.pluginDisplayVersion .. ")",
        contents = FocusPointDialog.createDialog(targetPhoto, photoView, infoView, kbdShortcutInput),
        accessoryView = controlPanel,
        title = "Focus-Points (Version " .. GlobalDefs.pluginDisplayVersion .. ")",
        actionVerb = "Close",
        cancelVerb = "< exclude >",
      }
      return userResponse
    end

    local function runFloatingDialog()
      -- Create static containers for use in dialog
      local kbdShortcutInput = buildKbdShortcutInput()
      local controlPanel     = buildControlPanel()

      -- Reset per-iteration state for the floating dialog flow
      userResponse        = nil
      exitDialog          = false
      pendingNewPhoto     = nil
      floatingDialogClose = nil

      -- Bump the generation counter so any stale callbacks from a previous
      -- iteration's floating dialog become no-ops and don't corrupt the
      -- state of the current iteration.
      dialogIteration = dialogIteration + 1
      local myIteration = dialogIteration

      -- Helper that closes the currently shown floating dialog (if any).
      -- The close handle is provided by Lightroom via the onShow callback.
      local function dismissFloatingDialog()
        if floatingDialogClose then
          local closeFn = floatingDialogClose
          floatingDialogClose = nil
          closeFn()
        end
      end

      local function dialogContents()
        local f = LrView.osFactory()
        local leftMargin   =  9
        local rightMargin  =  3
        local topMargin    =  8
        local bottomMargin =  4

        local floatingContents = f:column {
            spacing = f:control_spacing(),

            -- top margin
            f:spacer { height = topMargin },

            -- main dialog area
            f:row {
              spacing = f:control_spacing(),
              -- left margin
              f:spacer { width = leftMargin },
              FocusPointDialog.createDialog(
                targetPhoto, photoView, infoView, kbdShortcutInput),
              -- right margin
              f:spacer { width = rightMargin },
            },

            -- spacing before controls
            f:spacer { height = 0 },

            -- bottom controls
            f:row {
                spacing = f:control_spacing(),
                f:spacer { width = leftMargin },

                controlPanel,

                -- spacing before close button
                f:spacer { height = 8 },

                f:push_button {
                    title = "    Close    ",
                    action = function(button)
                      closeDialog(button,"ok")
                    end,
                },

                f:spacer { width = rightMargin },
            },

            -- bottom margin
            f:spacer { height = bottomMargin },
        }

        return floatingContents
      end

      LrDialogs.presentFloatingDialog(_PLUGIN, {
        title = "Focus-Points (Version " .. GlobalDefs.pluginDisplayVersion .. ")",
        contents = dialogContents(),
        resizable = true,
        save_frame = "FocusPointsFloatingDialogFrame",
        -- onShow gives us the close/toFront handles for this dialog instance.
        -- We need 'close' to programmatically dismiss the window when the
        -- selection changes or a navigation/keyboard shortcut is used,
        -- otherwise a new window would be stacked on top of the old one
        -- on every iteration of the outer loop.
        onShow = function(callForward)
          if myIteration ~= dialogIteration then return end
          floatingDialogClose = callForward and callForward.close
        end,
        -- User closed the floating dialog via window close button:
        windowWillClose = function()
          if myIteration ~= dialogIteration then return end
          floatingDialogClose = nil  -- already closing, no need to call close()
          if not exitDialog then
            userResponse = "ok"
            exitDialog = true
          end
        end,
        -- The user changed photo selection in Lightroom's Library view.
        -- Refresh the plugin window with the newly selected photo.
        -- Note: setting catalog:setSelectedPhotos(targetPhoto, {}) below also
        -- triggers this observer; we filter that case via 'newPhoto ~= targetPhoto'.
        selectionChangeObserver = function()
          if myIteration ~= dialogIteration then return end
          if exitDialog then return end
          local newPhoto = catalog:getTargetPhoto()
          if newPhoto and newPhoto ~= targetPhoto then
            pendingNewPhoto = newPhoto
            userResponse = "selectionChanged"
            exitDialog = true
            -- Dismiss the current dialog so the outer repeat loop can
            -- present a freshly-built one for the newly selected photo.
            dismissFloatingDialog()
          end
        end,
      })
      -- Block this task here while the floating dialog is alive.
      -- Every callback that wants the dialog to close must set
      -- 'exitDialog = true' AND dismiss the floating dialog
      -- (closeDialog(), selectionChangeObserver, windowWillClose).
      while not exitDialog do
        LrTasks.sleep(0.1)
      end

      return userResponse
    end

    -- Find the index 'current' of the target photo in set of selectedPhotos
    current = getPositionInSelection(targetPhoto, selectedPhotos)
    -- throw up this dialog as soon as possible as it blocks input which keeps the plugin from potentially launching
    -- twice if clicked on really quickly
    -- let the renderer build the view now and show progress dialog
    repeat
      -- Get logging ready for next photo
      Log.logInfo("FocusPoint", string.rep("=", 72))
      Log.resetErrorsWarnings()

      -- Save link to current photo, eg. as supplementary information in user messages
      GlobalDefs.currentPhoto = targetPhoto

      -- Update file name display
      setFileName(targetPhoto)

      -- Make the current photo the only selected one:
      -- otherwise potential flagging operations will apply to all selected photos
      catalog:setSelectedPhotos(targetPhoto, {})

      -- Build the views for the current photo. The 'Loading Data / Calculating
      -- Focus Point' progress dialog has been removed: in the new non-modal
      -- workflow it would flash up briefly each time the photo is changed in
      -- the Library view, which is distracting.
      photoView = nil
      infoView  = nil
      errorMsg  = nil

      if (targetPhoto:checkPhotoAvailability()) then
        local photoW, photoH = FocusPointDialog.calculatePhotoViewDimens(targetPhoto)
        rendererTable = PointsRendererFactory.createRenderer(targetPhoto)

        if rendererTable then
          metadata  = ExifUtils.readMetadataAsTable(targetPhoto)
          photoView = rendererTable.createPhotoView(targetPhoto, photoW, photoH, metadata)
          infoView  = rendererTable.createInfoView(targetPhoto, props, metadata)
          if not (photoView and infoView) then
            errorMsg = "Internal error: Unable to create main window"
          end
        else
          -- just to have this case covered - normally this condition should not occur
          errorMsg = "Internal error: Unmapped points renderer"
        end
      else
        errorMsg = "Photo is not available. Make sure hard drives are attached and try again"
      end

      -- photoView should never be nil in the absence of a fatal error
      local skipMainWindow
      if not photoView then
        skipMainWindow = true
      end

      -- a fatal error has occured for the current image: ask user whether to "Exit" the plugin
      -- or "Continue" with the next image in multi-image mode (which means repeat in single-image mode)
      if errorMsg then
        userResponse = LrDialogs.confirm(errorMsg, Utils.getPhotoFileName(), "Continue", "Stop")
        if userResponse == "cancel" then
          -- Stop plugin operation
          return
        else
          -- just skip the main window, continue with next image or retry for the current
          skipMainWindow = true
        end
      end

      if skipMainWindow then
        -- A fatal error has occured for the current image, "Exit" the plugin operation or
        -- "Continue" to next image (in multi-image mode) or repeat (single-image mode)
        nextPhoto()
      else

        -- Open main window
        Log.logInfo("FocusPoint", "Present dialog and information")

        local f = LrView.osFactory()
        clicked = false

        if floatingDialog then
          userResponse = runFloatingDialog()
        else
          userResponse = runModalDialog()
        end

        if userResponse == "next" then
          nextPhoto()
        elseif userResponse == "previous" then
          previousPhoto()
        elseif userResponse == "selectionChanged" and pendingNewPhoto then
          -- Make the photo selected in Library the next one to be displayed
          targetPhoto = pendingNewPhoto
          -- If the new photo happens to be in the original 'selectedPhotos' set,
          -- update the running index so navigation stays consistent.
          for i, photo in ipairs(selectedPhotos) do
            if photo == pendingNewPhoto then
              current = i
              break
            end
          end
        end

        -- Clean up
        rendererTable.cleanup()

        -- Close the plugin if user closed the floating dialog window
        exitPlugin = (userResponse == "ok") or (userResponse == "cancel")
      end

      -- Clean log for next photo if in AUTO mode
      if not exitPlugin and prefs.loggingLevel == "AUTO" then
        Log.initialize()
        logAppInfo()
      end
    until exitPlugin

    -- Restore the original selection pf photos when the plugin was started
    if #selectedPhotos > 1 and not LR5 then
      catalog:setSelectedPhotos(targetPhoto, selectedPhotos)
    end
    -- Return to Develop modul if the plugin has been started from there
    if WIN_ENV and switchedToLibrary then
      LrApplicationView.switchToModule("develop")
    end

    -- Let LR breathe to do garbage collection
    for i = 1, 5 do
      LrTasks.yield()
    end

  end)
end

LrTasks.startAsyncTask( showFocusPoint )

return FocusPoint
