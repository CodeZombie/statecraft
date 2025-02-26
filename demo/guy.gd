class_name Guy extends Sprite2D
@export var speed: float = 2
@export var pos_a: Node2D
@export var pos_b: Node2D
@export var debug_label: Label
var state_queue: StateQueue
var state_queue_speed: float = 1.0

var run_state_queue: bool = true
@export var pause_button: Button

func move_to_origin():
	self.position = Vector2(0, 0)
	
func _ready() -> void:
	state_queue = StateQueue.new("movement_state_queue").set_exit_policy(StateQueue.ExitPolicy.KEEP)
	state_queue.loop = true
	#state_queue.set_execution_mode(StateQueue.ExecutionMode.PARALLEL)
	#state_queue.set_exit_policy(StateQueue.ExitPolicy.REMOVE)
	state_queue.add_state(
		State.new("move_to_pos_a")\
		.add_signal("finished_moving", [{"name": "x", "type": TYPE_INT}])
		.add_enter_event(func():
			self.scale = Vector2(1,1)
			self.position.x = 300
			)
		.add_update_event(func(delta: float, state: State):
			self.position = lerp(self.position, pos_a.position, speed * delta)
			if self.position.distance_to(pos_a.position) < 10:
				state.emit_signal("finished_moving", 32)
			)
		.on("finished_moving", func(val: int, state: State): state.exit())
		)\
	#.advance_on("move_to_pos_a", "move_to_pos_a.finished_moving")\
	#state_queue = StateQueue.new("movement_state_queue")\
	.add_state(
		TweenState.new("move_to_pos_b", self, func(tween):
			tween.tween_property(self, "scale", Vector2(2, 2), 2)
			)\
		.add_update_event(func(_delta, state):
			self.position = lerp(self.position, pos_b.position, speed * _delta)
			if self.position.distance_to(pos_b.position) < 10:
				state.exit())
		#.add_exit_event(func():
			#state_queue.add_state_front(TimerState.new("timer_test", 1.0)))
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

func get_move_state(state_name: String, target_position: Vector2) -> State:
	return State.new(state_name)\
	.add_update_event(func(delta: float):
		self.position = lerp(self.position, target_position, speed * delta)
		if self.position.distance_to(target_position) < 10:
			return true
		)\
	.add_exit_event(func():
		self.position = target_position)
	
func get_rotation_state(state_id: String, target_node: Node2D, rotation_amount: float) -> State:
	return TweenState.new(state_id, target_node, func(tween: Tween):
		var target_rotation = target_node.rotation + deg_to_rad(rotation_amount)
		tween.tween_property(self, "rotation", target_rotation, 1.0))

func _process(delta: float) -> void:
	if run_state_queue:
		state_queue.run(delta, self.state_queue_speed)
	debug_label.text = "Exit Policy: {0}\n".format({0: self.state_queue._exit_policy})
	debug_label.text += "Execution Mode: {0}\n".format({0: self.state_queue._execution_mode})
	debug_label.text += "Loop: {0}\n".format({0: self.state_queue.loop})
	self.queue_redraw()

func _on_h_slider_value_changed(value: float) -> void:
	self.state_queue_speed = value

func _draw() -> void:
	self.state_queue.draw(self)

func _on_clear_button_pressed() -> void:
	self.state_queue.clear()

func _on_reset_button_pressed() -> void:
	self.state_queue.reset()

func _on_pause_button_pressed() -> void:
	self.run_state_queue = !self.run_state_queue
	self.pause_button.text = "pause" if self.run_state_queue else "unpause"

func _on_rand_move_button_pressed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var target_location: Vector2 = Vector2(randf_range(0, viewport_size.x), randf_range(0, viewport_size.y))
	self.state_queue.add_state(self.get_move_state("rand_move", target_location))

func _on_move_button_pressed() -> void:
	self.state_queue.add_state(self.get_move_state("move_to_a", self.pos_a.global_position))

func _on_rot_90_button_pressed() -> void:
	self.state_queue.add_state(self.get_rotation_state("rot 90", self, 90))

func _on_gun_rot_90_button_pressed() -> void:
	self.state_queue.add_state(self.get_rotation_state("gun rot 90", $Sprite2D, 90))

func _on_grow_button_pressed() -> void:
	self.state_queue.add_state(
		State.new("grow")
		.add_update_event(func(delta: float):
			self.scale += Vector2(5,5) * delta
			if self.scale.x >= 2:
				return true
			)
		.add_exit_event(func():
			self.scale = Vector2(2,2))
	)

func _on_shrink_button_pressed() -> void:
		self.state_queue.add_state(
		State.new("shrink")
		.add_update_event(func(delta: float):
			self.scale -= Vector2(5,5) * delta
			if self.scale.x <= 1:
				return true
			)
		.add_exit_event(func():
			self.scale = Vector2(1,1))
	)

func _on_toggle_exit_policy_button_pressed() -> void:
	if self.state_queue._exit_policy == StateQueue.ExitPolicy.KEEP:
		self.state_queue.set_exit_policy(StateQueue.ExitPolicy.REMOVE)
	else:
		self.state_queue.set_exit_policy(StateQueue.ExitPolicy.KEEP)


func _on_toggle_exec_mode_pressed() -> void:
	if self.state_queue._execution_mode == StateQueue.ExecutionMode.SERIAL:
		self.state_queue.set_execution_mode(StateQueue.ExecutionMode.PARALLEL)
	else:
		self.state_queue.set_execution_mode(StateQueue.ExecutionMode.SERIAL)


func _on_set_loop_button_pressed() -> void:
	self.state_queue.loop = !self.state_queue.loop


func _on_run_instantly_button_pressed() -> void:
	self.state_queue.run_instantly()


func _on_spin_and_unspin_button_pressed() -> void:
	var spin_and_unspin_state_queue: StateQueue = StateQueue.new("spin_and_unspin")
	spin_and_unspin_state_queue.add_state(self.get_rotation_state("rot 90", self, 90))
	spin_and_unspin_state_queue.add_state(self.get_rotation_state("rot -90", self, -90))
	self.state_queue.add_state(spin_and_unspin_state_queue)
