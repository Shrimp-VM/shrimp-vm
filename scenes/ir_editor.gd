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

@export_tool_button("Rebuild editor") var rebuilder = rebuild
@export_tool_button("Run workspace") var runer = run_workspace
@export_tool_button("Reload file system") var fsr = fs_reload
@export_category("Metadata")
@export var languages: Dictionary[StringName, String] = {
	"English": "en",
	"简体中文": "zh_CN"
}
@export var finiteBlockCount: bool = false
@export_category("Desk auto load")
@export var initialDesk: Array[ShrimpIR] = []
@export var autoLoadBuiltins: bool = false
@export_dir var autoLoadDirs: Array[String] = []
@export_category("File system auto load")
@export var initialFileSystem: Dictionary[StringName, ShrimpIR] = {}
@export var autoOpen: StringName = ""
@export_category("Wrapper & Data")
@export var rootWrapper: Dictionary = {}
@export_category("User permissons")
@export var allowArchive: bool = true
@export var allowDeleteFile: bool = true
@export var allowCreateFile: bool = true
@export var allowUserFileOverrideDefault: bool = false

@onready var vm: ShrimpVM = $%vm
@onready var fileManager: ShrimpFileManager = $%fileManager
@onready var openBtn: Button = $%openBtn
@onready var saveBtn: Button = $%saveBtn
@onready var langBtn: OptionButton = $%langBtn
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
@onready var inspector: NodeInspector = $%inspector
@onready var filesWrapper: Control = $%files
@onready var modalPanel: ClickableWrapper = $%modalPanel
@onready var modalLabel: RichTextLabel = $%modalTip
@onready var selectionMgr: SelectionManager = $%selections
@onready var loadingScreen: Control = $%loadingScreen
var rebuilding: bool = false
var debugContext: ExecutionContext
var compilationWarns: Array[Array] = []
var blockCounts: Dictionary[ShrimpIR, float] = {}
var selectingPath: WrapperPath
var garlicLsp: GarlicLspServer
var selectingPointer: Node:
	get:
		return WrapperContext.new(rootWrapper, selectingPath, get_root_block()).locate()

