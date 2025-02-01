class_name ParallelStateQueue extends StateRunner

func enter():
	super()
	for child_state in self.child_states:
		child_state.enter()

func update(delta: float, speed_scale: float = 1.0):
	for state in self.child_states:
		state.run(delta, speed_scale)

func exit():
	super()
	for child_state in self.child_states:
		if child_state.is_running:
			child_state.exit()

func add_state(state: State) -> StateRunner:
	if self.get_state(state.id):
		push_error("StateCraft Error: State with ID \"{0}\" already present in State Runner \"{1}\"".format({0: state.id, 1: self.id}))
	state.add_exit_event(func():
		for child_state in self.child_states:
			if child_state.is_running:
				return
		self.exit())
	self.child_states.append(state)
	return self
