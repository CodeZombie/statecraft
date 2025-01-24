class_name TimerState extends State

var duration: float
var _elapsed: float

func _init(id: String, duration: float, skippable: bool = false):
	super(id, skippable)
	self.duration = duration

	self.add_enter_method(func():
		self._elapsed = 0.0
	)
	
	self.add_update_method(func(_delta):
		# TODO: Validate that this actually elapses for the desired `duration`
		self._elapsed += _delta
		if self._elapsed >= self.duration:
			self.emit("timer_elapsed")
	)


func copy(new_state_id: String):
	var copy_state = TimerState.new(new_state_id, self.duration, self.skippable)
	for enter_method in self.on_enter_methods:
		copy_state.add_enter_method(enter_method)
	for update_method in self.on_update_methods:
		copy_state.add_update_method(update_method)
	for exit_method in self.on_exit_methods:
		copy_state.add_exit_method(exit_method)
	return copy_state
