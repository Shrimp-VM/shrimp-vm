@tool
extends Node

@onready var editor: ShrimpIREditor = $%editor

func _ready() -> void:
	# WrapperPathTest.test()
	# WrapperContextTest.test()
	# GarlicTest.test()
	editor.run_workspace()
