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
@onready var addChildTip: Control = $%addChildTip
var eventEmitter: ShrimpVMUtil.EventEmitter
var node: NodeBlock
var schema: Dictionary
var colorMap: Dictionary[String, Color] = {}

func _ready() -> void:
	unselect()
	templateWrapper.hide()
	addChildTip.hide()
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
				value = ShrimpVMUtil.erase_gunmu(value)
			if value.is_empty():
				emptyTip.show()
			else:
				emptyTip.hide()
				for item in value:
					arrayWrapper.add_child(create_showbox(schemx, item, nodx))
		else:
			push_error("The array parameter's wrapper value is not an Array[Variant].")
	else:
		emptyTip.hide()
		valueWrapper.add_child(create_showbox(schemx, value, nodx))
func select():
	selectionBar.show()
	if schema.array:
		addChildTip.show()
func unselect():
	selectionBar.hide()
	addChildTip.hide()
func create_showbox(schemx: Dictionary, value: Variant, nodx: NodeBlock) -> Control:
	if schemx.type is Array:
		var label = Label.new()
		label.text = str(schemx.type[value])
		return label
	match schemx.type:
		TYPE_STRING, TYPE_FLOAT, TYPE_STRING_NAME:
			var label = Label.new()
			label.text = str(value)
			return label
		TYPE_BOOL:
			var check = CheckButton.new()
			check.button_pressed = value
			check.disabled = true
			return check
		ShrimpIR.TYPE_ENUM:
			if value is Dictionary && !value.get("invalid", false):
				var instance = load("res://addons/shrimpvm/scenes/node_block.tscn").instantiate() as NodeBlock
				instance.colorMap = colorMap
				instance.inDesk = false
				instance.parentBlock = nodx
				instance.parentSchema = schemx
				instance.parentAttribute = name
				add_child(instance)
				instance.rebuild(ShrimpVMUtil.find_ir_node(value.type).get_wrapper_schema(), value)
				remove_child(instance)
				return instance
			else:
				var label = Label.new()
				label.text = str(null)
				label.label_settings = LabelSettings.new()
				label.label_settings.font_color = Color.RED
				return label
		_:
			return Control.new()
func create_editbox(schemx: Dictionary, value: Variant) -> Control:
	if schemx.type is Array:
		var btn = OptionButton.new()
		for item in schemx.type:
			btn.add_item(str(item))
		btn.item_selected.connect(eventEmitter.event.emit)
		btn.selected = value
		return btn
	if schemx.array:
		if ShrimpVMUtil.schema_typeis_ir(schemx): return null
		else:
			var editor = preload("res://addons/shrimpvm/scenes/item_editor.tscn").instantiate() as ItemEditor
			editor.itemType = schemx.type
			editor.updated.connect(eventEmitter.event.emit)
			editor.set_data(value)
			return editor
	else:
		return ItemEditor.create_editbox(schemx.type, value, eventEmitter.event.emit)

static func create_initial_value(schemx: Dictionary) -> Variant:
	if schemx.has("default"):
		return schemx.default
	if schemx.get("array", false):
		return []
	if schemx.type is Array:
		return 0
	return ItemEditor.create_initial_value(schemx.type)
