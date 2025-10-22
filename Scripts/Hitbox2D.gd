extends Area2D
class_name Hitbox2D

@export var damage: int = 50
@export var knockback: Vector2 = Vector2.ZERO
@export var hitstun_ms: int = 0
@export var i_frames_on_hit: float = 0.1

var instigator: Node = null
var active: bool = false
var _parried_this_swing := false

func _find_2d_collider(node: Node) -> Node:
	var n = node.get_node_or_null("Shape")
	if n == null: n = node.get_node_or_null("CollisionShape2D")
	if n == null: n = node.get_node_or_null("CollisionPolygon2D")
	if n == null:
		for c in node.get_children():
			if c is CollisionShape2D or c is CollisionPolygon2D:
				return c
	return n

func _ready() -> void:
	# --- FORCE LAYERS/MASKS (L7 ↔ L8) ---
	for i in range(1, 33):
		set_collision_layer_value(i, false)
		set_collision_mask_value(i, false)
	set_collision_layer_value(7, true)  # hitbox lives on layer 7
	set_collision_mask_value(8, true)   # and only collides with layer 8 (hurtbox)

	set_deferred("monitorable", true)
	set_deferred("monitoring",  false)

	var col := _find_2d_collider(self)
	if col == null:
		push_warning("[HITBOX] %s needs a CollisionShape2D/Polygon child." % [name])
	else:
		col.set_deferred("disabled", false)

	# Do NOT apply damage here; Hurtbox is the authority.
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func set_instigator(who: Node) -> void:
	instigator = who

func is_hitbox() -> bool: return true
func is_active() -> bool: return active

func get_payload() -> Dictionary:
	if instigator == null: return {}
	return {
		"damage": damage,
		"instigator": instigator,
		"knockback": knockback,
		"hitstun_ms": hitstun_ms,
		"i_frames_on_hit": i_frames_on_hit,
	}

func set_active(on: bool) -> void:
	active = on
	_parried_this_swing = false
	set_deferred("monitoring", on)

func mark_parried() -> void:
	_parried_this_swing = true
	active = false
	set_deferred("monitoring", false)

func _on_area_entered(_other: Area2D) -> void:
	# Intentionally empty. Hurtbox decides parry/damage.
	pass
