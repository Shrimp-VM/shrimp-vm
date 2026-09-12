@tool
extends Control
class_name NodeBlock

signal clicked()
signal selected(node: NodeBlock)
signal mark_selection(node: NodeBlock)
signal exhausted()

@export var inDesk: bool = false
@export var count: float = INF

@onready var selectionBar: Control = $%selection
@onready var frameBar: ClickableWrapper = $%frame
@onready var nameLabel: RichTextLabel = $%name
@onready var parameterPanel: Control = $%parameters
@onready var parameterWrapper: Control = $%wrapper
@onready var countBar: Control = $%countBar
@onready var countLabel: Label = $%count
var schema: Dictionary
var data: Dictionary
var parent: NodeBlock
var paramPointer: NodeParameter
var irPointer: ShrimpIR

func _ready() -> void:
	unselect()
	frameBar.clicked.connect(
		func():
			if !inDesk && !parameterWrapper.get_children().is_empty():
				parameterPanel.visible = !parameterPanel.visible
	)
	mark_selection.connect(
		func(node: NodeBlock):
			if is_instance_valid(parent):
				parent.mark_selection.emit(node)
	)
	mark_selection.emit(self)
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
			countLabel.text = "ENHAUSTED"
			countLabel.label_settings.font_color = Color.RED
		countBar.show()
	else:
		countBar.hide()
func rebuild(schemx: Dictionary, datx: Dictionary):
	schema = schemx
	data = datx
	parameterPanel.visible = !inDesk && len(schemx.attributes) > 0
	nameLabel.text = schemx.name
	rebuild_count()
	ShrimpVMUtil.disconnect_children(parameterWrapper)
	if !inDesk:
		for attributeKey in schemx.attributes:
			if typeof(schemx.attributes[attributeKey].type) == TYPE_INT && schemx.attributes[attributeKey].type == ShrimpIR.TYPE_EXTERNAL_PARAMETER: continue
			var instance = load("res://addons/shrimpvm/scenes/node_parameter.tscn").instantiate() as NodeParameter
			parameterWrapper.add_child(instance)
			instance.name = attributeKey
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
func unselect():
	selectionBar.hide()
	if is_instance_valid(paramPointer):
		paramPointer.unselect()
func create_wrapper() -> Dictionary:
	var result = {}
	result.type = data.type
	for key in schema.attributes:
		result[key] = NodeParameter.create_initial_value(schema.attributes[key])
	return result
