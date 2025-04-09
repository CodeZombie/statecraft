extends Control

var sq: StateQueue = StateQueue.new(^"sq").set_exit_policy(StateQueue.ExitPolicy.REMOVE)
var my_value: int = 32

func add_state():
	#var new_state: State = State.new(^"cool_state").add_enter_event(func(): print(self.my_value))
	#new_state.broadcast_.connect(func(bcast: StringName): print(bcast))
	#self.sq.add(new_state)
	
	self.sq.add(
		State.new(^"cool_state", false)
		.add_enter_event(func(): print(self.my_value))
		.on_broadcast(&"meow").then_exit()
		)
	
func _process(delta: float) -> void:
	sq.run(delta)
	queue_redraw()

func emit_broadcast():
	sq.broadcast(&"meow")

func _draw() -> void:
	sq.draw(self, Vector2(512, 0))
