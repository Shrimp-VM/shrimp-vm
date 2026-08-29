@tool
extends CanvasLayer
class_name ShrimpIREditor

@export_tool_button("重建") var rebuilder = rebuild
@export var treeData: Dictionary = {
	"type": "root",
	"body": []
}

@onready var vm: ShrimpVM = $%vm
@onready var fileManager: ShrimpFileManager = $%fileManager
@onready var openBtn: Button = $%openBtn
@onready var saveBtn: Button = $%saveBtn
@onready var runBtn: Button = $%runBtn
@onready var newFileBtn: Button = $%newBtn
@onready var fileOpener: FileDialog = $%fileOpener
@onready var fileSaver: FileDialog = $%fileSaver
@onready var deskWrapper: Control = $%wrapper
@onready var workspace: EditorWorkspace = $%workspace
@onready var treeCenter: Control = $%center
@onready var tipLabel: Control = $%tip
@onready var inspector: Control = $%inspector
@onready var attributeWrapper: Control = $%attributes
@onready var deleteBtn: Button = $%deleteBtn
@onready var filesWrapper: Control = $%files
var debugContext: ExecutionContext
var nodePointer: NodeBlock = null

func _ready() -> void:
	debugContext = ExecutionContext.new()
	debugContext.env.write_symbol("filemgr", fileManager)
	openBtn.pressed.connect(
		func():
			fileOpener.popup()
			load_file(await fileOpener.file_selected)
	)
	saveBtn.pressed.connect(
		func():
			fileSaver.popup()
			save_to(await fileSaver.file_selected)
	)
	runBtn.pressed.connect(
		func():
			fileManager.save(save_data())
			print("正在运行IR", treeData)
			await vm.execute(ShrimpSyntaxTreeImporter.compile(treeData), debugContext)
	)
	newFileBtn.pressed.connect(
		func():
			fileManager.add("%d.sst" % randi_range(100000, 999999), "{}")
	)
	workspace.clicked.connect(func(): select(null))
	deleteBtn.pressed.connect(
		func():
			nodePointer.data.invalid = true
			rebuild()
	)
	fileManager.add_file.connect(filesWrapper.add_child)
	fileManager.open_file.connect(
		func(f: VirtualFile):
			load_json(f.content)
	)
	fileManager.inarchive()
	rebuild()

func rebuild():
	ShrimpVMUtil.disconnect_children(deskWrapper)
	var categories = ShrimpVMUtil.get_categoried_irs()
	for category in categories:
		var title = Label.new()
		title.text = category
		deskWrapper.add_child(title)
		for ir in categories[category]:
			var instance = preload("./node_block.tscn").instantiate() as NodeBlock
			instance.inDesk = true
			node_join(instance, true)
			instance.rebuild(ir.get_wrapper_schema(), {"type": ir.get_node_type()})
			instance.clicked.connect(
				func():
					if has_root_node():
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
					else:
						treeData = instance.create_wrapper()
						rebuild()
					rebuild()
			)
	ShrimpVMUtil.disconnect_children(treeCenter, [tipLabel])
	if treeData.get("invalid", false):
		treeData = {}
		select(null)
		rebuild()
		return
	if has_root_node():
		var instance = preload("./node_block.tscn").instantiate() as NodeBlock
		instance.inDesk = false
		node_join(instance, false)
		instance.rebuild(ShrimpVMUtil.find_ir_node(treeData.type).get_wrapper_schema(), treeData)
		select(null)
		tipLabel.hide()
	else:
		select(null)
		tipLabel.show()
func has_root_node() -> bool:
	return len(treeData) > 0 && treeData.has("type")
func mark_selection(node: NodeBlock):
	node.selected.connect(select)
func node_join(node: NodeBlock, desk: bool):
	node.mark_selection.connect(mark_selection)
	if desk:
		deskWrapper.add_child(node)
	else:
		treeCenter.add_child(node)
func load_file(filepath: String):
	var file = FileAccess.open(filepath, FileAccess.ModeFlags.READ)
	if !file:
		return
	return load_json(file.get_as_text())
func load_json(text: String):
	var json = JSON.new()
	if json.parse(text) != OK:
		return
	return load_data(json.data)
func load_data(data: Dictionary):
	treeData = data
	rebuild()
func save_data(indent: bool = false):
	var json = JSON.new()
	return json.stringify(treeData, "    " if indent else "")
func save_to(filepath: String):
	var file = FileAccess.open(filepath, FileAccess.ModeFlags.WRITE)
	if !file:
		return file.get_open_error()
	file.store_string(save_data())
	return OK
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
			parameter.eventEmitter.event.connect(
				func(v):
					node.data[attributeKey] = v
					parameter.rebuild(node.schema.attributes[attributeKey], v, node)
			)
			var editor = parameter.create_editbox(attribute, node.data[attributeKey])
			if !is_instance_valid(editor):
				continue
			var instance = load("res://addons/shrimpvm/scenes/parameter_inspector.tscn").instantiate() as ParameterInspector
			attributeWrapper.add_child(instance)
			instance.rebuild(attribute.label, editor)
		inspector.show()
	else:
		inspector.hide()
