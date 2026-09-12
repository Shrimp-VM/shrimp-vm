@tool
extends Control
class_name VirtualFile

signal clicked()

@export_tool_button("Rebuild") var rebuilder = rebuild
@export var fileName: StringName = "File.sst"
@export_multiline var content: String = ""
@export var opening: bool = false

@onready var nameLabel: Label = $%name
@onready var indicator: Control = $%indicator

func _ready() -> void:
	rebuild()
func _physics_process(_delta: float) -> void:
	indicator.visible = opening
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MouseButton.MOUSE_BUTTON_LEFT: return
		if !event.pressed: return
		clicked.emit(self)

func rebuild():
	nameLabel.text = fileName
