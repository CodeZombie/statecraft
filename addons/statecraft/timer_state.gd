class_name TimerState extends State

var duration: float
var _elapsed: float

func _init(id: String, duration: float, skippable: bool = false):
	super(id, skippable)
	self.duration = duration

func enter():
	super()
	self._elapsed = 0.0
	
func update(delta: float, speed_scale: float = 1):
	super(delta, speed_scale)
	# TODO: validate that this actually runs for `duration`
	self._elapsed += delta
	if self._elapsed >= self.duration:
		self.emit("timer_elapsed")
		
func copy(new_id: String = self.id, _new_state = null) -> TimerState:
	return super(new_id, TimerState.new(new_id, self.duration) if not _new_state else _new_state)
	
