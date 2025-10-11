extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var body: StaticBody2D = $StaticBody2D


const MOVE_DISTANCE := 150    # how far the gate moves
const OPEN_SPEED := 100.0    # in pixels per second
const CLOSE_SPEED := 400.0   # in pixels per second


func open():
	global_position.y -= MOVE_DISTANCE; 
	#global_position.y = move_toward(global_position.y, global_position.y - MOVE_DISTANCE, OPEN_SPEED * delta)


func close():
	global_position.y += MOVE_DISTANCE; 
	#global_position.y = move_toward(global_position.y, global_position.y + MOVE_DISTANCE, CLOSE_SPEED * delta)
