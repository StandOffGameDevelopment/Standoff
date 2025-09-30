extends Area2D

@onready var sprite: AnimatedSprite2D = get_parent().get_node("AnimatedSprite2D")

func _ready() -> void:
	sprite.frame_changed.connect(_on_frame_changed)
	_on_frame_changed()

func _on_frame_changed() -> void:
	# For now, only handle Idle
	if sprite.animation != "Idle":
		_show_none()
		return

	var idx := sprite.frame  # 0..8
	var name := "Idle" + str(idx)

	# Disable all, then enable the matching polygon
	for child in get_children():
		if child is CollisionPolygon2D:
			child.disabled = true
			child.visible = false

	var target := get_node_or_null(name)
	if target and target is CollisionPolygon2D:
		target.disabled = false
		target.visible = true

func _show_none() -> void:
	for child in get_children():
		if child is CollisionPolygon2D:
			child.disabled = true
			child.visible = false
