@tool
extends EditorPlugin

var sstImporter: ShrimpSyntaxTreeImporter

func _enter_tree() -> void:
	sstImporter = load("./sst_importer.gd").new()
	add_import_plugin(sstImporter)
func _exit_tree() -> void:
	remove_import_plugin(sstImporter)
