@tool
extends Node
class_name ShrimpPluginManager

static var instance: ShrimpPluginManager

@export var defaultColor: Color = Color.BROWN

func _ready() -> void:
	instance = self

static func get_plugins() -> Array[ShrimpPlugin]:
	var result: Array[ShrimpPlugin] = []
	result.assign(instance.get_children())
	return result
static func shade_category(category: String) -> Color:
	for plugin in get_plugins():
		if plugin.categoryColors.has(category):
			return plugin.categoryColors[category]
	return instance.defaultColor
