@tool

class_name ConzoleLogItem
extends PanelContainer

const ICON_DEBUG = preload("res://addons/conzole/icon_debug.svg")
const ICON_ERROR = preload("res://addons/conzole/icon_error.svg")
const ICON_INFO = preload("res://addons/conzole/icon_info.svg")
const ICON_NOTICE = preload("res://addons/conzole/icon_notice.svg")
const ICON_VERBOSE = preload("res://addons/conzole/icon_verbose.svg")
const ICON_WARNING = preload("res://addons/conzole/icon_warning.svg")

const CONZOLE_KEY_VALUE_ITEM = preload("res://addons/conzole/conzole_key_value_item.tscn")

var _log_level: int
var _formatted_text: String
var _timestamp: String
var _expanded_vars: Dictionary = {}

static var styleboxes
static var colors

@onready var log_line: RichTextLabel = %LogLine
@onready var log_timestamp: RichTextLabel = %LogTimestamp
@onready var log_icon: TextureRect = %LogIcon
@onready var children_container: VBoxContainer = %ChildrenContainer

func log(_message, log_level: int = ConzolePlugin.LogLevel.INFO, recursed := false):
	_log_level = log_level
	var current_timestamp = Time.get_unix_time_from_system()
	var msec = str(current_timestamp).get_slice(".", 1).substr(0, 3)
	_timestamp = Time.get_time_string_from_system() + "." + msec
	if !recursed && _message is Array:
		for _message_item in _message:
			self.log(_message_item, log_level, true)
	else:
		_do_log(_message, log_level)
	
	_show_text()

func _do_log(_text, log_level: int):
	if _text is ConzoleFormattedText:
		_formatted_text += _text.get_formatted_text() + " "
	else:
		if _text is Object || _text is Dictionary:
			var key_value_item = CONZOLE_KEY_VALUE_ITEM.instantiate() as ConzoleKeyValueItem
			if _text is Object:
				key_value_item._key = '(Object)'
			elif _text.has("_conzole_remote_object_id"):
				key_value_item._key = 'Remote %s<%s>' % [str(_text.get("_conzole_remote_object_type")), str(_text.get("_conzole_remote_object_id"))]
			else:
				key_value_item._key = "{Dictionary}"
			key_value_item._value = _text
			children_container.add_child(key_value_item)
			_text = ConzoleFormattedText.message(str(key_value_item._key)).bold()
		else:
			_text = ConzoleFormattedText.message(_text)
		_formatted_text += _text.level(log_level).get_formatted_text() + " "

	#elif log_level != ConzolePlugin.LogLevel.MESSAGE:
		#_formatted_text += ConzoleFormattedText.stringify(_text) + " "

func _get_stylebox_with_color(_color: String):
	var _applied_color = Color.from_string(_color, Color.SEA_GREEN)
	
	var style_box = get_theme_stylebox("panel", "PanelContainer").duplicate()
	style_box.set("bg_color", _applied_color)
	
	return style_box

func _set_colors():
	if ConzoleLogItem.styleboxes is Dictionary:
		return
	
	styleboxes = {
		ConzolePlugin.LogLevel.WARN: _get_stylebox_with_color("#ffe0667a"),
		ConzolePlugin.LogLevel.ERROR: _get_stylebox_with_color("#ff87877a")
	}
	
	colors = {
		ConzolePlugin.LogLevel.WARN: Color.from_string("#e9ecef", Color.WHITE)
	}

func _show_text():
	#if Conzole._log_window_scene._settings[ConzoleWindow.SETTINGS.SHOW_TIMESTAMPS]:
	log_timestamp.text = "[" + _timestamp + "]"
	log_timestamp.visible = true
	#else:
		#log_timestamp.visible = false
	
	if _log_level != ConzolePlugin.LogLevel.MESSAGE:
		match _log_level:
			ConzolePlugin.LogLevel.INFO:
				log_icon.texture = ICON_INFO
			ConzolePlugin.LogLevel.WARN:
				log_icon.texture = ICON_WARNING
				_set_colors()
				log_line.add_theme_color_override("default_color", ConzoleLogItem.colors[ConzolePlugin.LogLevel.WARN])
				add_theme_stylebox_override("panel", ConzoleLogItem.styleboxes[ConzolePlugin.LogLevel.WARN])
			ConzolePlugin.LogLevel.ERROR:
				log_icon.texture = ICON_ERROR
				_set_colors()
				add_theme_stylebox_override("panel", ConzoleLogItem.styleboxes[ConzolePlugin.LogLevel.ERROR])
			ConzolePlugin.LogLevel.NOTICE:
				log_icon.texture = ICON_NOTICE
			ConzolePlugin.LogLevel.DEBUG:
				log_icon.texture = ICON_DEBUG
			ConzolePlugin.LogLevel.VERBOSE:
				log_icon.texture = ICON_VERBOSE
	
	log_line.text = _formatted_text

func filter(log_levels: Array, filter_value: String) -> bool:
	var _visible = true
	if !log_levels.has(_log_level):
		_visible = false
	if _visible && filter_value != '':
		if !_formatted_text.containsn(filter_value):
			_visible = false
	
	visible = _visible
	return visible
