extends Camera2D

signal page_changed(index: int)   # <- HUD listens to this

@export var total_pages: int = 5  # number of maps/dots
@export var page_width: float = 1920.0
@export var start_index: int = 2  # you start in the middle (0..4)

var current_index: int = -1
var _tween: Tween

func _ready() -> void:
	# optional: put camera in a group so HUD can find it
	if not is_in_group("Camera"): add_to_group("Camera")
	# initialize index once
	if current_index < 0:
		current_index = clampi(start_index, 0, total_pages - 1)
		emit_signal("page_changed", current_index)  # tell HUD where we start

func _move_left() -> void:
	# try to go one page left
	var new_index := clampi((current_index if current_index >= 0 else start_index) - 1, 0, total_pages - 1)
	if new_index == current_index:
		return # already at leftmost
	current_index = new_index
	var target := Vector2(position.x - page_width, position.y)
	_move_camera_to(target)

func _move_right() -> void:
	# try to go one page right
	var new_index := clampi((current_index if current_index >= 0 else start_index) + 1, 0, total_pages - 1)
	if new_index == current_index:
		return # already at rightmost
	current_index = new_index
	var target := Vector2(position.x + page_width, position.y)
	_move_camera_to(target)

func _move_camera_to(target: Vector2) -> void:
	if is_instance_valid(_tween):
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position", target, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# emit AFTER the camera finishes sliding (so the blink swaps exactly when the view lands)
	_tween.finished.connect(func ():
		emit_signal("page_changed", current_index)
	)
