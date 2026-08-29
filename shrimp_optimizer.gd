## Not implemented
@tool
extends RefCounted
class_name ShrimpOptimizer

signal warning(type: WarnType, message: String)

enum WarnType {
	NULL_NODE
}

var input: ShrimpIR
var result: ShrimpIR

func _init(inpux: ShrimpIR) -> void:
	input = inpux

func warn(type: WarnType, message: String):
	warning.emit(type, message)
## Not implemented!!!
func optimize() -> ShrimpIR:
	result = input
	return result