func _ready() -> void:
	if not Engine.is_editor_hint():
		garlicLsp = GarlicLspServer.new()
		add_child(garlicLsp)
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
	langBtn.item_selected.connect(
		func(index):
			TranslationServer.set_locale(languages[langBtn.get_item_text(index)])
			rebuild()
	)
	runBtn.pressed.connect(run_workspace)
	newFileBtn.pressed.connect(
		func():
			fileManager.add("%d.sst" % randi_range(100000, 999999), save_data())
	)
	closeFileBtn.pressed.connect(fileManager.close)
	deleteFileBtn.pressed.connect(fileManager.delete)
	workspace.clicked.connect(func(): select(null))
	inspector.delete.connect(
		func():
			await delete_node(selectingPointer)
			save_current_file()
			inspector.hide()
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
	var desk = initialDesk
	if autoLoadBuiltins:
		desk += ShrimpVMUtil.get_builtins()
	desk += ShrimpVMUtil.scan_ir_nodes(autoLoadDirs)
	blockCounts.merge(ShrimpVMUtil.create_count_map(desk))
	fs_reload()
	rebuild()
	modal()
	langBtn.item_count = 0
	for lang in languages:
		langBtn.add_item(lang)

func fs_reload():
	fileTip.show()
	if allowUserFileOverrideDefault:
		fs_load_default()
		fs_load_user()
	else:
		fs_load_user()
		fs_load_default()
	fileManager.close()
	fileManager.open(fileManager.search(autoOpen))
func fs_load_user():
	if !Engine.is_editor_hint():
		fileManager.inarchive()
		fileManager.auto_compile()
func fs_load_default():
	for fp in initialFileSystem:
		fileManager.add(fp, ShrimpCompiler.export_json(initialFileSystem[fp]), false)
func run_workspace():
	compilation_start.emit()
	compilationWarns = []
	save_current_file()
	if !has_root_node():
		compilation_warn.emit(ShrimpOptimizer.WarnType.NULL_ROOT, "Cannot run null script.")
	compilation_stage.emit("Building IR-Trees: %s" % JSON.stringify(rootWrapper, "    "))
	var ir = ShrimpCompiler.compile(rootWrapper, true, compilation_warn)
	compilation_finished.emit()
	script_run_start.emit()
	await vm.execute(ir, debugContext)
	script_run_finihsed.emit()
func rebuild_desk():
	var categories = ShrimpVMUtil.category_desk(blockCounts.keys())
	ShrimpVMUtil.disconnect_children(deskWrapper)
	for category in categories:
		var title = Label.new()
		title.text = ShrimpTranslator.get_category(category)
		title.label_settings = LabelSettings.new()
		title.label_settings.font_color = Color.BLACK
		deskWrapper.add_child(title)
		for ir in categories[category]:
			if ir is ShrimpIR:
				if ir.is_hidden(): continue
				var instance = NodeBlock.create(null, true, blockCounts[ir] if finiteBlockCount else INF, ir.get_node_type())
				node_join(instance, true)
				await instance.rebuild(true)
				instance.clicked.connect(
					func():
						if has_root_node():
							if !is_instance_valid(selectingPointer): return
							var wrapper = instance.create_wrapper()
							var childrenList: Array = []
							var insertIndex = -1
							if selectingPointer is NodeParameter:
								if !ShrimpVMUtil.schema_typeis(selectingPointer.schema, ShrimpIR.TYPE_ENUM): return
								if selectingPointer.schema.array:
									childrenList = selectingPointer.value
									insertIndex = -1
								else:
									selectingPointer.block.data[selectingPointer.name] = wrapper
							elif selectingPointer is NodeBlock:
								if !is_instance_valid(selectingPointer.parentBlock): return
								childrenList = selectingPointer.parentBlock.data[selectingPointer.parentParameterKey]
								insertIndex = selectingPointer.get_index()
							# 不是插入的话自动插进一个空数组去然后垃圾回收，不需要重写
							childrenList.assign(ShrimpVMUtil.erase_gunmu(childrenList))
							if insertIndex < 0:
								childrenList.append(wrapper)
							else:
								childrenList.insert(insertIndex, wrapper)
							if selectingPointer is NodeParameter:
								await selectingPointer.rebuild(true)
							elif selectingPointer is NodeBlock:
								await selectingPointer.parentParameterBox.rebuild(true)
							update_selection()
						else:
							rootWrapper = instance.create_wrapper()
						blockCounts[ir] -= 1
						save_current_file()
				)
func rebuild():
	if rebuilding: return
	rebuilding = true
	await loading()
	await rebuild_desk()
	fileManager.allowArchive = allowArchive
	newFileBtn.visible = allowCreateFile
	deleteFileBtn.visible = allowDeleteFile
	for child in treeCenter.get_children():
		if child is NodeBlock:
			child.queue_free()
	ShrimpVMUtil.disconnect_children(treeCenter, [treeTip])
	if has_root_node():
		var ir = find_ir_typed(rootWrapper.type)
		if ir:
			var rootContext = WrapperContext.new(rootWrapper)
			var instance = NodeBlock.create(rootContext, false)
			rootContext.nodeTree = instance
			node_join(instance, false)
			await instance.rebuild(true)
			treeTip.hide()
		else:
			push_warning("Tree build failed, unrecognized node %s" % rootWrapper.type)
	else:
		rootWrapper = {}
		treeTip.show()
	await select(selectingPath)
	await loaded()
	rebuilding = false
func loading():
	loadingScreen.show()
	loadingScreen.process_mode = Node.PROCESS_MODE_INHERIT
	await ShrimpPluginManager.frame()
func loaded():
	loadingScreen.hide()
	loadingScreen.process_mode = Node.PROCESS_MODE_DISABLED
	await ShrimpPluginManager.frame()
func get_root_block() -> NodeBlock:
	for child in treeCenter.get_children():
		if child is NodeBlock:
			return child
	return null
func delete_node(block: NodeBlock, auto_rebuild: bool = true):
	for parameter in block.parameterWrapper.get_children():
		if parameter is NodeParameter:
			if !ShrimpVMUtil.schema_typeis(parameter.schema, ShrimpIR.TYPE_ENUM): continue
			if parameter.schema.array:
				for child in parameter.arrayWrapper.get_children():
					if child is NodeBlock:
						delete_node(child, false)
			else:
				for child in parameter.valueWrapper.get_children():
					if child is NodeBlock:
						delete_node(child, false)
	block.data.invalid = true
	store_block(block.data.type)
	if auto_rebuild:
		if block.parentParameterBox:
			await block.parentParameterBox.rebuild(true)
		update_selection()
func store_block(type: String, count: int = 1):
	blockCounts[find_ir_typed(type)] += count
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
	rootWrapper = {}
	scriptNameLabel.text = "* Untitled"
	closeFileBtn.hide()
	deleteFileBtn.hide()
	rebuild()
func has_root_node() -> bool:
	return ShrimpVMUtil.wrapper_is_valid(rootWrapper)
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
	rootWrapper = data
	rebuild()
func save_data(indent: bool = false):
	var json = JSON.new()
	return json.stringify(rootWrapper, "    " if indent else "")
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
			inspector.block = selectingPointer
			inspector.rebuild(true)
			inspector.show()
		else:
			inspector.hide()
		update_selection()
	else:
		selectionMgr.stop_all()
		inspector.hide()
func update_selection():
	if is_instance_valid(selectingPointer):
		selectionMgr.select("cyan", selectingPointer)
	else:
		selectionMgr.stop("cyan")
func modal(content: String = ""):
	if content:
		modalLabel.text = content
		modalPanel.show()
		await modal_finished
	else:
		modalPanel.hide()
		modal_finished.emit()
