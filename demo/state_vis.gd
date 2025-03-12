extends Node2D
@export var fps_controller: Node3D

func _process(delta: float) -> void:
	queue_redraw()
	
func _draw() -> void:
	fps_controller.fps_fsm.draw(self, Vector2.ZERO)
