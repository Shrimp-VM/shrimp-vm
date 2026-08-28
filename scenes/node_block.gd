@tool
extends Control
class_name NodeBlock

signal selected(node: NodeBlock)
signal mark_selection(node: NodeBlock)

@onready var selectionBar: Control = $%selection
@onready var nameLabel: Label = $%name
@onready var parameterPanel: Control = $%parameters
@onready var parameterWrapper: Control = $%wrapper
var inDesk: bool = false
var schema: Dictionary
var data: Dictionary
var parent: NodeBlock
var currentSelectingParameter: NodeParameter

func _ready() -> void:
	unselect()
	mark_selection.connect(
		func(node: NodeBlock):
			if is_instance_valid(parent):
				parent.mark_selection.emit(node)
	)
	mark_selection.emit(self)
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MouseButton.MOUSE_BUTTON_LEFT: return
		if !event.pressed: return
		if !inDesk:
			selected.emit(self)

func rebuild(schemx: Dictionary, datx: Dictionary):
	schema = schemx
	data = datx
	parameterPanel.visible = !inDesk && len(schemx.attributes) > 0
	nameLabel.text = schemx.name
	ShrimpVMUtil.disconnect_children(parameterWrapper)
	if !inDesk:
		for attributeKey in schemx.attributes:
			var instance = load("res://addons/shrimpvm/scenes/node_parameter.tscn").instantiate() as NodeParameter
			parameterWrapper.add_child(instance)
			instance.name = attributeKey
			instance.rebuild(schemx.attributes[attributeKey], datx[attributeKey], self)
			instance.selected.connect(
				func(e):
					if is_instance_valid(currentSelectingParameter):
						currentSelectingParameter.unselect()
					currentSelectingParameter = e
					selected.emit(self)
			)
func select():
	unselect()
	selectionBar.show()
	if is_instance_valid(currentSelectingParameter):
		currentSelectingParameter.select()
func unselect():
	selectionBar.hide()
	if is_instance_valid(currentSelectingParameter):
		currentSelectingParameter.unselect()
