@tool
extends Node
class_name ShrimpFileManager

signal add_file(file: VirtualFile)
signal open_file(file: VirtualFile)
signal close_file(file: VirtualFile)
signal delete_file(file: VirtualFile)
signal rebuilding(file: VirtualFile)

@export_tool_button("Now archive") var a = func(): print(archive())
@export_tool_button("Now inarchive") var i = func(): print(inarchive())
@export_global_file var archiveFile = "user://virtuals.json"
@export var allowArchive: bool = true

var files: Array[VirtualFile] = []
var autoCompilations: Dictionary[VirtualFile, ShrimpIR] = {}
var currentOpening: VirtualFile = null

func auto_compile():
	for file in files:
		autoCompilations[file] = ShrimpCompiler.import_json(file.content)
func get_compilation(fn: StringName) -> ShrimpIR:
	for file in files:
		if file.fileName == fn:
			return autoCompilations.get(file)
	return null
func add(fn: StringName, content: String):
	match search(fn):
		var found when found is VirtualFile:
			open(found)
			delete()
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
	if is_instance_valid(currentOpening):
		close_file.emit(currentOpening)
		currentOpening.opening = false
		currentOpening = null
func delete():
	if is_instance_valid(currentOpening):
		if currentOpening in files:
			files.erase(currentOpening)
		if currentOpening in autoCompilations:
			autoCompilations.erase(currentOpening)
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
func serialize() -> String:
	return JSON.new().stringify(files.map(func(e: VirtualFile): return [e.fileName, e.content]))
func deserialize(src: String) -> Array:
	var json = JSON.new()
	if json.parse(src) != OK:
		return []
	return json.data
func archive() -> String:
	if !allowArchive:
		push_warning("Archive skipped.")
		return ""
	var fa = FileAccess.open(archiveFile, FileAccess.ModeFlags.WRITE)
	if fa == null:
		push_error("Failed to write archive file.")
		return ""
	var compiled = serialize()
	fa.store_string(serialize())
	fa.close()
	return compiled
func inarchive() -> String:
	if !allowArchive:
		push_warning("Inarchive skipped.")
		return ""
	var fa = FileAccess.open(archiveFile, FileAccess.ModeFlags.READ)
	if fa == null:
		push_error("Failed to read archive file.")
		return ""
	for data in deserialize(fa.get_as_text()):
		add(data[0], data[1])
	fa.close()
	return serialize()
