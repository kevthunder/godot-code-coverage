extends RefCounted


func choose(value: bool) -> String:
	var result := "if"
	if value:
		result = "if"
	else:
		result = "else"
	return result
