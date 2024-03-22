Global IniModes := ["A_", "AA_"]

;
;Configuration
;
If not FileExist(Path_Conf) {
	FileCopy(Path_ConfDefault, Path_Conf)
}
Global Conf := MakeMapFromIni(Path_Conf)
Global ConfDefault := MakeMapFromIni(Path_ConfDefault)

;
;Presets
;
Global Presets := FindPresets(Path_Presets)
Global PresetNames := []
For k,v in Presets {
	PresetNames.Push(k)
}

;
;Ini functions
;
MakeMapFromIni(FileName) {
	Obj := Map()

	SectionNames := StrSplit(IniRead(FileName), "`n")
	For _, SectionName in SectionNames {
		DisplaySectionName := SectionName
		Mode := FindIniMode(&DisplaySectionName)

		Obj[DisplaySectionName] := Map()

		For _, Pair in StrSplit(IniRead(FileName, SectionName), "`n") {
			Pair := StrSplit(Pair, "=",, 2)

			DisplayKeyName := Pair[1]
			NewMode := FindIniMode(&DisplayKeyName)
			Mode := NewMode != "" ? NewMode : Mode
			FormattedValue := IniModeFormat(Pair[2], Mode)

			Obj[DisplaySectionName][DisplayKeyName] := FormattedValue
		}
	}

	Return TweakIniMap(Obj)
}

FindIniMode(&Name) {
	Mode := ""
	For i, IniMode in IniModes {
		Prefix := SubStr(Name, 1, StrLen(IniMode))

		If Prefix = IniMode {
			Mode := IniMode
			Name := StrReplace(Name, IniMode)
		}
	}
	Return Mode
}

IniModeFormat(Value, Mode := "") {
	Switch Mode
	{
	Case "A_":
		Value := StrSplit(Value, ",")
	Case "AA_":
		Arr := []
		For i,v in StrSplit(Value, "|") {
			Arr.Push([])
			For _,v in StrSplit(v, ",") {
				Arr[i].Push(v)
			}
		}
		Value := Arr
	}
	Return Value
}

TweakIniMap(IniMap) {
	For SectionName,Section in IniMap {
		If IniMapTweaks["Sections"].Has(SectionName)
			IniMapTweaks["Sections"][SectionName](&IniMap, SectionName, Section)

		for Key,Value in Section {
			If IniMapTweaks["Keys"].Has(Key)
				IniMapTweaks["Keys"][Key](&IniMap, Key, Value)
		}
	}

	Return IniMap
}

;
;Preset functions
;
FindPresets(Folder) {
	Presets := map()
	Loop Files Folder "\*.ini", "R" {
		Name := StrReplace(A_LoopFileName, ".ini")
		Presets[Name] := MakeMapFromIni(A_LoopFilePath)
	}
	Return Presets
}

GetActivePreset() => Presets[Conf["Misc"]["ActivePreset"]]