class_name TweenState extends State

var scene_node: Node
var tween: Tween
var tween_definition_method: Callable
var _finished: bool = false

func _init(state_id: String, scene_node: Node, tween_definition_method: Callable, skippable: bool = false):
	super(state_id, skippable)
	
	self.scene_node = scene_node
	self.tween_definition_method = tween_definition_method
	
	self.add_enter_method(func():
		if self.tween:
			self.tween.kill()
		self._finished = false
		self.tween = self.scene_node.create_tween()
		tween_definition_method.call(self.tween)
		self.tween.play()
		self.tween.pause()
	)
	
	self.add_update_method(func(delta: float):
		if self.tween and not self._finished:
			self._finished = not self.tween.custom_step(delta)
			if self._finished:
				self.emit("tween_finished")
	)
	
	self.add_exit_method(self.kill.bind())
		
func kill():
	if self.tween:
		self.tween.kill()
		self.tween = null
