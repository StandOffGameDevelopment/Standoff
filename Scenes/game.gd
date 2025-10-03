extends Node2D

func _process(delta: float) -> void:
	var camera = $Camera2D
	var p2 = $Player2
	camera.position.x = p2.position.x   # follow only X
	# leave Y unchanged
