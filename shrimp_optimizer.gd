## Not implemented
@tool
extends RefCounted
class_name ShrimpOptimizer

signal warning(message: String)

var input: ShrimpIR
var result: ShrimpIR

func _init(inpux: ShrimpIR) -> void:
	input = inpux

func warn(message: String):
	warning.emit(message)
## Not implemented!!!
func optimize() -> ShrimpIR:
	result = input
	return result
