class_name MessageHandler

var target_message: String
var handler: Callable

func _init(target_message: String, handler: Callable):
	self.target_message = target_message
	self.handler = handler
