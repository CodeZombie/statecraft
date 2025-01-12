class_name Guy extends Sprite2D
@export var speed: float = 3
@export var pos_a: Node2D
@export var pos_b: Node2D
@export var debug_label: Label
var state_queue: StateQueue = StateQueue.new("movement_state_queue")
var state_queue_speed: float = 1.0

func move_to_origin():
	self.position = Vector2(0, 0)

func _ready() -> void:
	state_queue.add_state(State.new("move_to_pos_a")
	#.set_on_enter(func(): self.move_to_origin())
	.set_on_update(func(_delta):
		self.position = lerp(self.position, pos_a.position, speed * _delta)
		if self.position.distance_to(pos_a.position) < 10:
			return StateQueue.TransitionToNextState.new("movement_state_queue")
	)
	.add_tween(self, 
		func(tween):
			tween.tween_property(self, "scale", Vector2(2, 2), 0.5)
	))
	
	state_queue.add_state($Sprite2D.get_rotate_state())
	
	state_queue.add_state(State.new("rotate")
	.add_tween(self, 
		func(tween):
			tween.tween_property(self, "rotation", self.rotation + PI/2, 0.5),
		func():
			return StateQueue.TransitionToNextState.new("movement_state_queue")
	))
	
	state_queue.add_state(State.new("move_to_pos_b")
	.set_on_update(func(_delta):
		#self.position += self.position.direction_to(pos_b.position) * speed * _delta
		self.position = lerp(self.position, pos_b.position, speed * _delta)
		if self.position.distance_to(pos_b.position) < 10:
			return StateQueue.TransitionToNextState.new()
	).add_tween(self, 
		func(tween):
			tween.tween_property(self, "scale", Vector2(1, 1), 0.5)
		#func():
			#return StateQueue.TransitionToNextState.new("movement_state_queue")
	))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	debug_label.text = "DEBUG LABEL\n"
	debug_label.text += str(state_queue.id) + " : " + state_queue.get_status_string()
	for child_state in state_queue.child_states:
		debug_label.text += "\n   " + str(child_state.id) + " : " + child_state.get_status_string()
	state_queue.run(self.state_queue_speed, true)

func _on_h_slider_value_changed(value: float) -> void:
	self.state_queue_speed = value
