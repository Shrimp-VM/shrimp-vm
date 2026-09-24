@tool
extends ShrimpTypeEditor
class_name StringEditor

func get_type_id() -> Array[int]:
	return [TYPE_STRING]
func create_initial_value() -> Variant:
	return ""
func create_editbox(value: Variant, update: Callable) -> Control:
	var input = TextEdit.new()
	input.custom_minimum_size = Vector2i(200, 100)
	input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	input.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	input.text = str(value)
	input.text_changed.connect(func(): update.call(input.text))
	return input
func create_showbox(value: Variant) -> Control:
	var label = Label.new()
	label.text = str(value)
	return label
func extract_from(editbox: Control) -> Variant:
	if editbox is TextEdit:
		return editbox.text
	return ""
