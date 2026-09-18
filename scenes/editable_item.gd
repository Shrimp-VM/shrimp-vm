@tool
extends Control
class_name EditableItem

signal deleted()
signal updated(data)

@export var index: int = 0

@onready var indexLabel: Label = $%index
@onready var deleteBtn: Button = $%deleteBtn
@onready var contentWrapper: Control = $%content
var deleteConfirmed: bool = false

func _ready() -> void:
	deleteBtn.pressed.connect(
		func():
			if deleteConfirmed:
				deleted.emit()
				deleteBtn.text = "Delete"
				deleteConfirmed = false
			else:
				deleteBtn.text = "Confirm?"
				deleteConfirmed = true
	)
	rebuild()

func rebuild():
	if !is_instance_valid(indexLabel):
		indexLabel = get_node("%index")
	indexLabel.text = str(index + 1)
func set_content(type: int, value: Variant):
	var editor = ItemEditor.create_editbox(type, value, updated.emit)
	if !is_instance_valid(contentWrapper):
		contentWrapper = get_node("%content")
	ShrimpVMUtil.disconnect_children(contentWrapper)
	contentWrapper.add_child(editor)
	return editor
func get_content() -> Control:
	return contentWrapper.get_child(0)
