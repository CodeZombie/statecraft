extends CharacterBody3D

@export var arm: Node3D
@export_group("Basics")
@export var walk_speed: float = 5
@export var run_speed: float = 8
@export var crouch_speed: float = 1.0
@export var air_drag: float = 0.5
@export var jump_velocity: float = 5
@export var jump_movement_speed: float = 2.0
@export var standing_height: float = 2.0
@export var crouching_height: float = 1.0
@export var crouch_height_speed: float = 10.0
@export var normal_camera_fov: float = 75
@export var zoom_camera_fov: float = 40

@export_group("Advanced")
@export var acceleration: float = 10.0
@export var air_deceleration: float = 2.0
@export var mouse_sensitivity: float = 0.1

@export_group("Animation")
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
var _speed: float = 0.0
var _height: float = self.standing_height
var _mouse_input: Vector2 = Vector2.ZERO
var _camera_fov: float = self.normal_camera_fov
#var _head_height_offset_multiplier: float = 1.0

@onready var body_shape: Shape3D = $Body.shape

var camera_zoom_fsm: StateMachine = StateMachine.new(^"camera_controller")\
	.add_process_event(func(delta: float):
		$Head/Camera3D.fov = lerp($Head/Camera3D.fov, self._camera_fov, 8.0 * delta)
		)\
	.on(self.wants_to_zoom).then_transition([^"normal"], ^"zoom")\
	.on_inv(self.wants_to_zoom).then_transition([^"zoom"], ^"normal")\
	.add(State.new("normal")
		.keep_alive()
		.add_enter_event(func(): self._camera_fov = self.normal_camera_fov) )\
	.add(State.new("zoom")
		.keep_alive()
		.add_enter_event(func(): self._camera_fov = self.zoom_camera_fov))

var fps_fsm: StateMachine = StateMachine.new(^"fps controller")\
	.on(self.is_on_floor).then_transition([^"in_the_air/stance/aircrouch"], ^"on_ground/crouching")\
	.on(self.is_on_floor).then_transition([^"in_the_air/stance/airstand"], ^"on_ground/standing")\
	.on_inv(self.is_on_floor).then_transition([^"on_ground/standing"], ^"in_the_air/stance/airstand")\
	.on_inv(self.is_on_floor).then_transition([^"on_ground/crouching/idle"], ^"in_the_air/stance/aircrouch")\
	.on_inv(self.is_on_floor).then_transition([^"on_ground/crouching/sliding"], ^"in_the_air/stance/aircrouch/glide")\

	.add(StateMachine.new(^"on_ground")\
		.on(self.wants_to_crouch).then_transition([^"standing"], ^"crouching")
		.on_inv(self.wants_to_crouch).then_transition([^"crouching"], ^"standing/walking")
		
		.add(StateMachine.new(^"standing")
			.add_process_event(self.process_move_on_ground)
			.add_enter_event(self.set_standing_height)
			.on(self.wants_to_run).then_transition([^"walking"], ^"running")
			.on_inv(self.wants_to_run).then_transition([^"running"], ^"walking")
			.on(self.is_hitting_head).then_transition_from_any(^"hitting_head")
			.on_inv(self.is_hitting_head).then_transition([^"hitting_head"], ^"walking")
			
			.add(State.new(^"hitting_head")
				.keep_alive()
				.add_enter_event(self.set_crouch_speed)
				.add_enter_event(func(): self._height = self.body_shape.height)
				.add_exit_event(self.set_standing_height)
				.add_process_event(func(delta: float):
					if self.is_on_ceiling(): self._height -= 0.05)
			)

			.add(State.new(^"walking")
				.keep_alive()
				.on(self.wants_to_jump).then_call(self.jump)
				.add_enter_event(self.set_walk_speed)
			)

			.add(State.new(^"running")
				.keep_alive()
				.on(self.wants_to_jump).then_call(self.jump)
				.add_enter_event(self.set_run_speed)
			))

		.add(StateMachine.new(^"crouching")
			.keep_alive()
			
			.add_enter_event(self.set_crouching_height)
			.on(func(): return self.real_speed() > self.walk_speed).then_transition_from_any(^"sliding")
			.on(func(): return self.real_speed() <= self.crouch_speed).then_transition([^"sliding"], ^"idle")
			
			.add(State.new(^"idle")
			.on(self.wants_to_jump).then_call(self.crouch_jump)
				.add_process_event(self.process_move_on_ground)
				.keep_alive()
				.add_enter_event(self.set_crouch_speed)
				.keep_alive()
			)
				
			.add(State.new(^"sliding")
				.on(self.wants_to_jump).then_call(self.jump)
				.add_process_event(self.process_sliding)
				.keep_alive()
				.add_process_event(func(delta_: float): self._speed -= 0.1 * delta_) 
			)))\
			
	.add(StateQueue.new(^"in_the_air")\
		.keep_alive()
		.set_execution_mode(StateQueue.ExecutionMode.PARALLEL)

		.add(StateMachine.new(^"stance")\
			.on(self.wants_to_crouch).then_transition([^"airstand"], ^"aircrouch")
			.on_inv(self.wants_to_crouch).then_transition([^"aircrouch"], ^"airstand")
			
			.add(State.new(^"airstand")
				.keep_alive()
				.add_process_event(self.process_move_in_air)
				.add_enter_event(self.set_standing_height))

			.add(StateMachine.new(^"aircrouch")
				.keep_alive()
				.add_enter_event(self.set_crouching_height)
				.add(State.new(^"idle")
					.keep_alive()
					.add_process_event(self.process_move_in_air))
				.add(State.new(^"glide")
					.keep_alive()
					.add_process_event(self.process_sliding_in_air)
				)	
			))

		.add(StateMachine.new(^"fall_controller")\
			.on_enter().also(self.is_jumping).then_transition_from_any(^"freefall")
			.on_enter().also_inv(self.is_jumping).then_transition_from_any(^"coyote_timer")
			.on_signal(^"coyote_timer:exited").then_transition([^"coyote_timer"], ^"freefall")

			.add(State.new(^"coyote_timer")
				.keep_alive()
				.on(self.wants_to_jump).then_call(self.jump) # Despite there being two `self.wants_to_jump` checks, only one will be executed.
				.on(self.wants_to_jump).then_exit() # Despite `exit()` coming after `execute()`, they will both be guaranteed to execute.
				.on_timer(0.25).then_exit())

			.add(State.new(^"freefall")
				.keep_alive()
			)))

	
