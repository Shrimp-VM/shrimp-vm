@tool
extends Control
class_name NodeInspector

signal delete()
signal save()

@onready var descriptionLabel: Label = $%description
@onready var attributeWrapper: Control = $%attributes
@onready var deleteBtn: Button = $%deleteNode
var block: NodeBlock

func _ready() -> void:
	deleteBtn.pressed.connect(delete.emit)
func rebuild(release: bool = false):
	if release:
		await ShrimpPluginManager.frame()
	ShrimpVMUtil.disconnect_children(attributeWrapper)
	for attributeKey in block.schema.attributes:
		var eventEmitter = ShrimpVMUtil.EventEmitter.new()
		var attribute = block.schema.attributes[attributeKey]
		var parameter = block.parameterWrapper.get_node(attributeKey) as NodeParameter
		parameter.eventEmitter = eventEmitter
		parameter.eventEmitter.event.connect(
			func(v):
				block.data[attributeKey] = v
				save.emit()
				await parameter.rebuild(release)
		)
		var editor = parameter.create_editbox()
		if !is_instance_valid(editor):
			continue
		var instance = load("res://addons/shrimpvm/scenes/parameter_inspector.tscn").instantiate() as ParameterInspector
		attributeWrapper.add_child(instance)
		instance.rebuild(attribute.label, editor)
	descriptionLabel.text = ShrimpTranslator.get_ir_description(block.targetIR)
