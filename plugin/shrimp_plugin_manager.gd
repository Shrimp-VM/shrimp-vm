@tool
extends Node
class_name ShrimpPluginManager

static var instance: ShrimpPluginManager
static var savedDefaultColor: Color

@export var defaultColor: Color = Color.BROWN

func _ready() -> void:
	instance = self
	savedDefaultColor = defaultColor

static func get_plugins() -> Array[ShrimpPlugin]:
	if is_instance_valid(instance):
		var result: Array[ShrimpPlugin] = []
		result.assign(instance.get_children())
		return result
	else:
		return []
static func shade_category(category: String) -> Color:
	for plugin in get_plugins():
		if plugin.categoryColors.has(category):
			return plugin.categoryColors[category]
	return savedDefaultColor
