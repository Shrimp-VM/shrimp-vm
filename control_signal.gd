extends RefCounted
class_name ShrimpControlSignal

enum Type {
	RETURN,
	BREAK,
	CONTINUE,
	ERROR
}

var type: Type
var value: Variant

func _init(typx: Type = Type.RETURN, valuex: Variant = null) -> void:
	type = typx
	value = valuex
