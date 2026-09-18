extends RefCounted
class_name WrapperPath

const CLASSPATH = "."

enum PartType {
	ATTRIBUTE,
	INDEX,
	PARENT,
	SELF,
	ROOT
}

var type: PartType = PartType.ATTRIBUTE
var path = ""
var next: WrapperPath
var parent: WrapperPath

func _init(typx: PartType, patx = null, nexx: WrapperPath = null, parenx: WrapperPath = null) -> void:
	type = typx
	path = patx
	reparent(parenx)
	renext(nexx)
func _to_string() -> String:
	var result
	match type:
		PartType.ATTRIBUTE:
			result = "%s" % path
		PartType.INDEX:
			result = "[%d]" % path
		PartType.PARENT:
			result = "<"
		PartType.SELF:
			result = "#"
		PartType.ROOT:
			result = "/"
	if is_instance_valid(next):
		return "%s%s%s" % [result, CLASSPATH, next]
	else:
		return result

func reparent(parenx: WrapperPath):
	parent = parenx
	if is_instance_valid(parent):
		parent.next = self
func renext(nexx: WrapperPath):
	next = nexx
	if is_instance_valid(next):
		next.parent = self
func normalize() -> WrapperPath:
	var childrens: Array[WrapperPath] = []
	var rootPath: WrapperPath = seek_root()
	while is_instance_valid(rootPath):
		var current: WrapperPath = rootPath
		rootPath = rootPath.next
		current.next = null
		current.parent = null
		match current.type:
			PartType.PARENT:
				if not childrens.is_empty() && childrens[-1].type in [PartType.ATTRIBUTE, PartType.INDEX]:
					childrens.pop_back()
				else:
					childrens.append(current)
			PartType.SELF:
				pass
			_:
				childrens.append(current)
	if childrens.is_empty():
		return WrapperPath.new(PartType.SELF)
	for i in range(1, len(childrens)):
		childrens[i - 1].renext(childrens[i])
	childrens[0].parent = null
	return childrens[0]
func seek_parent(types: Array[PartType]) -> WrapperPath:
	if is_instance_valid(parent):
		if parent.type in types:
			return parent
		else:
			return parent.seek_parent(types)
	else:
		return null
func seek_root() -> WrapperPath:
	if is_instance_valid(parent):
		return parent.seek_root()
	else:
		return self
func duplicate(deep: bool = false) -> WrapperPath:
	return WrapperPath.new(
		type,
		path,
		next.duplicate(deep) if deep && is_instance_valid(next) else next,
		parent
	)
func concat(child: WrapperPath) -> WrapperPath:
	if child.type == PartType.ROOT:
		return child.duplicate()
	if is_instance_valid(next):
		return next.concat(child)
	else:
		renext(child)
	return self

static func from(classpath: String) -> WrapperPath:
	var result = WrapperPath.new(PartType.SELF)
	var parts = classpath.split(CLASSPATH)
	for part in parts:
		match part:
			"/":
				result = WrapperPath.new(PartType.ROOT)
			"<":
				result.concat(WrapperPath.new(PartType.PARENT))
			"#":
				result.concat(WrapperPath.new(PartType.SELF))
			var index when index.begins_with("[") && index.ends_with("]"):
				var i = int(index.substr(1, index.length() - 2))
				result.concat(WrapperPath.new(PartType.INDEX, i))
			var attribute:
				result.concat(WrapperPath.new(PartType.ATTRIBUTE, attribute))
	return result
