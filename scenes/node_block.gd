@tool
extends Control
class_name NodeBlock

signal clicked()
signal selected(node: NodeBlock)
signal mark_selection(node: NodeBlock)
signal exhausted()

@export_tool_button("Rebuild") var rebuilder = func(): if ir: rebuild(ir.get_wrapper_schema(), wrapper)
@export var inDesk: bool = false
@export var count: float = INF
@export var colorMap: Dictionary[String, Color] = {}
@export var ir: ShrimpIR
@export var wrapper: Dictionary[String, Variant]

@onready var selectionBar: Control = $%selection
@onready var frameBar: ClickableWrapper = $%frame
@onready var nameLabel: RichTextLabel = $%name
@onready var parameterPanel: Control = $%parameters
@onready var parameterWrapper: Control = $%wrapper
@onready var countBar: Control = $%countBar
@onready var countLabel: Label = $%count
@onready var nextSiblingTip: Control = $%nextSiblingTip
var schema: Dictionary
var data: Dictionary
var parentBlock: NodeBlock
var parentSchema: Dictionary
var parentAttribute: String
var paramPointer: NodeParameter
var frameBox: StyleBoxFlat
var parameterBox: StyleBoxFlat

func _ready() -> void:
	unselect()
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
	rebuilder.call()
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
	var node = ShrimpVMUtil.find_ir_node(data.get("type", ""))
	if node:
		return colorMap.get(node.get_category_tag(), Color.BLACK)
	else:
		return Color.BLACK
func rebuild(schemx: Dictionary, datx: Dictionary):
	schema = schemx
	data = datx
	frameBox.bg_color = get_color()
	parameterBox.bg_color = get_color()
	parameterPanel.visible = len(schemx.attributes) > 0
	nameLabel.text = schemx.name
	rebuild_count()
	ShrimpVMUtil.disconnect_children(parameterWrapper)
	if !inDesk:
		parameterPanel.hide()
		for attributeKey in schemx.attributes:
			if typeof(schemx.attributes[attributeKey].type) == TYPE_INT && schemx.attributes[attributeKey].type == ShrimpIR.TYPE_EXTERNAL_PARAMETER: continue
			var instance = load("res://addons/shrimpvm/scenes/node_parameter.tscn").instantiate() as NodeParameter
			parameterWrapper.add_child(instance)
			instance.name = attributeKey
			instance.colorMap = colorMap
			instance.rebuild(schemx.attributes[attributeKey], datx[attributeKey], self)
			instance.selected.connect(
				func(e):
					if is_instance_valid(paramPointer):
						paramPointer.unselect()
					paramPointer = e
					selected.emit(self)
			)
func select():
	unselect()
	selectionBar.show()
	if is_instance_valid(paramPointer):
		paramPointer.select()
	else:
		if is_instance_valid(parentBlock) && parentSchema.array:
			nextSiblingTip.show()
func unselect():
	selectionBar.hide()
	if is_instance_valid(paramPointer):
		paramPointer.unselect()
	nextSiblingTip.hide()
func create_wrapper() -> Dictionary:
	var result = {}
	result.type = data.type
	for key in schema.attributes:
		result[key] = NodeParameter.create_initial_value(schema.attributes[key])
	return result
