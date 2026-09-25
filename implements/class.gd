@tool
extends ShrimpInstance
class_name ShrimpClass

var initialized: bool = false
var body: Array[ShrimpIR] = []

func _init(bodx: Array[ShrimpIR], baseContext: ExecutionContext) -> void:
	body = bodx
	instanceContext = ExecutionContext.new(baseContext)
	instanceContext.env.write_symbol("this", self)

func init(vm: ShrimpVM):
	if initialized:
		push_warning("Don't init twice.")
		return
	await vm.execute_body(body, instanceContext)
	initialized = true
func create_instantiate(args: Array, vm: ShrimpVM) -> ShrimpInstance:
	if !initialized:
		push_error("Cannot create_instantiate a class before init.")
		return null
	var instance = ShrimpInstance.new()
	instance.prototype = self
	var context = ExecutionContext.new(instanceContext)
	context.env.write_symbol("this", instance)
	instance.instanceContext = context
	await instance.call_super_method("init", vm, args)
	return instance
