class_name Bullet extends RigidBody3D

signal collision

@onready var bullet_controller_vis: Node2D = $BulletControllerVis

var velocity_vector: Vector3
var get_speed_scale_method: Callable
var contacts: Array[Node3D] = []
var contact: Node3D
var contact_point: Vector3 = Vector3.ZERO

@onready var bullet_controller_fsm: StateMachine = StateMachine.new("bullet_fsm")\
	.from(^"airborn").on_signal(self.collision).then_transition_to(^"collision")\
	.from(^"airborn").on_signal(^"airborn:exited").then_transition_to(^"timeout")\
	.from(^"timeout").on_signal(^"timeout:exited").then_transition_to(^"delete")\
	.from(^"collision").on_signal(^"collision:exited").then_transition_to(^"delete")\
	
	.add(State.new(^"airborn", false)
		.add_process_event(func():
			if get_contact_count() > 0:
				contacts.append_array(get_colliding_bodies())
				contact = contacts[0]
				contact_point = self.global_position
				collision.emit())
		.add_enter_event(func():
			self.apply_impulse(velocity_vector))
		.on_timer(5.0).then_exit())\
			
	.add(State.new(^"collision", false)
		.add_enter_event(func():
			print(contact)
			if contact is RigidBody3D:
				contact.apply_impulse(
					(velocity_vector/10)/contact.mass, 
					contact.to_local(contact_point))
			elif contact is PhysicalBone3D:
				contact.apply_impulse(
					(velocity_vector/20),
					contact.to_local(contact_point)))
		.on_timer(1.0).then_exit())\
	
	.add(State.new(^"timeout", false)
		.add_enter_event(func():)
		.on_timer(1.0).then_exit())\
	
	.add(State.new(^"delete", false)
		.add_exit_event(func():
			self.queue_free())
		.on_timer(1.0).then_exit())

func _ready() -> void:
	bullet_controller_vis.state_machine = self.bullet_controller_fsm

func _process(delta: float) -> void:
	bullet_controller_fsm.run(delta, self.get_speed_scale_method.call())
	#self.audio_player.pitch_scale = self.get_speed_scale_method.call()
	
