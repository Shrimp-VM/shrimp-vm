@tool
extends CanvasLayer
class_name ShrimpIREditor

@export_tool_button("重建") var rebuilder = rebuild
@export var treeData: Dictionary = {
	"type": "root",
	"body": []
}

@onready var vm: ShrimpVM = $%vm
@onready var openBtn: Button = $%openBtn
@onready var runBtn: Button = $%runBtn
@onready var fileOpener: FileDialog = $%fileOpener
@onready var deskWrapper: Control = $%wrapper
@onready var treeCenter: Control = $%center
@onready var inspector: Control = $%inspector
@onready var attributeWrapper: Control = $%attributes
var debugContext: ExecutionContext
var currentSelectingNode: NodeBlock = null

func _ready() -> void:
	debugContext = ExecutionContext.new()
	openBtn.pressed.connect(
		func():
			fileOpener.popup()
			load_file(await fileOpener.file_selected)
	)
	runBtn.pressed.connect(
		func():
			vm.execute(ShrimpSyntaxTreeImporter.create_ir(treeData), debugContext)
	)
	rebuild()

func rebuild():
	var irs = ShrimpVMUtil.get_ir_nodes()
	ShrimpVMUtil.disconnect_children(deskWrapper)
	for ir in irs:
		var instance = preload("./node_block.tscn").instantiate() as NodeBlock
		node_join(instance, true)
		instance.in_desk = true
		instance.rebuild(ir.get_wrapper_schema(), {})
	ShrimpVMUtil.disconnect_children(treeCenter)
	var instance = preload("./node_block.tscn").instantiate() as NodeBlock
	node_join(instance, false)
	instance.in_desk = false
	instance.rebuild(ShrimpVMUtil.find_ir_node(treeData.type).get_wrapper_schema(), treeData)
func mark_selection(node: NodeBlock):
	node.selected.connect(select)
func node_join(node: NodeBlock, desk: bool):
	if desk:
		deskWrapper.add_child(node)
	else:
		treeCenter.add_child(node)
	node.mark_selection.connect(mark_selection)
func load_file(filepath: String) -> int:
	var file = FileAccess.open(filepath, FileAccess.ModeFlags.READ)
	if !file:
		return file.get_open_error()
	var json = JSON.new()
	var state = json.parse(file.get_as_text())
	if state != OK:
		return state
	treeData = json.data
	rebuild()
	return OK
func select(node: NodeBlock):
	if is_instance_valid(currentSelectingNode):
		currentSelectingNode.unselect()
		node.select()
	currentSelectingNode = node
	if is_instance_valid(node):
		ShrimpVMUtil.disconnect_children(attributeWrapper)
		for attributeKey in node.schema.attributes:
			var attribute = node.schema.attributes[attributeKey]
			var parameter = node.parameterWrapper.get_node(attributeKey) as NodeParameter
			var instance = load("res://addons/shrimpvm/scenes/parameter_inspector.tscn").instantiate() as ParameterInspector
			attributeWrapper.add_child(instance)
			instance.rebuild(attribute.label, parameter.create_editbox(attribute, node.data[attributeKey]))
	else:
		inspector.hide()
