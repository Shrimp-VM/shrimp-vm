@tool
extends Node
class_name ShrimpFileManager

signal add_file(file: VirtualFile)
signal open_file(file: VirtualFile)
signal close_file(file: VirtualFile)
signal delete_file(file: VirtualFile)
signal rebuilding(file: VirtualFile)

@export_global_file var archiveFile = "user://virtuals.json"
@export var allowArchive: bool = true

var files: Array[VirtualFile] = []
var currentOpening: VirtualFile = null

func add(fn: StringName, content: String):
	var file = load("res://addons/shrimpvm/scenes/virtual_file.tscn").instantiate() as VirtualFile
	file.fileName = fn
	file.content = content
	files.append(file)
	add_file.emit(file)
	file.clicked.connect(open)
	open(file)
	archive()
func open(file: VirtualFile):
	close()
	open_file.emit(file)
	currentOpening = file
	file.opening = true
func close():
	close_file.emit(currentOpening)
	if is_instance_valid(currentOpening):
		currentOpening.opening = false
	currentOpening = null
func delete():
	if is_instance_valid(currentOpening):
		if currentOpening in files:
			files.erase(currentOpening)
		currentOpening.queue_free()
	currentOpening = null
	delete_file.emit(currentOpening)
	archive()
func rename(fn: StringName):
	if !is_instance_valid(currentOpening): return
	currentOpening.fileName = fn
	archive()
func save(content: String):
	if !is_instance_valid(currentOpening): return
	currentOpening.content = content
	archive()
func search(fn: String) -> VirtualFile:
	var index = files.find_custom(func(e: VirtualFile): return e.fileName == fn)
	if index >= 0:
		return files[index]
	else:
		return null
func rebuild():
	rebuilding.emit(currentOpening)
	if is_instance_valid(currentOpening):
		currentOpening.rebuild()
func compile() -> String:
	return JSON.new().stringify(files.map(func(e: VirtualFile): return [e.fileName, e.content]))
func decompile(src: String) -> Array:
	var json = JSON.new()
	if json.parse(src) != OK:
		return []
	return json.data
func archive():
	if !allowArchive: return
	var fa = FileAccess.open(archiveFile, FileAccess.ModeFlags.WRITE)
	if fa == null:
		return
	fa.store_string(compile())
	fa.close()
func inarchive():
	if !allowArchive: return
	var fa = FileAccess.open(archiveFile, FileAccess.ModeFlags.READ)
	if fa == null:
		return
	for data in decompile(fa.get_as_text()):
		add(data[0], data[1])
	fa.close()
