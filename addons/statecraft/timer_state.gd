class_name TimerState extends State

var duration: float
var _elapsed: float

func _init(id: String, duration: float):
	super(id)
	self.keep_alive()
	self.duration = duration

func enter() -> bool:
	self._elapsed = 0.0
	return super()
	
func process(delta: float, speed_scale: float = 1):
	super(delta, speed_scale)
	# TODO: validate that this actually runs for `duration`
	self._elapsed += delta * speed_scale
	return self._elapsed >= self.duration 
		
func copy(new_id: NodePath = self.id, _new_state = null) -> TimerState:
	return super(new_id, TimerState.new(new_id, self.duration) if not _new_state else _new_state)
	
func as_string(indent: int = 0) -> String:
	var indent_string: String = ""
	for i in range(indent):
		indent_string += " "
	return "{indent_string} {id} : {status} || elapsed: {elapsed}".format({
		'indent_string': indent_string,
		'id': self.id,
		'status': self.get_status_string(),
		'elapsed': self._elapsed
	})
