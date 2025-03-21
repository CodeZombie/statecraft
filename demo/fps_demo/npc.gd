class_name NPC extends CharacterBody3D

@export_group("Active Ragdoll")
@export var target_skeleton: Skeleton3D
@export var physics_skeleton: Skeleton3D

@export var linear_spring_stiffness: float = 100.0
@export var linear_spring_damping: float = 10.0

@export var angular_spring_stiffness: float = 50.0
@export var angular_spring_damping: float = 20.0

@onready var physical_bone_simulator_3d: PhysicalBoneSimulator3D = $PhysicsModel/metarig/Skeleton3D/PhysicalBoneSimulator3D
@onready var animation_player: AnimationPlayer = $PhysicsModel/AnimatedModel/AnimationPlayer

@export_group("Head Movement")
@export var head_target: Node3D

@onready var head_look_at_modifier_3d: LookAtModifier3D = $PhysicsModel/metarig/Skeleton3D/HeadLookAtModifier3D
@onready var chest_look_at_modifier_3d: LookAtModifier3D = $PhysicsModel/metarig/Skeleton3D/ChestLookAtModifier3D
@onready var look_at_modifier_3d2: LookAtModifier3D = $PhysicsModel/AnimatedModel/metarig/Skeleton3D/LookAtModifier3D

var physics_bones

func _ready() -> void:
	physical_bone_simulator_3d.physical_bones_start_simulation()
	physics_bones = physical_bone_simulator_3d.get_children().filter(func(x): return x is PhysicalBone3D)
	animation_player.play("run")
	head_look_at_modifier_3d.target_node = head_look_at_modifier_3d.get_path_to(head_target)
	chest_look_at_modifier_3d.target_node = chest_look_at_modifier_3d.get_path_to(head_target)
	
func _physics_process(delta):
	for bone:PhysicalBone3D in physics_bones:
		var target_transform: Transform3D = target_skeleton.global_transform * target_skeleton.get_bone_global_pose(bone.get_bone_id())
		var current_transform: Transform3D = physics_skeleton.global_transform * physics_skeleton.get_bone_global_pose(bone.get_bone_id())
		
		var position_difference: Vector3 = target_transform.origin - bone.position
		var force: Vector3 = hookes_law(position_difference, bone.linear_velocity, linear_spring_stiffness, linear_spring_damping)
		bone.linear_velocity += (force * delta)
		
		#if bone.get_bone_id() != 5: #head
		var rotation_difference: Basis = (target_transform.basis * bone.global_transform.basis.inverse())
		var torque = hookes_law(rotation_difference.get_euler(), bone.angular_velocity, angular_spring_stiffness, angular_spring_damping)
		bone.angular_velocity += (torque * delta)
		
		#print(look_at_modifier_3d.is_target_within_limitation())
		
		#if bone.get_bone_id() == 5:
			#print("target: ", target_transform.origin)
			#print("current: ", current_transform.origin)
			#print("diff: ", position_difference)
			#print("lin: ", bone.linear_velocity)
			#print("ang: ", bone.angular_velocity)
			#print("pos: ", bone.position)
			#print("tar_rot: ", target_transform.basis)
			#print("cur_rot: ", bone.basis.inverse())

func hookes_law(displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)
