@tool

class_name ConzoleInstance
extends Node

var _log_window_scene: ConzoleWindow
var _base_group: ConzoleGroup
var _active_group: ConzoleGroup
var _is_booted := false
var _has_warned := false
var _timers = {}
var _counters = {}

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if OS.is_debug_build():
		enable()

func enable():
	#if _log_window_scene is ConzoleWindow:
		#return
	#
	#_log_window_scene = CONZOLE_WINDOW.instantiate() as ConzoleWindow
	#_log_window_scene.filters_updated.connect(_update_filters)
	#_log_window_scene.clear_log.connect(_clear_log)
	#get_viewport().set_embedding_subwindows(false)
	#get_tree().root.add_child.call_deferred(_log_window_scene)
	call_deferred("_boot")

func _clear_log():
	_base_group.clear()

func _update_filters():
	_base_group.filter(_log_window_scene._settings[ConzoleWindow.SETTINGS.LOG_LEVELS], _log_window_scene.filter_value)

func _boot():
	_is_booted = true

func _print_warning_if_needed():
	if !_has_warned:
		print_rich("[color=#ffec99]Warning: trying to use Conzole without being enabled. This message will only show once.[/color]")
		_has_warned = true

func _get_dictionary_from_object(_msg: Object) -> Dictionary:
	var dict = {}
	if _msg is Object:
		dict._conzole_remote_object_id = _msg.get_instance_id()
		dict._conzole_remote_object_type = _msg.get_class()
	
	for prop in _msg.get_property_list():
		var _val = _msg.get(prop.name)
		if _val is Object:
			dict[prop.name] = _get_dictionary_from_object(_val)
		elif _val is Dictionary:
			dict[prop.name] = _val
		else:
			dict[prop.name] = _val
	
	return dict

func _log(msg, log_level: int = ConzolePlugin.LogLevel.INFO, group_key: String = ''):
	var msgs = []
	if msg is Array:
		for _msg in msg:
			if _msg is ConzoleFormattedText:
				msgs.append(_msg.get_formatted_text())
			elif _msg is Object:
				msgs.append(_get_dictionary_from_object(_msg))
			else:
				msgs.append(_msg)
	elif msg is Object:
		msgs.append(_get_dictionary_from_object(msg))
	else:
		msgs.append(msg)

	EngineDebugger.send_message("conzole:log", [{ "msg": msgs, "log_level": log_level, "group_key": group_key }])
	#if !_is_booted:
		#_print_warning_if_needed()
		#return
	#
	#var _log_item = _get_active_group()._log(msg, log_level, group_key)
	#await get_tree().process_frame
	#_log_window_scene.scroll_to(_log_item)

func log(msg, group_key: String = ''):
	self._log(msg, ConzolePlugin.LogLevel.MESSAGE, group_key)

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

func group(key: String = 'default', options: Dictionary = {}):
	EngineDebugger.send_message("conzole:group", [{ "key": key, "options": options }])

func groupEnd(key: String = 'default'):
	EngineDebugger.send_message("conzole:groupEnd", [{ "key": key }])

func time(label: String = 'default'):
	EngineDebugger.send_message("conzole:time", [{ "label": label }])

func timeLog(label: String = 'default'):
	EngineDebugger.send_message("conzole:timeLog", [{ "label": label }])

func timeEnd(label: String = 'default'):
	EngineDebugger.send_message("conzole:timeEnd", [{ "label": label }])

func assertion(value: bool, output_1: Variant, output_2: Variant = null):
	if value:
		return
	
	EngineDebugger.send_message("conzole:assertion", [{ "output_1": output_1, "output_2": output_2 }])

func count(label: String = 'default'):
	EngineDebugger.send_message("conzole:count", [{ "label": label }])

func countReset(label: String = 'default'):
	EngineDebugger.send_message("conzole:countReset", [{ "label": label }])

func clear():
	EngineDebugger.send_message("conzole:clear", [])

func _self_test():
	self.log("Test", "test group 1")
	self.log("Test 2", "test group 2")
	self.log("Test 3", "test group 3/sub group 1")
	self.log("Test 2", "test group 3")
	self.groupEnd()
	self.warn("Test warning")
	self.err("Test error")
	self.debug("Test debug message")
	self.notice("Test notice")
	self.verbose("Test verbose message")
	self.group()
	self.log("Grouped message 1")
	self.group()
	self.log("Grouped message 2")
	self.groupEnd()
	self.log("Grouped message 1")
	self.groupEnd()
	var test_panel = PanelContainer.new()
	var msg = ConzoleFormattedText.message("test").bold()
	self.log(msg)
	self.log([msg, test_panel])
	self.log({ "dictionary_key_1": "one", "dictionary_key_2": 1, "dictionary_key_3": false, "dictionary_key_4": ["one", "two", "three"], "dictionary_key_5": { "object_key_1": 1, "object_key_2": Vector2(1, 1) } })
	self.time()
	await get_tree().create_timer(.26).timeout
	self.timeLog()
	self.timeEnd()
	self.count()
	self.count()
	self.countReset()
	self.countReset("bob")
	self.assertion(false, "%s failed", ["test"])
	self.assertion(true, ["test"])
	self.assertion(false, {"error": "test failed"})
