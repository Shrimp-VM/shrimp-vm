@tool
class_name ShrimpCompiler

const IMPORTER_ID = "shrimpvm.shrimpir"

func _init() -> void:
	assert(false, "Don't instantiate ShrimpCompiler!!!")

static func import_file(source: String) -> ShrimpIR:
	var file = FileAccess.open(source, FileAccess.ModeFlags.READ)
	if file == null:
		push_error("Failed to read file.")
		return null
	return import_json(file.get_as_text())
static func import_json(text: String) -> ShrimpIR:
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		push_error("Failed to parse json data.")
		return null
	return import_data(json.data)
static func import_data(data: Variant) -> ShrimpIR:
	if data is Dictionary:
		var first = compile(data)
		if !first:
			push_error("IR-Node compilation failed.")
			return null
		if first.get_node_type() != ShrimpRootNode.get_node_type():
			push_error("Must start with a root node.")
			return null
		return first
	else:
		push_error("First node must be a dictionary.")
		return null
static func compile(from: Variant, optimize: bool = false, warnSignal = null) -> ShrimpIR:
	if from is not Dictionary:
		push_error("Can only compile #wrapper dictionary# to IR-Node.")
		return null
	if !from:
		push_error("Cannot compile null to IR-Node.")
		return null
	if from.get("invalid", false):
		# deleted by user, skip
		return null
	for node in ShrimpVMUtil.get_ir_nodes():
		if node == null:
			push_warning("Failed to load node script: %s." % node)
			continue
		if node.get_node_type() == from.type:
			var result = node.create_from(from)
			if result is not ShrimpIR:
				push_error("Broken node %s: not created an IR-Node." % node)
				return null
			if optimize:
				var optimizer = ShrimpOptimizer.new(result)
				if warnSignal is Signal:
					optimizer.warning.connect(warnSignal.emit)
				return optimizer.optimize()
			else:
				return result
	push_error("Unknown IR-Node type: %s." % from.type)
	return null
static func compile_body(from: Array, optimize: bool = true) -> Array[ShrimpIR]:
	var result: Array[ShrimpIR] = []
	for wrapper in from:
		result.append(compile(wrapper, optimize))
	return result
static func decompile(from: ShrimpIR) -> Dictionary:
	return {"type": from.get_node_type()}.merged(from.decompile(), true)
static func decompile_body(from: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for ir in from:
		if ir is ShrimpIR:
			result.append(decompile(ir))
	return result
