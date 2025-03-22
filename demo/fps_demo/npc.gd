class_name NPC extends CharacterBody3D

@export_group("Stats")
@export_range(0.0, 100.0, 0.1) var health: float = 100.0


@export_group("Head Movement")
@export var head_target: Node3D

@onready var chest_look_at_modifier_3d: LookAtModifier3D = $PhysicsModel/AnimatedModel/metarig/Skeleton3D/ChestLookAtModifier3D
@onready var head_look_at_modifier_3d: LookAtModifier3D = $PhysicsModel/AnimatedModel/metarig/Skeleton3D/HeadLookAtModifier3D

@onready var animation_player: AnimationPlayer = $PhysicsModel/AnimatedModel/AnimationPlayer

#var ragdoll_fsm: StateMachine = StateMachine.new(^"ragdoll_fsm")\
	
func _ready() -> void:
	animation_player.play("run")
	head_look_at_modifier_3d.target_node = head_look_at_modifier_3d.get_path_to(head_target)
	chest_look_at_modifier_3d.target_node = chest_look_at_modifier_3d.get_path_to(head_target)
