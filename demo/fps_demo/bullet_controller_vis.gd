extends Node2D
var state_machine: StateMachine

func _process(delta: float) -> void:
	queue_redraw()
	
func _draw() -> void:
	state_machine.draw(self, Vector2(170.0, 400))
