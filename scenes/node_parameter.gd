@tool
extends Control
class_name NodeParameter

@onready var nameLabel: Label = $%name
@onready var templateWrapper: Control = $%templates
@onready var arrayWrapper: Control = $%array
@onready var valueWrapper: Control = $%value

func make_template(namx: NodePath) -> Control:
	return templateWrapper.get_node(namx).duplicate()
func rebuild(schema: Dictionary, value: Variant):
	nameLabel.text = schema.label
	ShrimpVMUtil.disconnect_children(arrayWrapper)
	ShrimpVMUtil.disconnect_children(valueWrapper)
	if schema.array:
		for item in value:
			arrayWrapper.add_child(create_primary_parameter(schema, item))
	else:
		valueWrapper.add_child(create_primary_parameter(schema, value))
func create_primary_parameter(schema: Dictionary, value: Variant):
	match schema.type:
		TYPE_FLOAT:
			return make_template("numberInput")
		TYPE_STRING:
			return make_template("textInput")
		ShrimpIR.TYPE_ENUM:
			var irs = ShrimpVMUtil.get_ir_nodes()
			var instance = preload("./node_block.tscn").instantiate() as NodeBlock
			add_child(instance)
			instance.in_desk = false
			instance.rebuild(ShrimpVMUtil.find_ir_node(value.type).get_wrapper_schema(), value)
			remove_child(instance)
			return instance
