class_name RelayMessage extends Object
# RelayMessage are:
#	1. A target node path
#	2. A method name StringName
#	3. A list of arguments.


#enum Type {CONNECT_SIGNAL_OBJECT, CONNECT_SIGNAL_VIA_NAME, ADD_ENTERED_CALLBACK, ADD_UPDATED_CALLBACK, ADD_EXITED_CALLBACK, CALL_METHOD, EMIT_SIGNAL, ATTACH_ON_BROADCAST_CALLBACK}


var target_node_path: NodePath
var method_name: StringName
var args: Array
var permanent: bool = false
var handled: bool = false

func _init(target_node_path_: NodePath, method_name_: StringName, args_: Array = [], permanent_: bool = false):
	self.target_node_path = target_node_path_
	self.method_name = method_name_
	self.args = args_
	self.permanent = permanent_

func is_terminal() -> bool:
	return self.target_node_path.get_name_count() == 0

func get_descendant_copy() -> RelayMessage:
	if self.is_terminal():
		assert(false, "Cannot create a descendant copy of a terminal RelayMessage")
	return RelayMessage.new(
		self.target_node_path.slice(1), 
		self.method_name,
		self.args,
		self.permanent)
		
func get_next_node() -> NodePath:
	return NodePath(self.target_node_path.get_name(0))

func next_node_is(relay_node_id: NodePath) -> bool:
	return self.get_next_node() == relay_node_id or self.get_next_node() == ^"*"
	
func is_double_wildcard() -> bool:
	if self.is_terminal():
		return false
	return self.get_next_node() == ^"**"
	
func _to_string() -> String:
	return "RelayMessage[{type}][{target}]".format({
		'method_name': self.method_name,
		'target': self.target_node_path,
	})

func handle(relay_node: RelayNode) -> bool:
	if not self.is_terminal():
		relay_node.propagate_message_to_children(self)
		return false
	elif not self.handled:
		relay_node.callv(self.method_name, self.args)
		self.handled = true
		return true
	return false
