@tool
extends EditorPlugin

var sstImporter: SSTImporter
var garlicImporter: GarlicImporter

func _enter_tree() -> void:
	sstImporter = SSTImporter.new()
	garlicImporter = GarlicImporter.new()
	add_import_plugin(sstImporter)
	add_import_plugin(garlicImporter)
func _exit_tree() -> void:
	remove_import_plugin(sstImporter)
	remove_import_plugin(garlicImporter)
