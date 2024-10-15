extends Sprite2D
@export var speed: float = 200
@export var pos_a: Node2D
@export var pos_b: Node2D
@export var debug_label: Label
var state_queue: StateQueue = StateQueue.new("movement_state_queue")

var _run_once = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	state_queue.add_state(State.new("move_to_pos_a")
	.set_on_update(func(): return func(_state, _delta):
		self.position += self.position.direction_to(pos_a.position) * speed * _delta
		if self.position.distance_to(pos_a.position) < 10:
			return _state.exit())
	.add_tween(false, self, func(): return func(tween):
		tween.tween_property(self, "scale", Vector2(3, 3), 0.5)
	))
	
	
	state_queue.add_state(State.new("rotate")
	.add_tween(true, self, func(): return func(tween):
		tween.tween_property(self, "rotation", self.rotation + PI/2, 1))
	.set_on_exit(func(): return func(_state):
		pass
	))
	
	state_queue.add_state(State.new("move_to_pos_b")
	.set_on_update(func(): return func(_state, _delta):
		self.position += self.position.direction_to(pos_b.position) * speed * _delta
		if self.position.distance_to(pos_b.position) < 10:
			return state_queue.transition_to("move_to_pos_a"))
	.add_tween(false, self, func(): return func(tween):
		tween.tween_property(self, "scale", Vector2(1, 1), 1)
	))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	debug_label.text = "DEBUG LABEL\n"
	debug_label.text += str(state_queue.id) + " : " + state_queue.get_state_string()
	for child_state in state_queue.child_states:
		debug_label.text += "\n   " + str(child_state.id) + " : " + child_state.get_state_string()
	state_queue.run(delta, 1.0, true)
