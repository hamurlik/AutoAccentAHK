;
;Main
;
ModifyText(Str, Preset) {
	Meta := Map()
	Meta["Segments"] := Map()
	Meta["Segments"]["IgnoreSegments"] := FindIgnoreSegments(Str)
	Meta["Segments"]["ExtraChanceSegments"] := FindExtraChanceSegments(Str)

	For i,FunctionName in Preset["Conf"]["Order"] {
		PresetFunctions[FunctionName](&Str, &Meta, Preset)
	}

	return Str
}

;
;Preset functions
;
PresetFunctions := Map()

PresetFunctions["Words"] := Step_Words
Step_Words(&Str, &Meta, Preset) {
	Regex(&Str, &Meta, "iS)(\b(" Preset["Words"]["RegexStr"] ")\b)", Fn, Map("PresetWords", Preset["Words"]))

	Fn(Match, &Str, &Meta, FoundPos, LengthDiff, Parameters) {
		If ShouldIgnore(FoundPos, Meta)
			Return

		Key := StrLower(Match[])

		Chances := GetInfluencedChances(Parameters["PresetWords"]["Keys"][Key]["Chances"], FoundPos, Meta)

		RandomIndex := GetRandomIndexFromChances(Chances)
		If RandomIndex != 0 {
			Replacement := Parameters["PresetWords"]["Keys"][Key]["Replacements"][RandomIndex]
			Replacement := MatchCase(Replacement, Match[])

			Str := ModString(Str, FoundPos, Match.Len, Replacement)
		}
	}
}

PresetFunctions["Letters"] := Step_Letters
Step_Letters(&Str, &Meta, Preset) {
	PreviousPos := -1
	PreviousLength := 0
	PreviousKey := ""
	PreviousPassed := false

	Regex(&Str, &Meta, "iS)(" Preset["Letters"]["RegexStr"] ")", Fn, Map(
		"PresetLetters", Preset["Letters"],
		"PreviousPos", &PreviousPos,
		"PreviousLength", &PreviousLength,
		"PreviousKey", &PreviousKey,
		"PreviousPassed", &PreviousPassed
	))

	Fn(Match, &Str, &Meta, FoundPos, LengthDiff, Parameters) {
		If ShouldIgnore(FoundPos, Meta)
			Return

		Key := StrLower(Match[])
		PreviousPos := %Parameters["PreviousPos"]% + LengthDiff
		PreviousLength := %Parameters["PreviousLength"]%
		PreviousKey := %Parameters["PreviousKey"]%
		PreviousPassed := %Parameters["PreviousPassed"]%

		If Conf["Misc"]["GuaranteeIfPreviousLetter"] and PreviousKey = Match[] and FoundPos - PreviousLength = PreviousPos {
			If PreviousPassed {
				Replacement := SubStr(Str, PreviousPos, PreviousLength)
				Replacement := MatchCase(Replacement, Match[])

				Str := ModString(Str, FoundPos, Match.Len, Replacement)
			}

			%Parameters["PreviousPos"]% := FoundPos
			%Parameters["PreviousLength"]% := PreviousLength
			%Parameters["PreviousKey"]% := Match[]
			%Parameters["PreviousPassed"]% := PreviousPassed
		} Else {
			Chances := GetInfluencedChances(Parameters["PresetLetters"]["Keys"][Key]["Chances"], FoundPos, Meta)

			RandomIndex := GetRandomIndexFromChances(Chances)
			Replacement := ""
			If RandomIndex != 0 {
				Replacement := Parameters["PresetLetters"]["Keys"][Key]["Replacements"][RandomIndex]
				Replacement := MatchCase(Replacement, Match[])

				Modify := True
				If Conf["Misc"]["NoNonAsciiFirstCharacter"] {
					FirstAsciiCharacter := RegExMatch(Str, "iS)[a-zA-Z]")
					If FoundPos <= FirstAsciiCharacter and not IsAlpha(Replacement) {
						Modify := False
					}
				}

				If Modify
					Str := ModString(Str, FoundPos, Match.Len, Replacement)
				Else
					Replacement := ""
			}

			%Parameters["PreviousPos"]% := FoundPos
			%Parameters["PreviousLength"]% := Replacement != "" ? StrLen(Replacement) : Match.Len
			%Parameters["PreviousKey"]% := Match[]
			%Parameters["PreviousPassed"]% := Replacement != "" ? true : false
		}
	}
}

