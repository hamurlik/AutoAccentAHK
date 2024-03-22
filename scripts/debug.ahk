ObjectToString(Obj) {
	Str := ""
	RecurseObjIntoStr(Obj, &Str, 0)
	Return Str
}

RecurseObjIntoStr(Obj, &Str, RecurseCount) {
	Tabs := ""
	loop RecurseCount {
		Tabs := Tabs "  "
	}

	Enumerable(&Obj)
	for i,v in Obj {
		IsEnumerable := Enumerable(&v)
		if IsEnumerable {
			Str := Str "`n" Tabs i " = ["
			RecurseObjIntoStr(v, &Str, RecurseCount + 1)
			Str := Str "`n" Tabs "]"
		} else {
			Str := Str "`n" Tabs i " = " v
		}
	}
}

Enumerable(&Obj) {
	switch type(Obj), 0
	{
	case "array":
		return true
	case "map":
		return true
	case "object":
		Obj := Obj.OwnProps()
		return true
	default:
		return false
	}
}