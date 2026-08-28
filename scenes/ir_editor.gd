@tool
extends CanvasLayer
class_name ShrimpIREditor

@export var schemas: Array[ShrimpIR] = []
@export var treeData: Dictionary = {
	"type": "root",
	"body": []
}

@onready var deskWrapper: Control = $%wrapper
@onready var treeCenter: Control = $%center

func _ready() -> void:
	rebuild()

func rebuild():
	ShrimpVMUtil.disconnect_children(deskWrapper)
	for ir in schemas:
		var instance = preload("./node_block.tscn").instantiate() as NodeBlock
		deskWrapper.add_child(instance)
		instance.in_desk = true
		instance.rebuild(ir.get_wrapper_schema(), {})
	ShrimpVMUtil.disconnect_children(treeCenter)
	var instance = preload("./node_block.tscn").instantiate() as NodeBlock
	treeCenter.add_child(instance)
	instance.in_desk = false
	for ir in schemas:
		if ir.get_node_type() == treeData.type:
			instance.rebuild(ir.get_wrapper_schema(), treeData)
			break
