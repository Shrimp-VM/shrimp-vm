extends RefCounted
class_name ShrimpPlugin

const DEFAULT_COLOR = Color.RED

static var plugins: Array[ShrimpPlugin] = []

var name: String
var description: String
var author: String
var version: String

func _init(namx: String = "Unnamed Plugin", desc: String = "A plugin.", authox: String = "", versiox: String = "1.0.0") -> void:
	name = namx
	description = desc
	author = authox
	version = versiox

func category_colors() -> Dictionary[String, Color]:
	return {}

static func shade_category(category: String) -> Color:
	for plugin in plugins:
		var map = plugin.category_colors()
		if map.has(category):
			return map.get(category, DEFAULT_COLOR)
	return DEFAULT_COLOR
