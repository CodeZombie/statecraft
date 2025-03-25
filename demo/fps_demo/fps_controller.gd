extends CharacterBody3D

var speed_scale: float = 1.0
var _desired_speed_scale: float = speed_scale

@export var held_weapon: Gun

@export_group("Ground Movement")
@export var walk_speed: float = 6.0
@export var run_speed: float = 8.5
@export var crouch_speed: float = 3.5
@export var slide_friction: float = 3.0
@export var ground_accel := 11.0
@export var ground_decel := 7.0
@export var ground_friction := 3.5

@export_group("Air Movement")
@export var jump_velocity: float = 5.5
@export var air_move_cancel_factor := 3.5
@export var min_air_speed: float = 1.0
@export var air_deceleration: float = 12.0

@export_group("Height")
@export var standing_height: float = 2.0
@export var crouching_height: float = 1.0
@export var crouch_height_speed: float = 10.0

@export_group("Camera")
@export var normal_camera_fov: float = 75
@export var zoom_camera_fov: float = 40
@export var mouse_sensitivity: float = 0.1

@export_group("Animation")
# Not implemented yet
@export var crouch_curve: Curve
@export var jump_takeoff_curve: Curve
@export var ground_impact_curve: Curve

@export var controls : Dictionary = {
	LEFT = "ui_left",
	RIGHT = "ui_right",
	FORWARD = "ui_up",
	BACKWARD = "ui_down",
	JUMP = "ui_accept",
	CROUCH = "crouch",
	RUN = "run",
}

## Private Members
var _height: float = self.standing_height
var _mouse_input: Vector2 = Vector2.ZERO
var _camera_fov: float = self.normal_camera_fov
var _desired_direction: Vector3 = Vector3.ZERO

@onready var _prev_location: Vector3 = self.global_position
var _total_steps: float = 0.0
var _time_in_air: float = 0.0

@onready var _body_shape: Shape3D = $Body.shape
@onready var camera_3d: Camera3D = $Head/Camera3D
@onready var arm: Node3D = $Head/ARm

@onready var hand_hipfire_offset: Vector3 = $Head/ARm/Hand.position

var sights_fsm: StateMachine = StateMachine.new(^"sights_fsm")\
.add(State.new(^"idle", false))\
.add(TweenState.new(^"lifting_gun_to_face", self, func(tween: Tween):
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property($Head/Camera3D, ^"fov", self.zoom_camera_fov, 0.35)
	tween.parallel().tween_property($Head/ARm/Hand, ^"position", Vector3.ZERO, 0.2)))\
.add(State.new(^"in_ironsights", false))\
.add(TweenState.new(^"lowering_gun_from_face", self, func(tween: Tween):
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property($Head/Camera3D, ^"fov", self.normal_camera_fov, 0.2)
	tween.parallel().tween_property($Head/ARm/Hand, ^"position", self.hand_hipfire_offset, 0.3)))\
.from([^"idle", ^"lowering_gun_from_face"]).if_true(self.wants_iron_sights).then_transition_to(^"lifting_gun_to_face")\
.from([^"lifting_gun_to_face", ^"in_ironsights"]).if_false(self.wants_iron_sights).then_transition_to(^"lowering_gun_from_face")\
.on_signal_path(^"lifting_gun_to_face:exited").then_transition_to(^"in_ironsights")\
.on_signal_path(^"lowering_gun_from_face:exited").then_transition_to(^"idle")
#var sights_fsm: StateMachine = StateMachine.new(^"sights_fsm")\
	#.from(^"hipfire").if_true(self.wants_iron_sights).then_transition_to(^"aiming")\
	#.from(^"iron_sights").if_false(self.wants_iron_sights).then_transition_to(^"resting")\
	#.from(^"resting").on_signal(^"resting:exited").then_transition_to(^"hipfire")\
	#.from(^"aiming").on_signal(^"aiming:exited").then_transition_to(^"iron_sights")\
	#
	#.add(State.new(^"hipfire", false)
		#.add_enter_event(func():
			#camera_3d.position = Vector3.ZERO))\
	#
	#.add(State.new(^"iron_sights", false)
		#.add_enter_event(func():
			#camera_3d.position = Vector3(0.111, -0.021, 0.0)))\
	#
	#.add(StateQueue.new(^"resting")\
		#.set_execution_mode(StateQueue.ExecutionMode.PARALLEL)
		#
		#.add(TweenState.new(^"raise_head", self, func(tween: Tween): 
			#tween.tween_property(camera_3d, "position", Vector3.ZERO, 0.2)))
