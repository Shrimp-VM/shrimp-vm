@tool
extends Control
class_name Triangle

enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

@export var direction: Direction = Direction.RIGHT
@export var fillColor: Color = Color.WHITE
@export var borderColor: Color = Color.BLACK
@export var borderWidth: float = 0

func _process(_delta: float) -> void:
	queue_redraw()
func _draw() -> void:
	var polygon = get_polygon()
	draw_colored_polygon(polygon, fillColor)
	if borderWidth > 0:
		draw_polyline(polygon, borderColor, borderWidth, false)

func anchor(x: float, y: float) -> Vector2:
	return size * Vector2(x, y)
func get_polygon() -> PackedVector2Array:
	match direction:
		Direction.UP:
			return [
				anchor(0.5, 0),
				anchor(1, 1),
				anchor(0, 1)
			]
		Direction.DOWN:
			return [
				anchor(0, 0),
				anchor(1, 0),
				anchor(0.5, 1)
			]
		Direction.LEFT:
			return [
				anchor(0, 0.5),
				anchor(1, 0),
				anchor(1, 1)
			]
		Direction.RIGHT:
			return [
				anchor(0, 0),
				anchor(1, 0.5),
				anchor(0, 1)
			]
		_:
			return []
