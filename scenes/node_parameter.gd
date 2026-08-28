@tool
extends Control
class_name NodeParameter

@onready var nameLabel: Label = $%name
@onready var templateWrapper: Control = $%templates
@onready var arrayWrapper: Control = $%array
@onready var valueWrapper: Control = $%value

func _ready() -> void:
	templateWrapper.hide()

func make_template(namx: NodePath) -> Control:
	return templateWrapper.get_node(namx).duplicate()
func rebuild(schema: Dictionary, value: Variant):
	nameLabel.text = schema.label
	ShrimpVMUtil.disconnect_children(arrayWrapper)
	ShrimpVMUtil.disconnect_children(valueWrapper)
	if schema.get("array", false):
		for item in value:
			arrayWrapper.add_child(create_primary_parameter(schema, item))
	else:
		valueWrapper.add_child(create_primary_parameter(schema, value))
func create_primary_parameter(schema: Dictionary, value: Variant):
	match schema.type:
		TYPE_FLOAT:
			var input = make_template("numberInput")
			if input is LineEdit:
				input.text = str(value)
			return input
		TYPE_STRING:
			var input = make_template("textInput")
			if input is LineEdit:
				input.text = value
			return input
		ShrimpIR.TYPE_ENUM:
			var irs = ShrimpVMUtil.get_ir_nodes()
			var instance = load("res://addons/shrimpvm/scenes/node_block.tscn").instantiate()
			add_child(instance)
			instance.in_desk = false
			instance.rebuild(ShrimpVMUtil.find_ir_node(value.type).get_wrapper_schema(), value)
			remove_child(instance)
			return instance
