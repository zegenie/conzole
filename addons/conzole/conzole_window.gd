@tool

class_name ConzoleWindow
extends Control

const CONZOLE_GROUP = preload("res://addons/conzole/conzole_group.tscn")

signal filters_updated
signal clear_log

@onready var children_container: VBoxContainer = %ChildrenContainer
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var clear_button: Button = %ClearButton
@onready var filter_messages_error: Button = %FilterMessagesError
@onready var filter_messages_warning: Button = %FilterMessagesWarning
@onready var filter_messages_notice: Button = %FilterMessagesNotice
@onready var filter_messages_info: Button = %FilterMessagesInfo
@onready var filter_messages_message: Button = %FilterMessagesMessage
@onready var filter_messages_debug: Button = %FilterMessagesDebug
@onready var filter_messages_verbose: Button = %FilterMessagesVerbose
@onready var parking_lot_button: Button = %ParkingLotButton
@onready var filter_input: LineEdit = %FilterInput
@onready var parking_lot_container: MarginContainer = $VBoxContainer/HBoxContainer/ParkingLotContainer
@onready var parking_lot_group_container: VBoxContainer = %ParkingLotGroupContainer

const SETTINGS = {
    "SHOW_TIMESTAMPS": "show_timestamps",
    "MAX_GROUP_LINES": "max_group_lines",
    "MAX_LOG_LINES": "max_log_lines",
    "LOG_LEVELS": "log_levels",
}

var _settings = {
    SETTINGS.SHOW_TIMESTAMPS: true,
    SETTINGS.MAX_GROUP_LINES: 10,
    SETTINGS.MAX_LOG_LINES: 1000,
    SETTINGS.LOG_LEVELS: [
        ConzolePlugin.LogLevel.ERROR, 
        ConzolePlugin.LogLevel.WARN, 
        ConzolePlugin.LogLevel.NOTICE, 
        ConzolePlugin.LogLevel.MESSAGE, 
        ConzolePlugin.LogLevel.INFO
    ]
}

var filter_value := ''
var scroll_paused := false
var _base_group: ConzoleGroup
var _active_group: Array[ConzoleGroup] = []
var _is_booted := false
var _has_warned := false
var _timers = {}
var _counters = {}
var _watched_objects = []
var _parking_lot_group: ConzoleGroup

func _ready() -> void:
    # title = "Conzole v" + ConzolePlugin.VERSION
    scroll_container.get_v_scroll_bar().scrolling.connect(_sense_scroll_paused)
    clear_button.pressed.connect(_clear_log)
    filter_messages_debug.set_pressed_no_signal(_settings[SETTINGS.LOG_LEVELS].has(ConzolePlugin.LogLevel.DEBUG))
    filter_messages_debug.toggled.connect(func (_toggled_on: bool): _update_filters(ConzolePlugin.LogLevel.DEBUG, _toggled_on))
    filter_messages_error.set_pressed_no_signal(_settings[SETTINGS.LOG_LEVELS].has(ConzolePlugin.LogLevel.ERROR))
    filter_messages_error.toggled.connect(func (_toggled_on: bool): _update_filters(ConzolePlugin.LogLevel.ERROR, _toggled_on))
    filter_messages_info.set_pressed_no_signal(_settings[SETTINGS.LOG_LEVELS].has(ConzolePlugin.LogLevel.INFO))
    filter_messages_info.toggled.connect(func (_toggled_on: bool): _update_filters(ConzolePlugin.LogLevel.INFO, _toggled_on))
    filter_messages_message.set_pressed_no_signal(_settings[SETTINGS.LOG_LEVELS].has(ConzolePlugin.LogLevel.MESSAGE))
    filter_messages_message.toggled.connect(func (_toggled_on: bool): _update_filters(ConzolePlugin.LogLevel.MESSAGE, _toggled_on))
    filter_messages_notice.set_pressed_no_signal(_settings[SETTINGS.LOG_LEVELS].has(ConzolePlugin.LogLevel.NOTICE))
    filter_messages_notice.toggled.connect(func (_toggled_on: bool): _update_filters(ConzolePlugin.LogLevel.NOTICE, _toggled_on))
    filter_messages_warning.set_pressed_no_signal(_settings[SETTINGS.LOG_LEVELS].has(ConzolePlugin.LogLevel.WARN))
    filter_messages_warning.toggled.connect(func (_toggled_on: bool): _update_filters(ConzolePlugin.LogLevel.WARN, _toggled_on))
    filter_messages_verbose.set_pressed_no_signal(_settings[SETTINGS.LOG_LEVELS].has(ConzolePlugin.LogLevel.VERBOSE))
    filter_messages_verbose.toggled.connect(func (_toggled_on: bool): _update_filters(ConzolePlugin.LogLevel.VERBOSE, _toggled_on))
    filter_input.text_changed.connect(_update_text_filter)
    parking_lot_button.toggled.connect(_toggle_parking_lot)
    self.log(["Conzole", ConzoleFormattedText.message("v" + str(ConzolePlugin.VERSION)).bold(), "activated"])
    _parking_lot_group = CONZOLE_GROUP.instantiate() as ConzoleGroup
    _parking_lot_group._log_window_scene = self
    _parking_lot_group._group_key = "Watched objects"
    parking_lot_group_container.add_child(_parking_lot_group)
    _parking_lot_group.hide_header(0)
    _parking_lot_group.header_container.visible = true
    _parking_lot_group.set_pinned()
    _parking_lot_group.set_color("#ffd43b66")
    #_parking_lot_group.group("Watched objects", { "color": Color.TRANSPARENT, "pinned": true })

