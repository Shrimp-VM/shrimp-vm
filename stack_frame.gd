extends RefCounted
class_name ShrimpFrame

enum Boundary {
	BLOCK,
	LOOP,
	FUNCTION
}

var body: Array[ShrimpIR]
var pointerIndex: int = 0
var env: ExecutionEnvironment
var boundary: Boundary
var function: ShrimpFunction
var lastResult: Variant

func _init(bodx: Array[ShrimpIR], enx: ExecutionEnvironment, boundarx: Boundary = Boundary.BLOCK, functiox: ShrimpFunction = null) -> void:
	body = bodx
	env = enx
	boundary = boundarx
	function = functiox
