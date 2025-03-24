class_name NPC extends CharacterBody3D

@export_group("Stats")
@export_range(0.0, 100.0, 0.1) var health: float = 100.0
@export var speed: float = 20.0
@export var acceleration: float = 5.0
@export var rotation_speed: float = 2.0
@export var lerp_rate: float = 0.1

@export var follow_target: Node3D

@onready var chest_look_at_modifier_3d: LookAtModifier3D = $PhysicsModel/AnimatedModel/metarig/Skeleton3D/ChestLookAtModifier3D
@onready var head_look_at_modifier_3d: LookAtModifier3D = $PhysicsModel/AnimatedModel/metarig/Skeleton3D/HeadLookAtModifier3D
@onready var target_skeleton: Skeleton3D = $PhysicsModel/AnimatedModel/metarig/Skeleton3D
@onready var physics_skeleton: Skeleton3D = $PhysicsModel/metarig/Skeleton3D

@onready var physics_model: Node3D = $PhysicsModel
@onready var animation_player: AnimationPlayer = $PhysicsModel/AnimatedModel/AnimationPlayer
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var area_3d: Area3D = $PhysicsModel/metarig/Skeleton3D/BoneAttachment3D/Area3D

var look_at_modifier_target: Node

var NPC_observe_fsm: StateMachine = StateMachine.new(^"NPC_observe_fsm")\
	.from(^"idle").if_true(self.check_observable_object).then_transition_to(^"look_at_object")\
	.from(^"look_forward").if_true(self.check_observable_object).then_transition_to(^"look_at_object")\
	.from(^"look_forward").on_signal(^"look_forward:exited").then_transition_to(^"idle")\
	
	.from(^"focus").if_false(self.check_observable_object).then_transition_to(^"look_forward")\
	.from(^"look_at_object").if_false(self.check_observable_object).then_transition_to(^"look_forward")\
	.from(^"look_at_object").on_signal(^"look_at_object:exited").then_transition_to(^"focus")\
	
	.add(State.new(^"idle", false)
		.add_enter_event(func():
			head_look_at_modifier_3d.influence = 0.0
			chest_look_at_modifier_3d.influence = 0.0))\
	
	.add(State.new(^"focus", false)
		.add_enter_event(func():
			head_look_at_modifier_3d.influence = 1.0
			chest_look_at_modifier_3d.influence = 1.0))\
	
	.add(StateQueue.new(^"look_forward")\
		.set_execution_mode(StateQueue.ExecutionMode.PARALLEL)
		
		.add_exit_event(func():
			head_look_at_modifier_3d.target_node = NodePath("")
			chest_look_at_modifier_3d.target_node = NodePath(""))
		
		.add(TweenState.new(^"move_head", self, func(tween: Tween):
			tween.tween_property(head_look_at_modifier_3d, "influence", 0.0, 0.5)))
		.add(TweenState.new(^"move_chest", self, func(tween: Tween):
			tween.tween_property(chest_look_at_modifier_3d, "influence", 0.0, 0.5))))\

	.add(StateQueue.new(^"look_at_object")\
		.set_execution_mode(StateQueue.ExecutionMode.PARALLEL)
		
		.add_enter_event(func():
			head_look_at_modifier_3d.target_node = head_look_at_modifier_3d.get_path_to(look_at_modifier_target)
			chest_look_at_modifier_3d.target_node = chest_look_at_modifier_3d.get_path_to(look_at_modifier_target))
			
		.add(TweenState.new(^"move_head", self, func(tween: Tween):
			tween.tween_property(head_look_at_modifier_3d, "influence", 1.0, 0.5)))
		.add(TweenState.new(^"move_chest", self, func(tween: Tween):
			tween.tween_property(chest_look_at_modifier_3d, "influence", 1.0, 0.5))))

func _ready() -> void:
	$NPCControllerVis.state_machine = self.NPC_observe_fsm
	
	animation_player.play("run")

func _physics_process(delta: float) -> void:
	
	#navigation_agent_3d.target_position = follow_target.global_position
	
	update_velocity(delta)
	update_rotation(delta)
	
	find_observable_object()
	self.NPC_observe_fsm.run(delta)

func update_velocity(delta) -> void:
	var direction = get_direction()
	
	var new_velocity: Vector3 = Vector3(0, 0, 0)
	
	new_velocity.y = direction.y * speed
	
	if direction:
		new_velocity.x = lerp(new_velocity.x, direction.x * speed, acceleration * delta)
		new_velocity.z = lerp(new_velocity.z, direction.z * speed, acceleration * delta)
	else:
		new_velocity.x = lerp(new_velocity.x, 0.0, acceleration * delta)
		new_velocity.z = lerp(new_velocity.z, 0.0, acceleration * delta)
	
	navigation_agent_3d.set_velocity(new_velocity)

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = velocity.move_toward(safe_velocity, 0.5)
	move_and_slide()

func update_rotation(delta) -> void:
	var new_transform = physics_model.transform.looking_at(get_direction(), Vector3.UP)
	physics_model.transform = physics_model.transform.interpolate_with(new_transform, rotation_speed * delta)

func find_observable_object():
	look_at_modifier_target = null
	
	var observable_objects = area_3d.get_overlapping_bodies()
	
	if observable_objects.size() == 0:
		return
	
	for object in observable_objects:
		if object is Player:
			look_at_modifier_target = object.head

func check_observable_object() -> bool:
	if look_at_modifier_target == null:
		return false
	else:
		return true

func get_direction() -> Vector3:
	var current_location = global_transform.origin
	var next_location = navigation_agent_3d.get_next_path_position()
	
	return (next_location - current_location).normalized()
