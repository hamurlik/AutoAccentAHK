Global SelectionMethods := ["Ctrl+A (doesnt work on rogue)", "Arrow Spam (slow)"]

A_TrayMenu.Delete("3&")
A_TrayMenu.Delete("&Open")
A_TrayMenu.Delete("&Help")
A_TrayMenu.Delete("&Window Spy")
A_TrayMenu.Delete("&Edit Script")
A_TrayMenu.Delete("2&")
A_TrayMenu.Delete("&Suspend Hotkeys")
A_TrayMenu.Delete("&Pause Script")

A_TrayMenu.Insert("&Reload Script")

Menu_SimpleYesNo(A_TrayMenu, "Reset Settings", "Delete conf.ini to reset settings?", "Reset Settings", ResetSettings, "1&")
ResetSettings(ItemName, ItemPos, MyMenu) {
	FileDelete(Path_Conf)
	Reload
}

Menu_Simple(A_TrayMenu, "Open Readme", OpenReadme, "1&")
OpenReadme(ItemName, ItemPos, MyMenu) {
	Run(Path_Readme)
}

A_TrayMenu.Insert("1&")

ExtraChanceSubmenu := Menu()
Menu_Toggle(ExtraChanceSubmenu, "Enabled", "ExtraChance", "Enabled")
Menu_Input(ExtraChanceSubmenu, "Multiplier", "Default: " ConfDefault["ExtraChance"]["Mult"] "`nInput new multiplier:", "Caps Extra Chance", "ExtraChance", "Mult",, IsFloat)
A_TrayMenu.Insert("1&", "Caps Extra Chance", ExtraChanceSubmenu)

Menu_Toggle(A_TrayMenu, "Ignore Quoted", "Misc", "IgnoreQuoted", "1&")
A_TrayMenu.Insert("1&")

SelectionMethodSubmenu := Menu()
Menu_ToggleOneOnly(SelectionMethodSubmenu, SelectionMethods, "Misc", "SelectionMethod")
A_TrayMenu.Insert("1&", "Selection Method", SelectionMethodSubmenu)

Menu_Hotkey(A_TrayMenu, "Hotkey", "See key names in AHK documentation.`nDefault: " ConfDefault["Misc"]["Hotkey"] "`nInput new hotkey:", "Hotkey", "Misc", "Hotkey", "w300 h125", "1&")
A_TrayMenu.Insert("1&")

PresetSubmenu := Menu()
Menu_ToggleOneOnly(PresetSubmenu, PresetNames, "Misc", "ActivePreset")
A_TrayMenu.Insert("1&", "Preset", PresetSubmenu)

Menu_Input(A_TrayMenu, "Global Multiplier", "Default: " ConfDefault["Misc"]["GlobalMult"] "`nInput new multiplier:", "Global Multiplier", "Misc", "GlobalMult",, IsFloat, "1&")
Menu_Toggle(A_TrayMenu, "No non-ascii 1st char", "Misc", "NoNonAsciiFirstCharacter", "1&")
Menu_Toggle(A_TrayMenu, "100% if prev. letter", "Misc", "GuaranteeIfPreviousLetter", "1&")

Persistent

;
;Tray menu functions
;
Menu_Toggle(MenuObj, Name, Section, Key, Pos := 0) {
	if Pos != 0
		MenuObj.Insert(Pos, Name, Fn)
	else
		MenuObj.Add(Name, Fn)

	if Conf[Section][Key]
		MenuObj.Check(Name)

	Fn(ItemName, ItemPos, MyMenu) {
		MyMenu.ToggleCheck(ItemName)
		Conf[Section][Key] := Conf[Section][Key] = 1 ? 0 : 1
		IniWrite(Conf[Section][Key], Path_Conf, Section, Key)
	}
}

