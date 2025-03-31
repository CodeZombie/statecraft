class_name ExpDecayJoint3D extends Node3D

@export var root: Node3D

static func exp_decay(a: float, b: float, decay: float, delta: float) -> float:
	return b - (a - b) * exp(-decay * delta)

static func exp_decay_vec3(a: Vector3, b: Vector3, decay: float, delta: float) -> Vector3:
	return Vector3(
		exp_decay(a.x, b.x, decay, delta),
		exp_decay(a.y, b.y, decay, delta),
		exp_decay(a.z, b.z, decay, delta)
	)

func _process(delta: float) -> void:
	if self.root:
		#self.global_position = root.global_position
		self.global_position = lerp(self.global_position, root.global_position, delta * 80.0)
		#self.global_position = exp_decay_vec3(self.global_position, root.global_position, 0.01, delta)
		self.global_rotation.x = lerp_angle(self.global_rotation.x, root.global_rotation.x, delta * 80.0)
		self.global_rotation.y = lerp_angle(self.global_rotation.y, root.global_rotation.y, delta * 80.0)
		self.global_rotation.z = lerp_angle(self.global_rotation.z, root.global_rotation.z, delta * 80.0)
		#self.global_transform.basis = Basis(Quaternion(self.global_transform.basis).slerp(Quaternion(root.global_transform.basis), 0.5))
