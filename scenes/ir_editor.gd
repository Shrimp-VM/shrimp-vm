@tool
extends Control
class_name ShrimpIREditor

signal compilation_start()
signal compilation_stage(namx: String)
signal compilation_warn(type: ShrimpOptimizer.WarnType, message: String)
signal compilation_finished()
signal script_run_start()
signal script_run_finihsed()
signal modal_finished()

@export_tool_button("Rebuild") var rebuilder = rebuild
@export var treeData: Dictionary = {
	"type": "root",
	"body": []
}
@export var finiteBlockCount: bool = false
@export var initialDesk: Array[ShrimpIR] = []
@export var defaultFileSystem: Dictionary[StringName, ShrimpIR] = {}
@export var loadBuiltins: bool = false
@export_dir var autoScanDirs: Array[String] = []

@onready var vm: ShrimpVM = $%vm
@onready var fileManager: ShrimpFileManager = $%fileManager
@onready var openBtn: Button = $%openBtn
@onready var saveBtn: Button = $%saveBtn
@onready var runBtn: Button = $%runBtn
@onready var newFileBtn: Button = $%newFileBtn
@onready var closeFileBtn: Button = $%closeFileBtn
@onready var deleteFileBtn: Button = $%deleteFileBtn
@onready var fileOpener: FileDialog = $%fileOpener
@onready var fileSaver: FileDialog = $%fileSaver
@onready var deskWrapper: Control = $%wrapper
@onready var workspace: EditorWorkspace = $%workspace
@onready var scriptNameLabel: Label = $%scriptName
@onready var treeCenter: Control = $%center
@onready var treeTip: Control = $%treeTip
@onready var fileTip: Control = $%fileTip
@onready var inspector: Control = $%inspector
@onready var deleteNodeBtn: Button = $%deleteNode
@onready var attributeWrapper: Control = $%attributes
@onready var filesWrapper: Control = $%files
@onready var modalPanel: ClickableWrapper = $%modalPanel
@onready var modalLabel: RichTextLabel = $%modalTip
@onready var nodeDescriptionLabel: Label = $%nodeDescription
@onready var selectionMgr: SelectionManager = $%selections
var debugContext: ExecutionContext
var compilationWarns: Array[Array] = []
var blockCounts: Dictionary[ShrimpIR, float] = {}
var selectingPath: WrapperPath
var selectingPointer: Node:
	get:
		return WrapperContext.new(treeData, selectingPath, get_root_block()).locate()

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
			compilation_start.emit()
			compilationWarns = []
			save_current_file()
			if !has_root_node():
				compilation_warn.emit(ShrimpOptimizer.WarnType.NULL_ROOT, "Cannot run null script.")
			compilation_stage.emit("Building IR-Trees: %s" % JSON.stringify(treeData, "    "))
			var ir = ShrimpCompiler.compile(treeData, true, compilation_warn)
			compilation_finished.emit()
			script_run_start.emit()
			await vm.execute(ir, debugContext)
			script_run_finihsed.emit()
	)
	newFileBtn.pressed.connect(
		func():
			fileManager.add("%d.sst" % randi_range(100000, 999999), save_data())
	)
	closeFileBtn.pressed.connect(fileManager.close)
	deleteFileBtn.pressed.connect(fileManager.delete)
	workspace.clicked.connect(func(): select(null))
	deleteNodeBtn.pressed.connect(
		func():
			delete_node(selectingPointer)
			save_current_file()
	)
	fileManager.add_file.connect(
		func(f: VirtualFile):
			filesWrapper.add_child(f)
			fileTip.hide()
	)
	fileManager.open_file.connect(
		func(f: VirtualFile):
			load_json(f.content)
			scriptNameLabel.text = f.fileName
			closeFileBtn.show()
			deleteFileBtn.show()
	)
	fileManager.close_file.connect(func(_f): close_current_file())
	fileManager.delete_file.connect(
		func(_f):
			close_current_file()
			if fileManager.files.is_empty():
				fileTip.show()
	)
	fileManager.rebuilding.connect(
		func(file: VirtualFile):
			if is_instance_valid(file):
				scriptNameLabel.text = file.fileName
	)
	modalPanel.clicked.connect(modal)
	compilation_warn.connect(func(t, m): compilationWarns.append([t, m]))
	fileTip.show()
	for fp in defaultFileSystem:
		fileManager.add(fp, ShrimpCompiler.export_json(defaultFileSystem[fp]))
	if !Engine.is_editor_hint():
		fileManager.inarchive()
		fileManager.close()
	var desk = initialDesk
	if loadBuiltins:
		desk += ShrimpVMUtil.get_builtins()
	desk += ShrimpVMUtil.scan_ir_nodes(autoScanDirs)
	blockCounts = ShrimpVMUtil.create_count_map(desk)
	rebuild()
	rebuild_desk()
	modal()