#
		#.add(TweenState.new(^"lower_gun", self, func(tween: Tween): 
			#tween.tween_property(arm, "position", Vector3.ZERO, 0.2)))
#
		#.add(TweenState.new(^"rotate_gun", self, func(tween: Tween): 
			#tween.tween_property(arm, "rotation", Vector3.ZERO, 0.2))))\
#
	#.add(StateQueue.new(^"aiming")\
		#.set_execution_mode(StateQueue.ExecutionMode.PARALLEL)
		#
		#.add(TweenState.new(^"lower_head", self, func(tween: Tween): 
			#tween.tween_property(camera_3d, "position", Vector3(0.111, -0.021, 0.0), 0.2)))
#
		#.add(TweenState.new(^"raise_gun", self, func(tween: Tween): 
			#tween.tween_property(arm, "position", Vector3(0.004, 0.027, 0.0), 0.2)))
			#
		#.add(TweenState.new(^"rotate_gun", self, func(tween: Tween): 
			#tween.tween_property(arm, "rotation_degrees", Vector3(-5.7, -3.0, -3.5), 0.2))))

#var camera_zoom_fsm: StateMachine = StateMachine.new(^"camera_controller")\
	#.add_process_event(func(delta: float):
		#$Head/Camera3D.fov = lerp($Head/Camera3D.fov, self._camera_fov, 8.0 * delta) 
		#self.speed_scale = lerp(self.speed_scale, self._desired_speed_scale, 12 * delta)
		#)\
		#
	#.from(^"normal").if_true(self.wants_to_zoom).then_transition_to(^"zoom")\
	#.from(^"zoom").if_false(self.wants_to_zoom).then_transition_to(^"normal")\
	#
	#.add(State.new("normal", false)
		#.add_enter_event(func(): 
			#self._desired_speed_scale = 1.0
			#self._camera_fov = self.normal_camera_fov) )\
	#
	#.add(State.new("zoom", false)
		#.add_enter_event(func(): 
			#self._desired_speed_scale = 0.2
			#self._camera_fov = self.zoom_camera_fov))

