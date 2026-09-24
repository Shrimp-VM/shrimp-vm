@abstract
@tool
extends Node
class_name ShrimpTypeEditor

@abstract func get_type_id() -> Array[int]
@abstract func create_initial_value() -> Variant
@abstract func create_editbox(value: Variant, update: Callable) -> Control
@abstract func create_showbox(value: Variant) -> Control
@abstract func extract_from(editbox: Control) -> Variant
