@tool
extends EditorPlugin

var sstImporter: SSTImporter
var garlicImporter: GarlicImporter
var garlicLsp: GarlicLspServer

func _enter_tree() -> void:
	sstImporter = SSTImporter.new()
	garlicImporter = GarlicImporter.new()
	add_import_plugin(sstImporter)
	add_import_plugin(garlicImporter)
	garlicLsp = GarlicLspServer.new()
	add_child(garlicLsp)
func _exit_tree() -> void:
	remove_import_plugin(sstImporter)
	remove_import_plugin(garlicImporter)
	if garlicLsp != null:
		garlicLsp.queue_free()
		garlicLsp = null
