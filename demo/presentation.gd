extends Control

var root_state_queue: StateQueue = StateQueue.new("root")

func _ready() -> void:
	root_state_queue.add_state(State.new("intro_state_queue"))
	
func _process(delta: float) -> void:
	if self.root_state_queue.run(delta):
		print("Root state queue exited.")
		
func get_intro_state_queue():
	print(5 + 5)
	
	if 5 and 4:
		print("Nice")
	get_stack()
	get_intro_state_queue()
	pass
