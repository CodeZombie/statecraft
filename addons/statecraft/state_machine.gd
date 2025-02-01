class_name StateMachine extends StateRunner

func copy(new_id: String = self.id, _new_state = null) -> StateMachine:
	return super(new_id, StateMachine.new(new_id) if not _new_state else _new_state)
	
func update(delta: float, speed_scale: float = 1.0) -> bool:
	var r_val: bool = super(delta, speed_scale)
	if r_val:
		return true
		
	self.get_current_state().run(delta, speed_scale)
	return false
	
	
func add_state(state: State) -> StateMachine:
	if self.get_state(state.id):
		push_error("StateCraft Error: State with ID \"{0}\" already present in State Machine \"{1}\"".format({0: state.id, 1: self.id}))
	return super(state)
