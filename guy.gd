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
	
	state_queue.add_state(TweenState.new("move_to_pos_a", self, func(tween):
		tween.tween_property(self, "scale", Vector2(2, 2), 0.5)
	).add_update_method(func(_delta):
		self.position = lerp(self.position, pos_a.position, speed * _delta)
	).add_condition("move_finished", func():
		return self.position.distance_to(pos_a.position) < 10
	))
	state_queue.transition_from("move_to_pos_a").on("move_to_pos_a.move_finished")
	
	#TODO: transition_to and on_message should be able to handle multiple messages:
	#	`state_queue.transition_on(["move_to_pos_a.move_finished", "move_to_pos_a.tween_finished"])
	# which will only tansition when both messages are true.
	
	#TODO: rename "message" to "condition"
	
	#state_queue.add_state(State.new(
		#"move_to_pos_a"
	#).add_update_method(func(_delta):
		#self.position = lerp(self.position, pos_a.position, speed * _delta)
	#).add_message("finished", func():
		#return self.position.distance_to(pos_a.position) < 10
	#).add_tween(self, func(tween):
		#tween.tween_property(self, "scale", Vector2(2, 2), 0.5)
	#)).on_message("move_to_pos_a", "finished", state_queue.transition_to_next_state.bind())
	#
	state_queue.add_state($Sprite2D.get_rotate_state()).transition_from("sprite_2d_rotate").on("sprite_2d_rotate.rotate_timer.finished")
	
	state_queue.add_state(TweenState.new("rotate", self, func(tween):
		tween.tween_property(self, "rotation", self.rotation + PI/2, 0.5)
	))
	state_queue.transition_from("rotate").on("rotate.finished")
	
	#state_queue.add_state(State.new("rotate")
	#.add_tween(self, 
		#func(tween):
			#tween.tween_property(self, "rotation", self.rotation + PI/2, 0.5),
		#func():
			#return StateQueue.transitionToNextState()
	#))
	#
	state_queue.add_state(TweenState.new("move_to_pos_b", self, func(tween):
		tween.tween_property(self, "scale", Vector2(1, 1), 0.5)
	).add_update_method(func(delta):
		self.position = lerp(self.position, pos_b.position, speed * delta)
	).add_condition("move_finished", func():
		return self.position.distance_to(pos_b.position) < 10
	))
	state_queue.transition_from("move_to_pos_b").on("move_to_pos_b.move_finished")
	
	#state_queue.add_state(State.new("move_to_pos_b")
	#.set_on_update(func(_delta):
		#self.position = lerp(self.position, pos_b.position, speed * _delta)
		#if self.position.distance_to(pos_b.position) < 10:
			#return StateQueue.transitionToNextState()
	#).add_tween(self, 
		#func(tween):
			#
	#))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	debug_label.text = "DEBUG LABEL\n"
	debug_label.text += str(state_queue.id) + " : " + state_queue.get_status_string()
	for child_state in state_queue.child_states:
		debug_label.text += "\n   " + str(child_state.id) + " : " + child_state.get_status_string()
	state_queue.run(self.state_queue_speed, true)

func _on_h_slider_value_changed(value: float) -> void:
	self.state_queue_speed = value
