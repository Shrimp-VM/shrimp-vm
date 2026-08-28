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
var nodePointer: NodeBlock = null

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

func rebuild():
	var irs = ShrimpVMUtil.get_ir_nodes()
	ShrimpVMUtil.disconnect_children(deskWrapper)
	for ir in irs:
		var instance = preload("./node_block.tscn").instantiate() as NodeBlock
		instance.inDesk = true
		node_join(instance, true)
		instance.rebuild(ir.get_wrapper_schema(), {"type": ir.get_node_type()})
		instance.clicked.connect(
			func():
				if !is_instance_valid(nodePointer): return
				if !is_instance_valid(nodePointer.paramPointer): return
				if nodePointer.paramPointer.schema.type != ShrimpIR.TYPE_ENUM: return
				var attributeKey = nodePointer.paramPointer.name
				var newNode = instance.create_wrapper()
				if nodePointer.paramPointer.schema.get("array", false):
					var datas = nodePointer.data[attributeKey] as Array
					datas.append(newNode)
				else:
					nodePointer.data[attributeKey] = newNode
				rebuild()
		)
	ShrimpVMUtil.disconnect_children(treeCenter)
	var instance = preload("./node_block.tscn").instantiate() as NodeBlock
	instance.inDesk = false
	node_join(instance, false)
	instance.rebuild(ShrimpVMUtil.find_ir_node(treeData.type).get_wrapper_schema(), treeData)
	select(null)
func mark_selection(node: NodeBlock):
	node.selected.connect(select)
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
	load_data(json.data)
	return OK
func load_data(data: Dictionary):
	treeData = data
	rebuild()
func select(node: NodeBlock):
	if is_instance_valid(nodePointer):
		nodePointer.unselect()
		nodePointer.paramPointer = null
	nodePointer = node
	if is_instance_valid(node):
		node.select()
		ShrimpVMUtil.disconnect_children(attributeWrapper)
		for attributeKey in node.schema.attributes:
			var eventEmitter = ShrimpVMUtil.EventEmitter.new()
			var attribute = node.schema.attributes[attributeKey]
			var parameter = node.parameterWrapper.get_node(attributeKey) as NodeParameter
			parameter.eventEmitter = eventEmitter
			var editor = parameter.create_editbox(attribute, node.data[attributeKey])
			if !is_instance_valid(editor):
				continue
			eventEmitter.event.connect(
				func(v):
					node.data[attributeKey] = v
					parameter.rebuild(node.schema.attributes[attributeKey], v, node)
			)
			var instance = load("res://addons/shrimpvm/scenes/parameter_inspector.tscn").instantiate() as ParameterInspector
			attributeWrapper.add_child(instance)
			instance.rebuild(attribute.label, editor)
		inspector.show()
	else:
		inspector.hide()
