@tool
extends ShrimpTypeEditor
class_name StringNameEditor

func get_type_id() -> Array[int]:
	return [TYPE_STRING_NAME]
func create_initial_value() -> Variant:
	return "Unnamed"
func create_editbox(value: Variant, update: Callable) -> Control:
	var input = LineEdit.new()
	input.custom_minimum_size.x = 100
	input.text = str(value)
	input.text_changed.connect(update)
	return input
func create_showbox(value: Variant) -> Control:
	var label = Label.new()
	label.text = str(value)
	return label
func extract_from(editbox: Control) -> Variant:
	if editbox is LineEdit:
		return editbox.text
	return null
