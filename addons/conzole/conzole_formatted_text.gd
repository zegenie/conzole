@tool

class_name ConzoleFormattedText
extends Node

var _message_text: String
var _is_bold := false
var _color: String
var _level: int = ConzolePlugin.LogLevel.INFO

static func stringify(message: Variant) -> String:
	var result: String
	
	if message is Dictionary:
		return JSON.new().stringify(message, "  ", false, true)
	elif message is String:
		return message
	elif message is Object:
		var dict = {}
		for prop in message.get_property_list():
			dict[prop.name] = ConzoleFormattedText.stringify(message.get(prop.name))
		return JSON.new().stringify(dict, "  ", false, true)
	else:
		return str(message)

static func message(text: Variant) -> ConzoleFormattedText:
	var _message_object = ConzoleFormattedText.new()
	_message_object._message_text = ConzoleFormattedText.stringify(text)
	
	return _message_object

func level(log_level: int) -> ConzoleFormattedText:
	_level = log_level
	return self

func bold() -> ConzoleFormattedText:
	_is_bold = true
	return self

func color(_text_color: Variant) -> ConzoleFormattedText:
	if _text_color is Color:
		_text_color = _text_color.to_html()
	
	_color = _text_color
	return self

func get_formatted_text():
	var _text = _message_text
	
	if _is_bold:
		_text = "[b]" + _text + "[/b]"
	if _color:
		_text = "[color=%s]%s[/color]" % [_color, _text]
	
	return _text
