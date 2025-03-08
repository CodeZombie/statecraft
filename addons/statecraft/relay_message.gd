class_name RelayMessage extends Object

enum Type {CONNECT_EXTERNAL_SIGNAL, CONNECT_INTERNAL_SIGNAL, ADD_ENTERED_CALLBACK, ADD_UPDATED_CALLBACK, ADD_EXITED_CALLBACK, CALL_METHOD, EMIT_SIGNAL, ATTACH_ON_BROADCAST_CALLBACK}


var target_node_path: NodePath
var message_type: int
var permanent: bool = false
var args: Dictionary[StringName, Variant]

# static func node_path_string_to_node_path_array(node_path: String) -> Array[StringName]:
# 	var stringname_array: Array[StringName]
# 	stringname_array.assign(node_path.split("."))
# 	if stringname_array[0] == &"":
# 		stringname_array.pop_front()
# 	return stringname_array
	
# static func node_path_array_to_node_path_string(node_path: Array[StringName]) -> StringName:
# 	return '.'.join(node_path)

func _init(target_node_path_: NodePath, message_type_: int, args_: Dictionary[StringName, Variant] = {}, permanent_: bool = false):
	# if target_node_path_ is String or target_node_path_ is StringName:
	# 	self.target_node_path = RelayMessage.node_path_string_to_node_path_array(target_node_path_)
	# elif target_node_path_ is Array:
	# 	self.target_node_path.assign(target_node_path_)
	# else:
	# 	assert(false, "Invalid type for target_node_path \"{0}\" in RelayMessage.".format(target_node_path_))
	self.target_node_path = target_node_path_
	self.message_type = message_type_
	self.args = args_
	self.permanent = permanent_

func is_terminal() -> bool:
	return self.target_node_path.get_name_count() == 0
	#return len(self.target_node_path) == 0

func get_descendant_copy() -> RelayMessage:
	if self.is_terminal():
		assert(false, "Cannot create a descendant copy of a terminal RelayMessage")
	return RelayMessage.new(
		self.target_node_path.slice(1), 
		self.message_type,
		self.args,
		self.permanent)
		
func get_next_node() -> NodePath:
	return self.target_node_path.get_name(0)
	#return self.target_node_path[0]

func next_node_is(relay_node_id: NodePath) -> bool:
	return self.get_next_node() == relay_node_id or self.get_next_node() == ^"*"
	
func is_double_wildcard() -> bool:
	if self.is_terminal():
		return false
	return self.get_next_node() == ^"**"
	
func _to_string() -> String:
	return "RelayMessage[{type}][{target}]".format({
		'type': Type.keys()[self.message_type],
		'target': '.'.join(self.target_node_path),
		#'args': self.args
	})
