extends Node2D

signal player_entered(direction: String)

func _on_body_entered(body):
	if body.is_in_group("player"):
		var direction
		if body.position.x < global_position.x: 
			direction = "left" 
		else: direction = "right"
		print("Player entered" + direction)
		player_entered.emit(direction)

func open_gate():
	for gate in get_children():
		if gate.has_method("open_gate"):
			gate.open_gate()
