extends Node2D


func _on_player_entered_tower(body: Node2D) -> void:
	if body is Player_1:
		if $Camera2D.position.x == -793:
			_transition_camera_to(Vector2(0, $Camera2D.position.y))  # new camera target position
		if $Camera2D.position.x == 0:
			_transition_camera_to(Vector2(793, $Camera2D.position.y))  # new camera target position
		
	if body is Player_2:
		if $Camera2D.position.x == 793:
			_transition_camera_to(Vector2(0, $Camera2D.position.y))  # new camera target position
		if $Camera2D.position.x == 0:
			_transition_camera_to(Vector2(-793, $Camera2D.position.y))  # new camera target position


func _transition_camera_to(target: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property($Camera2D, "position", target, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
