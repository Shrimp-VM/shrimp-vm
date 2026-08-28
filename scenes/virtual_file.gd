@tool
extends Control
class_name VirtualFile

signal opened()

@export_tool_button("重建") var rebuilder = rebuild
@export var fileName: StringName = "File.sst"
@export_multiline var content: String = ""

@onready var nameLabel: Label = $%name

func _ready() -> void:
	rebuild()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MouseButton.MOUSE_BUTTON_LEFT: return
		if !event.pressed: return
		opened.emit(self)

func rebuild():
	nameLabel.text = fileName
