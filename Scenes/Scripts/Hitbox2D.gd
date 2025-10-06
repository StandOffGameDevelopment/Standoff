extends Area2D
class_name Hitbox2D

@export var damage: int = 10
@export var knockback: Vector2 = Vector2.ZERO
@export var hitstun_ms: int = 0
@export var i_frames_on_hit: float = 0.1

var instigator: Node = null
var active: bool = false

func _ready() -> void:
	# Force layers/masks: Hitbox L=4 (1<<2), M=8 (1<<3)
	collision_layer = 1 << 2
	collision_mask  = 1 << 3
	monitorable = true
	monitoring  = false

	# Ensure we actually have an enabled shape
	var cs := get_node_or_null("CollisionShape2D")
	if cs and cs is CollisionShape2D:
		if cs.shape == null:
			push_warning("[HITBOX] %s has NO shape set. Add a CollisionShape2D shape." % [name])
		cs.set_deferred("disabled", false)
	else:
		push_warning("[HITBOX] %s is missing a CollisionShape2D child." % [name])

	# Connect signal once
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func set_instigator(who: Node) -> void:
	instigator = who

func is_hitbox() -> bool:
	return true

func is_active() -> bool:
	return active

func get_payload() -> Dictionary:
	return {
		"damage": damage,
		"instigator": instigator,
		"knockback": knockback,
		"hitstun_ms": hitstun_ms,
		"i_frames_on_hit": i_frames_on_hit,
	}

func set_active(on: bool) -> void:
	active = on
	set_deferred("monitoring", on)

func _on_area_entered(other: Area2D) -> void:
	if not active:
		return
	# Let the Hurtbox drive Health if it implements that flow
	if other.has_method("got_hit"):
		return

	# Fallback: if the hurtbox exposes a direct entrypoint, call it
	if other.has_method("_apply_damage_and_emit"):
		var p: Dictionary = get_payload()
		other._apply_damage_and_emit(
			int(p.get("damage", 0)),
			p.get("instigator", null),
			(p.get("knockback", Vector2.ZERO) as Vector2),
			int(p.get("hitstun_ms", 0)),
			float(p.get("i_frames_on_hit", 0.0))
		)
