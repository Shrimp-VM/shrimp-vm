@tool
extends Resource
class_name GarlicTree

@export var wrapper: Dictionary

func load_from(from_fp: String) -> GarlicTree:
	wrapper = GarlicParser.parse_from_file(from_fp)
	return self
