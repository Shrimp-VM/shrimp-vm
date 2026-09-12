class_name ShrimpVMUtil

class EventEmitter extends RefCounted:
	signal event()

	func emit(data):
		event.emit(data)

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
static func disconnect_children(node: Node, excludes: Array = []):
	for child in node.get_children():
		if child not in excludes:
			node.remove_child(child)
static func get_importer_setting():
	return ProjectSettings.get_setting("importer_defaults/%s" % ShrimpCompiler.IMPORTER_ID)
static func list_scripts(baseDir: String):
	return Array(
		Array(ResourceLoader.list_directory(baseDir))
			.filter(func(e: String): return e.ends_with(".gd"))
			.map(func(e: String): return baseDir.path_join(e))
	)
static func category_desk(irs: Array[ShrimpIR]) -> Dictionary[String, Array]:
	var result: Dictionary[String, Array] = {}
	for ir in irs:
		var category = ir.get_category_tag()
		if !result.has(category):
			result[category] = []
		result[category].append(ir)
	return result
static func scan_ir_nodes(baseDirs: Array) -> Array[ShrimpIR]:
	var result: Array[ShrimpIR] = []
	for dir in baseDirs:
		for fp in list_scripts(dir):
			var script = load(fp)
			if script is Script:
				var instance = script.new()
				if instance is ShrimpIR:
					result.append(instance)
	return result
static func get_configured_irs() -> Array[ShrimpIR]:
	return scan_ir_nodes(
		concat_array(
			[get_importer_setting().ir_script_dir],
			get_builtins()
		)
	)
static func get_builtin_subdir(path: String):
	return "res://addons/shrimpvm/nodes/".path_join(path)
static func get_builtins():
	return ["base", "functions", "literals"].map(get_builtin_subdir)
static func find_ir_node(type: String) -> ShrimpIR:
	var irs = get_configured_irs()
	var index = irs.find_custom(func(e): return e.get_node_type() == type)
	if index >= 0:
		return irs[index]
	else:
		return null
static func concat_array(a: Array, b: Array):
	var result = a.duplicate()
	result.append_array(b)
	return result
