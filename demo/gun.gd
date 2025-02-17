extends Node2D

signal magazine_pressed

var gunshot_sound = preload("res://demo/assets/gunshot.mp3")
var reload_sound = preload("res://demo/assets/reload.mp3")
var click_sound = preload("res://demo/assets/click.mp3")

@export var audio_player: AudioStreamPlayer2D
@export var debug_label: Label

var gun_state_machine: StateMachine
var gunbody_start_position: Vector2
var trigger_pressed = false
#var magazine_pressed = false
var magazine_capacity = 40
var loaded_rounds = magazine_capacity
@export var firing_interval = 0.1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.gunbody_start_position = $GunBody.position

	gun_state_machine = StateMachine.new("gun")\
	.add_update_event(
		func(_delta): 
			$GunBody.position += $GunBody.position.direction_to(self.gunbody_start_position) * $GunBody.position.distance_to(self.gunbody_start_position) * 20 * _delta)\
	.add_state(State.new("idle").keep_alive())\
	.from("idle").to("reload").on(self.magazine_pressed)\
	.from("idle").to_dynamic(func():
		if self.trigger_pressed:
			if self.loaded_rounds == 0:
				return "magazine_empty_click"
			return "jammed" if randf() > 0.95 else "fire_round")\
			
	.add_state(
		TimerState.new("magazine_empty_click", self.firing_interval)\
		.add_enter_event(play_sound.bind(click_sound)) )\
	.from("magazine_empty_click").to("idle").on_exit()\
	
	.add_state(
		StateMachine.new("jammed")
		.add_state(
			State.new("idle").keep_alive()
			.emit_on("clearing_jam", self.magazine_pressed))\
		.add_state(
			TimerState.new("click", firing_interval)
			.add_enter_event(play_sound.bind(click_sound)))
		.from("idle").to("click").on(self.is_trigger_pressed.bind())\
		.from("click").to("idle").on_exit())\
	.from("jammed").to("reload").on("jammed.idle.clearing_jam")\
	.add_state(self.fire_round_state("fire_round"))\
	.from("fire_round").to("idle").on_exit()
	
	StateQueue.new("reload")\
	.add_state(
		TweenState.new("mag_out", self, func(tween: Tween): 
			tween.tween_property($GunBody/Magazine, "position", Vector2(89, 85), .5))\
		.add_enter_event(play_sound.bind(reload_sound)))\
	.add_state(
		TweenState.new("mag_in", self, func(tween: Tween): 
			tween.tween_property($GunBody/Magazine, "position", Vector2(89, 45), .5)))\
	.add_exit_event(func(): self.loaded_rounds = self.magazine_capacity)\
	.add_to_runner(gun_state_machine)
	
	gun_state_machine.transition_on_exit("reload", "idle")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	gun_state_machine.run(delta, 1.0)

	self.queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if not event.pressed:
			#self.magazine_pressed = false
			self.trigger_pressed = false

func _on_magazine_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed == true:
			self.magazine_pressed.emit()
		#self.magazine_pressed = (event as InputEventMouseButton).pressed
		
func _on_trigger_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		self.trigger_pressed = (event as InputEventMouseButton).pressed
	
func is_trigger_pressed() -> bool:
	return self.trigger_pressed
	
#func is_magazine_pressed() -> bool:
	#return self.magazine_pressed
	
func play_sound(sound_stream):
	audio_player.stream = sound_stream
	audio_player.pitch_scale = randf_range(1.2, 1.4)
	audio_player.play()
	
func fire_round_state(state_id: String = "fire_round") -> State:
	return TweenState.new(state_id, self, func(tween: Tween):
		tween.tween_property($GunBody, "position", $GunBody.position - Vector2(32, 0), firing_interval + randf_range(-.01, 0.01)) )\
	.add_enter_event(func():
		play_sound(gunshot_sound)
		self.loaded_rounds -= 1)

func _draw() -> void:
	self.gun_state_machine.draw(Vector2(768, 64), self, 16, 8)
