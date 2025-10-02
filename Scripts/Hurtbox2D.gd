extends Area2D
class_name Hurtbox2D

@onready var player: CharacterBody2D = $".."


func _ready() -> void:
	collision_layer = 1 << 3   # layer 4: Hurtboxes
	collision_mask  = 1 << 2   # mask  3: Hitboxes
	monitoring = true
	monitorable = true
	area_entered.connect(_on_area_entered)

func _on_area_entered(a: Area2D) -> void:
	if player == null: return
	if not (a is Hitbox2D): return
	var hb := a as Hitbox2D
	if hb.instigator == player: return   # ignore self-hits
	player.take_damage(hb.damage, hb.instigator, hb.knockback)
