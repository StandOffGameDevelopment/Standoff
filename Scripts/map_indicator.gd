extends Control
class_name MapIndicator

@export var total_maps: int = 5
@export var dot_size: int = 16
@export var inactive_color: Color = Color8(140, 140, 140)
@export var active_color: Color = Color8(255, 255, 255)
@export var blink_min_alpha: float = 0.35
@export var blink_duration: float = 0.45
@export var auto_bind_to_game: bool = true
@export var game_group: StringName = &"Game"   # put your Game node in this group

@onready var dots_box: HBoxContainer = $Dots
var _dots: Array[Panel] = []
var _active_idx: int = -1
var _blink_tween: Tween

func _ready() -> void:
	_build_dots()

	# Prefer binding to the Camera (emits page_changed)
	var cam := get_tree().get_first_node_in_group("Camera")
	if cam and cam.has_signal("page_changed"):
		cam.page_changed.connect(set_current_map)

		# Safely read the camera's current_index (won't error if missing)
		var idx = cam.get("current_index")
		if typeof(idx) != TYPE_NIL and int(idx) >= 0:
			set_current_map(int(idx))
		return

	# Fallback: bind to Game if it relays map_changed
	if auto_bind_to_game:
		var game := get_tree().get_first_node_in_group(game_group)
		if game and game.has_signal("map_changed"):
			game.map_changed.connect(set_current_map)
			if game.get("current_map_index") != null and int(game.current_map_index) >= 0:
				set_current_map(int(game.current_map_index))
			return

	# Last-resort default
	set_current_map(0)




func _build_dots() -> void:
	for c in dots_box.get_children(): c.queue_free()
	_dots.clear()

	for i in total_maps:
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(dot_size, dot_size)

		var sb := StyleBoxFlat.new()
		sb.bg_color = inactive_color
		sb.set_corner_radius_all(dot_size)
		sb.set_border_width_all(0)
		dot.add_theme_stylebox_override("panel", sb)

		dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.modulate.a = 0.8

		dots_box.add_child(dot)
		_dots.append(dot)

func set_current_map(index: int) -> void:
	if index < 0 or index >= total_maps:
		push_warning("MapIndicator: index out of range: %s" % index)
		return

	if is_instance_valid(_blink_tween):
		_blink_tween.kill()

	for dot in _dots:
		var sb := dot.get_theme_stylebox("panel") as StyleBoxFlat
		if sb: sb.bg_color = inactive_color
		dot.modulate.a = 0.8

	_active_idx = index
	var active := _dots[_active_idx]
	var active_sb := active.get_theme_stylebox("panel") as StyleBoxFlat
	if active_sb: active_sb.bg_color = active_color
	active.modulate.a = 1.0

	_blink_tween = create_tween()
	_blink_tween.set_loops()
	_blink_tween.tween_property(active, "modulate:a", blink_min_alpha, blink_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_blink_tween.tween_property(active, "modulate:a", 1.0, blink_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
