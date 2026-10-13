@tool
extends RefCounted
class_name ShrimpFunction

var capturedThis: ShrimpInstance
var capturedContext: ShrimPoroutine
var capturedEnv: ExecutionEnvironment
var params: Array
var body: Array[ShrimpIR]
var async: bool
var generator: bool

func _init(context: ShrimPoroutine, this: ShrimpInstance, paramx: Array = [], bodx: Array[ShrimpIR] = [], asynx: bool = false, generatox: bool = false) -> void:
	capturedContext = context
	capturedThis = this
	if is_instance_valid(context):
		capturedEnv = context.env
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
		return
	elif len(input) < len(params):
		push_error("Too less parameters")
		return
	var runContext = ShrimPoroutine.new(capturedContext)
	runContext.setup_function(self, input, vm)
	if generator:
		return ShrimpGenerator.new(runContext, vm)
	runContext.reparent_head(vm.globalContext)
	return await runContext.drive_all()
