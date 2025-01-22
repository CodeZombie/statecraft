class_name ParallelStateQueue extends StateRunner

func _init(state_id: String, skippable: bool = false):
	super(state_id, skippable)
	
	self.add_enter_method(func():
		for child_state in self.child_states:
			print("ParallelStateQueue child enter")
			child_state.enter()
	)
	
	self.add_exit_method(func():
		for child_state in self.child_states:
			print("ParallelStateQueue child exit")
			child_state.exit()
	)

func update(delta: float, speed_scale: float = 1.0):
	super(delta, speed_scale)
	for state in self.child_states:
		state.update(delta, speed_scale)
