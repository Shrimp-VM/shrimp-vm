@tool
extends Control
class_name ItemEditor

signal updated(newData: Array)

@export var itemType: int = TYPE_FLOAT

@onready var addBtn: Button = $%addBtn
@onready var clearBtn: Button = $%clearBtn
@onready var itemsWrapper: Control = $%wrapper
@onready var emptyTip: Label = $%emptyTip
var bannedItem: EditableItem

func _ready() -> void:
	addBtn.pressed.connect(func(): add_item(type_editor().create_initial_value()))
	clearBtn.pressed.connect(clear)
func type_editor() -> ShrimpTypeEditor:
	return ShrimpPluginManager.try_edit(itemType)

func clear():
	ShrimpVMUtil.disconnect_children(itemsWrapper)
	update_emit()
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
	var editor = type_editor()
	return (
		itemsWrapper
			.get_children()
			.filter(func(e): return e != bannedItem)
			.map(func(e: EditableItem): return editor.extract_from(e.get_content()))
	)
func rebuild():
	var i = 0
	for child in itemsWrapper.get_children():
		if child == bannedItem: continue
		if child is EditableItem:
			child.index = i
			child.rebuild()
			i += 1
	if !is_instance_valid(emptyTip):
		emptyTip = get_node("%emptyTip")
	emptyTip.visible = i <= 0
func update_emit():
	updated.emit(get_data())
	rebuild()

static func extract_value(type: int, node: Control) -> Variant:
	var editor = ShrimpPluginManager.try_edit(type)
	return editor.extract_from(node) if editor else null
static func create_showbox(type: int, value: Variant) -> Control:
	var editor = ShrimpPluginManager.try_edit(type)
	return editor.create_showbox(value) if editor else null
static func create_editbox(type: int, value: Variant, update: Callable = func(_e): return ) -> Control:
	var editor = ShrimpPluginManager.try_edit(type)
	return editor.create_editbox(value, update) if editor else null
static func create_initial_value(type: int) -> Variant:
	var editor = ShrimpPluginManager.try_edit(type)
	return editor.create_initial_value() if editor else null
static func create(type: int, initialData: Array, update: Callable = func(_e): return ):
	var editor = preload("res://addons/shrimpvm/scenes/item_editor.tscn").instantiate() as ItemEditor
	editor.itemType = type
	editor.updated.connect(update)
	editor.set_data(initialData)
	return editor
