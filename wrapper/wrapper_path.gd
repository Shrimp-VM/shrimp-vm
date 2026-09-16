extends RefCounted
class_name WrapperPath

enum PartType {
	ATTRIBUTE,
	INDEX
}

var type: PartType = PartType.ATTRIBUTE
var path = ""
var next: WrapperPath

func run(data) -> Variant:
	match type:
		PartType.ATTRIBUTE:
			if data is Dictionary:
				return data.get(path)
			else:
				push_error("Mush execute attribute on a Wrapper.")
		PartType.INDEX:
			if data is Array:
				return data.get(path)
			else:
				push_error("Mush execute index on a Array.")
	push_error("Invalid part type.")
	return null
func execute_root(data) -> Variant:
	var result = run(data)
	if is_instance_valid(next):
		return next.execute_root(result)
	else:
		return result
