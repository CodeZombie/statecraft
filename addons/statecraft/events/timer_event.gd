#class_name Countdown
#signal elapsed
#var duration: float
#var _elapsed: float = 0.0
#var has_elapsed: bool = false
#var name: StringName
#
#func _init(duration: float):
	#self.duration = duration
#
#func reset():
	#self.has_elapsed = false
	#self._elapsed = 0.0
#
#func update(delta: float, speed_scale: float):
	#if self.has_elapsed: 
		#return
	#self._elapsed += delta * speed_scale
	#if self._elapsed >= self.duration:
		#self.elapsed.emit()
		#self.has_elapsed = true
		#

class_name TimerEvent extends Event

var duration: float

func _init(duration: float):
	self.duration = duration


# func attach_to_state(state: State, callable: Callable, running_state_paths: Array = [&""]) -> void:
	# var callable_: Callable = State._bind_with_optional_state(state, callable)
	# var sig: Signal
	# 
	# var timer_id: StringName = StringName("__TIMER_{0}".format({0: state._get_unique_id()}))
	# var duration_: float = self.duration
	# 
	# state.add_entered_callback(func(state_: State):
		# state_.props[timer_id] = 0.0)
	# 
	# if running_state_paths == [&""] or len(running_state_paths) == 0:
		# state.add_updated_callback(func(delta: float, state_: State):
			# if state_.props[timer_id] > duration_:
				# return
			# state_.props[timer_id] += delta
			# if state_.props[timer_id] > duration_:
				# State._call_with_optional_state(state_, callable))
				# 
	# else:
		# sig = state.create_unique_signal()
		# state.add_updated_callback(func(delta: float, state_: State):
			# if state_.props[timer_id] > duration_:
				# return
			# state_.props[timer_id] += delta
			# if state_.props[timer_id] > duration_:
				# sig.emit())
		# 
		# for running_state_path in running_state_paths:
			# state.recieve_message(RelayMessage.new(
				# running_state_path,
				# RelayMessage.Type.CONNECT_EXTERNAL_SIGNAL,
				# {
					# 'signal': sig,
					# 'callable': callable_,
					# 'strip_args': false
				# },
				# len(running_state_path) > 0
			# ))

func attach_to_state(state: State, callable: Callable, target_state_paths: Array[NodePath] = [^""] as Array[NodePath]) -> void:
	var bound_callable: Callable = SCUtils.weakbind_state_to_callable(state, callable)
	var bridge_signal: Signal

	for target_state_path in target_state_paths:
		if target_state_path.get_name_count() == 0:
			state.add_on_timer_event(self.duration, bound_callable)
		else:
			if not bridge_signal:
				bridge_signal = state.create_unique_signal()
				state.add_on_timer_event(self.duration, func(): bridge_signal.emit())
				
			state.recieve_message(RelayMessage.new(
				target_state_path,
				&"connect_signal",
				[bridge_signal, bound_callable],
				true
			))
			
