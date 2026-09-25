@tool
extends RefCounted
class_name ShrimpFunction

var capturedThis: ShrimpInstance
var capturedContext: ExecutionContext
var params: Array
var body: Array[ShrimpIR]
var async: bool
var generator: bool

func _init(context: ExecutionContext, this: ShrimpInstance, paramx: Array = [], bodx: Array[ShrimpIR] = [], asynx: bool = false, generatox: bool = false) -> void:
	capturedContext = context
	capturedThis = this
	params = paramx
	body = bodx
	async = asynx
	generator = generatox

func run(input: Array, vm: ShrimpVM):
	if !is_instance_valid(vm):
		push_warning("VM is invalid, skipped function running.")
		return
	if len(input) > len(params):
		push_error("Too much parameters")
	elif len(input) < len(params):
		push_error("Too less parameters")
	else:
		var runContext = ExecutionContext.new(capturedContext, ExecutionContext.LifeMode.STOP)
		for i in len(params):
			runContext.env.write_symbol(params[i], input[i])
		runContext.env.write_symbol("this", capturedThis)
		if generator:
			runContext.start(body, vm, false)
			return ShrimpGenerator.new(runContext, vm)
		else:
			return await vm.execute_body(body, runContext)
