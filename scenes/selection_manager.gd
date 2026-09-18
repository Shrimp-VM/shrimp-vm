@tool
extends Control
class_name SelectionManager

const BOX_PADDING = 10

func _ready() -> void:
	stop_all()

func get_panel_list() -> Array[String]:
	var result: Array[String] = []
	result.assign(get_children().map(func(e: Node): return e.name))
	return result
func get_panel(namx: String) -> Panel:
	var panel = get_node_or_null(namx)
	if panel is Panel:
		return panel
	else:
		return null
func start(namx: String):
	get_panel(namx).show()
func stop(namx: String):
	get_panel(namx).hide()
func stop_all():
	for panel in get_panel_list():
		stop(panel)
func move(namx: String, positiox: Vector2, sizx: Vector2):
	var panel = get_panel(namx)
	panel.global_position = positiox
	panel.size = sizx
	start(namx)
func select(namx: String, box: Control):
	move(namx, box.global_position - Vector2(1, 1) * BOX_PADDING, box.size + Vector2(1, 1) * 2 * BOX_PADDING)
