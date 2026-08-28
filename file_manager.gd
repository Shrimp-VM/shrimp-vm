@tool
extends Node
class_name ShrimpFileManager

signal open_file(file: VirtualFile)
signal add_file(file: VirtualFile)

var files: Array[VirtualFile] = []
var currentOpening: VirtualFile = null

func _ready() -> void:
	open_file.connect(func(f): currentOpening = f)

func add(fn: StringName, content: String):
	var file = preload("res://addons/shrimpvm/scenes/virtual_file.tscn").instantiate() as VirtualFile
	file.fileName = fn
	file.content = content
	files.append(file)
	add_file.emit(file)
	file.opened.connect(open_file.emit)
	file.opened.emit(file)
func rename(fn: StringName):
	if !is_instance_valid(currentOpening): return
	currentOpening.fileName = fn
	archive()
func save(content: String):
	if !is_instance_valid(currentOpening): return
	currentOpening.content = content
	archive()
func compile() -> String:
	return JSON.new().stringify(files.map(func(e: VirtualFile): return [e.fileName, e.content]))
func decompile(src: String) -> Array:
	var json = JSON.new()
	if json.parse(src) != OK:
		return []
	return json.data
func archive():
	var fa = FileAccess.open("user://virtuals.json", FileAccess.ModeFlags.WRITE)
	if fa == null:
		return
	fa.store_string(compile())
	fa.close()
func inarchive():
	var fa = FileAccess.open("user://virtuals.json", FileAccess.ModeFlags.READ)
	if fa == null:
		return
	for data in decompile(fa.get_as_text()):
		add(data[0], data[1])
	fa.close()
