Hotkey Conf["Misc"]["Hotkey"], Start

Start(ThisHotkey) {
	switch Conf["Misc"]["SelectionMethod"], 0 {
		case SelectionMethods[1]: ;ctrl+a
			A_Clipboard := ""
			Send("^a")
			Send("^c")
			ClipWait()
			A_Clipboard := ModifyText(A_ClipBoard, GetActivePreset())
			Send("^v")
			SoundBeep()
		case SelectionMethods[2]: ;arrow spam
			A_Clipboard := ""
			Loop 50
				Send("^{Right}")
			Loop 50
				Send("^+{Left}")
			Send("^c")
			ClipWait()
			A_Clipboard := ModifyText(A_ClipBoard, GetActivePreset())
			Send("^v")
			SoundBeep()
	}
}