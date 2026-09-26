@tool
extends Control
class_name ClickableWrapper
 
signal clicked()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			if event.pressed:
				clicked.emit()
