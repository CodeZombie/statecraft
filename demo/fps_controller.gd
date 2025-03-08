extends CharacterBody3D

@export_group("Basics")
@export var walk_speed: float = 5
@export var run_speed: float = 8
@export var crouch_speed: float = 1.0
@export var air_drag: float = 0.5
@export var jump_velocity: float = 4.5
@export var jump_movement_speed: float = 2.0
@export var standing_height: float = 2.0
@export var crouching_height: float = 1.0
@export var crouch_height_speed: float = 10.0

@export_group("Advanced")
@export var acceleration: float = 10.0
@export var air_deceleration: float = 2.0
@export var mouse_sensitivity: float = 0.1
@export var crouch_height_offset_multiplier: float = 0.5

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
#var _head_height_offset_multiplier: float = 1.0

@onready var body_shape: Shape3D = $Body.shape


#var _fps_controller: StateMachine = StateMachine.new("fps controller")\
##.on(self.wants_to_jump).transition("on_ground", "jump")\
#.add_state(
	#StateMachine.new("on_ground")\
	#.add_entered_callback(func(): print("NICE"))
	#.on_enter().then_execute(func(): print("HI"))
	#.on_update().then_execute(func(delta: float):
		#var base_movement_direction: Vector2 = Input.get_vector(controls.LEFT, controls.RIGHT, controls.FORWARD, controls.BACKWARD)
		#var direction = base_movement_direction.rotated(-$Head.rotation.y)
		#direction = Vector3(direction.x, 0, direction.y)
		#self.velocity.x = lerp(velocity.x, direction.x * _speed, acceleration * delta)
		#self.velocity.z = lerp(velocity.z, direction.z * _speed, acceleration * delta))
	#.on(self.wants_to_crouch).transition("walking", "crouching")
	#.on_inv(self.wants_to_crouch).transition("crouching", "walking")
	#.on(self.wants_to_run).transition("walking", "running")
	#.on_inv(self.wants_to_run).transition("running", "walking")
	#.on(self.wants_to_crouch).transition("running", "crouching")
	#.add_state(
		#State.new("walking")\
		#.keep_alive()
		#.on_enter().then_execute(func(): 
			#self._speed = self.walk_speed
			#self._height = self.standing_height))\
	#.add_state(
		#State.new("running")\
		#.keep_alive()
		#.on_enter().then_execute(func():
			#self._speed = self.run_speed
			#self._height = self.standing_height))
	#.add_state(
		#State.new("crouching")\
		#.keep_alive()
		#.on_enter().then_execute(func():
			#self._speed = self.crouch_speed
			#self._height = self.crouching_height)))\
#.add_state(
	#State.new("jump")
	#.on_enter().then_execute(func(): self.velocity.y -= 10.0))\
#.on_child_exited("jump").transition_from_any("in_the_air.fall_controller.freefall.awaiting_liftoff")\
#.on(self.is_on_floor).transition("in_the_air.fall_controller.freefall.awaiting_landing", "on_ground")\
#.add_state(
	#StateQueue.new("in_the_air")
	#.set_execution_mode(StateQueue.ExecutionMode.PARALLEL)
	#.on_update().then_execute(func(delta: float):
		#var base_movement_direction: Vector2 = Input.get_vector(controls.LEFT, controls.RIGHT, controls.FORWARD, controls.BACKWARD)
		#var direction = base_movement_direction.rotated(-$Head.rotation.y)
		#direction = Vector3(direction.x, 0, direction.y)
		#self.velocity.x = lerp(velocity.x, direction.x * self._speed * self.air_drag, self.air_deceleration * delta)
		#self.velocity.z = lerp(velocity.z, direction.z * self._speed * self.air_drag, self.air_deceleration * delta))
	#.add_state(
		#StateMachine.new("stance_controller")
		#.on_enter().also_inv(self.wants_to_crouch).transition_from_any("standing")
		#.on_enter().also(self.wants_to_crouch).transition_from_any("crouching")
		#.on(self.wants_to_crouch).transition_from_any("crouching")
		#.on_inv(self.wants_to_crouch).transition_from_any("standing")
		#.add_state(
			#State.new("standing")
			#.on_enter().then_execute(func(): self._height = self.standing_height))
		#.add_state(
			#State.new("crouching")
			#.on_enter().then_execute(func(): self._height = self.crouching_height)))
	#.add_state(
		#StateMachine.new("fall_controller")
		#.on_child_exited("coyote_timer").transition_from_any("freefall")
		#.add_state(
			#State.new("coyote_timer")
			#.on_timer(1.5).then_exit())
		#.add_state(
			#StateMachine.new("freefall")
			#.on_child_exited("awaiting_liftoff").transition_from_any("awaiting_landing")
			#.add_state(
				#TimerState.new("awaiting_liftoff", 0.2))
			#.add_state(
				#State.new("awaiting_landing").keep_alive())
			#)
	#)
#)



var test_fsm: StateMachine = StateMachine.new(^"tst_fsm")\
#.on(self.wants_to_crouch).then_execute(func(delta: float): print("Crouch pressed"))\
#.on_enter().then_execute(func(): print("Entered :)"))\
#.on_update().then_execute(func(delta: float): self.position.x += 2 * delta)\
#.on_update().then_execute(func(delta: float, state_: State): self.position.x -= 1 * delta)\
.on(func(): 
	print("Pooop fuck")
	return self.wants_to_crouch).transition("stand", "crouch")\
#.on(self.wants_to_crouch).then_execute(func(): print("pee and poo"))\
#.on_inv(self.wants_to_crouch).transition("crouch", "stand")\
#.on_child_exited("crouch").then_execute(func(state_: State): print("Nice"))\
.add_state(State.new("stand").keep_alive())\
.add_state(State.new("crouch").keep_alive())

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	#self._fps_controller.run(delta)
	self.test_fsm.run(delta)
	$Control/Label.text = self.test_fsm.as_string()
	$Control/Label.text += "\nCeiling Detector Colliding? " + str($Head/CeilingDetector.is_colliding())
	$Control/Label.text += "\n Body Height: " + str(self.body_shape.height)
	$Control/Label.text += "\n _speed: " + str(self._speed)
	
	self.move_and_slide()

	$Head.rotation_degrees.y -= self._mouse_input.x * self.mouse_sensitivity
	$Head.rotation_degrees.x -= self._mouse_input.y * mouse_sensitivity
	$Head.rotation.x = clamp($Head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	self._mouse_input = Vector2.ZERO

	if self.in_the_air():
		velocity.y -= 9.8 * delta

	self.body_shape.height = lerp(self.body_shape.height, self._height, self.crouch_height_speed * delta)

func _unhandled_input(event : InputEvent):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		self._mouse_input.x += event.relative.x
		self._mouse_input.y += event.relative.y
		
func hitting_head() -> bool:
	return $Head/CeilingDetector.is_colliding()

func wants_to_jump() -> bool:
	return self.is_on_floor() and Input.is_action_just_pressed(controls.JUMP)
	
func wants_to_crouch() -> bool:
	return Input.is_action_pressed(controls.CROUCH)

func wants_to_run() -> bool:
	return Input.is_action_pressed(controls.RUN)
	
func in_the_air() -> bool:
	return not self.is_on_floor()
