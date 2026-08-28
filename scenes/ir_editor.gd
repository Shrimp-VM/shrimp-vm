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
@onready var workspace: EditorWorkspace = $%workspace
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
	workspace.clicked.connect(func(): select(null))
	rebuild()
	select(null)

func rebuild():
	var irs = ShrimpVMUtil.get_ir_nodes()
	ShrimpVMUtil.disconnect_children(deskWrapper)
	for ir in irs:
		var instance = preload("./node_block.tscn").instantiate() as NodeBlock
		instance.in_desk = true
		node_join(instance, true)
		instance.rebuild(ir.get_wrapper_schema(), {})
	ShrimpVMUtil.disconnect_children(treeCenter)
	var instance = preload("./node_block.tscn").instantiate() as NodeBlock
	instance.in_desk = false
	node_join(instance, false)
	instance.rebuild(ShrimpVMUtil.find_ir_node(treeData.type).get_wrapper_schema(), treeData)
func mark_selection(node: NodeBlock):
	node.selected.connect(select)
	print("m", node)
func node_join(node: NodeBlock, desk: bool):
	node.mark_selection.connect(mark_selection)
	if desk:
		deskWrapper.add_child(node)
	else:
		treeCenter.add_child(node)
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
	currentSelectingNode = node
	if is_instance_valid(node):
		node.select()
		ShrimpVMUtil.disconnect_children(attributeWrapper)
		for attributeKey in node.schema.attributes:
			var attribute = node.schema.attributes[attributeKey]
			var parameter = node.parameterWrapper.get_node(attributeKey) as NodeParameter
			var editor = parameter.create_editbox(attribute, node.data[attributeKey])
			if !is_instance_valid(editor):
				print(attributeKey, "没有编辑器，跳过")
				continue
			var instance = load("res://addons/shrimpvm/scenes/parameter_inspector.tscn").instantiate() as ParameterInspector
			attributeWrapper.add_child(instance)
			instance.rebuild(attribute.label, editor)
		inspector.show()
	else:
		inspector.hide()
