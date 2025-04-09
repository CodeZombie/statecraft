class_name RelayMessage extends RefCounted

# RelayMessages are used to propagate targetted method calls through a RelayNode tree to nodes that match the target_node_path.

# The target_node_path is 
# The method_name is 

var target_node_path: NodePath
# a NodePath that is used to identify the target node(s) of the message.

var method_name: StringName
# the name of the method that will be called on the target node(s).

var args: Array
# an array of arguments that will be passed to the method call.

#var handled: bool = false
# if true, the message has been handled by the RelayNode and will not be re-handled.

func _init(target_node_path_: NodePath, method_name_: StringName, args_: Array = []):
	#self.uuid = Time.get_ticks_msec()
	self.target_node_path = target_node_path_
	self.method_name = method_name_
	self.args = args_

func is_terminal() -> bool:
	return self.target_node_path.get_name_count() == 0

func get_descendant_copy() -> RelayMessage:
	if self.is_terminal():
		assert(false, "Cannot create a descendant copy of a terminal RelayMessage")
	var descendant_message_copy: RelayMessage = RelayMessage.new(
		self.target_node_path.slice(1), 
		self.method_name,
		self.args)
	#descendant_message_copy.uuid = self.uuid
	return descendant_message_copy
		
func get_next_node() -> NodePath:
	return NodePath(self.target_node_path.get_name(0))

func next_node_is(relay_node_id: NodePath) -> bool:
	return self.get_next_node() == relay_node_id or self.get_next_node() == ^"*"
	
func next_node_is_a_double_wildcard() -> bool:
	if self.is_terminal():
		return false
	return self.get_next_node() == ^"**"
	
func _to_string() -> String:
	return "RelayMessage[{method_name}][{target}]".format({
		'method_name': self.method_name,
		'target': self.target_node_path,
	})

func handle(relay_node: RelayNode) -> bool:
	if not self.is_terminal():
		relay_node.propagate_message_to_children(self)
		return false
	#elif not self.handled:
	relay_node.callv(self.method_name, self.args)
	#self.handled = true
	return true
	#return false
