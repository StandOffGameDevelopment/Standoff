extends Area2D
class_name Hitbox2D

@export var damage := 15
@export var knockback := Vector2(220, -120)  # tweak
var instigator: Node = null

var active := false:
	set = set_active

func _ready() -> void:
	set_active(false)
	# Layers: 3 = Hitboxes, 4 = Hurtboxes (adjust if you used different slots)
	collision_layer = 1 << 2
	collision_mask  = 1 << 3

func set_active(v: bool) -> void:
	active = v
	monitoring = v
	set_deferred("monitorable", v)
