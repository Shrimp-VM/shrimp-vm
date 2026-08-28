class_name ShrimpVMUtil

class EventEmitter extends RefCounted:
	signal event()

static func hide_keys(dic: Dictionary, keys: Array[StringName]) -> Dictionary:
	var result = dic.duplicate()
	for key in keys:
		result.erase(key)
	return result
static func is_script_inherits(script: GDScript, ancestor: GDScript) -> bool:
	var current: Script = script
	while current != null:
		if current == ancestor:
			return true
		current = current.get_base_script()
	return false
static func disconnect_children(node: Node):
	for child in node.get_children():
		node.remove_child(child)
static func get_importer_setting():
	return ProjectSettings.get_setting("importer_defaults/%s" % ShrimpSyntaxTreeImporter.IMPORTER_ID)
static func get_ir_nodes() -> Array[ShrimpIR]:
	var base: String = get_importer_setting().ir_script_dir
	var result: Array[ShrimpIR] = []
	for i in ShrimpVMUtil.concat_array(
		["res://addons/shrimpvm/nodes/root_node.gd"],
		Array(DirAccess.get_files_at(base))
			.filter(func(e: String): return e.ends_with(".gd"))
			.map(func(e: String): return base.path_join(e)),
	):
		result.append((load(i) as GDScript).new())
	return result
static func find_ir_node(type: String) -> ShrimpIR:
	return get_ir_nodes().filter(func(e): return e.get_node_type() == type)[0]
static func concat_array(a: Array, b: Array):
	var result = a.duplicate()
	result.append_array(b)
	return result
