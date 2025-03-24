class_name RagdollSimulator3D extends PhysicalBoneSimulator3D

@export_group("Active Ragdoll")
@export var target_skeleton: Skeleton3D

@export var linear_spring_stiffness: float = 100.0
@export var linear_spring_damping: float = 10.0
@export var max_linear_force: float = 9999.0

@export var angular_spring_stiffness: float = 50.0
@export var angular_spring_damping: float = 20.0
@export var max_angular_force: float = 9999.0

var bones: Dictionary = {}
var previous_final_skeleton_modifier

func _ready() -> void:
	
	physical_bones_start_simulation()
	
func _process_modification() -> void:
	#for bone:PhysicalBone3D in physical_bones:
	pass

func _physics_process(delta):
	handle_skeleton_modifier_signals()
	
	if bones.size() > 0:
		active_ragdoll_process(delta)
	
	bones.clear()

func hookes_law(displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)

# Note: If you want the final modified bone pose then .get_bone_global_pose() must occur
# at the moment the final SkeletonModifier3Ds "modification_processed" signal is fired
func update_bone_dict() -> void:
	for bone:PhysicalBone3D in get_physical_bones():
		var target_transform: Transform3D = target_skeleton.global_transform * target_skeleton.get_bone_global_pose(bone.get_bone_id())
		var current_transform: Transform3D = bone.global_transform
		#var current_transform: Transform3D = get_parent().global_transform * get_parent().get_bone_global_pose(bone.get_bone_id())
		
		var bone_dict: Dictionary = {bone : [target_transform, current_transform]}
		bones.merge(bone_dict, true)

func get_physical_bones() -> Array[Node]:
	return get_children().filter(func(x): return x is PhysicalBone3D)

func get_final_modified_skeleton():
	var skeleton_modifiers = target_skeleton.get_children().filter(func(x): return x is SkeletonModifier3D)
	skeleton_modifiers = skeleton_modifiers.filter(func(mod): return mod.active)
	if skeleton_modifiers.size() > 0:
		return skeleton_modifiers.back()
	else:
		return null

func handle_skeleton_modifier_signals() -> void:
	var final_skeleton_modifier = get_final_modified_skeleton()
	if not final_skeleton_modifier == previous_final_skeleton_modifier:
		if previous_final_skeleton_modifier is SkeletonModifier3D:
			if previous_final_skeleton_modifier.is_connected("modification_processed", update_bone_dict):
				previous_final_skeleton_modifier.disconnect("modification_processed", update_bone_dict)
	if final_skeleton_modifier is SkeletonModifier3D:
		if not final_skeleton_modifier.is_connected("modification_processed", update_bone_dict):
			final_skeleton_modifier.connect("modification_processed", update_bone_dict)
	else:
		update_bone_dict()
	
	previous_final_skeleton_modifier = final_skeleton_modifier

func active_ragdoll_process(delta) -> void:
	# apply forces to physical bones
	for bone:PhysicalBone3D in get_physical_bones():

		var target_transform: Transform3D = bones[bone][0]
		var current_transform: Transform3D = bones[bone][1]
		
		var position_difference = target_transform.origin - current_transform.origin
		if position_difference.length_squared() > 1.0:
			bone.global_position = target_transform.origin
		else:
			var force: Vector3 = hookes_law(position_difference, bone.linear_velocity, linear_spring_stiffness, linear_spring_damping)
			force = force.limit_length(max_linear_force)
			bone.linear_velocity += (force * delta)
		
		var rotation_difference: Basis = (target_transform.basis * current_transform.basis.inverse())
		var torque = hookes_law(rotation_difference.get_euler(), bone.angular_velocity, angular_spring_stiffness, angular_spring_damping)
		torque = torque.limit_length(max_angular_force)
		bone.angular_velocity += (torque * delta)
