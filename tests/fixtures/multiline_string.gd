extends RefCounted


func get_source() -> String:
	return """
if true:
	print("literal")
else :
	pass
"""
