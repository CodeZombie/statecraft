class_name TweenState extends State

var scene_node: Node
var tween: Tween
var tween_definition_method: Callable
var _finished: bool = false
var _tween_execution_position: State.ExecutionPosition = State.ExecutionPosition.POST_UPDATE

func _init(state_id: String, scene_node: Node, tween_definition_method: Callable):
	super(state_id)
	self.keep_alive()
	self.scene_node = scene_node
	self.tween_definition_method = tween_definition_method

func kill():
	if self.tween:
		self.tween.kill()
		self.tween = null

func enter() -> bool:
	if self.tween:
		self.tween.kill()
	self._finished = false
	self.tween = self.scene_node.create_tween()
	self.tween_definition_method.call(self.tween)
	self.tween.play()
	self.tween.pause()
	return super()
	
func set_tween_execution_position(execution_position: State.ExecutionPosition) -> TweenState:
	self._tween_execution_position = execution_position
	return self
	
func update(delta: float, speed_scale: float = 1):
	if self._tween_execution_position == State.ExecutionPosition.PRE_UPDATE:
		if super(delta, speed_scale):
			return true
		
	if self.tween and not self._finished:
		self._finished = not self.tween.custom_step(delta * speed_scale)
		if self._finished:
			return true
		
	if self._tween_execution_position == State.ExecutionPosition.POST_UPDATE:
		if super(delta, speed_scale):
			return true
		
	return false

func exit():
	if super():
		self.kill()
	
func copy(new_id: String = self.id, _new_state = null):
	return super(new_id, TweenState.new(new_id, self.scene_node, self.tween_definition_method) if not _new_state else _new_state)

func as_string(indent: int = 0) -> String:
	var indent_string: String = ""
	for i in range(indent):
		indent_string += " "
	if self.tween:
		return indent_string + self.id + ": " + self.get_status_string() + "e " + str(snapped(self.tween.get_total_elapsed_time(), 0.01))
	else:
		return indent_string + self.id + ": " + self.get_status_string() 
