@tool
extends EditorImportPlugin
class_name ShrimpSyntaxTreeImporter

const IMPORTER_ID = "shrimpvm.shrimpir"

func _get_importer_name() -> String:
	return IMPORTER_ID
func _get_visible_name() -> String:
	return "Shrimp IR Graph"
func _get_recognized_extensions() -> PackedStringArray:
	return ["sst"]
func _get_save_extension() -> String:
	return "tres"
func _get_resource_type() -> String:
	return "ShrimpIR"
func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	return [
		{
			"name": "ir_script_dir",
			"display_name": "IR script directory",
			"property_hint": PropertyHint.PROPERTY_HINT_DIR,
			"usage": PROPERTY_USAGE_DEFAULT,
			"default_value": ""
		}
	]
func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var result = import_file(source_file)
	if result is ShrimpIR:
		return ResourceSaver.save(result, "%s.%s" % [save_path, _get_save_extension()])
	else:
		return ERR_PARSE_ERROR

static func import_file(source: String) -> ShrimpIR:
	var file = FileAccess.open(source, FileAccess.ModeFlags.READ)
	if file == null:
		push_error("Failed to read file.")
		return null
	return import_json(file.get_as_text())
static func import_json(text: String) -> ShrimpIR:
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		push_error("Failed to parse json data.")
		return null
	return import_data(json.data)
static func import_data(data: Variant) -> ShrimpIR:
	if data is Dictionary:
		var first = compile(data)
		if !first:
			push_error("Failed to create IR-Node.")
			return null
		if first.get_node_type() != ShrimpRootNode.get_node_type():
			push_error("Must start with a root node.")
			return null
		return first
	else:
		push_error("First node must be a dictionary.")
		return null
static func compile(from: Variant) -> ShrimpIR:
	if from is not Dictionary:
		assert(false,"Can only compile wrapper to IR-Node.")
		return null
	if !from:
		push_error("Cannot create IR-Node from null.")
		return null
	if from.get("invalid", false):
		# 这是个棍母，直接跳过
		return null
	for node in ShrimpVMUtil.get_ir_nodes():
		if node == null:
			push_warning("Failed to load node script: %s." % node)
			continue
		if node.get_node_type() == from.type:
			var result = node.create_from(from)
			if result is not ShrimpIR:
				push_error("Broken node %s: not created an IR-Node." % node)
				return null
			return result
	push_error("Unknown IR-Node type: %s." % from.type)
	return null
static func compile_body(from: Array) -> Array[ShrimpIR]:
	var result: Array[ShrimpIR] = []
	for wrapper in from:
		result.append(compile(wrapper))
	return result
static func decompile(from: ShrimpIR) -> Dictionary:
	return {"type": from.get_node_type()}.merged(from.decompile(), true)
static func decompile_body(from: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for ir in from:
		if ir is ShrimpIR:
			result.append(decompile(ir))
	return result
