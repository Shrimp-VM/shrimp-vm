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
var schema: Dictionary

func _ready() -> void:
	unselect()
	templateWrapper.hide()
func _gui_input(event: InputEvent) -> void:
	if schema.type != ShrimpIR.TYPE_ENUM: return
	if event is InputEventMouseButton:
		if event.button_index != MouseButton.MOUSE_BUTTON_LEFT: return
		if !event.pressed: return
		selected.emit(self)

func make_template(namx: NodePath) -> Control:
	return templateWrapper.get_node(namx).duplicate()
func rebuild(schemx: Dictionary, value: Variant, nodx: NodeBlock):
	schema = schemx
	node = nodx
	nameLabel.text = schemx.label
	ShrimpVMUtil.disconnect_children(arrayWrapper)
	ShrimpVMUtil.disconnect_children(valueWrapper)
	if schemx.get("array", false):
		for item in value:
			arrayWrapper.add_child(create_showbox(schemx, item, nodx))
	else:
		valueWrapper.add_child(create_showbox(schemx, value, nodx))
func select():
	selectionBar.show()
func unselect():
	selectionBar.hide()
func create_showbox(schema: Dictionary, value: Variant, node: NodeBlock) -> Control:
	match schema.type:
		TYPE_STRING, TYPE_FLOAT:
			var input = Label.new()
			input.text = "%s" % (value)
			return input
		ShrimpIR.TYPE_ENUM:
			if value is Dictionary:
				var instance = load("res://addons/shrimpvm/scenes/node_block.tscn").instantiate() as NodeBlock
				instance.inDesk = false
				instance.parent = node
				add_child(instance)
				instance.rebuild(ShrimpVMUtil.find_ir_node(value.type).get_wrapper_schema(), value)
				remove_child(instance)
				return instance
			else:
				var label = Label.new()
				label.text = "棍母"
				label.label_settings = LabelSettings.new()
				label.label_settings.font_color = Color.RED
				return label
		_:
			return Control.new()
func create_editbox(schema: Dictionary, value: Variant) -> Control:
	match schema.type:
		TYPE_STRING, TYPE_FLOAT:
			var input = TextEdit.new()
			input.custom_minimum_size = Vector2i(200, 100)
			input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
			input.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			input.text = "%s" % (value)
			input.text_changed.connect(func(): eventEmitter.event.emit(input.text))
			return input
		ShrimpIR.TYPE_ENUM:
			return null
		_:
			return null

static func create_initial_value(type: int) -> Variant:
	match type:
		TYPE_STRING:
			return "棍母"
		TYPE_FLOAT:
			return 0
		ShrimpIR.TYPE_ENUM:
			return null
		_:
			return NAN
