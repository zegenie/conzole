@tool

class_name ConzoleGroup
extends Control

const CONZOLE_LOG_ITEM = preload("res://addons/conzole/conzole_log_item.tscn")
const CONZOLE_GROUP = preload("res://addons/conzole/conzole_group.tscn")

@onready var expand_button: Button = %ExpandButton
@onready var clear_button: Button = %ClearButton
@onready var remove_button: Button = %RemoveButton
@onready var title: Label = %Title
@onready var children_container: VBoxContainer = %ChildrenContainer
@onready var header_container: PanelContainer = %HeaderContainer
@onready var margin_container: MarginContainer = %MarginContainer

var _expanded := true
var _group_key: String
var _groups = {}
var _active_group: ConzoleGroup
var _parent_group: ConzoleGroup
var _max_lines
var _can_hide := true
var _log_window_scene: ConzoleWindow

func _ready() -> void:
	title.text = _group_key if _group_key != 'default' else ''
	clear_button.pressed.connect(func (): clear())
	expand_button.pressed.connect(func (): toggle())
	if _can_hide:
		remove_button.pressed.connect(_remove_group)
	else:
		remove_button.visible = false
	_update_toggle()

func _remove_group():
	_parent_group._groups.erase(_group_key)
	queue_free()

func _log(_messages, log_level: int, group_key: String = '') -> ConzoleLogItem:
	if group_key != '':
		var group_keys = group_key.split('/', true, 1)
		group_key = group_keys[0]
		if !_groups.has(group_key):
			group(group_key, {}, false)
		
		return _groups[group_key]._log(_messages, log_level, group_keys[1] if group_keys.size() > 1 else '')
	
	var _log_item = _add_log_item()
	_log_item.log(_messages, log_level)
	
	var applied_max_lines: int
	if _max_lines != null:
		applied_max_lines = _max_lines as int
	elif header_container.visible:
		applied_max_lines = _log_window_scene._settings[ConzoleWindow.SETTINGS.MAX_GROUP_LINES]
	else:
		applied_max_lines = _log_window_scene._settings[ConzoleWindow.SETTINGS.MAX_LOG_LINES]
	
	if applied_max_lines is int && applied_max_lines > 0:
		if children_container.get_child_count() > applied_max_lines:
			var _children = children_container.get_children()
			_children.reverse()
			var _log_items = 0
			var _remove_items = []
			for _child in _children:
				if _child is ConzoleLogItem:
					if _log_items < applied_max_lines:
						_log_items += 1
					else:
						_remove_items.append(_child)
			for _child in _remove_items:
				children_container.remove_child(_child)
		
	return _log_item

func log(_messages, group_key: String = '') -> ConzoleLogItem:
	return _log(_messages, ConzolePlugin.LogLevel.MESSAGE, group_key)

func info(msg, group_key: String = ''):
	self._log(msg, ConzolePlugin.LogLevel.INFO, group_key)

func warn(msg, group_key: String = ''):
	self._log(msg, ConzolePlugin.LogLevel.WARN, group_key)

func debug(msg, group_key: String = ''):
	self._log(msg, ConzolePlugin.LogLevel.DEBUG, group_key)

func err(msg, group_key: String = ''):
	self._log(msg, ConzolePlugin.LogLevel.ERROR, group_key)

func notice(msg, group_key: String = ''):
	self._log(msg, ConzolePlugin.LogLevel.NOTICE, group_key)

func verbose(msg, group_key: String = ''):
	self._log(msg, ConzolePlugin.LogLevel.VERBOSE, group_key)

func set_max_lines(value: int):
	_max_lines = value

func set_pinned():
	remove_button.visible = false

func set_color(_color: Variant):
	if _color is String:
		_color = Color.from_string(_color, Color.SEA_GREEN)
	
	var style_box = header_container.get_theme_stylebox("panel", "PanelContainer").duplicate()
	style_box.set("bg_color", _color)
	style_box.set("border_width_left", 0)
	header_container.add_theme_stylebox_override("panel", style_box)

func clear(include_groups := true):
	for child in children_container.get_children():
		if child is ConzoleGroup && include_groups:
			children_container.remove_child(child)
		elif child is ConzoleLogItem:
			children_container.remove_child(child)

func group(key: String = 'default', options: Dictionary = {}, set_active := true) -> ConzoleGroup:
	var _group: ConzoleGroup
	var group_key: String = ''
	var group_keys: Array = []
	if key.contains('/'):
		group_keys = key.split('/', true, 1)
		group_key = group_keys[0]
		set_active = false
	else:
		group_key = key
	
	if !_groups.has(group_key):
		_group = CONZOLE_GROUP.instantiate() as ConzoleGroup
		_group._log_window_scene = _log_window_scene
		_group._group_key = group_key
		_group._parent_group = self
		_groups[group_key] = _group
		children_container.add_child(_group)
	else:
		_group = _groups[group_key]
	
	if options.has("color"):
		_group.set_color(options.color)
	if options.has("pinned"):
		_group.set_pinned()
	
	if group_keys.size() > 1:
		return _group.group(group_keys[1], options)
	
	if set_active:
		_active_group = _group
	
	return _group

func addGroup(key: String, options: Dictionary = {}) -> ConzoleGroup:
	var _group = group(key, options, false)
	return _group

func groupEnd():
	_active_group = self

func _add_log_item() -> ConzoleLogItem:
	var _log_item = CONZOLE_LOG_ITEM.instantiate() as ConzoleLogItem
	children_container.add_child(_log_item)
	_log_item.filter(_log_window_scene._settings[ConzoleWindow.SETTINGS.LOG_LEVELS], _log_window_scene.filter_value)
	return _log_item

func hide_header(margins = 8):
	header_container.visible = false
	margin_container.add_theme_constant_override("margin_left", margins)
	margin_container.add_theme_constant_override("margin_right", margins)

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

func filter(log_levels: Array, filter_value: String) -> int:
	var visible_messages = 0
	for child in children_container.get_children():
		if child is ConzoleGroup:
			var child_visible_messages = child.filter(log_levels, filter_value)
			if child_visible_messages > 0:
				visible_messages += child.filter(log_levels, filter_value)
		elif child is ConzoleLogItem:
			if child.filter(log_levels, filter_value):
				visible_messages += 1
	
	visible = visible_messages > 0
	return visible_messages
