@tool

class_name FilterModifier3D extends SkeletonModifier3D

@export_group("Bone Filter")
## Activated bones copy target skeleton.
@export var inclusion: bool = false:
	set(value):
		inclusion = value
		if inclusion == true and exclusion == true:
			exclusion = false
## All bones except activated bones copy target skeleton.
@export var exclusion: bool = false:
	set(value):
		exclusion = value
		if exclusion == true and inclusion == true:
			inclusion = false
## Dictionary of parent Skeleton3D bones. Activate bones to be filtered by checking the boolean true.
@export var bones: Dictionary

func _validate_property(property: Dictionary) -> void:
	if property.name == "bones":
		var skeleton: Skeleton3D = get_skeleton()
		if skeleton:
			for bone_idx in skeleton.get_bone_count() - 1:
				var bone = skeleton.get_bone_name(bone_idx)
				if bones.has(bone):
					pass
				else:
					bones[bone] = false

func _process_modification() -> void:
	pass

func change_bones(bones_to_filter: Array[String], include_bones: bool = true, exclude_bones: bool = false, reset_bones: bool = false):
	if reset_bones:
		for key in bones.keys():
			bones[key] = false
	
	for bone in bones_to_filter:
		if bones.has(bone):
			bones[bone] = true
		else:
			push_warning("Bone not found on parent Skeleton3D.")
	
	exclusion = exclude_bones
	inclusion = include_bones
