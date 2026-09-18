@tool
extends Node
class_name ShrimpPluginManager

const DEFAULT_COLOR = Color.RED

static var instance: ShrimpPluginManager

func _ready() -> void:
	instance = self

static func get_plugins() -> Array[ShrimpPlugin]:
	var result: Array[ShrimpPlugin] = []
	result.assign(instance.get_children())
	return result
static func shade_category(category: String) -> Color:
	for plugin in get_plugins():
		if plugin.category_colors.has(category):
			return plugin.category_colors.get(category, DEFAULT_COLOR)
	return DEFAULT_COLOR
