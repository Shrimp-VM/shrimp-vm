@tool
extends Control
class_name ItemEditor

signal updated(newData: Array)

@export var itemType: Variant.Type = TYPE_FLOAT

@onready var addBtn: Button = $%addBtn
@onready var itemsWrapper: Control = $%wrapper
var bannedItem: EditableItem

func _ready() -> void:
	addBtn.pressed.connect(func(): add_item(create_initial_value(itemType)))

func add_item(value):
	var instance = preload("res://addons/shrimpvm/scenes/editable_item.tscn").instantiate() as EditableItem
	if !is_instance_valid(itemsWrapper):
		itemsWrapper = get_node("%wrapper")
	itemsWrapper.add_child(instance)
	instance.set_content(itemType, value)
	instance.deleted.connect(
		func():
			bannedItem = instance
			instance.queue_free()
			update_emit()
			bannedItem = null
	)
	instance.updated.connect(func(_d): update_emit())
	update_emit()
func set_data(items: Array):
	for item in items:
		add_item(item)
func get_data() -> Array:
	return (
		itemsWrapper
		.get_children()
		.filter(func(e): return e != bannedItem)
		.map(func(e: EditableItem): return extract_value(itemType, e.get_content()))
	)
func rebuild():
	var i = 0
	for child in itemsWrapper.get_children():
		if child == bannedItem: continue
		if child is EditableItem:
			child.index = i
			child.rebuild()
			i += 1
func update_emit():
	updated.emit(get_data())
	rebuild()

static func extract_value(type: Variant.Type, node: Control) -> Variant:
	match type:
		TYPE_STRING, TYPE_STRING_NAME:
			if node is TextEdit:
				return node.text
			elif node is LineEdit:
				return node.text
		TYPE_FLOAT:
			if node is LineEdit:
				if node.text.is_valid_float():
					return node.text.to_float()
		TYPE_BOOL:
			if node is CheckButton:
				return node.button_pressed
	return null
static func create_editbox(type: Variant.Type, value: Variant, update: Callable = func(_e): return ) -> Control:
	match type:
		TYPE_STRING:
			var input = TextEdit.new()
			input.custom_minimum_size = Vector2i(200, 100)
			input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
			input.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			input.text = str(value)
			input.text_changed.connect(func(): update.call(input.text))
			return input
		TYPE_STRING_NAME:
			var input = LineEdit.new()
			input.custom_minimum_size.x = 100
			input.text = str(value)
			input.text_changed.connect(update)
			return input
		TYPE_FLOAT:
			var input = LineEdit.new()
			input.custom_minimum_size = Vector2i(300, 30)
			input.text = "%s" % (value)
			input.text_changed.connect(
				func(new: String):
					if new.is_valid_float():
						update.call(new.to_float())
			)
			return input
		TYPE_BOOL:
			var check = CheckButton.new()
			check.button_pressed = value
			check.toggled.connect(update)
			return check
		_:
			return null
static func create_initial_value(type: Variant.Type):
	match type:
		TYPE_STRING, TYPE_STRING_NAME:
			return "Empty string"
		TYPE_FLOAT:
			return 0
		TYPE_BOOL:
			return false
		_:
			return null
