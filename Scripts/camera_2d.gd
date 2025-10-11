extends Camera2D


func _move_left() -> void:
	print("Camera moving left")
	_move_camera_to(Vector2(self.position.x - 1920, self.position.y))


func _move_right() -> void:
	print("Camera moving right")
	_move_camera_to(Vector2(self.position.x + 1920, self.position.y))


func _move_camera_to(target: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", target, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
