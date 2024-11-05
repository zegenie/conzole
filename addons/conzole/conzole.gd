@tool
class_name ConzoleInstance
extends Node
## Conzole developer console, inspired by the browser developer console
##
## Allows rich logging output with support for grouping, formatting and
## variable watching. 
## 
## [b]Important:[/b] This class is referenced using the global autoloaded singleton [code]Conzole[/code]
## Internally, these are in the [ConzoleInstance] class, but when used in your code you should
## always use the [code]Conzole[/code] class name.
##
## @tutorial: https://github.com/zegenie/conzole/blob/master/README.md

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

## Flags the plugin as enabled. Automatically triggered if a debug build is detected
func enable():
    call_deferred("_boot")

func _boot():
    _is_booted = true

func _get_dictionary_from_object(_msg: Object, _processed_objects = []) -> Dictionary:
    var dict = {}
    if _msg is Object:
        dict._conzole_remote_object_id = _msg.get_instance_id()
        dict._conzole_remote_object_type = _msg.get_class()
    
    for prop in _msg.get_property_list():
        var _val = _msg.get(prop.name)
        if _val is Object:
            if !_processed_objects.has(_val.get_instance_id()):
                _processed_objects.append(_val.get_instance_id())
                dict[prop.name] = _get_dictionary_from_object(_val, _processed_objects)
            else:
                dict[prop.name] = {
                    "_conzole_remote_object_id": _val.get_instance_id(),
                    "_conzole_remote_object_type": _val.get_class()
                }
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

## Logs a message to the conzole window with loglevel [constant ConzolePlugin.LogLevel.MESSAGE]
## [param [group_key]] Optional log group
func log(msg, group_key: String = ''):
    self._log(msg, ConzolePlugin.LogLevel.MESSAGE, group_key)

## Logs a message to the conzole window with loglevel [constant ConzolePlugin.LogLevel.INFO]
## [param [group_key]] Optional log group
func info(msg, group_key: String = ''):
    self._log(msg, ConzolePlugin.LogLevel.INFO, group_key)

## Logs a message to the conzole window with loglevel [constant ConzolePlugin.LogLevel.WARNING]
## [param [group_key]] Optional log group
func warn(msg, group_key: String = ''):
    self._log(msg, ConzolePlugin.LogLevel.WARN, group_key)

## Logs a message to the conzole window with loglevel [constant ConzolePlugin.LogLevel.DEBUG]
## [param [group_key]] Optional log group
func debug(msg, group_key: String = ''):
    self._log(msg, ConzolePlugin.LogLevel.DEBUG, group_key)

## Logs a message to the conzole window with loglevel [constant ConzolePlugin.LogLevel.ERROR]
## [param [group_key]] Optional log group
func err(msg, group_key: String = ''):
    self._log(msg, ConzolePlugin.LogLevel.ERROR, group_key)

## Logs a message to the conzole window with loglevel [constant ConzolePlugin.LogLevel.NOTICE]
## [param [group_key]] Optional log group
func notice(msg, group_key: String = ''):
    self._log(msg, ConzolePlugin.LogLevel.NOTICE, group_key)

## Logs a message to the conzole window with loglevel [constant ConzolePlugin.LogLevel.VERBOSE]
## [param [group_key]] Optional log group
func verbose(msg, group_key: String = ''):
    self._log(msg, ConzolePlugin.LogLevel.VERBOSE, group_key)

## Creates or updates a group with the path [param key], defaults to an empty group name
## If no group key is specified, the current active group will be set to this new group.
## With an active group, any log messages or new group calls will be added inside this group.
##
## To end an active group, use [method ConzoleInstance.groupEnd]
##
## [param [options]] Optional dictionary of options to pass
## [param options.color] Set the group header color to any valid [Color]
## [param options.pinned] If [code]true[/code], pins the group so it's not removed when the conzole is cleared
## [param options.max_lines] Specify a max number of lines to show in this group
func group(key: String = 'default', options: Dictionary = {}):
    EngineDebugger.send_message("conzole:group", [{ "key": key, "options": options }])

## Ends the currently active group, or the group specified with the [param key] parameter
## If you start a new group with the same key later, it will not reuse the old group
func groupEnd(key: String = 'default'):
    EngineDebugger.send_message("conzole:groupEnd", [{ "key": key }])

## Starts a timer that can be used to track elapsed time
## [param [label]] Optional label identifying the timer, which can be re-used later
func time(label: String = 'default'):
    EngineDebugger.send_message("conzole:time", [{ "label": label }])

## Output the time elapsed since the start of the timer
## [param [label]] Optional label identifying the timer, in case you have multiple timers
func timeLog(label: String = 'default'):
    EngineDebugger.send_message("conzole:timeLog", [{ "label": label }])

## Ends the timer and outputs the time elapsed
## [param [label]] Optional label identifying the timer, in case you have multiple timers
func timeEnd(label: String = 'default'):
    EngineDebugger.send_message("conzole:timeEnd", [{ "label": label }])

## Print output if the first parameter evaluates to [code]true[/code]
## [param output_1] This output can either be a string, or an object. If it's an object, its
## content is logged if the assertion evaluates to [code]true[/code]
## [param output_2] An array of string replacements to use if [param output_1] is a string
func assertion(value: bool, output_1: Variant, output_2: Variant = null):
    if value:
        return
    
    EngineDebugger.send_message("conzole:assertion", [{ "output_1": output_1, "output_2": output_2 }])

## Logs the number of times that calls to count() has been called
## [param [label]] Optional label identifying the counter, to track multiple counters at the same time
func count(label: String = 'default'):
    EngineDebugger.send_message("conzole:count", [{ "label": label }])

## Resets the active counter (if no label is specified) or the counter specified by the [param label] parameter
## [param [label]] Optional label identifying the counter, to track multiple counters at the same time
func countReset(label: String = 'default'):
    EngineDebugger.send_message("conzole:countReset", [{ "label": label }])

## Clears the conzole log output and any watched variables
func clear():
    EngineDebugger.send_message("conzole:clear", [])

## Watch a variable by placing it in the "Watched variables" section of the Conzole
## [param [label]] Optional label identifying the variable
func watch(obj: Object, label: String = ''):
    EngineDebugger.send_message("conzole:watch", [{ "_remote_object_id": obj.get_instance_id(), "_remote_object_type": obj.get_class() , "label": label }])

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
    self.watch(test_panel)
    self.watch(test_panel, "My label")
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
