extends RefCounted
class_name ShrimpAsyncTask

enum TaskState {
	RESOLVED,
	REJECTED,
	PENDING
}

signal resolved(result)
signal rejected(reason)
signal stateChanged(data)

var state: TaskState = TaskState.PENDING
var data: Variant = null

func _init(executor: Callable) -> void:
	executor.call(
		func(result):
			state = TaskState.RESOLVED
			data = result
			resolved.emit(result)
			stateChanged.emit(result)
			,
		func(reason):
			state = TaskState.REJECTED
			data = reason
			rejected.emit(reason)
			stateChanged.emit(reason)
	)

func pipe():
	match state:
		TaskState.PENDING:
			return stateChanged
		TaskState.REJECTED, TaskState.RESOLVED:
			return data
