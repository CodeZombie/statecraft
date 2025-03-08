class_name TransitionChainTo

var state_runner: StateContainer
var from_state_ids: Array[StringName]
var to_state_id: StringName

func _init(state_runner: StateContainer, from_state_ids: Array[StringName], to_state_id: StringName):
	self.state_runner = state_runner
	self.from_state_ids = from_state_ids
	self.to_state_id = to_state_id
	
func on(condition: Variant, secondary_callable_condition: Variant = null) -> StateContainer:
	print("TransitionChainTo.on({0} -> {1})".format({0: self.from_state_ids, 1: self.to_state_id}))
	
	
	# Create a way to refer to the `self.*` variables without using `self.
	# this is necesasry so the lambda function doesn't have to hold a reference to
	# this TransitionChainTo instance, which would increment it's RefCounter and prevent it
	# from being garbage collected.
	# If we didn't, every time we used a TransitionChain, we would be reserving mem that would
	# only ever be freed when all the from_state_ids are freed. Basically a memory leak.
	var state_runner_ = self.state_runner
	var to_state_id_ = self.to_state_id
	
	#if condition is String:
		# Get signal from condition (aka jumping.landed)
		# Have the from state listen to that signal, and when it executes, transition the state_runner.
		# The problem is, the signal condition might not exist at this point, so we have to make this
		# connection using RelayMessages.
		# additionally, the fromstate might not exist at this point either, 
		# Yeah, there's no way to do this lol.
		#self.state_runner.on_signal_path(condition,)
		#for from_state_id in self.from_state_ids:
			#var from_states: Array = self.state_runner.get_children_via_path(from_state_id)
			#self.state_runner.on_signal_path(condition, func():
				#for from_state in from_states:
					#if from_state.status == State.StateStatus.RUNNING:
						#state_runner_.transition_to(to_state_id_))
		#var from_state_ids = self.from_state_ids.duplicate()
		#var state_runner_ = self.state_runner
		#self.state_runner.on_signal_path(
			#condition, 
			#func():
				#var running_ids = []
				#for from_state_id in from_state_ids:
					#if state_runner_.is_running(from_state_id):
						#print("Running: ", from_state_id)
						#print(" now trans to ", to_state_id)
						#state_runner_.transition_to(to_state_id)
						#return)
	#else:
	for from_state_id in self.from_state_ids:
		state_runner.recieve_message(RelayMessage.new(
			from_state_id, 
			RelayMessage.Type.CALL_METHOD, 
			{
				'method_name': 'on',
				'args': 
					[
						condition, 
						func(): return state_runner_.transition_to(to_state_id)
					]
			},
			true))
		#self.state_runner.transition_on(from_state_id, self.to_state_id, condition, secondary_callable_condition)
	return state_runner
	
func on_broadcast(broadcast_name: StringName) -> StateContainer:
	var state_runner_ = self.state_runner
	var to_state_id_ = self.to_state_id
	# ATTACH_ON_BROADCAST_CALLBACK
	for from_state_id in self.from_state_ids:
		self.state_runner.recieve_message(RelayMessage.new(
			from_state_id,
			RelayMessage.Type.ATTACH_ON_BROADCAST_CALLBACK,
			{
				'broadcast_name': broadcast_name,
				'callback': func(): state_runner.transition_to(to_state_id_)
			}
		))
	return self.state_runner

func on_exit() -> StateContainer:
	var state_runner_ = self.state_runner
	var to_state_id_ = self.to_state_id
	
	for from_state_id in self.from_state_ids:
		state_runner.recieve_message(RelayMessage.new(
			from_state_id,
			RelayMessage.Type.CALL_METHOD,
			{
				'method_name': 'on_signal_path',
				'args': ["exited", func(): state_runner_.transition_to(to_state_id)]
			},
			true
		))
		
		
		#self.state_runner.transition_on_exit(from_state_id, self.to_state_id)
	return self.state_runner