func _ready() -> void:
	# Capture mouse movement, so we can look around
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	self.floor_snap_length = 1.0
	
func overshoot_lerp(start, end, time, damping = 0.5):                     
		#Simple harmonic motion with damping.                                     
		var pos = start + (end - start) * (1.0 - exp(-damping * time) * cos(2.0 * PI * time))                                                                    
		return pos

func _physics_process(delta: float) -> void:
	# update the FSM
	self.fps_fsm.run(delta)
	self.camera_zoom_fsm.run(delta)
	


	# Show FSM debug
	$Control/Label.text = self.fps_fsm.as_string()
	$Control/Label.text += "\nCeiling Detector Colliding? " + str($Head/CeilingDetector.is_colliding())
	$Control/Label.text += "\n Body Height: " + str(self.body_shape.height)
	$Control/Label.text += "\n _speed: " + str(self._speed)
	$Control/Label.text += "\n real_speed: " + str(self.real_speed())
	
	# Apply basic movement physics
	self.move_and_slide()
	
	# Apply mouselook
	$Head.rotation_degrees.y -= self._mouse_input.x * self.mouse_sensitivity
	$Head.rotation_degrees.x -= self._mouse_input.y * mouse_sensitivity
	$Head.rotation.x = clamp($Head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	self._mouse_input = Vector2.ZERO

	# Apply gravity
	if self.in_the_air():
		velocity.y -= 9.8 * delta

	# Apply crouching/standing height interpolation
	self.body_shape.height = lerp(self.body_shape.height, self._height, self.crouch_height_speed * delta)


	self.arm.global_position = lerp(self.arm.global_position, $Head.global_position, 32.0 * delta)
	self.arm.rotation = lerp(self.arm.rotation, $Head.rotation, 32.0 * delta)

func _unhandled_input(event : InputEvent):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Store mouse movement to be later applied to the camera's rotation
		self._mouse_input.x += event.relative.x
		self._mouse_input.y += event.relative.y

## Conditions

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

func wants_to_zoom() -> bool:
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

## Computed properties

func real_speed() -> float:
	return Vector2(self.velocity.x, self.velocity.z).length()

## Actions

func jump() -> void:
	if not self.is_hitting_head():
		self.velocity.y = self.jump_velocity
	
func crouch_jump() -> void:
	if not self.is_hitting_head():
		self.velocity.y += (self.jump_velocity / 1.5)

func set_crouch_speed() -> void:
	self._speed = self.crouch_speed

func set_walk_speed() -> void:
	self._speed = self.walk_speed

func set_run_speed() -> void:
	self._speed = self.run_speed

func set_standing_height() -> void:
	self._height = self.standing_height

func set_crouching_height() -> void:
	self._height = self.crouching_height

func process_move_on_ground(delta: float) -> void:
	var base_movement_direction: Vector2 = Input.get_vector(controls.LEFT, controls.RIGHT, controls.FORWARD, controls.BACKWARD)
	var direction = base_movement_direction.rotated(-$Head.rotation.y)
	direction = Vector3(direction.x, 0, direction.y)
	self.velocity.x = lerp(velocity.x, direction.x * self._speed, acceleration * delta)
	self.velocity.z = lerp(velocity.z, direction.z * self._speed, acceleration * delta)

func process_move_in_air(delta: float) -> void:
	var base_movement_direction: Vector2 = Input.get_vector(controls.LEFT, controls.RIGHT, controls.FORWARD, controls.BACKWARD)
	var direction = base_movement_direction.rotated(-$Head.rotation.y)
	direction = Vector3(direction.x, 0, direction.y)
	self.velocity.x = lerp(velocity.x, direction.x * self._speed * self.air_drag, self.air_deceleration * delta)
	self.velocity.z = lerp(velocity.z, direction.z * self._speed * self.air_drag, self.air_deceleration * delta)

func process_sliding(delta: float) -> void:
	self.velocity.x = lerp(velocity.x, 0.0, 1.0 * delta)
	self.velocity.z = lerp(velocity.z, 0.0, 1.0 * delta)

func process_sliding_in_air(delta: float) -> void:
	self.velocity.x = lerp(velocity.x, 0.0, 0.1 * delta)
	self.velocity.z = lerp(velocity.z, 0.0, 0.1 * delta)
