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
	var result = import_from_file(source_file, options)
	if result is ShrimpIR:
		return ResourceSaver.save(result, "%s.%s" % [save_path, _get_save_extension()])
	else:
		return ERR_PARSE_ERROR

func import_from_file(source: String, options: Dictionary) -> ShrimpIR:
	var file = FileAccess.open(source, FileAccess.ModeFlags.READ)
	if file == null:
		return null
	var text = file.get_as_text()
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		push_error("Failed to parse json data.")
		return null
	var data = json.data
	if data is Dictionary:
		var first = create_ir(data, options)
		if !first:
			push_error("Failed to create IR-Node.")
			return null
		if first.node_type != ShrimpRootNode.get_node_type():
			push_error("Must start with a root node.")
			return null
		return first
	else:
		push_error("First node must be a dictionary.")
		return null
func create_ir(from: Dictionary, options: Dictionary) -> ShrimpIR:
	for node in ShrimpVMUtil.get_ir_nodes():
		if node == null:
			push_warning("Failed to load node script: %s" % node)
			continue
		if node.get_node_type() == from.type:
			var result = node.create_from(from, self, options)
			if result is not ShrimpIR:
				push_error("Broken node %s: not created an IR-Node" % node)
				return null
			result.node_type = from.type
			return result
	push_error("Unknown IR-Node type: %s" % from.type)
	return null