Menu_ToggleOneOnly(MenuObj, Names, Section, Key, Pos := 0) {
	for i,Name in Names {
		if Pos != 0
			MenuObj.Insert(Pos, Name, Fn)
		else
			MenuObj.Add(Name, Fn)

		if Conf[Section][Key] = Name
			MenuObj.Check(Name)
	}

	Fn(ItemName, ItemPos, MyMenu) {
		if Conf[Section][Key] != ItemName {
			for i,Name in Names {
				if Name != ItemName
					MyMenu.Uncheck(Name)
			}
			MyMenu.Check(ItemName)
			Conf[Section][Key] := ItemName
			IniWrite(Conf[Section][Key], Path_Conf, Section, Key)
		}
	}
}

Menu_Input(MenuObj, Name, Prompt, Title, Section, Key, Options := "w200 h110", TestFn := 0, Pos := 0) {
	if Pos != 0
		MenuObj.Insert(Pos, Name, Fn)
	else
		MenuObj.Add(Name, Fn)

	Fn(ItemName, ItemPos, MyMenu) {
		Answer := InputBox(Prompt, Title, Options, Conf[Section][Key])
		if Answer.Result = "OK" {
			if TestFn = 0 or TestFn(Answer.Value) {
				if Answer.Value != Conf[Section][Key] {
					Conf[Section][Key] := Answer.Value
					IniWrite(Conf[Section][Key], Path_Conf, Section, Key)
				}
			} else {
				MsgBox("Invalid input.")
				Fn(ItemName, ItemPos, MyMenu)
			}
		}
	}
}

Menu_Hotkey(MenuObj, Name, Prompt, Title, Section, Key, Options := "w200 h110", Pos := 0) {
	if Pos != 0
		MenuObj.Insert(Pos, Name, Fn)
	else
		MenuObj.Add(Name, Fn)

	Fn(ItemName, ItemPos, MyMenu, FirstRun := true) {
		if FirstRun {
			Result := MsgBox("Open AHK documentation?`nhttps://www.autohotkey.com/docs/v2/KeyList.htm`nhttps://www.autohotkey.com/docs/v2/Hotkeys.htm#Symbols",, "YesNo")
			if Result = "Yes" {
				Run("https://www.autohotkey.com/docs/v2/Hotkeys.htm#Symbols")
				Run("https://www.autohotkey.com/docs/v2/KeyList.htm")
			}
		}
		FirstRun := false

		Answer := InputBox(Prompt, Title, Options, Conf[Section][Key])
		if Answer.Result = "OK" {
			if Answer.Value != Conf[Section][Key] {
				try
					Hotkey Answer.Value, EmptyFn
				catch ValueError as err {
					MsgBox("Invalid hotkey.`nError: " err.Extra "`nCheck AutoHotkey documentation.")
					Fn(ItemName, ItemPos, MyMenu, FirstRun)
				} else {
					Hotkey Conf[Section][Key], "Off"
					Hotkey Answer.Value, Start
					Hotkey Answer.Value, "On"
					Conf[Section][Key] := Answer.Value
					IniWrite(Conf[Section][Key], Path_Conf, Section, Key)
				}
			}
		}
	}

	EmptyFn(*) {

	}
}

Menu_Simple(MenuObj, Name, ParamFn, Pos := 0) {
	if Pos != 0
		MenuObj.Insert(Pos, Name, Fn)
	else
		MenuObj.Add(Name, Fn)

	Fn(ItemName, ItemPos, MyMenu) {
		ParamFn(ItemName, ItemPos, MyMenu)
	}
}

Menu_SimpleYesNo(MenuObj, Name, Prompt, Title, ParamFn, Pos := 0) {
	if Pos != 0
		MenuObj.Insert(Pos, Name, Fn)
	else
		MenuObj.Add(Name, Fn)

	Fn(ItemName, ItemPos, MyMenu) {
		Result := MsgBox(Prompt, Title, "YesNo")
		if Result = "Yes"
			ParamFn(ItemName, ItemPos, MyMenu)
	}
}

SegmentSymbolTest(Str) {
	If StrLen(Str) = 1 and not IsLower(Str, "Locale") and not IsUpper(Str, "Locale")
		Return true

	Return false
}