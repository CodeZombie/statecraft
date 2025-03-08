class_name RelayNode extends RefCounted
## A node in a heirarchy able to propagate targetted messages to it's children.

var id: NodePath
# TODO: create a new, identifcal data structure that only holds permanent mesasges meant for 
#	this Node. 
#	We want this because there are many times we need to loop through this list looking for
#	either terminal or non-terminal nodes.
#	If we kept them in separate data structures, we may remove a few loops from the code.
# TODO: rename "permanent" to something else maybe? 
#	The point of permanent is to propagate to all current and future nodes, and for nodes to 
#	hold the message until they are handled.
#	Theres probably a better name than 'permanent'

# We're using a Dict like a Set. We don't care about the values, just the keys.
var permanent_messages: Dictionary[RelayMessage, bool]

var _debug: bool = false

func _init(id_: NodePath):
	assert(id_.get_name_count() == 1, "RelayNode id must be a single path: \"{0}\"".format({0: id_}))
	assert(id_.get_subname_count() == 0, "RelayNode id must be not contain subnames: \"{0}\"".format({0: id_}))
	self.id = id_

func get_all_children() -> Array:
	return []
	
func get_children(node_path: NodePath) -> Array:
	var matches: RelayNode = []
	for child in self.get_all_children():
		if node_path.get_name_count() == 1:
			if child.id == node_path:
				matches.append(child)
		else:
			var next_child: NodePath = node_path.get_name(0)
			if child.id == next_child or next_child == ^"*" or next_child == ^"**":
				matches += child.get_children(node_path.slice(1))
				if next_child == ^"**":
					matches += child.get_children(node_path)
	return matches

#	return self.get_children_via_path_array(Array(target_path.split('.')))

# func get_children_via_path_array(target_path_array: Array[StringName]) -> Array:
# 	var target_path_array_copy = target_path_array.duplicate()
# 	var matches: Array = []
# 	var next_child = target_path_array_copy.pop_front()
# 	for child in self.get_children():
# 		if child.id == next_child:
# 			if len(target_path_array_copy) == 0:
# 				matches.append(child)
# 			else:
# 				matches += child.get_children_via_path_array(target_path_array_copy)
# 	return matches

func propagate_permanent_messages_to_child_node(child_node: RelayNode) -> void:
	for relay_message in self.permanent_messages.keys():
		if relay_message.is_terminal():
			continue
		var descendant_message_copy: RelayMessage = relay_message.get_descendant_copy()
		if relay_message.is_double_wildcard():
			relay_node.recieve_message(relay_message)
		elif relay_message.next_node_is(relay_node.id):
			relay_node.recieve_message(descendant_message_copy)

func propagate_message_to_children(relay_message: RelayMessage) -> void:
	if relay_message.is_terminal():
		return
	
	var descendant_message_copy: RelayMessage = relay_message.get_descendant_copy()
	
	for child in self.get_children():
		if relay_message.next_node_is(child.id):
			child.recieve_message(descendant_message_copy)
		if relay_message.is_double_wildcard():
			child.recieve_message(relay_message)
			
func recieve_message(relay_message: RelayMessage) -> void:
	if self._debug: print("{id}.recieve_message({1})".format({'id': self.id, 1: relay_message.to_string()}))
	if relay_message.permanent and relay_message not in self.permanent_messages:
		self.permanent_messages[relay_message] = true
		
	if relay_message.is_double_wildcard():
		self.recieve_message(relay_message.get_descendant_copy())
	if relay_message.is_terminal():
		if self._handle_message(relay_message):
			if relay_message.permanent:
				if self._debug: print("{id} message handled: {msg}".format({'id': self.id, 'msg': relay_message.to_string()}))
				self.permanent_messages.erase(relay_message)
	else:
		self.propagate_message_to_children(relay_message)

func handle_all_permanent_messages() -> void:
	for relay_message in self.permanent_messages.keys():
		if relay_message.is_terminal():
			if self._handle_message(relay_message):
				if self._debug: print("{id} message handled: {msg}".format({'id': self.id, 'msg': relay_message.to_string()}))
				self.permanent_messages.erase(relay_message)
			
func handle_all_permanent_messages_of_type(message_type: int) -> void:
	for relay_message in self.permanent_messages.keys():
		if relay_message.is_terminal() and relay_message.message_type == message_type:
			if self._handle_message(relay_message):
				if self._debug: print("{id} message handled: {msg}".format({'id': self.id, 'msg': relay_message.to_string()}))
				self.permanent_messages.erase(relay_message)

func _handle_message(relay_message: RelayMessage) -> bool:
	assert(false, "Cannot call `_handle_message` on base RelayNode class.")
	return false
