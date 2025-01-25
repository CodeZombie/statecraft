class_name StateMachine extends StateRunner

func copy(new_id: String = self.id, _new_state = null) -> StateMachine:
	return super(new_id, StateMachine.new(new_id) if not _new_state else _new_state)
