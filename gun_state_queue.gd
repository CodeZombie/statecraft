extends Node2D

var gunshot_sound = preload("res://assets/gunshot.mp3")
var reload_sound = preload("res://assets/reload.mp3")
var click_sound = preload("res://assets/click.mp3")

@export var audio_player: AudioStreamPlayer2D
@export var debug_label: Label

var gun_state_machine: StateMachine = StateMachine.new("gun_state_machine")
var gunbody_start_position: Vector2
var trigger_pressed = false
var magazine_pressed = false
var magazine_capacity = 40
var loaded_rounds = magazine_capacity
@export var firing_interval = 0.1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.gunbody_start_position = $GunBody.position
	
	# Always running while the state machine is running...
	gun_state_machine.add_update_method(func(_delta):
		$GunBody.position += $GunBody.position.direction_to(self.gunbody_start_position) * $GunBody.position.distance_to(self.gunbody_start_position) * 20 * _delta)
	
	gun_state_machine.add_state(State.new("idle"))
	gun_state_machine.transition_on("idle", "reload", self.is_magazine_pressed.bind())
	gun_state_machine.transition_dynamic("idle", func():
		if self.trigger_pressed:
			if self.loaded_rounds == 0:
				return "magazine_empty_click"
			return "jammed" if randf() > 0.9 else "fire_round")
	
	var magazine_empty_click_state: State = gun_state_machine.add_state(TimerState.new("magazine_empty_click", self.firing_interval))
	magazine_empty_click_state.add_enter_method(func():
		audio_player.stream = click_sound
		audio_player.play())
	gun_state_machine.transition_on("magazine_empty_click", "idle", "magazine_empty_click.timer_elapsed")
	
	var jammed_state: StateMachine = StateMachine.new("jammed")
	var jammed_state_machine: StateMachine = gun_state_machine.add_state(jammed_state)
	print(gun_state_machine.id)
	print(jammed_state_machine.id)
	jammed_state_machine.add_state(State.new("idle"))
	jammed_state_machine.transition_on("idle", "click", self.is_trigger_pressed.bind())
	jammed_state_machine.transition_on("idle", "clear_jam", self.is_magazine_pressed.bind())
	jammed_state_machine.add_state(TimerState.new("click", firing_interval)) #magazine_empty_click_state.copy
	jammed_state_machine.transition_on("click", "idle", "click.timer_elapsed")
	jammed_state_machine.add_state(
		State.new("clear_jam")\
		.add_enter_method(func(): gun_state_machine.transition_to("reload"))
	)
	
	gun_state_machine.add_state(self.fire_round_state("fire_round"))
	gun_state_machine.transition_on("fire_round", "idle", "fire_round.tween_finished")
	
	var reload_state: StateQueue = gun_state_machine.add_state(StateQueue.new("reload"))
	var mag_out_state: TweenState = reload_state.add_state(TweenState.new("mag_out", self, func(tween: Tween): 
		tween.tween_property($GunBody/Magazine, "position", Vector2(89, 85), .5)))
	mag_out_state.add_enter_method(func():
		audio_player.stream = reload_sound
		audio_player.play())
	reload_state.transition_on("mag_out", "mag_in", "mag_out.tween_finished")
	reload_state.add_state(TweenState.new("mag_in", self, func(tween: Tween):
		tween.tween_property($GunBody/Magazine, "position", Vector2(89, 45), .5)))
	reload_state.on("mag_in", "mag_in.tween_finished", gun_state_machine.transition_to.bind("idle"))
	reload_state.add_exit_method(func(): self.loaded_rounds = self.magazine_capacity)
	
		
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	gun_state_machine.run(1.0)
	
	self.debug_label.text = "trigger_pressed: " + str(trigger_pressed) + "\n" + "magazine_pressed: " + str(magazine_pressed) + "\n" + "loaded_rounds: " + str(loaded_rounds) + "\n" + "Current State: " + str(gun_state_machine.get_current_state().id)
	self.debug_label.text += "\n"
	self.debug_label.text += self.gun_state_machine.as_string()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.pressed:
			self.magazine_pressed = false
			self.trigger_pressed = false

func _on_magazine_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		self.magazine_pressed = (event as InputEventMouseButton).pressed
		
func _on_trigger_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		self.trigger_pressed = (event as InputEventMouseButton).pressed
	
func is_trigger_pressed() -> bool:
	return self.trigger_pressed
	
func is_magazine_pressed() -> bool:
	return self.magazine_pressed
	
func fire_round_state(state_id: String = "fire_round") -> State:
	var state: TweenState = TweenState.new(state_id, self, func(tween: Tween):
		tween.tween_property($GunBody, "position", $GunBody.position - Vector2(32, 0), firing_interval + randf_range(-.01, 0.01)) )
	state.add_enter_method(func():
		audio_player.stream = gunshot_sound
		audio_player.pitch_scale = randf_range(1.2, 1.4)
		audio_player.play()
		self.loaded_rounds -= 1)
	return state
