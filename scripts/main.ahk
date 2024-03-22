#Requires AutoHotkey v2.0

SetWorkingDir StrReplace(A_ScriptDir, "\scripts")
Global Path_Conf := "conf.ini"
Global Path_ConfDefault := "scripts\conf_default.ini"
Global Path_Presets := "presets"
Global Path_Readme := "Readme.txt"

;
;Ini map tweaks list
;
#Include initweaks.ahk

;
;Configuration and presets
;
#Include conf.ahk

;
;Tray menu
;
#Include menu.ahk

;
;Hotkey
;
#Include hotkey.ahk

;
;Text modification logic
;
#Include logic.ahk

;
;Debug functions
;
#Include debug.ahk