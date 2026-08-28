@tool
extends Control
class_name NodeParameter

signal selected(parameter: NodeParameter)

@onready var selectionBar: Control = $%selection
@onready var nameLabel: Label = $%name
@onready var templateWrapper: Control = $%templates
@onready var arrayWrapper: Control = $%array
@onready var valueWrapper: Control = $%value
var eventEmitter: ShrimpVMUtil.EventEmitter
var node: NodeBlock

func _ready() -> void:
	unselect()
	templateWrapper.hide()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MouseButton.MOUSE_BUTTON_LEFT: return
		if !event.pressed: return
		selected.emit(self)

func make_template(namx: NodePath) -> Control:
	return templateWrapper.get_node(namx).duplicate()
func rebuild(schema: Dictionary, value: Variant, nodx: NodeBlock):
	node = nodx
	nameLabel.text = schema.label
	ShrimpVMUtil.disconnect_children(arrayWrapper)
	ShrimpVMUtil.disconnect_children(valueWrapper)
	if schema.get("array", false):
		for item in value:
			arrayWrapper.add_child(create_showbox(schema, item, nodx))
	else:
		valueWrapper.add_child(create_showbox(schema, value, nodx))
func create_showbox(schema: Dictionary, value: Variant, node: NodeBlock) -> Control:
	match schema.type:
		TYPE_STRING, TYPE_FLOAT:
			var input = Label.new()
			input.text = "%s" % (value)
			return input
		ShrimpIR.TYPE_ENUM:
			var instance = load("res://addons/shrimpvm/scenes/node_block.tscn").instantiate() as NodeBlock
			instance.inDesk = false
			instance.parent = node
			add_child(instance)
			instance.rebuild(ShrimpVMUtil.find_ir_node(value.type).get_wrapper_schema(), value)
			remove_child(instance)
			return instance
		_:
			return Control.new()
func create_editbox(schema: Dictionary, value: Variant) -> Control:
	match schema.type:
		TYPE_STRING, TYPE_FLOAT:
			var input = TextEdit.new()
			input.custom_minimum_size = Vector2i(200, 100)
			input.text = "%s" % (value)
			input.text_changed.connect(eventEmitter.event.emit)
			return input
		ShrimpIR.TYPE_ENUM:
			return null
		_:
			return null
func select():
	selectionBar.show()
func unselect():
	selectionBar.hide()
