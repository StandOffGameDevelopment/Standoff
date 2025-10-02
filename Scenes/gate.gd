extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var body: StaticBody2D = $StaticBody2D
@onready var timer: Timer = $Timer

# Adjust as needed
const MOVE_DISTANCE := -64      # how far the gate moves up (negative = up)
const MOVE_SPEED := 100.0       # pixels per second

var opening := false
var target_y := 0.0

func _ready():
	target_y = global_position.y + MOVE_DISTANCE
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.start()
	timer.timeout.connect(_on_timeout)

func _on_timeout():
	opening = true

func _process(delta: float):
	if opening:
		# Move gate upward
		global_position.y = move_toward(global_position.y, target_y, MOVE_SPEED * delta)

		# When it reaches target → disable collision so fighters can pass
		if is_equal_approx(global_position.y, target_y):
			opening = false
