@tool
extends EditorImportPlugin
class_name SSTImporter

func _get_importer_name() -> String:
	return ShrimpCompiler.IMPORTER_ID
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
	var result = ShrimpCompiler.import_file(source_file)
	if result is ShrimpIR:
		return ResourceSaver.save(result, "%s.%s" % [save_path, _get_save_extension()])
	else:
		return ERR_PARSE_ERROR
