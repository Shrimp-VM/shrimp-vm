@tool
extends EditorPlugin

var sstImporter: SSTImporter

func _enter_tree() -> void:
	sstImporter = SSTImporter.new()
	add_import_plugin(sstImporter)
func _exit_tree() -> void:
	remove_import_plugin(sstImporter)
