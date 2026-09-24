extends RefCounted
class_name ShrimpGenerator

enum State {
	READY,
	PAUSED,
	DONE
}

signal resumed()

const TAG = "generator"

var state: State = State.READY
var context: ExecutionContext
var vm: ShrimpVM
var lastValue: Variant

func _init(parenx: ExecutionContext, vmx: ShrimpVM) -> void:
	context = parenx
	vm = vmx
	context.tags[TAG] = self

func is_valid() -> bool:
	return state != State.DONE
func next() -> Variant:
	if state == State.DONE:
		return null
	elif state == State.READY:
		drive()
	else:
		resumed.emit()
	if state == State.PAUSED:
		return lastValue
	state = State.DONE
	return null
func suspend(data: Variant) -> Variant:
	lastValue = data
	state = State.PAUSED
	await resumed
	return data
func drive():
	await context.eventloop(vm)
	state = State.DONE

static func find(contexx: ExecutionContext) -> ShrimpGenerator:
	var current = contexx
	while is_instance_valid(current):
		var found = current.tags.get(TAG)
		if found is ShrimpGenerator:
			return found
		current = current.parent
	return null
