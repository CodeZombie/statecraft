@tool

class_name ModelModifier3D extends FilterModifier3D

## Target Skeleton3D for parent Skeleton3D to model.
@export var target_skeleton: Skeleton3D

@onready var ragdoll_simulator_3d: RagdollSimulator3D = $"../RagdollSimulator3D"

#func _process_modification() -> void:
	#var skeleton: Skeleton3D = get_skeleton()
	#if !skeleton:
		#return # Ensure SkeletonModifier3D is child of Skeleton3D
	##print(bones.find_key(true))
	#if inclusion:
		#for key in bones.keys():
			#if bones[key] == true:
				#var bone_idx = skeleton.find_bone(key)
				#
				#skeleton.set_bone_pose(bone_idx, target_skeleton.get_bone_pose(bone_idx))
	#elif exclusion:
		#for key in bones.keys():
			#if bones[key] == false:
				#var bone_idx = skeleton.find_bone(key)
				#skeleton.set_bone_pose(bone_idx, target_skeleton.get_bone_pose(bone_idx))
	#else:
		#for bone_idx in skeleton.get_bone_count() - 1:
			#skeleton.set_bone_pose(bone_idx, target_skeleton.get_bone_pose(bone_idx))
