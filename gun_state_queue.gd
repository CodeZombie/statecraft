extends Node2D

var gun_state_machine: StateMachine = StateMachine.new("gun_state_machine")

var gunshot_sound = preload("res://assets/gunshot.mp3")
var reload_sound = preload("res://assets/reload.mp3")
var click_sound = preload("res://assets/click.mp3")

@export var audio_player: AudioStreamPlayer2D

var gunbody_start_position: Vector2
var trigger_pressed = false
var magazine_pressed = false
var magazine_capacity = 12
var loaded_rounds = magazine_capacity
var firing_interval = 0.2

@export var debug_label: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.gunbody_start_position = $GunBody.position
	
	# Always running while the state machine is running...
	gun_state_machine.set_on_update(func(): return func(state, delta):
		$GunBody.position += $GunBody.position.direction_to(self.gunbody_start_position) * $GunBody.position.distance_to(self.gunbody_start_position) * 20 * delta
	)
	
	# Define the "Idle" State.
	# THis state checks for user interaction and transitions to a different state to perform the desired action.
	gun_state_machine.add_state(
		State.new("idle")
		.set_on_update(func(): return func(_state, delta):
			if self.trigger_pressed:
				if loaded_rounds > 0:
					gun_state_machine.transition_to("fire_a_round")
				else:
					gun_state_machine.transition_to("click")
			if self.magazine_pressed:
				gun_state_machine.transition_to("reload")))
	
	# Define the "Click" state.
	# This just plays a click sound, waits a short amount of time, then transitions back to Idle.
	gun_state_machine.add_state(
		State.new("click")
		.set_on_enter(func(): return func(state):
			audio_player.stream = click_sound
			audio_player.play())
		.set_timeout(firing_interval)
		.set_on_exit(func(): return func(state):
			return gun_state_machine.transition_to("idle")))
	
	# The "Fire A Round" state
	# This tweens the gun body back 32 units to simulate a "kickback" effect,
	# plays a gunshot sound,
	# reduces the "loaded rounds" variable
	# Then transitions back to idle after a 'firing interval' amount of time has elapsed.
	gun_state_machine.add_state(
		State.new("fire_a_round")
		.add_tween(false, self, func(): return func(tween: Tween):
			tween.tween_property($GunBody, "position", $GunBody.position - Vector2(32, 0), .01))
		.set_on_enter(func(): return func(_state):
			audio_player.stream = gunshot_sound
			audio_player.pitch_scale = randf_range(1.2, 1.4)
			audio_player.play()
			self.loaded_rounds -= 1)
		.set_timeout(firing_interval)
		.set_on_exit(func(): return func(_state):
			gun_state_machine.transition_to("idle")))
	
	# The Reload state.
	# This is a StateQueue which plays two states sequentially.
	# The first state
	gun_state_machine.add_state(
		StateQueue.new("reload")
		.add_state(
			State.new("out")
			.set_on_enter(func(): return func(state):
				audio_player.stream = reload_sound
				audio_player.play()
				)
			.add_tween(true, self, func(): return func(tween: Tween):
				tween.tween_property($GunBody/Magazine, "position", Vector2(89, 85), .5)
				)
			)
		.add_state(
			State.new("in")
			.add_tween(true, self, func(): return func(tween: Tween):
				tween.tween_property($GunBody/Magazine, "position", Vector2(89, 45), .5)
				)
			.set_on_exit(func(): return func(state):
				self.loaded_rounds = self.magazine_capacity
				return gun_state_machine.transition_to("idle"))
	))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	gun_state_machine.run(delta, 1.0)
	
	self.debug_label.text = "trigger_pressed: " + str(trigger_pressed) + "\n" + "magazine_pressed: " + str(magazine_pressed) + "\n" + "loaded_rounds: " + str(loaded_rounds) + "\n" + "Current State: " + str(gun_state_machine.get_current_state_id())
	self.debug_label.text += "\n"
	self.debug_label.text += self.gun_state_machine.get_debug_string()

func _on_magazine_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		self.magazine_pressed = (event as InputEventMouseButton).pressed


func _on_trigger_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		self.trigger_pressed = (event as InputEventMouseButton).pressed