func rebuild_desk():
	var categories = ShrimpVMUtil.category_desk(blockCounts.keys())
	ShrimpVMUtil.disconnect_children(deskWrapper)
	for category in categories:
		var title = Label.new()
		title.text = category
		deskWrapper.add_child(title)
		for ir in categories[category]:
			if ir is ShrimpIR:
				var instance = NodeBlock.create(null, true, blockCounts[ir] if finiteBlockCount else INF, ir.get_node_type())
				node_join(instance, true)
				instance.rebuild()
				instance.clicked.connect(
					func():
						if has_root_node():
							if !is_instance_valid(selectingPointer): return
							var wrapper = instance.create_wrapper()
							var childrenList: Array = []
							var insertIndex = 0
							if is_instance_valid(selectingPointer):
								if selectingPointer is NodeParameter:
										if selectingPointer.schema.type != ShrimpIR.TYPE_ENUM: return
										var attributeKey = selectingPointer.name
										if selectingPointer.schema.get("array", false):
											childrenList = selectingPointer.data[attributeKey]
											insertIndex = -1
										else:
											selectingPointer.data[attributeKey] = wrapper
								elif selectingPointer is NodeBlock:
									if is_instance_valid(selectingPointer.parentBlock):
										childrenList = selectingPointer.parentBlock.data[selectingPointer.parentAttribute]
										insertIndex = selectingPointer.get_index() - 1
							childrenList.assign(ShrimpVMUtil.erase_gunmu(childrenList))
							if insertIndex < 0:
								childrenList.append(wrapper)
							else:
								childrenList.insert(insertIndex, wrapper)
						else:
							treeData = instance.create_wrapper()
						blockCounts[ir] -= 1
						save_current_file()
						rebuild()
				)
func rebuild():
	if Engine.is_editor_hint():
		rebuild_desk()
	ShrimpVMUtil.disconnect_children(treeCenter, [treeTip])
	if has_root_node():
		var ir = find_ir_typed(treeData.type)
		if ir:
			var rootContext = WrapperContext.new(treeData)
			var instance = NodeBlock.create(rootContext, false)
			rootContext.nodeTree = instance
			node_join(instance, false)
			instance.rebuild()
			treeTip.hide()
		else:
			push_warning("Tree build failed, unrecognized node %s" % treeData.type)
	else:
		treeData = {}
		treeTip.show()
	select(null)
func get_root_block() -> NodeBlock:
	for child in treeCenter.get_children():
		if child is NodeBlock:
			return child
	return null
func delete_node(block: NodeBlock):
	for parameter in block.parameterWrapper.get_children():
		if parameter is NodeParameter:
			if typeof(parameter.schema.type) != TYPE_INT || parameter.schema.type != ShrimpIR.TYPE_ENUM: continue
			if parameter.schema.array:
				for child in parameter.arrayWrapper.get_children():
					if child is NodeBlock:
						delete_node(child)
			else:
				for child in parameter.valueWrapper.get_children():
					if child is NodeBlock:
						delete_node(child)
	block.data.invalid = true
	store_block(block.data.type)
	rebuild()
func store_block(type: String, count: int = 1):
	blockCounts[find_ir_typed(type)] += count
	rebuild_desk()
func consume_block(type: String):
	store_block(type, -1)
func find_ir_typed(type: String) -> ShrimpIR:
	var irs = blockCounts.keys()
	var index = irs.find_custom(func(x: ShrimpIR): return x.get_node_type() == type)
	if index >= 0:
		return irs[index]
	else:
		return null
func save_current_file():
	fileManager.save(save_data())
func close_current_file():
	treeData = {}
	scriptNameLabel.text = "* Untitled"
	closeFileBtn.hide()
	deleteFileBtn.hide()
	rebuild()
func has_root_node() -> bool:
	return ShrimpVMUtil.wrapper_is_valid(treeData)
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
func select(path: WrapperPath):
	selectingPath = path
	if is_instance_valid(selectingPointer):
		if selectingPointer is NodeBlock:
			ShrimpVMUtil.disconnect_children(attributeWrapper)
			for attributeKey in selectingPointer.schema.attributes:
				var eventEmitter = ShrimpVMUtil.EventEmitter.new()
				var attribute = selectingPointer.schema.attributes[attributeKey]
				var parameter = selectingPointer.parameterWrapper.get_node(attributeKey) as NodeParameter
				parameter.eventEmitter = eventEmitter
				parameter.eventEmitter.event.connect(
					func(v):
						selectingPointer.data[attributeKey] = v
						save_current_file()
						parameter.rebuild()
				)
				var editor = parameter.create_editbox()
				if !is_instance_valid(editor):
					continue
				var instance = load("res://addons/shrimpvm/scenes/parameter_inspector.tscn").instantiate() as ParameterInspector
				attributeWrapper.add_child(instance)
				instance.rebuild(attribute.label, editor)
			nodeDescriptionLabel.text = selectingPointer.schema.description
			selectionMgr.select("cyan", selectingPointer)
		elif selectingPointer is NodeParameter:
			selectionMgr.select("cyan", selectingPointer)
		inspector.show()
	else:
		selectionMgr.stop_all()
		inspector.hide()
func modal(content: String = ""):
	if content:
		modalLabel.text = content
		modalPanel.show()
		await modal_finished
	else:
		modalPanel.hide()
		modal_finished.emit()