var fps_fsm: StateMachine = StateMachine.new(^"fps controller")\
	.add_process_event(self.global_physics_process)\
	# If we're crouching while jumping and we hit the ground, transition to the on_ground/crouching state.
	.from(^"in_the_air/stance/aircrouch").if_true(self.is_on_floor).then_transition_to(^"on_ground/crouching")\
	# If we're standing upright while in the air and we hit the ground, transition to the on_ground/standing state.
	.from(^"in_the_air/stance/airstand").if_true(self.is_on_floor).then_transition_to(^"on_ground/standing")\
	# If we're crouching while we hit the ground and we're going fast enough, start sliding
	.from(^"in_the_air/stance/aircrouch").if_true(self.is_on_floor).and_if_true(self.is_sprinting).then_transition_to(^"on_ground/crouching/sliding")\
	# If we were standing on the ground and now we're in the air, transition to air standing state.
	.from(^"on_ground/standing").if_false(self.is_on_floor).then_transition_to(^"in_the_air/stance/airstand")\
	# if we were regular crouchingg while on the ground and now we're not on the ground, transition to air crouch,
	.from(^"on_ground/crouching/idle").if_false(self.is_on_floor).then_transition_to(^"in_the_air/stance/aircrouch")\
	# If we were sliding on the ground and now we're in the air, transition to the aircrouch/glide state.
	.from(^"on_ground/crouching/sliding").if_false(self.is_on_floor).then_transition_to(^"in_the_air/stance/aircrouch/glide")\

	.add(StateMachine.new(^"on_ground")\
		.from(^"standing").if_true(self.wants_to_crouch).then_transition_to(^"crouching")
		.from(^"crouching").if_false(self.wants_to_crouch).then_transition_to(^"standing")

		.add(StateMachine.new(^"standing")
			.add_enter_event(self.set_standing_height)
			.if_true(self.is_hitting_head).then_transition_to(^"hitting_head")
			.from(^"walking").if_true(self.wants_to_run).then_transition_to(^"running")
			.from(^"running").if_false(self.wants_to_run).then_transition_to(^"walking")
			.from(^"hitting_head").if_false(self.is_hitting_head).then_transition_to(^"walking")

			.add(State.new(^"walking", false)
				.add_process_event(self.process_move_on_ground.bind(self.walk_speed))
				.if_true(self.wants_to_jump).then_call(self.jump)
			)

			.add(State.new(^"running", false)
				.add_process_event(self.process_move_on_ground.bind(self.run_speed))
				.if_true(self.wants_to_jump).then_call(self.jump)
			)
			
			.add(State.new(^"hitting_head", false)
				.add_enter_event(func(): self._height = self._body_shape.height)
				.add_process_event(self.process_move_on_ground.bind(self.crouch_speed))
				.add_process_event(func(delta: float):
					if self.is_on_ceiling(): self._height -= 0.05)
				.add_exit_event(self.set_standing_height)
			))

		.add(StateMachine.new(^"crouching")
			.add_enter_event(self.set_crouching_height)
			.if_true(func(): return self.real_speed() > self.walk_speed).then_transition_to(^"sliding")
			.from(^"sliding").if_true(func(): return self.real_speed() <= self.crouch_speed).then_transition_to(^"idle")
			
			.add(State.new(^"idle", false)
				.if_true(self.wants_to_jump).then_call(self.crouch_jump)
				.add_process_event(self.process_move_on_ground.bind(self.crouch_speed))
			)
				
			.add(State.new(^"sliding", false)
				.if_true(self.wants_to_jump).then_call(self.slide_jump)
				.add_process_event(self.process_sliding)
			)))\
			
	.add(StateQueue.new(^"in_the_air")\
		.set_execution_mode(StateQueue.ExecutionMode.PARALLEL)

		.add(StateMachine.new(^"stance")\
			.from(^"airstand").if_true(self.wants_to_crouch).then_transition_to(^"aircrouch")
			.from(^"aircrouch").if_false(self.wants_to_crouch).then_transition_to(^"airstand")
			
			.add(State.new(^"airstand", false)
				.add_process_event(self.process_move_in_air)
				.add_enter_event(self.set_standing_height) )

			.add(StateMachine.new(^"aircrouch")
				.add_enter_event(self.set_crouching_height)
				
				.add(State.new(^"idle", false)
					.add_process_event(self.process_move_in_air) )
					
				.add(State.new(^"glide", false)
					.add_process_event(self.process_sliding_in_air) )
			))

		.add(StateMachine.new(^"fall_controller")\
			.on_enter().and_if_true(self.is_jumping).then_transition_to(^"freefall")
			.on_enter().and_if_false(self.is_jumping).then_transition_to(^"coyote_timer")
			.from(^"coyote_timer").on_signal(^"coyote_timer:exited").then_transition_to(^"freefall")

			.add(State.new(^"coyote_timer", false)
				.if_true(self.wants_to_jump).then_call(self.jump)
				.if_true(self.wants_to_jump).then_exit()
				.on_timer(0.25).then_exit())

			.add(StateMachine.new(^"freefall")
				.from(^"awaiting_walljump").on_signal(^"awaiting_walljump:walljumped").then_transition_to(^"walljump")
				.from(^"walljump").on_signal(^"walljump:exited").then_transition_to(^"awaiting_walljump")
				
				.add(State.new(^"awaiting_walljump", false)
					.add_signal(&"walljumped")
					.if_true(self.wants_to_jump).and_if_true(self.is_on_wall).then_emit(&"walljumped") )
					
				.add(State.new(^"walljump", false)
					.add_enter_event(self.wall_jump)
					.on_timer(0.75).then_exit() )
			)))
			
