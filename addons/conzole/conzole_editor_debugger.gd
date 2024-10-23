@tool
class_name ConzoleEditorDebugger 
extends EditorDebuggerPlugin

var conzole_window_panel: ConzoleWindow
var found := false
var found_item

func _has_capture(prefix):
	# Return true if you wish to handle message with this prefix.
	return prefix == "conzole"

func select_object_in_remote_tree(node: Node, id: int):
	if node == null:
		return
	if node.is_class("Tree"):
		var root = node.get_root()
		select_object_in_tree_items(root,  id)
		if found:
			return
	for child in node.get_children():
		select_object_in_remote_tree(child, id)
		if found:
			return

func _uncollapse_up(item: TreeItem):
	item.collapsed = false
	if item.get_parent():
		_uncollapse_up(item.get_parent())
	
func select_object_in_tree_items(item: TreeItem, id: int):
	if item == null:
		return
	if item.get_metadata(0) == id:
		#_uncollapse_up(item)
		#item.get_tree().scroll_to_item(item)
		#item.select(0)
		found = true
		found_item = item
	if item.get_children():
		for treeItem in item.get_children():
			select_object_in_tree_items(treeItem, id)
			if found:
				return
	item = item.get_next()
	
func _capture(message, data, session_id):
	match message:
		"conzole:log":
			var _msgs = []
			conzole_window_panel.log(data[0].msg, data[0].group_key)
			#if data[0].msg is Array:
				#for msg in data[0].msg:
					#if msg is Dictionary:
						#if msg.has("_conzole_remote_object_id"):
							#va
							#var session = get_session(session_id)
							#var node_id = msg._conzole_remote_object_id
							#var object = instance_from_id(node_id)
							#var remote_object = EditorDebuggerRemoteObject.new()
							#print(is_instance_id_valid(node_id))
							#var root_node = EditorInterface.get_edited_scene_root().get_node('/root').find_child("*EditorDebuggerTree*", true, false)
							#found = false
							#found_item = null
							#select_object_in_remote_tree(root_node, node_id)
							#if found:
								#_msgs.append(found_item)
								#print(found_item)
						#else:
							#_msgs.append(msg)
					#else:
						#_msgs.append(msg)
			#else:
				#printerr("waat")
			return true
		"conzole:group":
			conzole_window_panel.group(data[0].key, data[0].options)
			return true
		"conzole:groupEnd":
			conzole_window_panel.groupEnd(data[0].key)
			return true
		"conzole:clear":
			conzole_window_panel.clear()
			return true
		"conzole:count":
			conzole_window_panel.count(data[0].label)
			return true
		"conzole:countReset":
			conzole_window_panel.countReset(data[0].label)
			return true
		"conzole:time":
			conzole_window_panel.time(data[0].label)
			return true
		"conzole:timeLog":
			conzole_window_panel.timeLog(data[0].label)
			return true
		"conzole:timeEnd":
			conzole_window_panel.timeEnd(data[0].label)
			return true
		"conzole:assertion":
			conzole_window_panel.assertion(data[0].output_1, data[0].output_2)
			return true
	return false

func _setup_session(session_id):
	# Add a new tab in the debugger session UI containing a label.
	#var label = Label.new()
	#label.name = "Example plugin"
	#label.text = "Example plugin"
	var session = get_session(session_id)
	# Listens to the session started and stopped signals.
	session.started.connect(_start_session)
	session.stopped.connect(func (): print("Session stopped"))
	#session.add_session_tab(conzole_window_panel)

func _start_session():
	conzole_window_panel.clear()
	conzole_window_panel.log("Debug session started")
	# Conzole._session = session
