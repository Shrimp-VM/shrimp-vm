@tool
extends Control
class_name Triangle

enum Direction {
	RIGHT,
	LEFT
}

@export var direction: Direction = Direction.RIGHT

func _process(_delta: float) -> void:
	queue_redraw()
func _draw() -> void:
	draw_colored_polygon([
		Vector2(direction * size.x, 0),
		Vector2(size.x - direction * size.x, size.y / 2),
		Vector2(direction * size.x, size.y)
	], Color.WHITE)