func _ready() -> void:
	# Capture mouse movement.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	$fps_controller_vis.state_machine = self.fps_fsm
	#$zoom_controller_vis.state_machine = self.camera_zoom_fsm
	$aiming_controller_vis.state_machine = self.sights_fsm
	
	self.held_weapon.get_speed_scale_method = self.get_speed_scale

func _physics_process(delta: float) -> void:
		# update the State Mahcines
	self.fps_fsm.run(delta, self.speed_scale)
	self.sights_fsm.run(delta, self.speed_scale)
	#self.camera_zoom_fsm.run(delta, self.speed_scale)
	
func global_physics_process(delta: float) -> void:
	var footstep_speed: float = (self.global_position - self._prev_location).length()
	if self.in_the_air():
		self._time_in_air += delta
	else:
		self._time_in_air = 0.0
		
	footstep_speed = max(0.0, footstep_speed - self._time_in_air / 6.0)
	if self.is_crouching():
		footstep_speed /= 2.0
	
	self._total_steps += footstep_speed
	self._prev_location = self.global_position
	# Apply gravity
	self.velocity.y -= ProjectSettings.get_setting(&"physics/3d/default_gravity") * delta
	
	self.arm.position.y = sin(self._total_steps / 75.0 * 100.0) * 0.15 * footstep_speed * delta * 10.0
	self.arm.position.x = sin(self._total_steps / 150.0 * 100.0) * 0.05 * footstep_speed * delta * 10.0
	self.arm.position.z = sin(self._total_steps / 200.0 * 100.0) * 0.025 * footstep_speed * delta * 10.0
	$Head/ARm/Hand/ak_308.rotation.x = sin(self._total_steps / 200.0 * 100.0) * 1.25 * footstep_speed * delta * 10.0
	$Head/ARm/Hand/ak_308/Sketchfab_model.rotation.y = sin(self._total_steps / 125.0 * 100.0) * (PI/4.0) * footstep_speed * delta * 10.0
	
	
	# Apply basic movement physics
	var old_velocity = self.velocity
	self.velocity *= 60 * delta
	self.move_and_slide()
	self.velocity = old_velocity


	
	# Apply crouching/standing height interpolation
	self._body_shape.height = move_toward(self._body_shape.height, self._height, max(0.05, self.crouch_height_speed * delta))

func _process(delta: float) -> void:
	
	# Apply mouselook
	self.rotation_degrees.y -= self._mouse_input.x * self.mouse_sensitivity
	$Head.rotation_degrees.x -= self._mouse_input.y * self.mouse_sensitivity
	$Head.rotation_degrees.x = clamp($Head.rotation_degrees.x, -90, 90)
	self._mouse_input = Vector2.ZERO
	
	# Update the direction the player wants to move in.
	var input_dir: Vector2 = Input.get_vector(controls.LEFT, controls.RIGHT, controls.FORWARD, controls.BACKWARD).normalized()
	self._desired_direction = self.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	
	# Pass events to the held weapon object:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		self.held_weapon.squeeze_trigger()
	if Input.is_key_pressed(KEY_R):
		self.held_weapon.reload()
	
func _unhandled_input(event : InputEvent):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Store mouse movement to be later applied to the camera's rotation
		self._mouse_input.x += event.relative.x
		self._mouse_input.y += event.relative.y

## Conditions

func is_moving() -> bool:
	return self.real_speed() > 0

func wants_to_jump() -> bool:
	return Input.is_action_just_pressed(controls.JUMP)

func is_hitting_head() -> bool:
	return $Head/CeilingDetector.is_colliding()

func wants_to_crouch() -> bool:
	return Input.is_action_pressed(controls.CROUCH)

func wants_to_run() -> bool:
	return Input.is_action_pressed(controls.RUN)
	
func in_the_air() -> bool:
	return not self.is_on_floor()
	
func is_jumping() -> bool:
	return self.velocity.y > 0

func is_crouching() -> bool:
	return self._body_shape.height == self.crouching_height

func wants_to_zoom() -> bool:
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)

func wants_iron_sights() -> bool:
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

func is_sprinting() -> bool:
	return self.is_on_floor() and not self.is_crouching() and self.real_speed() >= self.run_speed - 1.0
	
