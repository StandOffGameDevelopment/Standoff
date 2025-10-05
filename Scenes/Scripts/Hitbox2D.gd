extends Area2D
class_name Hitbox2D

@export var damage: int = 10
@export var knockback_local: Vector2 = Vector2(350, -120)
@export var hitstun_ms: int = 120
@export var i_frames_on_hit: float = 0.10

var instigator: Node = null
var active: bool = false
var _already_hit := {}

func _ready() -> void:
	collision_layer = 1 << 2  # layer 3
	collision_mask  = 1 << 3  # mask 4
	active = false
	monitoring = false
	monitorable = false
	area_entered.connect(_on_area_entered)

func set_active(value: bool) -> void:
	active = value
	monitoring = value
	monitorable = value
	if not value:
		_already_hit.clear()
	print("[HITBOX]", name, " active=", active, " monitoring=", monitoring, " monitorable=", monitorable)

func is_active() -> bool:
	return active

func is_hitbox() -> bool:
	return true

func set_instigator(node: Node) -> void:
	instigator = node

func get_payload() -> Dictionary:
	return {
		"damage": damage,
		"knockback": _compute_knockback_global(),
		"hitstun_ms": hitstun_ms,
		"instigator": instigator,
		"i_frames_on_hit": i_frames_on_hit,
	}

func _on_area_entered(area: Area2D) -> void:
	# Only count hits while active (extra guard)
	if not active:
		return
	var owner_node := area.get_owner()
	if owner_node == null:
		return
	if _already_hit.has(owner_node):
		return
	_already_hit[owner_node] = true
	# Damage is applied by the Hurtbox.

func _compute_knockback_global() -> Vector2:
	var dir: int = 1
	if instigator:
		if instigator.has_node("P2AnimatedSprite2D"):
			var spr: AnimatedSprite2D = instigator.get_node("P2AnimatedSprite2D")
			dir = -1 if spr.flip_h else 1
		elif instigator.has_node("AnimatedSprite2D"):
			var spr2: AnimatedSprite2D = instigator.get_node("AnimatedSprite2D")
			dir = -1 if spr2.flip_h else 1
		else:
			dir = -1 if instigator.scale.x < 0.0 else 1
	return Vector2(knockback_local.x * dir, knockback_local.y)
