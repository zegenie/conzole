@tool
class_name ConzolePlugin
extends EditorPlugin

const AUTOLOAD_NAME = "Conzole"
const VERSION: String = "0.2"

const CONZOLE_WINDOW = preload("res://addons/conzole/conzole_window.tscn")

var conzole_instance: ConzoleInstance

static var active_debugger: ConzoleEditorDebugger

enum LogLevel {
	ERROR,
	WARN,
	NOTICE,
	MESSAGE,
	INFO,
	VERBOSE,
	DEBUG
}

var conzole_window = CONZOLE_WINDOW.instantiate() as ConzoleWindow
var debugger = ConzoleEditorDebugger.new()

func _enter_tree() -> void:
	add_control_to_bottom_panel(conzole_window, "Conzole")
	debugger.conzole_window_panel = conzole_window
	add_debugger_plugin(debugger)
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/conzole/conzole.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)

func _has_main_screen() -> bool:
	return false

func _exit_tree() -> void:
	remove_debugger_plugin(debugger)
	pass
