class_name ShrimpUtil

static func hideKeys(dic: Dictionary, keys: Array[StringName]) -> Dictionary:
	var result = dic.duplicate()
	for key in keys:
		result.erase(key)
	return result
static func isScriptInherits(script: GDScript, ancestor: GDScript) -> bool:
	var current: Script = script
	while current != null:
		if current == ancestor:
			return true
		current = current.get_base_script()
	return false
