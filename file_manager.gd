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
	file.content = content
	file.opened.connect(open_file.emit)
	add_file.emit(file)
	file.rename(fn)
func save(content: String):
	if !is_instance_valid(currentOpening): return
	currentOpening.content = content
