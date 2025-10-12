extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var body: StaticBody2D = $StaticBody2D


const MOVE_DISTANCE := 50  # how far the gate moves
const OPEN_SPEED := 1.0    # in seconds
const CLOSE_SPEED := 0.3   # in seconds


func open():
	var tween := create_tween()
	tween.tween_property(self, "position", self.position + Vector2(0, -MOVE_DISTANCE), OPEN_SPEED) \
		.set_trans(Tween.TRANS_LINEAR) \
		.set_ease(Tween.EASE_IN_OUT)


func close():
	var tween := create_tween()
	tween.tween_property(self, "position", self.position + Vector2(0, MOVE_DISTANCE), CLOSE_SPEED) \
		.set_trans(Tween.TRANS_LINEAR) \
		.set_ease(Tween.EASE_IN_OUT)
