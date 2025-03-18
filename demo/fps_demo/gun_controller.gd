class_name Gun extends Node3D

signal shoot_signal
signal reload_signal
signal trigger_muzzle_flash

var gunshot_sound = preload("res://demo/assets/gunshot.mp3")
var reload_sound = preload("res://demo/assets/reload.mp3")
var click_sound = preload("res://demo/assets/click.mp3")

# These two properties need to be set from an outside object.
# They should hold methods that tell this gun whether the oject holding it is running or walking.
var walk_animation_condition: Callable
var run_animation_condition: Callable

var mag_capacity: int = 12
var rounds_in_mag: int = self.mag_capacity

@export var fire_rate: float = 0.1

@export var animation_player: AnimationPlayer
@export var audio_player: AudioStreamPlayer3D

@onready var gun_fsm: StateMachine = StateMachine.new(^"gun_fsm")\
	.from(^"idle").on_signal(self.shoot_signal).and_if_false(self.gun_is_empty).then_transition_to(^"shoot")\
	.from(^"idle").on_signal(self.shoot_signal).and_if_true(self.gun_is_empty).then_transition_to(^"empty_fire")\
	.from([^"idle", ^"shoot"]).on_signal(self.reload_signal).then_transition_to(^"reload")\
	.from(^"shoot").on_signal(^"shoot:exited").then_transition_to(^"idle")\
	.from(^"empty_fire").on_signal(^"empty_fire:exited").then_transition_to(^"idle")\
	.from(^"reload").on_signal(^"reload:exited").then_transition_to(^"idle")\

	.add(StateMachine.new(^"idle")
		.from([^"walk", ^"sprint"]).if_false(self.should_play_walk_animation).and_if_false(self.should_play_run_animation).then_transition_to(^"static")
		.from([^"static", ^"sprint"]).if_true(self.should_play_walk_animation).then_transition_to(^"walk")
		.from([^"static", ^"walk"]).if_true(self.should_play_run_animation).then_transition_to(^"sprint")
		
		.add(State.new(^"static", false)
			.add_enter_event(self.play_animation.bind(&"LVA4_Armature|wpn_val_idle")) )
			
		.add(State.new(^"walk", false)
			.add_enter_event(self.play_animation.bind(&"LVA4_Armature|wpn_val_walk")) )
			
		.add(State.new(^"sprint", false)
			.add_enter_event(self.play_animation.bind(&"LVA4_Armature|wpn_val_sprint"))) )\
	
	# Tween states allow a state to execute a tween, exiting upon completion.
	# Tweens need to be defined using a callback so that they can be re-created every time this state enters.
	# Godot does not allow states to be "re-run" - they must be re-created if you want them to run again, and this
	# callback system allows us to do that dynamically.
	.add(TweenState.new(^"shoot", self, func(tween: Tween): 
			# Push back into the player's shoulder
			tween.tween_property(self, ^":position:z", .1, min(0.15, self.fire_rate / 2.0)) 
			# Return to original position
			tween.tween_property(self, ^":position:z", 0.0, min(0.15, self.fire_rate / 2.0)) )
		.add_enter_event(func(): 
			self.play_animation(&"LVA4_Armature|wpn_val_shoot")
			self.rounds_in_mag -= 1
			self.play_sound(self.gunshot_sound)
			self.trigger_muzzle_flash.emit()))\

	.add(State.new(^"empty_fire", false)
		.add_enter_event(func(): self.play_sound(self.click_sound))
		.on_timer(self.fire_rate).then_exit())\
		
	.add(State.new(^"reload", false)
		.add_enter_event(func():
			self.play_animation(&"LVA4_Armature|wpn_val_reload")
			self.play_sound(self.reload_sound) )
		.add_exit_event(func():
			self.rounds_in_mag = self.mag_capacity )
		# There's a little bit of magic going on on this line.
		# We want the State to exit when the animation finishes, so what we're doing here is:
		# Hooking up a listener to the `animation_player.animation_finished` signal.
		# However, the reaction (then_exit()) will only occur if the "filter" condition function is true.
		# In this case, the filter condition function returns true if the animation name value that the signal is emitted with is
		# the the same reload animation this state triggered in the enter event.
		.on_signal(animation_player.animation_finished, func(animation_name: StringName): return animation_name == &"LVA4_Armature|wpn_val_reload").then_exit())

	#.on_signal(animation_player.animation_finished, func(n: StringName): return n == &"LVA4_Armature|wpn_val_shoot").then_exit())
var muzzle_flash_fsm: StateMachine = StateMachine.new("muzzle_flash_controller")\
	.from(^"idle").on_signal(self.trigger_muzzle_flash).then_transition_to(^"flash")\
	.from(^"flash").on_signal(^"flash:exited").then_transition_to(^"idle")\

	.add(State.new(^"idle", false)
		.add_enter_event(func(): $muzzle_flash.visible = false))\
		
	.add(State.new("flash", false)
		.add_enter_event(func():$muzzle_flash.visible = true)
		.on_timer(0.1).then_exit() )
	
func _ready() -> void:
	$gun_controller_vis.state_machine = self.gun_fsm	

func play_animation(animation_name: StringName) -> void:
	$AnimationPlayer.play(animation_name)
	
func _process(delta: float) -> void:
	gun_fsm.run(delta)
	muzzle_flash_fsm.run(delta)
	
### Conditions:
func should_play_walk_animation() -> bool:
	return self.walk_animation_condition.call()
	
func should_play_run_animation() -> bool:
	return self.run_animation_condition.call()
	
func gun_is_empty() -> bool:
	return self.rounds_in_mag == 0

### ACTIONS:
func play_sound(sound_stream):
	audio_player.stream = sound_stream
	audio_player.pitch_scale = randf_range(1.2, 1.4)
	audio_player.play()

### PUBLIC METHODS:
func squeeze_trigger():
	self.shoot_signal.emit()
	
func reload():
	self.reload_signal.emit()