PresetFunctions["ReplaceC"] := Step_ReplaceC
Step_ReplaceC(&Str, &Meta, Preset) {
	Regex(&Str, &Meta, "iS)(c)", Fn)

	Fn(Match, &Str, &Meta, FoundPos, LengthDiff, Parameters) {
		If ShouldIgnore(FoundPos, Meta)
			Return

		Replacement := "s"
		If FoundPos + 1 <= StrLen(Str) {
			NextChar := SubStr(Str, FoundPos + 1, 1)
			If NextChar != "e" and NextChar != "i" and NextChar != "y" {
			 	If NextChar != "k" and NextChar != "h"
					Replacement := "k"
				Else
					Replacement := "c"
			}
		}

		If Replacement != "c" {
			Replacement := MatchCase(Replacement, Match[])
			Str := ModString(Str, FoundPos, 1, Replacement)
		}
	}
}

PresetFunctions["CapitalizeZ"] := Step_CapitalizeZ
Step_CapitalizeZ(&Str, &Meta, Preset) {
	Str := StrReplace(Str, "z", "Z", true)
}

PresetFunctions["EdgyPunctuation"] := Step_EdgyPunctuation
Step_EdgyPunctuation(&Str, &Meta, Preset) {
	Regex(&Str, &Meta, "iS)(\b\w+\b)", Fn, Map("PresetEdgyPunctuation", Preset["EdgyPunctuation"]))

	Fn(Match, &Str, &Meta, FoundPos, LengthDiff, Parameters) {
		If ShouldIgnore(FoundPos, Meta)
			Return

		Suffix := SubStr(Str, FoundPos + Match.Len, 1)
		IsPeriod := Suffix = "."
		IsComma := Suffix = ","
		IsSingleQuote := Suffix = "'"
		IsExclamation := Suffix = "!"
		IsQuestion := Suffix = "?"

		If not IsPeriod and not IsComma and not IsSingleQuote and not IsExclamation and not IsQuestion {
			Chances := GetInfluencedChances([Parameters["PresetEdgyPunctuation"]["Chance"]], FoundPos, Meta)
			RandomIndex := GetRandomIndexFromChances(Chances)

			If RandomIndex != 0
				Str := ModString(Str, FoundPos + Match.Len, 0, "...")
		}
	}
}

;
;Regex logic
;
Regex(&Str, &Meta, Regex, Fn, Parameters := Map()) {
	Pos := 1
    LastStr := Str
	LengthDiff := 0
    While (FoundPos := RegExMatch(Str, Regex, &Match, Pos))
	{
		LastStr := Str
        Fn(Match, &Str, &Meta, FoundPos, LengthDiff, Parameters)

		LengthDiff := StrLen(Str) - StrLen(LastStr)

		For Key,ArrOfArrays in Meta["Segments"] {
			For IndexArr,Arr in ArrOfArrays {
				For i,v in Arr {
					Meta["Segments"][Key][IndexArr][i] := v + LengthDiff
				}
			}
		}

        Pos := FoundPos + Match.Len + LengthDiff
    }
}

;
;Segment functions
;
ShouldIgnore(Pos, Meta) {
	Return Conf["Misc"]["IgnoreQuoted"] and IsInSegments(Pos, Meta["Segments"]["IgnoreSegments"])
}

ShouldExtraChance(Pos, Meta) {
	Return Conf["ExtraChance"]["Enabled"] and IsInSegments(Pos, Meta["Segments"]["ExtraChanceSegments"])
}

IsInSegments(Pos, Segments) {
	For i,v in Segments {
        If v.Length >= 2 and Pos >= v[1] and Pos <= v[2] {
            Return true
        }
    }

    Return false
}

