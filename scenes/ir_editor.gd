@tool
extends CanvasLayer
class_name ShrimpIREditor

@export_tool_button("重建") var rebuilder = rebuild
@export var treeData: Dictionary = {
	"type": "root",
	"body": []
}

@onready var deskWrapper: Control = $%wrapper
@onready var treeCenter: Control = $%center

func _ready() -> void:
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
