class_name Guy extends Sprite2D
@export var speed: float = 2
@export var pos_a: Node2D
@export var pos_b: Node2D
@export var debug_label: Label
var state_queue: StateQueue
var state_queue_speed: float = 1.0

func move_to_origin():
	self.position = Vector2(0, 0)
	
#TODO: transition_to and on_message should be able to handle multiple messages:

func _ready() -> void:
	state_queue = StateQueue.new("movement_state_queue")
	#state_queue.set_execution_mode(StateQueue.EXECUTION_MODE.PARALLEL)
	state_queue.set_exit_policy(StateQueue.EXIT_POLICY.REMOVE)
	state_queue.add_state(
		State.new("move_to_pos_a")\
		.add_enter_event(func():
			self.scale = Vector2(1,1)
			self.position.x = 300
			)
		.add_update_event(func(delta: float):
			self.position = lerp(self.position, pos_a.position, speed * delta)
			return self.position.distance_to(pos_a.position) < 10
			)
		)\
	#state_queue = StateQueue.new("movement_state_queue")\
	.add_state(
		TweenState.new("move_to_pos_b", self, func(tween):
			tween.tween_property(self, "scale", Vector2(2, 2), 2)
			)\
		.add_update_event(func(state, _delta):
			self.position = lerp(self.position, pos_b.position, speed * _delta)
			if self.position.distance_to(pos_b.position) < 10:
				state.exit())
		)\
		
	.add_state($Sprite2D.get_rotate_state())
	#.add_state(
		#TweenState.new("rotate", self, func(tween):
			#tween.tween_property(self, "rotation", self.rotation + PI/2, 0.5) )
			#)\
	#.add_state(
		#TweenState.new("move_to_pos_b", self, func(tween):
			#tween.tween_property(self, "scale", Vector2(1, 1), 0.5))\
		#.add_update_event(func(state, delta):
			#self.position = lerp(self.position, pos_b.position, speed * delta)
			#if self.position.distance_to(pos_b.position) < 10:
				#state.emit("move_finished") ))\
	#.advance_on("move_to_pos_b", "move_to_pos_b.move_finished")\
	#.on("move_to_pos_b.move_finished", func(state): state.emit("all_done"))
	#
	#state_queue.on("all_done", func(): self.pos_a.position.x -= 100)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	debug_label.text = state_queue.as_string()
	state_queue.run(delta, self.state_queue_speed)
	self.queue_redraw()

func _on_h_slider_value_changed(value: float) -> void:
	self.state_queue_speed = value

func _draw() -> void:
	self.state_queue.draw(Vector2(2, 2), self)
