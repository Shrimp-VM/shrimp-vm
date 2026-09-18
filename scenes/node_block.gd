@tool
extends Control
class_name NodeBlock

signal clicked()
signal selected(node: NodeBlock)
signal mark_selection(node: NodeBlock)
signal exhausted()

@export var inDesk: bool = false
@export var count: float = INF
@export var ir: ShrimpIR
@export var wrapper: Dictionary[String, Variant]

@onready var frameBar: ClickableWrapper = $%frame
@onready var nameLabel: RichTextLabel = $%name
@onready var parameterPanel: Control = $%parameters
@onready var parameterWrapper: Control = $%wrapper
@onready var countBar: Control = $%countBar
@onready var countLabel: Label = $%count
var frameBox: StyleBoxFlat
var parameterBox: StyleBoxFlat
var context: WrapperContext
var paramPointer: NodeParameter
var targetIR: ShrimpIR:
	get:
		return ShrimpVMUtil.find_ir_node(data.type)
var schema: Dictionary:
	get:
		return targetIR.get_wrapper_schema()
var data: Dictionary:
	get:
		return context.get_pointer()
var parentBlock: NodeBlock:
	get:
		return null

func _ready() -> void:
	frameBar.clicked.connect(
		func():
			if !inDesk && !parameterWrapper.get_children().is_empty():
				parameterPanel.visible = !parameterPanel.visible
	)
	mark_selection.connect(
		func(node: NodeBlock):
			if is_instance_valid(parentBlock):
				parentBlock.mark_selection.emit(node)
	)
	mark_selection.emit(self)
	frameBox = frameBar.get_theme_stylebox("panel")
	parameterBox = parameterPanel.get_theme_stylebox("panel")
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MouseButton.MOUSE_BUTTON_LEFT: return
		if !event.pressed: return
		if inDesk:
			if count > 0:
				clicked.emit()
				consume()
		else:
			selected.emit(self)

func consume():
	count -= 1
	rebuild_count()
	if count <= 0:
		exhausted.emit()
func rebuild_count():
	if inDesk && count != INF:
		if count > 0:
			countLabel.text = "×%d" % count
			countLabel.label_settings.font_color = Color.WHITE
		else:
			countLabel.text = "EXHAUSTED"
			countLabel.label_settings.font_color = Color.RED
		countBar.show()
	else:
		countBar.hide()
func get_color() -> Color:
	var node = ShrimpVMUtil.find_ir_node(context.get_pointer().get("type", ""))
	if node:
		return ShrimpPlugin.shade_category(node.get_category_tag())
	else:
		return Color.BLACK
func rebuild():
	frameBox.bg_color = get_color()
	parameterBox.bg_color = get_color()
	parameterPanel.visible = len(schema.attributes) > 0 && !inDesk
	nameLabel.text = schema.name
	rebuild_count()
	ShrimpVMUtil.disconnect_children(parameterWrapper)
	if !inDesk:
		for key in schema.attributes:
			if ShrimpVMUtil.schema_typeis(schema, ShrimpIR.TYPE_EXTERNAL_PARAMETER): continue
			var instance = NodeParameter.create(context.forward(WrapperPath.from(key)), key, parameterWrapper)
			instance.selected.connect(
				func(e):
					if is_instance_valid(paramPointer):
						paramPointer.unselect()
					paramPointer = e
					selected.emit(self)
			)
func create_wrapper() -> Dictionary:
	var result = {}
	result.type = data.type
	for key in schema.attributes:
		result[key] = ItemEditor.create_initial_value(schema.attributes[key])
	return result
func auto_rebuild(node: Node) -> NodeBlock:
	if get_parent(): return
	node.add_child(self)
	rebuild()
	node.remove_child(self)
	return self

static func create(contexx: WrapperContext, inDesx: bool) -> NodeBlock:
	var instance = load("res://addons/shrimpvm/scenes/node_block.tscn").instantiate() as NodeBlock
	instance.context = contexx
	instance.inDesk = inDesx
	return instance
