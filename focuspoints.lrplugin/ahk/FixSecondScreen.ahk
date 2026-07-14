; Script Information ===========================================================
; Name .........: Fix Second Screen
; Purpose ......: Companion script for Focus Point Viewer.
;                 Works around Lightroom SDK window activation issues.
; AHK Version ..: 2.0.10 (Unicode 64-bit) - Oct 2023
; OS Version ...: Windows 11
; Author .......: Karsten Gieselmann
; Filename .....: FixSecondScreen.ahk
; ==============================================================================

; NOTE
;
; This script intentionally favors robustness over completeness.
; A known limitation is that Lightroom cannot be minimized while the
; Focus Points Follow window is open. This is an acceptable trade-off for
; reliable keyboard focus restoration during normal use.
;

#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; Focus Points Interactive — Initialize keyboard focus for plugin window
; ==============================================================================
;
; Lightroom creates the floating dialog without giving keyboard focus to any
; control. Sending one Right Arrow initializes the keyboard focus so that
; keyboard shortcuts work immediately.
; ------------------------------------------------------------------------------

global g_LastInteractiveHwnd := 0

; Check every 50 ms for a newly created Interactive window.
INTERACTIVE_POLL_INTERVAL_MS := 50
FOLLOW_POLL_INTERVAL_MS := 10

SetTimer WatchInteractiveWindow, INTERACTIVE_POLL_INTERVAL_MS

WatchInteractiveWindow()
{
    global g_LastInteractiveHwnd

    hwnd := WinExist("Focus Points Interactive")

    ; Window closed -> reset
    if (!hwnd)
    {
        g_LastInteractiveHwnd := 0
        return
    }

    ; Same window as before -> nothing to do
    if (hwnd = g_LastInteractiveHwnd)
        return

    ; New Interactive window detected.
    g_LastInteractiveHwnd := hwnd

    ; Give Lightroom time to finish creating it.
    Sleep 25

    ; Activate the dialog.
    WinActivate("ahk_id " hwnd)

    ; Small additional delay before sending the initialization key.
    Sleep 25

    ; Initialize keyboard focus.
    Send "{Down}"
}

; ==============================================================================
;  Focus Points Follow — keep keyboard focus on Lightroom
; ==============================================================================
;
; Detects the exact moment the "Focus Points Follow" floating dialog is
; created/shown (including on refresh = close+reopen)and immediately hands
; keyboard focus back to Lightroom Classic (ahk_class AgWinMainFrame).

; This only fires on window CREATION (EVENT_OBJECT_SHOW). Once the dialog exists,
; clicking into it and interacting works completely normally — the script
; won't touch it again until it is closed and recreated.
; ------------------------------------------------------------------------------


TargetTitle  := "Focus Points Follow"   ; substring match
LightroomWin := "ahk_class AgWinMainFrame"

OBJID_WINDOW          := 0
EVENT_OBJECT_SHOW     := 0x8002
WINEVENT_OUTOFCONTEXT := 0x0000

; Keep references global so they aren't garbage-collected
global g_HookCB := CallbackCreate(OnWinEvent, "F", 7)
global g_Hook := DllCall("SetWinEventHook"
    , "UInt", EVENT_OBJECT_SHOW
    , "UInt", EVENT_OBJECT_SHOW
    , "Ptr", 0
    , "Ptr", g_HookCB
    , "UInt", 0
    , "UInt", 0
    , "UInt", WINEVENT_OUTOFCONTEXT
    , "Ptr")

OnExit((*) => DllCall("UnhookWinEvent", "Ptr", g_Hook))

; --- Callback: fires for every EVENT_OBJECT_SHOW system-wide ---
OnWinEvent(hHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime) {
    ; idObject must be OBJID_WINDOW (0) — filters out child controls
    ; (buttons, text fields, etc.) inside the dialog also becoming visible
    if (idObject != OBJID_WINDOW) || !hwnd
        return

    title := ""
    try title := WinGetTitle("ahk_id " hwnd)
    if InStr(title, TargetTitle)
        ReturnFocusToLightroom()
}

; --- Race the SDK's own activation and reassert Lightroom ---
ReturnFocusToLightroom() {
    ; The LrC SDK creates the floating dialog as the active window.
    ; We reassert Lightroom several times over ~150ms to make sure
    ; our activation wins even if the SDK re-asserts itself once
    ; the window finishes painting.
    Loop 6 {
        Sleep 25
        if WinExist(LightroomWin)
            WinActivate(LightroomWin)
    }
}
