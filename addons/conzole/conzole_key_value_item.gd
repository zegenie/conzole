@tool

class_name ConzoleKeyValueItem
extends Control

const CONZOLE_KEY_VALUE_ITEM = preload("res://addons/conzole/conzole_key_value_item.tscn")

@onready var expand_button: Button = %ExpandButton
@onready var remove_button: Button = %RemoveButton
@onready var inspect_button: Button = %InspectButton
@onready var title: Label = %Title
@onready var value: Label = %Value
@onready var children_container: VBoxContainer = %ChildrenContainer
@onready var header_container: PanelContainer = %HeaderContainer
@onready var margin_container: MarginContainer = %MarginContainer

var _expanded := false
@export var _key: Variant = null
@export var _value: Variant = null
@export var _parent_item: ConzoleKeyValueItem = null

func objectify():
	if _value is Dictionary:
		expand_button.visible = true
		for dict_key in _value:
			if ["_conzole_remote_object_id", "_conzole_remote_object_type"].has(dict_key):
				continue
			
			var key_value_item = CONZOLE_KEY_VALUE_ITEM.instantiate() as ConzoleKeyValueItem
			key_value_item._key = dict_key
			key_value_item._value = _value[dict_key]
			key_value_item._parent_item = self
			children_container.add_child(key_value_item)
	elif _value is Object:
		expand_button.visible = true
		for prop in _value.get_property_list():
			var key_value_item = CONZOLE_KEY_VALUE_ITEM.instantiate() as ConzoleKeyValueItem
			key_value_item._key = prop.name
			key_value_item._value = _value.get(prop.name)
			key_value_item._parent_item = self
			children_container.add_child(key_value_item)
	
	if (_value is String || _value is StringName) && _value == '':
		value.text = "(Empty string)"
	elif _value is Dictionary:
		if _value.has("_conzole_remote_object_id"):
			value.text = '%s<%s>' % [str(_value.get("_conzole_remote_object_type")), str(_value.get("_conzole_remote_object_id"))]
		else:
			value.text = "{Dictionary}"
	else:
		value.text = str(_value)

	if expand_button.visible:
		expand_button.pressed.connect(func (): toggle())
	if !_parent_item is ConzoleKeyValueItem:
		remove_button.visible = true
		remove_button.pressed.connect(_remove_item)
	else:
		remove_button.visible = false
	
	if _value is Object:
		inspect_button.visible = true
		inspect_button.pressed.connect(_inspect_value)
	else:
		inspect_button.visible = false
	_update_toggle()

func _ready() -> void:
	title.text = str(_key) + ":"
	expand_button.visible = false
	objectify()

func _inspect_value():
	var val = _value as Object
	EditorInterface.get_inspector().object_id_selected.emit(val.get_instance_id())

func _remove_item():
	queue_free()

func toggle():
	_expanded = !_expanded
	_update_toggle()

func expand():
	_expanded = true
	_update_toggle()

func collapse():
	_expanded = false
	_update_toggle()

func _update_toggle():
	children_container.visible = _expanded
	expand_button.pivot_offset = expand_button.size / 2
	if _expanded:
		expand_button.rotation_degrees = 0
	else:
		expand_button.rotation_degrees = -90
