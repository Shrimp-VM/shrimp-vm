@tool
extends Node
class_name ShrimpTranslator

static var instance: ShrimpTranslator

func _ready() -> void:
	instance = self

static func translate(key: String, default: String = ""):
	var text = instance.tr(key)
	if text == key:
		return default
	else:
		return text
static func read_ir_schema(ir: ShrimpIR, attribute: String) -> String:
	return translate("shrimpvm.ir.%s.%s" % [ir.get_node_type(), attribute], ir.get_wrapper_schema().get(attribute, "Failed to translate."))
static func get_ir_name(ir: ShrimpIR) -> String:
	return read_ir_schema(ir, "name")
static func get_ir_description(ir: ShrimpIR) -> String:
	return read_ir_schema(ir, "description")
static func get_attribute_label(ir: ShrimpIR, attribute: String) -> String:
	return translate("shrimpvm.ir.%s.param.%s.label" % [ir.get_node_type(), attribute], ir.get_wrapper_schema().attributes[attribute].label)
static func get_category(category: String) -> String:
	return translate("shrimpvm.category.%s" % category, category)
