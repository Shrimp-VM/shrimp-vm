extends Control
class_name ParameterInspector

@onready var nameLabel: Label = $%name
@onready var editorWrapper: Control = $%editor

func rebuild(namx: String, editor: Control):
	nameLabel.text = namx
	ShrimpVMUtil.disconnect_children(editorWrapper)
	editorWrapper.add_child(editor)
