class_name Guy extends Sprite2D
@export var speed: float = 3
@export var pos_a: Node2D
@export var pos_b: Node2D
@export var debug_label: Label
var state_queue: StateQueue
var state_queue_speed: float = 1.0

func move_to_origin():
	self.position = Vector2(0, 0)
	
#TODO: transition_to and on_message should be able to handle multiple messages:

func _ready() -> void:
	state_queue = StateQueue.new("movement_state_queue")\
	.add_state(
		TweenState.new("move_to_pos_a", self, func(tween):
			tween.tween_property(self, "scale", Vector2(2, 2), 0.5))\
		.add_update_method(func(state, _delta):
			self.position = lerp(self.position, pos_a.position, speed * _delta)
			if self.position.distance_to(pos_a.position) < 10:
				state.emit("move_finished") ))\
	.advance_on("move_to_pos_a", "move_to_pos_a.move_finished")\
	
	.add_state($Sprite2D.get_rotate_state())\
	.advance_on("sprite_2d_rotate", "sprite_2d_rotate.rotate_timer.timer_elapsed")\
	.add_state(
		TweenState.new("rotate", self, func(tween):
			tween.tween_property(self, "rotation", self.rotation + PI/2, 0.5) ))\
	.advance_on("rotate", "rotate.tween_finished")\
	
	.add_state(
		TweenState.new("move_to_pos_b", self, func(tween):
			tween.tween_property(self, "scale", Vector2(1, 1), 0.5))\
		.add_update_method(func(state, delta):
			self.position = lerp(self.position, pos_b.position, speed * delta)
			if self.position.distance_to(pos_b.position) < 10:
				state.emit("move_finished") ))\
	.advance_on("move_to_pos_b", "move_to_pos_b.move_finished")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	debug_label.text = state_queue.as_string()
	state_queue.run(self.state_queue_speed, true)

func _on_h_slider_value_changed(value: float) -> void:
	self.state_queue_speed = value
