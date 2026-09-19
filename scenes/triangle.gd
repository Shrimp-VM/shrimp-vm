@tool
extends Control
class_name Triangle

enum Direction {
	RIGHT,
	LEFT
}

@export var direction: Direction = Direction.RIGHT
@export var fillColor: Color = Color.WHITE
@export var borderColor: Color = Color.BLACK
@export var borderWidth: float = 0

func _process(_delta: float) -> void:
	queue_redraw()
func _draw() -> void:
	var polygon = [
		Vector2(direction * size.x, 0),
		Vector2(size.x - direction * size.x, size.y / 2),
		Vector2(direction * size.x, size.y)
	]
	draw_colored_polygon(polygon, fillColor)
	if borderWidth > 0:
		draw_polyline(polygon, borderColor, borderWidth, false)
