@tool
class_name ConzoleEditorDebugger 
extends EditorDebuggerPlugin

var conzole_window_panel: ConzoleWindow
var found := false
var found_item

func _has_capture(prefix):
    # Return true if you wish to handle message with this prefix.
    return prefix == "conzole"

func _capture(message, data, session_id):
    match message:
        "conzole:log":
            var _msgs = []
            conzole_window_panel._log(data[0].msg, data[0].log_level, data[0].group_key)
            #if data[0].msg is Array:
                #for msg in data[0].msg:
                    #if msg is Dictionary:
                        #if msg.has("_conzole_remote_object_id"):
                            #
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
        "conzole:watch":
            conzole_window_panel.watch(data[0]._remote_object_id, data[0]._remote_object_type, data[0].label)
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
    session.stopped.connect(_stop_session)
    #session.add_session_tab(conzole_window_panel)

func _start_session():
    conzole_window_panel.clear()
    conzole_window_panel.log("Debug session started")
    # Conzole._session = session

func _stop_session():
    conzole_window_panel.log("-------------------")
    conzole_window_panel.log("Debug session ended")