func is_walking() -> bool:
	return self.is_on_floor() and not self.is_crouching() and self.real_speed() < self.run_speed - 1.0 and self.real_speed() >= self.walk_speed - 1.0

## Computed properties

func real_speed() -> float:
	return Vector2(self.velocity.x, self.velocity.z).length()

func get_speed_scale() -> float:
	return self.speed_scale

## Actions

func jump() -> void:
	if not self.is_hitting_head():
		self.velocity.y = self.jump_velocity
	
func crouch_jump() -> void:
	if not self.is_hitting_head():
		self.velocity.y = (self.jump_velocity / 1.5)

func wall_jump() -> void:
	var collision_count: int = self.get_slide_collision_count()
	var wall_jump_normal: Vector3 = Vector3.ZERO
	for i in range(collision_count):
		wall_jump_normal += get_slide_collision(i).get_normal().normalized()
	wall_jump_normal = wall_jump_normal.normalized()
	wall_jump_normal += Vector3(self.velocity.normalized().x, 0.0, self.velocity.normalized().z)
	wall_jump_normal = wall_jump_normal.normalized()
	var current_velocity: float = self.real_speed()
	self.velocity = wall_jump_normal * current_velocity
	self.velocity.y += current_velocity

func slide_jump() -> void:
	if not self.is_hitting_head():
		self.velocity.y = (self.jump_velocity * 1.25)

func set_standing_height() -> void:
	self._height = self.standing_height

func set_crouching_height() -> void:
	self._height = self.crouching_height

func process_move_on_ground(delta: float, speed: float) -> void:
	#var base_movement_direction: Vector2 = Input.get_vector(controls.LEFT, controls.RIGHT, controls.FORWARD, controls.BACKWARD)
	#var direction = base_movement_direction.rotated(-$Head.rotation.y)
	#direction = Vector3(direction.x, 0, direction.y)
	#self.velocity.x = lerp(velocity.x, direction.x * self._speed, acceleration * delta)
	#self.velocity.z = lerp(velocity.z, direction.z * self._speed, acceleration * delta)

	# Similar to the air movement. Acceleration and friction on ground.
	var cur_speed_in_desired_direction = self.velocity.dot(self._desired_direction)
	var add_speed_till_cap = speed - cur_speed_in_desired_direction
	if add_speed_till_cap > 0:
		var accel_speed = self.ground_accel * delta * self.run_speed
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * self._desired_direction
	
	# Apply friction
	var control = max(self.velocity.length(), self.ground_decel)
	var drop = control * self.ground_friction * delta
	var new_speed = max(self.velocity.length() - drop, 0.0)
	if self.velocity.length() > 0:
		new_speed /= self.velocity.length()
	self.velocity *= new_speed
		
func process_move_in_air(delta: float) -> void:
	if self._desired_direction.length() > 0:
		var current_velocity_y = self.velocity.y
		var movement_speed: float = max(self.min_air_speed, Vector2(self.velocity.x, self.velocity.z).length())
		var desired_direction_with_speed: Vector3 = self._desired_direction * movement_speed
		desired_direction_with_speed.y = current_velocity_y
		self.velocity = self.velocity.move_toward(desired_direction_with_speed, self.air_deceleration * delta)

func process_sliding(delta: float) -> void:
	var slide_velocity: Vector2 = Vector2(velocity.x, velocity.z).normalized() * (self.real_speed() - (self.slide_friction * delta))
	self.velocity.x = slide_velocity.x #lerp(velocity.x, slide_velocity.x, 1.0 * delta)
	self.velocity.z = slide_velocity.y #lerp(velocity.z, slide_velocity.y, 1.0 * delta)

func process_sliding_in_air(delta: float) -> void:
	# Similar to `process_move_in_air` but doesnt allow you to change direction in the air, only slow down/stop.
	var desire_to_go_backwards: float = -self.velocity.normalized().dot(self._desired_direction.normalized())
	if desire_to_go_backwards > 0:
		self.velocity.x *= 1 - (desire_to_go_backwards * self.air_move_cancel_factor * delta)
		self.velocity.z *= 1 - (desire_to_go_backwards * self.air_move_cancel_factor * delta)