func _toggle_parking_lot(is_toggled: bool):
    parking_lot_container.visible = !parking_lot_container.visible

func _clear_log():
    _base_group.clear()

func _update_text_filter(new_text: String):
    filter_value = new_text
    
    #filters_updated.emit()
    _base_group.filter(_settings[ConzoleWindow.SETTINGS.LOG_LEVELS], filter_value)

func _update_filters(filter, value):
    if value && !_settings[SETTINGS.LOG_LEVELS].has(filter):
        _settings[SETTINGS.LOG_LEVELS].append(filter)
    elif !value:
        _settings[SETTINGS.LOG_LEVELS] = _settings[SETTINGS.LOG_LEVELS].filter(func (_value): return _value != filter)
    
    _base_group.filter(_settings[ConzoleWindow.SETTINGS.LOG_LEVELS], filter_value)
    filters_updated.emit()

func _sense_scroll_paused():
    var value = scroll_container.get_v_scroll_bar().value
    var max_value = scroll_container.get_v_scroll_bar().max_value
    var page = scroll_container.get_v_scroll_bar().page
    if !scroll_paused && value + page < max_value:
        scroll_paused = true
    elif value + page == max_value:
        scroll_paused = false

func scroll_to(log_item: Control):
    if !scroll_paused:
        scroll_container.ensure_control_visible(log_item)

func _log(msg, log_level: int = ConzolePlugin.LogLevel.INFO, group_key: String = ''):
    var _log_item = _get_active_group()._log(msg, log_level, group_key)
    await get_tree().process_frame
    scroll_to(_log_item)

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

func _get_active_group() -> ConzoleGroup:
    if !_base_group is ConzoleGroup:
        _base_group = CONZOLE_GROUP.instantiate() as ConzoleGroup
        _base_group._log_window_scene = self
        children_container.add_child(_base_group)
        _base_group.hide_header()
    
    if _active_group.size() == 0:
        _active_group.append(_base_group)
    
    return _active_group.back()

func watch(remote_object_id: int, remote_object_type: String, label: String = ''):
    if _watched_objects.has(remote_object_id):
        return
    
    var key_value_item = ConzoleKeyValueItem.CONZOLE_KEY_VALUE_ITEM.instantiate() as ConzoleKeyValueItem
    key_value_item._value = { "_conzole_remote_object_id": remote_object_id }
    key_value_item._is_watched = true
    if label != '':
        key_value_item._value._conzole_remote_object_label = '<%s>' % [remote_object_type]
        key_value_item._key = label
    else:
        key_value_item._key = '%s<%s>' % [remote_object_type, remote_object_id]
    _parking_lot_group.children_container.add_child(key_value_item)
    _watched_objects.append(remote_object_id)

func group(key: String = 'default', options: Dictionary = {}) -> ConzoleGroup:
    var _group = _get_active_group().group(key, options)
    if key == 'default':
        _active_group.append(_group)
        return _active_group.back()
    
    return _group

func groupEnd(key: String = 'default'):
    if _base_group._groups.has(key):
        _base_group._groups.erase(key)
    
    _active_group.pop_back()

func time(label: String = 'default'):
    if !_timers.has(label):
        _timers[label] = Time.get_ticks_msec()
    else:
        self.warn("Timer %s already exists" % label)

func timeLog(label: String = 'default'):
    if !_timers.has(label):
        self.warn("Timer %s doesn't exist" % label)
        return
    
    var elapsed_time = Time.get_ticks_msec() - _timers[label]
    self.log("%s: %sms" % [label, str(elapsed_time)])

func timeEnd(label: String = 'default'):
    if !_timers.has(label):
        self.warn("Timer %s doesn't exist" % label)
        return
    
    var elapsed_time = Time.get_ticks_msec() - _timers[label]
    self.log("%s: %sms - timer ended" % [label, str(elapsed_time)])
    _timers.erase(label)

func assertion(output_1: Variant, output_2: Variant = null):
    if output_1 is String:
        self.err(["Assertion failed:", output_1 % output_2])
    else:
        self.err(["Assertion failed:", output_1])

func count(label: String = 'default'):
    if !_counters.has(label):
        _counters[label] = 0
    
    _counters[label] += 1
    self.log("%s: %d" % [label, _counters[label]])

func countReset(label: String = 'default'):
    if !_counters.has(label):
        self.warn("Counter %s doesn't exist" % label)
        return
    
    _counters[label] = 0
    self.log("%s: %d" % [label, _counters[label]])

func reset():
    if _active_group:
        _active_group.clear()
    
    if _base_group && !_base_group.is_queued_for_deletion() && _base_group is ConzoleGroup:
        _base_group.clear()
        _base_group.queue_free()
        _base_group = null

func clear():
    if _base_group is ConzoleGroup:
        _base_group.clear()
        _base_group.queue_free()
        _base_group = null
    
    _active_group.clear()
    _parking_lot_group.clear(false)
