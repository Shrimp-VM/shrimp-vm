@tool
extends ShrimpTypeEditor
class_name FloatEditor

func get_type_id() -> Array[int]:
	return [TYPE_FLOAT]
func create_initial_value() -> Variant:
	return 0
func create_editbox(value: Variant, update: Callable) -> Control:
	var input = LineEdit.new()
	input.custom_minimum_size = Vector2i(300, 30)
	input.text = "%s" % (value)
	input.text_changed.connect(
		func(new: String):
			if new.is_valid_float():
				update.call(new.to_float())
	)
	return input
func create_showbox(value: Variant) -> Control:
	var label = Label.new()
	label.text = str(value)
	return label
func extract_from(editbox: Control) -> Variant:
	if editbox is LineEdit:
		if editbox.text.is_valid_float():
			return editbox.text.to_float()
	return null
