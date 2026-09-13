@tool
extends Control
class_name EditableItem

signal delete()

@export var index: int = 0

@onready var indexLabel: Label = $%index
@onready var deleteBtn: Button = $%deleteBtn
@onready var contentWrapper: Control = $%content

func _ready() -> void:
	deleteBtn.pressed.connect(delete.emit)
	rebuild()

func rebuild():
	indexLabel.text = str(index + 1)
func set_content(editor: Control):
	ShrimpVMUtil.disconnect_children(contentWrapper)
	contentWrapper.add_child(editor)
	return editor
func get_content() -> Control:
	return contentWrapper.get_child(0)
