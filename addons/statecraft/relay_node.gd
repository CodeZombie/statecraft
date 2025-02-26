class_name RelayNode extends RefCounted
## A node in a heirarchy able to propagate targetted messages to it's children.

var id: StringName
# TODO: create a new, identifcal data structure that only holds permanent mesasges meant for 
#	this Node. 
#	We want this because there are many times we need to loop through this list looking for
#	either terminal or non-terminal nodes.
#	If we kept them in separate data structures, we may remove a few loops from the code.
# TODO: rename "permanent" to something else maybe? 
#	The point of permanent is to propagate to all current and future nodes, and for nodes to 
#	hold the message until they are handled.
#	Theres probably a better name than 'permanent'
var permanent_messages: Dictionary[RelayMessage, bool]

func _init(id_: StringName):
	assert(not id_.contains('.'), "RelayNode ID cannot contain periods: \"{0}\"".format({0: id_}))
	self.id = id_

func get_children() -> Array:
	assert(false, "Do not call `get_children` on RelayNode base class. It must be implemented in child class.")
	return []

func propagate_permanent_messages_to_relay_node(relay_node: RelayNode) -> void:
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
	if relay_message.permanent and relay_message not in self.permanent_messages:
		self.permanent_messages[relay_message] = true
		
	if relay_message.is_double_wildcard():
		self.recieve_message(relay_message.get_descendant_copy())
	if relay_message.is_terminal():
		if self._handle_message(relay_message):
			if relay_message.permanent:
				self.permanent_messages.erase(relay_message)
	else:
		self.propagate_message_to_children(relay_message)

func handle_all_permanent_messages() -> void:
	for relay_message in self.permanent_messages.keys():
		if relay_message.is_terminal():
			if self._handle_message(relay_message):
				self.permanent_messages.erase(relay_message)
			
func handle_all_permanent_messages_of_type(message_type: int) -> void:
	for relay_message in self.permanent_messages.keys():
		if relay_message.is_terminal() and relay_message.message_type == message_type:
			if self._handle_message(relay_message):
				self.permanent_messages.erase(relay_message)

func _handle_message(relay_message: RelayMessage) -> bool:
	assert(false, "Cannot call `_handle_message` on base RelayNode class.")
	return false
