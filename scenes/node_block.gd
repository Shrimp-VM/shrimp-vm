@tool
extends Control
class_name NodeBlock

@onready var nameLabel: Label = $%name
@onready var parameterPanel: Control = $%parameters
@onready var parameterWrapper: Control = $%wrapper
var in_desk: bool = false

func rebuild(schema: Dictionary, data: Dictionary):
	parameterPanel.visible = !in_desk
	nameLabel.text = schema.name
	ShrimpVMUtil.disconnect_children(parameterWrapper)
	if !in_desk:
		for parameter in schema.attributes:
			var instance = preload("./node_parameter.tscn").instantiate() as NodeParameter
			parameterWrapper.add_child(instance)
			instance.rebuild(schema.attributes[parameter], data[parameter])
