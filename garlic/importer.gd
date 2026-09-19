@tool
extends EditorImportPlugin
class_name GarlicImporter

func _get_importer_name() -> String:
	return GarlicParser.IMPORTER_ID
func _get_visible_name() -> String:
	return "Garlic DSL"
func _get_recognized_extensions() -> PackedStringArray:
	return ["srk"]
func _get_save_extension() -> String:
	return "tres"
func _get_resource_type() -> String:
	return "GarlicTree"
func _get_import_options(_path: String, _preset_index: int) -> Array[Dictionary]:
	return []
func _import(
	source_file: String,
	save_path: String,
	_options: Dictionary,
	_platform_variants: Array[String],
	_gen_files: Array[String]
) -> Error:
	return ResourceSaver.save(GarlicTree.new().load_from(source_file), "%s.%s" % [save_path, _get_save_extension()])
