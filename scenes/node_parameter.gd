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
var context: WrapperContext
var targetIR: ShrimpIR:
	get:
		return ShrimpVMUtil.find_ir_node(context.forward(WrapperPath.from("<")).get_pointer().type)
var schema: Dictionary:
	get:
		return targetIR.get_wrapper_schema().attributes[context.pointer.seek_tail().path]
var value:
	get:
		return context.get_pointer()
var block: NodeBlock:
	get:
		return context.locate([NodeBlock])

func _ready() -> void:
	unselect()
	templateWrapper.hide()
	addChildTip.hide()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MouseButton.MOUSE_BUTTON_LEFT: return
		if !event.pressed: return
		if ShrimpVMUtil.schema_typeis(schema, ShrimpIR.TYPE_ENUM):
			selected.emit(self)
		else:
			block.requestSelect()

func make_template(namx: NodePath) -> Control:
	return templateWrapper.get_node(namx).duplicate()
func rebuild():
	nameLabel.text = schema.label
	ShrimpVMUtil.disconnect_children(arrayWrapper, [emptyTip])
	ShrimpVMUtil.disconnect_children(valueWrapper)
	if schema.array:
		if value is Array:
			if value.is_empty():
				emptyTip.show()
			else:
				emptyTip.hide()
				for i in len(value):
					arrayWrapper.add_child(create_showbox(i))
		else:
			push_error("The array parameter's wrapper value is not an Array.")
	else:
		emptyTip.hide()
		valueWrapper.add_child(create_showbox())
func select():
	selectionBar.show()
	if schema.array:
		addChildTip.show()
func unselect():
	selectionBar.hide()
	addChildTip.hide()
func create_primarybox(data: Variant, index: int = -1) -> Control:
	match schema.type:
		ShrimpIR.TYPE_ENUM:
			if ShrimpVMUtil.wrapper_is_valid(data):
				if value is Array:
					return NodeBlock.create(context.forward(WrapperPath.from("[%d]" % index)), false).auto_rebuild(self)
				else:
					return NodeBlock.create(context, false).auto_rebuild(self)
			else:
				var label = Label.new()
				label.text = "NULL"
				label.label_settings = LabelSettings.new()
				label.label_settings.font_color = Color.RED
				return label
		_:
			return ItemEditor.create_showbox(schema.type, data)
func create_showbox(index: int = -1) -> Control:
	if schema.type is Array:
		var label = Label.new()
		label.text = str(schema.type[value])
		return label
	if schema.array:
		var data
		if value is Array:
			data = value[index]
		else:
			data = value
		return create_primarybox(data, index)
	else:
		return create_primarybox(value)
func create_editbox() -> Control:
	if schema.type is Array:
		var btn = OptionButton.new()
		for item in schema.type:
			btn.add_item(str(item))
		btn.item_selected.connect(eventEmitter.event.emit)
		btn.selected = value
		return btn
	if schema.array:
		if ShrimpVMUtil.schema_typeis(schema, ShrimpIR.TYPE_ENUM): return null
		else:
			var editor = preload("res://addons/shrimpvm/scenes/item_editor.tscn").instantiate() as ItemEditor
			editor.itemType = schema.type
			editor.updated.connect(eventEmitter.event.emit)
			editor.set_data(value)
			return editor
	else:
		return ItemEditor.create_editbox(schema.type, value, eventEmitter.event.emit)

static func create_initial_value(schemx: Dictionary):
	if schemx.array:
		return []
	elif schemx.type is Array:
		return 0
	else:
		return ItemEditor.create_initial_value(schemx.type)
static func create(contexx: WrapperContext, root: Node) -> NodeParameter:
	contexx.pointer = contexx.pointer.normalize()
	var instance = preload("res://addons/shrimpvm/scenes/node_parameter.tscn").instantiate() as NodeParameter
	instance.name = contexx.pointer.seek_tail().path
	instance.context = contexx
	root.add_child(instance)
	instance.rebuild()
	return instance
