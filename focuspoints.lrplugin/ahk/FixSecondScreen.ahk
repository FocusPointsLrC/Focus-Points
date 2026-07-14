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

; ------------------------------------------------------------------------------
; Focus Points Interactive mode workaround
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

; ------------------------------------------------------------------------------
; Follow mode workaround
;
; Lightroom transfers keyboard focus to each newly opened Follow window, stealing keyboard
; focus from the Lightroom main window. As soon as the Follow window becomes
; active, keyboard focus is returned to Lightroom so that the arrow keys
; continue to navigate photos.
;
; The Follow window remains fully usable with the mouse. Keyboard input remains
; with Lightroom.
; ------------------------------------------------------------------------------

global g_HandledFollowHwnd := 0

FOLLOW_ACTIVATION_DELAY_MS := 15

SetTimer WatchFollowWindow, FOLLOW_POLL_INTERVAL_MS

WatchFollowWindow()
{
    global g_HandledFollowHwnd
    global FOLLOW_ACTIVATION_DELAY_MS

    hwnd := WinActive("Focus Points Follow")

    if (hwnd && hwnd != g_HandledFollowHwnd)
    {
        g_HandledFollowHwnd := hwnd

        Sleep FOLLOW_ACTIVATION_DELAY_MS

        if WinActive("ahk_id " hwnd)
            ; Return keyboard focus to Lightroom's main window.
            WinActivate("ahk_class AgWinMainFrame")
    }

    if (!hwnd)
        g_HandledFollowHwnd := 0
}