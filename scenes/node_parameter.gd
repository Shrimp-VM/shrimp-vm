@tool
extends Control
class_name NodeParameter

signal selected(parameter: NodeParameter)

@onready var selectionBar: Control = $%selection
@onready var nameLabel: Label = $%name
@onready var templateWrapper: Control = $%templates
@onready var arrayWrapper: Control = $%array
@onready var valueWrapper: Control = $%value
@onready var emptyTip: Control = $%emptyTip
var eventEmitter: ShrimpVMUtil.EventEmitter
var node: NodeBlock
var schema: Dictionary

func _ready() -> void:
	unselect()
	templateWrapper.hide()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MouseButton.MOUSE_BUTTON_LEFT: return
		if !event.pressed: return
		if typeof(schema.type) == TYPE_INT && schema.type == ShrimpIR.TYPE_ENUM:
			selected.emit(self)
		else:
			node.selected.emit(node)

func make_template(namx: NodePath) -> Control:
	return templateWrapper.get_node(namx).duplicate()
func rebuild(schemx: Dictionary, value: Variant, nodx: NodeBlock):
	schema = schemx
	node = nodx
	nameLabel.text = schemx.label
	ShrimpVMUtil.disconnect_children(arrayWrapper, [emptyTip])
	ShrimpVMUtil.disconnect_children(valueWrapper)
	if schemx.get("array", false):
		if value is Array:
			if typeof(schemx.type) == TYPE_INT && schemx.type == ShrimpIR.TYPE_ENUM:
					value = value.filter(func(e): return !e.get("invalid", false))
			if value.is_empty():
				emptyTip.show()
			else:
				emptyTip.hide()
				for item in value:
					arrayWrapper.add_child(create_showbox(schemx, item, nodx))
		else:
			push_error("array参数的值不是Array")
	else:
		emptyTip.hide()
		valueWrapper.add_child(create_showbox(schemx, value, nodx))
func select():
	selectionBar.show()
func unselect():
	selectionBar.hide()
func create_showbox(schema: Dictionary, value: Variant, node: NodeBlock) -> Control:
	if schema.type is Array:
		var label = Label.new()
		label.text = str(schema.type[value])
		return label
	match schema.type:
		TYPE_STRING, TYPE_FLOAT:
			var label = Label.new()
			label.text = "%s" % (value)
			return label
		TYPE_BOOL:
			var check = CheckButton.new()
			check.button_pressed = value
			check.disabled = true
			return check
		ShrimpIR.TYPE_ENUM:
			if value is Dictionary && !value.get("invalid", false):
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
	if schema.type is Array:
		var btn = OptionButton.new()
		for item in schema.type:
			btn.add_item(str(item))
		btn.item_selected.connect(eventEmitter.event.emit)
		btn.selected = value
		return btn
	match schema.type:
		TYPE_STRING:
			var input = TextEdit.new()
			input.custom_minimum_size = Vector2i(200, 100)
			input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
			input.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			input.text = "%s" % (value)
			input.text_changed.connect(func(): eventEmitter.event.emit(input.text))
			return input
		TYPE_FLOAT:
			var input = LineEdit.new()
			input.custom_minimum_size = Vector2i(300, 30)
			input.text = "%s" % (value)
			input.text_changed.connect(
				func(new: String):
					if new.is_valid_float():
						eventEmitter.event.emit(float(new))
			)
			return input
		TYPE_BOOL:
			var check = CheckButton.new()
			check.button_pressed = value
			check.toggled.connect(eventEmitter.event.emit)
			return check
		ShrimpIR.TYPE_ENUM:
			return null
		_:
			return null

static func create_initial_value(schema: Dictionary) -> Variant:
	if schema.has("default"):
		return schema.default
	if schema.get("array", false):
		return []
	if schema.type is Array:
		return 0
	match schema.type:
		TYPE_STRING:
			return "棍母"
		TYPE_FLOAT:
			return 0
		TYPE_BOOL:
			return false
		ShrimpIR.TYPE_ENUM:
			return null
		_:
			return NAN
