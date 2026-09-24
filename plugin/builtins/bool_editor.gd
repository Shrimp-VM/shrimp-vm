@tool
extends ShrimpTypeEditor
class_name BoolEditor

func get_type_id() -> Array[int]:
	return [TYPE_BOOL]
func create_initial_value() -> Variant:
	return false
func create_editbox(value: Variant, update: Callable) -> Control:
	var check = CheckButton.new()
	check.button_pressed = value
	check.toggled.connect(update)
	return check
func create_showbox(value: Variant) -> Control:
	var check = CheckButton.new()
	check.button_pressed = value
	check.disabled = true
	return check
func extract_from(editbox: Control) -> Variant:
	if editbox is CheckButton:
		return editbox.button_pressed
	return null
