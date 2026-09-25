@tool
extends Node
class_name ShrimpPluginManager

const FRAME_OUTSIDE_TREE = 60

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
static func try_edit(type: int) -> ShrimpTypeEditor:
	for plugin in get_plugins():
		for child in plugin.get_children():
			if child is ShrimpTypeEditor:
				if type in child.get_type_id():
					return child
	return null
static func frame():
	if is_instance_valid(instance):
		if instance.is_inside_tree():
			return instance.get_tree().process_frame
	return SceneTree.new().create_timer(1.0 / FRAME_OUTSIDE_TREE).timeout
