@tool
extends RefCounted
class_name ShrimpAttributeDescriptor

enum PermissonAccess {
	PRIVATE,
	PUBLIC,
	PROTECTED
}

var permisson: PermissonAccess = PermissonAccess.PUBLIC
var currentValue = null

func duplicate() -> ShrimpAttributeDescriptor:
	var result = ShrimpAttributeDescriptor.new()
	result.permisson = permisson
	result.currentValue = currentValue
	return result
