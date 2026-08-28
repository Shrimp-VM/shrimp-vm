@tool
extends Control
class_name NodeParameter

@onready var nameLabel: Label = $%name
@onready var wrapperContainer: Control = $%wrapper

func rebuild(schema: Dictionary, value: Variant):
	print(schema, value)
