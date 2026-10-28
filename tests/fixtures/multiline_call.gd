extends RefCounted


func calculate() -> int:
	var value := 1 # don't treat apostrophes in comments as string delimiters
	return _sum(
		value,
		2
	)


func _sum(first: int, second: int) -> int:
	return first + second
