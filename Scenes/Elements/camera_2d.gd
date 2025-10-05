extends Camera2D


func _on_tower_entered(direction: String) -> void:
	if direction == "left":
		print("Player entered from the left")
		_transition_camera_to(Vector2(self.position.x + 793, self.position.y))
	if direction == "right":
		print("Player entered from the right")
		_transition_camera_to(Vector2(self.position.x - 793, self.position.y))


func _transition_camera_to(target: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", target, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
