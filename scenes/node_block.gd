@tool
extends Control
class_name NodeBlock

signal clicked()
signal selected(pointer: WrapperPath)
signal mark_selection(node: NodeBlock)
signal exhausted()

@export_tool_button("Rebuild") var r = rebuild
@export var inDesk: bool = false
@export var count: float = INF
@export_category("Placeholders")
@export var placeholderIR: ShrimpIR
@export var placeholderWrapper: Dictionary[String, Variant]

@onready var frameBar: ClickableWrapper = $%frame
@onready var nameLabel: RichTextLabel = $%name
@onready var parameterPanel: Control = $%parameters
@onready var parameterWrapper: Control = $%wrapper
@onready var countBar: Control = $%countBar
@onready var countLabel: Label = $%count
@onready var parentIcon: Triangle = $%parentIcon
@onready var nextIcon: Triangle = $%nextIcon
@onready var triangles: Control = $%triangles
var styleBox: StyleBoxFlat
var targetContext: WrapperContext
var ownerParameter: NodeParameter
var getContext: WrapperContext:
	get:
		if is_instance_valid(targetContext):
			return targetContext
		else:
			return WrapperContext.new(placeholderWrapper.merged({"type": placeholderIR.get_node_type()}), WrapperPath.from("/"), self)
var targetIR: ShrimpIR:
	get:
		return ShrimpVMUtil.find_ir_node(data.type)
var schema: Dictionary:
	get:
		return targetIR.get_wrapper_schema()
var data: Dictionary:
	get:
		return getContext.get_pointer()
var parentBlock: NodeBlock:
	get:
		return ownerParameter.ownerBlock if ownerParameter else null
var parentParameterKey: String:
	get:
		return String(ownerParameter.name) if ownerParameter else ""
var parentParameterBox: NodeParameter:
	get:
		return parentBlock.get_parameter(parentParameterKey)

func _ready() -> void:
	# frameBar.clicked.connect(
	# 	func():
	# 		if !inDesk && !parameterWrapper.get_children().is_empty():
	# 			parameterPanel.visible = !parameterPanel.visible
	# )
	mark_selection.connect(
		func(node: NodeBlock):
			if is_instance_valid(parentBlock) && parentBlock:
				parentBlock.mark_selection.emit(node)
	)
	mark_selection.emit(self)
	styleBox = get_theme_stylebox("panel")
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MouseButton.MOUSE_BUTTON_LEFT: return
		if !event.pressed: return
		if inDesk:
			if count > 0:
				clicked.emit()
				consume()
		else:
			request_select()

func get_parameter(key: String) -> NodeParameter:
	return parameterWrapper.get_node(key)
func request_select(pointer: WrapperPath = null):
	selected.emit(pointer if is_instance_valid(pointer) else getContext.pointer)
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
	var node = ShrimpVMUtil.find_ir_node(getContext.get_pointer().get("type", ""))
	if node:
		return ShrimpPluginManager.shade_category(node.get_category_tag())
	else:
		return Color.BLACK
func rebuild():
	rebuild_count()
	nameLabel.text = ShrimpTranslator.get_ir_name(targetIR)
	styleBox.bg_color = get_color()
	nextIcon.fillColor = get_color()
	parameterPanel.visible = can_show_parameters()
	triangles.visible = !inDesk
	if can_show_parameters():
		ShrimpVMUtil.disconnect_children(parameterWrapper)
		for key in schema.attributes:
			if ShrimpVMUtil.schema_typeis(schema.attributes[key], ShrimpIR.TYPE_EXTERNAL_PARAMETER): continue
			var instance: NodeParameter
			if Engine.is_editor_hint():
				instance = NodeParameter.create(getContext.forward(WrapperPath.from(key)), parameterWrapper, self)
			else:
				instance = NodeParameter.create(getContext.forward(WrapperPath.from(key)), parameterWrapper, self)
			instance.selected.connect(
				func(p: NodeParameter):
					request_select(p.getContext.pointer)
			)
func can_show_parameters() -> bool:
	return len(schema.attributes) > 0 && !inDesk
func create_wrapper() -> Dictionary:
	var result = {}
	result.type = data.type
	for key in schema.attributes:
		result[key] = NodeParameter.create_initial_value(schema.attributes[key])
	return result
func mount(parent: Node) -> NodeBlock:
	parent.add_child(self)
	rebuild()
	return self

static func create(contexx: WrapperContext, inDesx: bool, counx: float = INF, type: String = "", ownerParam: NodeParameter = null) -> NodeBlock:
	var instance = preload("res://addons/shrimpvm/scenes/node_block.tscn").instantiate() as NodeBlock
	instance.count = counx
	instance.inDesk = inDesx
	if inDesx:
		contexx = WrapperContext.new({"type": type})
		contexx.nodeTree = instance
	instance.targetContext = contexx
	instance.ownerParameter = ownerParam
	instance.name = "%s_%d" % [instance.targetIR.get_node_type(), randi_range(111111, 999999)]
	return instance
