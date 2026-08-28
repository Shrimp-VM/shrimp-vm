@tool
extends Control
class_name NodeBlock

signal selected(node: NodeBlock)
signal mark_selection(node: NodeBlock)

@onready var selectionBar: Control = $%selection
@onready var nameLabel: Label = $%name
@onready var parameterPanel: Control = $%parameters
@onready var parameterWrapper: Control = $%wrapper
var in_desk: bool = false
var schema: Dictionary
var data: Dictionary
var parent: NodeBlock

func _ready() -> void:
	mark_selection.connect(
		func(node: NodeBlock):
			if is_instance_valid(parent):
				parent.mark_selection.emit(node)
	)
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MouseButton.MOUSE_BUTTON_LEFT: return
		if !event.pressed: return
		selected.emit(self)

func rebuild(schemx: Dictionary, datx: Dictionary):
	schema = schemx
	data = datx
	parameterPanel.visible = !in_desk && len(schemx.attributes) > 0
	nameLabel.text = schemx.name
	ShrimpVMUtil.disconnect_children(parameterWrapper)
	if !in_desk:
		for attributeKey in schemx.attributes:
			var instance = load("res://addons/shrimpvm/scenes/node_parameter.tscn").instantiate() as NodeParameter
			parameterWrapper.add_child(instance)
			instance.name = attributeKey
			instance.rebuild(schemx.attributes[attributeKey], datx[attributeKey], self)
func select():
	selectionBar.show()
func unselect():
	selectionBar.hide()
