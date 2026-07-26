; Script Information ===========================================================
; Name .........: Focus-Points Hotkey
; Description ..: Hotkey assignments for Focus-Points plugin for LrC (French)
; AHK Version ..: 2.0.10 (Unicode 64-bit) - Oct 2023
; OS Version ...: Windows 11
; Author .......: Karsten Gieselmann
; Filename .....: FocusPointsHotkey_de.ahk
; ==============================================================================

SendMode("Input")           ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir(A_ScriptDir)  ; Ensures a consistent starting directory.

; ------------------------------------------------------------------------------
;Shortcuts for Lightroom Classic 15 (French)
; ------------------------------------------------------------------------------

#HotIf WinActive("Lightroom Classic")
{
  NumpadMult::  MenuSelect(, , "Fichier", "Module externe - Extras", "` ` ` Show Focus Point")
  NumpadDiv::   MenuSelect(, , "Fichier", "Module externe - Extras", "` ` ` Show Metadata")
 ^NumpadSub::   MenuSelect(, , "Fichier", "Module externe - Extras", "` ` ` Straighten Images")
}
