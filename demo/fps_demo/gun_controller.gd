class_name Gun extends Node3D

signal shoot_signal
signal reload_signal
signal trigger_muzzle_flash
signal trigger_bullet_spawn

const BULLET = preload("res://demo/fps_demo/bullet.tscn")

var gunshot_sound = preload("res://demo/assets/gunshot.mp3")
var reload_sound = preload("res://demo/assets/reload.mp3")
var click_sound = preload("res://demo/assets/click.mp3")


var get_speed_scale_method: Callable

var mag_capacity: int = 500
var rounds_in_mag: int = self.mag_capacity

var active_bullets: Array[Object] = []

@export var gun_fsm_vis: FSMVis

@export var fire_rate: float = 0.2
@export var muzzle_velocity: float = 280.0

@export var root: Node3D
@export var audio_player: AudioStreamPlayer3D
@export var bullet_impulse_origin: Marker3D
@export var bullet_spawn_marker: Marker3D


@onready var gun_fsm: StateMachine = StateMachine.new(^"gun_fsm")\
	.from(^"idle").on_signal(self.shoot_signal).and_if_false(self.gun_is_empty).then_transition_to(^"shoot")\
	.from(^"idle").on_signal(self.shoot_signal).and_if_true(self.gun_is_empty).then_transition_to(^"empty_fire")\
	.from([^"idle", ^"shoot"]).on_signal(self.reload_signal).then_transition_to(^"reload")\
	.from(^"shoot").on_signal(^"shoot:exited").then_transition_to(^"idle")\
	.from(^"empty_fire").on_signal(^"empty_fire:exited").then_transition_to(^"idle")\
	.from(^"reload").on_signal(^"reload:exited").then_transition_to(^"idle")\

	.add(State.new(^"idle", false))\
	
	# Tween states allow a state to execute a tween, exiting upon completion.
	# Tweens need to be defined using a callback so that they can be re-created every time this state enters.
	# Godot does not allow states to be "re-run" - they must be re-created if you want them to run again, and this
	# callback system allows us to do that dynamically.
	.add(TweenState.new(^"shoot", self, func(tween: Tween):
			var original_position: Vector3 = self.position
			var kickback_position: Vector3 = Vector3(
				self.position.x + randf_range(-0.005, 0.005),
				self.position.y + randf_range(0, 0.005),
				self.position.z + randf_range(0.2, 0.3),
				)
			# Push back into the player's shoulder
			tween.set_trans(Tween.TRANS_ELASTIC)
			tween.set_ease(Tween.EASE_OUT)
			tween.tween_property(self, ^":position", kickback_position, min(0.15, self.fire_rate / 2.0)) 
			# Return to original position
			tween.tween_property(self, ^":position", original_position, min(0.15, self.fire_rate / 2.0)) )
		.add_enter_event(func():
			var bullet = BULLET.instantiate()
			bullet.get_speed_scale_method = self.get_speed_scale_method
			root.add_child(bullet)
			bullet.global_transform.basis = bullet_spawn_marker.global_transform.basis
			bullet.global_position = bullet_spawn_marker.global_position
			var direction = (bullet_spawn_marker.global_position - bullet_impulse_origin.global_position).normalized()
			bullet.velocity_vector = direction*muzzle_velocity
			self.rounds_in_mag -= 1
			self.play_sound(self.gunshot_sound)
			self.trigger_muzzle_flash.emit()
			self.trigger_bullet_spawn.emit()))\

	.add(State.new(^"empty_fire", false)
		.add_enter_event(func(): self.play_sound(self.click_sound))
		.on_dynamic_timer(randf_range.bind(self.fire_rate - 0.05, self.fire_rate + 0.05)).then_exit())\
		
	.add(State.new(^"reload", false)
		.on_timer(0.75).then_exit()
		.add_enter_event(func():
			self.play_sound(self.reload_sound) )
		.add_exit_event(func():
			self.rounds_in_mag = self.mag_capacity ))

	#.on_signal(animation_player.animation_finished, func(n: StringName): return n == &"LVA4_Armature|wpn_val_shoot").then_exit())
var muzzle_flash_fsm: StateMachine = StateMachine.new("muzzle_flash_controller")\
	.from(^"idle").on_signal(self.trigger_muzzle_flash).then_transition_to(^"flash")\
	.from(^"flash").on_signal(^"flash:exited").then_transition_to(^"idle")\

	.add(State.new(^"idle", false)
		.add_enter_event(func(): $muzzle_flash_light.visible = false))\
		
	.add(State.new("flash", false)
		.add_enter_event(func():$muzzle_flash_light.visible = true)
		.on_timer(0.1).then_exit() )

func _ready() -> void:
	self.gun_fsm_vis.state_machine = self.gun_fsm

func _process(delta: float) -> void:
	gun_fsm.run(delta, self.get_speed_scale_method.call())
	muzzle_flash_fsm.run(delta, self.get_speed_scale_method.call())
	self.audio_player.pitch_scale = self.get_speed_scale_method.call()
	
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
