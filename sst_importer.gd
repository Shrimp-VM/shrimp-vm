@tool
extends EditorImportPlugin
class_name ShrimpSyntaxTreeImporter

func _get_importer_name() -> String:
	return "shrimpvm.shrimpir"
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
			"name": "nodes",
			"display_name": "IR-Nodes",
			"type": TYPE_ARRAY,
			"property_hint": PropertyHint.PROPERTY_HINT_ARRAY_TYPE,
			"hint_string": "ShrimpIR",
			"usage": PROPERTY_USAGE_DEFAULT,
			"default_value": [ShrimpRootNode.new()]
		}
	]
func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var file = FileAccess.open(source_file, FileAccess.ModeFlags.READ)
	if file == null:
		return file.get_open_error()
	var text = file.get_as_text()
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		push_error("Failed to parse json data.")
		return ERR_PARSE_ERROR
	var data = json.data
	if data is Dictionary:
		var first = create_ir(data, options)
		if !first:
			push_error("Failed to create IR-Node.")
			return ERR_PARSE_ERROR
		if first.node_type != ShrimpRootNode.get_node_type():
			push_error("Must start with a root node.")
			return ERR_PARSE_ERROR
		return ResourceSaver.save(first, "%s.%s" % [save_path, _get_save_extension()])
	else:
		return ERR_PARSE_ERROR

func create_ir(from: Dictionary, options: Dictionary) -> ShrimpIR:
	for i in options.nodes:
		var node: GDScript = i.get_script()
		if node == null:
			push_error("Cannot load IR-Node script: %s" % i)
			continue
		if node.get_node_type() == from.type:
			var result = node.create_from(from, self, options)
			if result is not ShrimpIR:
				push_error("Broken node %s: not created an IR-Node." % node)
				return null
			result.node_type = from.type
			return result
	push_error("Unknown IR-Node type: %s" % from.type)
	return null
