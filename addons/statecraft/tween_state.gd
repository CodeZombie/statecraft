class_name TweenState extends State

var scene_node: Node
var tween: Tween
var tween_definition_method: Callable
var _finished: bool = false

func _init(state_id: String, scene_node: Node, tween_definition_method: Callable):
	super(state_id)
	self.scene_node = scene_node
	self.tween_definition_method = tween_definition_method

func kill():
	if self.tween:
		self.tween.kill()
		self.tween = null

func enter():
	super()
	if self.tween:
		self.tween.kill()
	self._finished = false
	self.tween = self.scene_node.create_tween()
	self.tween_definition_method.call(self.tween)
	self.tween.play()
	self.tween.pause()
	
func update(delta: float, speed_scale: float = 1):
	super(delta, speed_scale)
	if self.tween and not self._finished:
		self._finished = not self.tween.custom_step(delta * speed_scale)
	if self.id == "mag_out":
		print("finished: {0}".format({0: self._finished}))
	return self._finished

func exit():
	self.kill()
	super()

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
