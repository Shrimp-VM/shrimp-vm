@tool
extends Control
class_name NodeParameter

signal selected(parameter: NodeParameter)

@export_tool_button("Rebuild") var r = rebuild

@onready var nameLabel: Label = $%name
@onready var templateWrapper: Control = $%templates
@onready var arrayWrapper: Control = $%array
@onready var valueWrapper: Control = $%value
@onready var emptyTip: Control = $%emptyTip
var eventEmitter: ShrimpVMUtil.EventEmitter
var ownerBlock: NodeBlock
## 用getContext，不要直接用targetContext
var targetContext: WrapperContext
var getContext: WrapperContext:
	get:
		if is_instance_valid(targetContext): return targetContext
		else:
			var result = WrapperContext.new({
				"type": "placeholder",
				"param": []
			}, WrapperPath.from("/"))
			result.nodeTree = NodeBlock.create(result, false)
			return result.forward(WrapperPath.from("#.param"))
var targetIR: ShrimpIR:
	get:
		return ShrimpVMUtil.find_ir_node(getContext.forward(WrapperPath.from("<")).get_pointer().type)
var schema: Dictionary:
	get:
		return targetIR.get_wrapper_schema().attributes[getContext.pointer.seek_tail().path]
var value:
	get:
		return getContext.get_pointer()
var block: NodeBlock:
	get:
		return getContext.locate([NodeBlock])

func _ready() -> void:
	templateWrapper.hide()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MouseButton.MOUSE_BUTTON_LEFT: return
		if !event.pressed: return
		if ShrimpVMUtil.schema_typeis(schema, ShrimpIR.TYPE_ENUM):
			selected.emit(self)
		else:
			block.request_select()

func make_template(namx: NodePath) -> Control:
	return templateWrapper.get_node(namx).duplicate()
func rebuild(release: bool = false):
	if release:
		await ShrimpPluginManager.frame()
	if !is_inside_tree():
		return
	nameLabel.text = ShrimpTranslator.get_attribute_label(ownerBlock.targetIR, name)
	ShrimpVMUtil.disconnect_children(arrayWrapper)
	ShrimpVMUtil.disconnect_children(valueWrapper)
	if schema.array:
		if value is Array:
			if ShrimpVMUtil.schema_typeis(schema, ShrimpIR.TYPE_ENUM):
				value = ShrimpVMUtil.erase_gunmu(value)
			if value.is_empty():
				emptyTip.show()
			else:
				emptyTip.hide()
				valueWrapper.hide()
				for i in len(value):
					var showbox = await create_showbox(i, arrayWrapper, release)
					if !showbox.get_parent():
						arrayWrapper.add_child(showbox)
		else:
			push_error("The array parameter's wrapper value is not an Array.")
	else:
		emptyTip.hide()
		arrayWrapper.hide()
		var showbox = await create_showbox(-1, valueWrapper, release)
		if !showbox.get_parent():
			valueWrapper.add_child(showbox)
func create_primarybox(data: Variant, index: int, wrapper: Control, release: bool = false) -> Control:
	match schema.type:
		ShrimpIR.TYPE_ENUM:
			if ShrimpVMUtil.wrapper_is_valid(data):
				if value is Array:
					return await NodeBlock.create(getContext.forward(WrapperPath.from("[%d]" % index)), false, INF, "", self).mount(wrapper, release)
				else:
					return await NodeBlock.create(getContext, false, INF, "", self).mount(wrapper, release)
			else:
				var label = Label.new()
				label.text = "NULL"
				label.label_settings = LabelSettings.new()
				label.label_settings.font_color = Color.RED
				return label
		_:
			return ItemEditor.create_showbox(schema.type, data)
func create_showbox(index: int, wrapper: Control, release: bool = false) -> Control:
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
		return await create_primarybox(data, index, wrapper, release)
	else:
		return await create_primarybox(value, -1, wrapper, release)
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
			return ItemEditor.create(schema.type, value, eventEmitter.event.emit)
	else:
		return ItemEditor.create_editbox(schema.type, value, eventEmitter.event.emit)
func mount(root: Node, release: bool = false):
	root.add_child(self)
	await rebuild(release)

static func create_initial_value(schemx: Dictionary):
	if schemx.array:
		return []
	elif schemx.type is Array:
		return 0
	else:
		return ItemEditor.create_initial_value(schemx.type)
static func create(contexx: WrapperContext, ownerBlocx: NodeBlock = null) -> NodeParameter:
	contexx.pointer = contexx.pointer.normalize()
	var instance = preload("res://addons/shrimpvm/scenes/node_parameter.tscn").instantiate() as NodeParameter
	instance.name = contexx.pointer.seek_tail().path
	instance.targetContext = contexx
	instance.ownerBlock = ownerBlocx
	return instance
