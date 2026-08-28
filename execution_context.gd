extends RefCounted
class_name ExecutionContext

var parent: ExecutionContext
var env: ExecutionEnvironment

func _init(parenx: ExecutionContext = null, enx: ExecutionEnvironment = null) -> void:
	parent = parenx
	if !is_instance_valid(enx):
		enx = ExecutionEnvironment.new()
	env = enx
	if is_instance_valid(parent):
		env.parent = parent.env
