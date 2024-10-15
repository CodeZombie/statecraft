extends Node2D

var gun_state_machine: StateMachine = StateMachine.new("gun_state_machine")

var start_position: Vector2
var trigger_pressed = false
var magazine_pressed = false
var loaded_rounds = 50
var firing_interval = 0.2

@export var debug_label: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.start_position = position
	gun_state_machine.set_on_update(func(): return func(state, delta):
		self.position += self.position.direction_to(self.start_position) * self.position.distance_to(self.start_position) * 20 * delta
	)
	
	gun_state_machine.add_state(State.new("idle")
	.set_on_update(func(): return func(_state, delta):
		if self.trigger_pressed and loaded_rounds > 0:
			return gun_state_machine.transition_to("fire_a_round")
		if self.magazine_pressed:
			return gun_state_machine.transition_to("reload")
	))
	
	gun_state_machine.add_state(State.new("fire_a_round")
	.add_tween(false, self, func(): return func(tween: Tween):
		tween.tween_property(self, "position", self.position - Vector2(32, 0), .0001)
	)
	.set_on_enter(func(): return func(_state):
		self.loaded_rounds -= 1)
	.set_timeout(firing_interval)
	.set_on_exit(func(): return func(_state):
		gun_state_machine.transition_to("idle")
	))
	
	var reload_state_queue = StateQueue.new("reload")
	reload_state_queue.set_on_exit(func(): return func(state):
		gun_state_machine.transition_to("idle")
	)
	
	reload_state_queue.add_state(State.new("reload_out")
	.add_tween(true, self, func(): return func(tween: Tween):
		tween.tween_property($GunBody/Magazine, "position", Vector2(89, 85), 1)))
	
	reload_state_queue.add_state(State.new("reload_in")
	.add_tween(true, self, func(): return func(tween: Tween):
		tween.tween_property($GunBody/Magazine, "position", Vector2(89, 45), 1))
	.set_on_exit(func(): return func(state):
		self.loaded_rounds = 50
	))
	
	gun_state_machine.add_state(reload_state_queue)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	gun_state_machine.run(delta, 1.0)
	
	self.debug_label.text = "trigger_pressed: " + str(trigger_pressed) + "\n" + "magazine_pressed: " + str(magazine_pressed) + "\n" + "loaded_rounds: " + str(loaded_rounds) + "\n" + "Current State: " + str(gun_state_machine.get_current_state_id())


func _on_magazine_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		self.magazine_pressed = (event as InputEventMouseButton).pressed


func _on_trigger_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		self.trigger_pressed = (event as InputEventMouseButton).pressed
