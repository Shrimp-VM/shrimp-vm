@tool
extends Node
class_name ShrimpPlugin

@export var category_colors: Dictionary[String, Color] = {}

var pluginName: String
var description: String
var author: String
var version: String

func _init(namx: String = "Unnamed Plugin", desc: String = "A plugin.", authox: String = "", versiox: String = "1.0.0") -> void:
	pluginName = namx
	description = desc
	author = authox
	version = versiox
