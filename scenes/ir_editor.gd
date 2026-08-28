@tool
extends CanvasLayer
class_name ShrimpIREditor

@export_tool_button("重建") var rebuilder = rebuild
@export var treeData: Dictionary = {
	"type": "root",
	"body": []
}

@onready var openBtn: Button = $%openBtn
@onready var fileOpener: FileDialog = $%fileOpener
@onready var deskWrapper: Control = $%wrapper
@onready var treeCenter: Control = $%center

func _ready() -> void:
	openBtn.pressed.connect(
		func():
			fileOpener.popup()
			load_file(await fileOpener.file_selected)
	)
	rebuild()

func rebuild():
	var irs = ShrimpVMUtil.get_ir_nodes()
	ShrimpVMUtil.disconnect_children(deskWrapper)
	for ir in irs:
		var instance = preload("./node_block.tscn").instantiate() as NodeBlock
		deskWrapper.add_child(instance)
		instance.in_desk = true
		instance.rebuild(ir.get_wrapper_schema(), {})
	ShrimpVMUtil.disconnect_children(treeCenter)
	var instance = preload("./node_block.tscn").instantiate() as NodeBlock
	treeCenter.add_child(instance)
	instance.in_desk = false
	instance.rebuild(ShrimpVMUtil.find_ir_node(treeData.type).get_wrapper_schema(), treeData)
func load_file(filepath: String) -> int:
	var file = FileAccess.open(filepath, FileAccess.ModeFlags.READ)
	if !file:
		return file.get_open_error()
	var json = JSON.new()
	var state = json.parse(file.get_as_text())
	if state != OK:
		return state
	print(json.data)
	treeData = json.data
	rebuild()
	return OK