FindIgnoreSegments(Str) {
	Return FindSegmentsFromSymbol(Str, "`"")
}

FindExtraChanceSegments(Str) {
	StrArray := StrSplit(Str)
	StrArray.Push(" ")

	Segments := []

	CapsStartPos := 0
	CapsCount := 0
	For Pos,Char in StrArray {
		If IsUpper(Char, "Locale") {
			If CapsStartPos <= 0
				CapsStartPos := Pos

			CapsCount := CapsCount + 1
		} Else {
			If CapsCount >= 2 {
				Segments.Push([CapsStartPos, Pos - 1])
			}

			CapsStartPos := 0
			CapsCount := 0
		}
	}

	Return Segments
}

FindSegmentsFromSymbol(Str, Symbol) {
	Segments := [[]]
	Pos := 1
    While (FoundPos := InStr(Str, Symbol, 0, Pos)) {
        If Segments[Segments.Length].Length < 2 {
			Segments[Segments.Length].Push(FoundPos)
		} Else {
			Segments.Push([FoundPos])
		}

        Pos := FoundPos + 1
    }

	Return Segments
}

;
;Randomization functions
;
GetRandomIndexFromChances(Chances) {
	Roll := Random(0.0, 1.0)

	ChancesStr := ""
	For i,v in Chances
		ChancesStr := ChancesStr v ","

	ChancesStr := SubStr(ChancesStr, 1, StrLen(ChancesStr) - 1)

	ChancesStr := Sort(ChancesStr, "NRD,")
	ChancesSorted := StrSplit(ChancesStr, ",")

	For i,v in ChancesSorted {
		If ChancesSorted.Has(i - 1)
			ChancesSorted[i] := LockNumberToRange(ChancesSorted[i - 1] - v, 0.0, 1.0)
		Else
			ChancesSorted[i] := LockNumberToRange(1.0 - v, 0.0, 1.0)
	}

	BestPick := 0
	For i,v in ChancesSorted {
		If Roll > v {
			BestPick := i
			Break
		}
	}

	;MsgBox("Rolled: " Roll "`n" ObjectToString(ChancesSorted) "`nOutcome: " BestPick)

	Return BestPick
}

GetInfluencedChances(Chances, Pos, Meta) {
	Mult := Conf["Misc"]["GlobalMult"]

	If ShouldExtraChance(Pos, Meta)
		Mult := Mult * Conf["ExtraChance"]["Mult"]

	Return InfluenceChances(Chances, Mult)
}

InfluenceChances(Chances, Mult) {
	Sum := 0.0
	For i,v in Chances
		Sum := Sum + v

	MaxMult := 1.0 / Sum
	Mult := LockNumberToRange(Mult, 0.0, MaxMult)

	NewChances := []
	For i,v in Chances
		NewChances.Push(v * Mult)

	Return NewChances
}

LockNumberToRange(Num, MinRange, MaxRange) {
	If Num > MaxRange
		Num := MaxRange
	Else If Num < MinRange
		Num := MinRange

	Return Num
}

;
;Case matching functions
;
MatchCase(ToMatch, MatchThis) {
    ToMatchArray := StrSplit(ToMatch)
	ToMatchArrayGood := []
	For i,Char in ToMatchArray {
		If IsLower(Char, "Locale") or IsUpper(Char, "Locale")
			ToMatchArrayGood.Push(Char)
	}

    MatchThisArray := StrSplit(MatchThis)
	MatchThisArrayGood := []
	For i,Char in MatchThisArray {
		If IsLower(Char, "Locale") or IsUpper(Char, "Locale")
			MatchThisArrayGood.Push(Char)
	}

    Final := []
    For i,Char in ToMatchArrayGood {
        If MatchThisArrayGood.Has(i) {
            Final.Push(ConvertCase(Char, MatchThisArrayGood[i]))
        } Else If i-1 >= 1 and Final.Has(i-1) {
            Final.Push(ConvertCase(Char, Final[i-1]))
        } Else {
            Final.Push(Char)
        }
    }

	For i,Char in ToMatchArray {
		If not IsLower(Char, "Locale") and not IsUpper(Char, "Locale")
			Final.InsertAt(i, Char)
	}

	;MsgBox("ToMatch: " ToMatch "`nToMatchGood: " ArrayToString(ToMatchArrayGood) "`nMatchThis: " MatchThis "`nMatchThisGood: " ArrayToString(MatchThisArrayGood) "`nFinal: " ArrayToString(Final))

    Return ArrayToString(Final)
}

ConvertCase(ToMatch, MatchThis) {
    If IsUpper(MatchThis, "Locale") {
        Return StrUpper(ToMatch)
    } Else If IsLower(MatchThis, "Locale") {
        Return StrLower(ToMatch)
    } Else {
        Return ToMatch
    }
}

;
;String manipulation functions
;
ModString(Str, Pos, EraseLength := 0, Replace := "") {
    StrArray := StrSplit(Str)

	If EraseLength > 0
		StrArray.RemoveAt(Pos, EraseLength)

    StrArray.InsertAt(Pos, Replace)

    Return ArrayToString(StrArray)
}

ArrayToString(Arr) {
	Str := ""
	For i,Char in Arr
		Str := Str Char

	Return Str
}