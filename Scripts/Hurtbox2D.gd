extends Area2D
class_name Hurtbox2D

@export var health_path: NodePath
signal got_hit(instigator: Node, damage: int, knockback: Vector2, hitstun_ms: int)

# TODO: remove not needed links
@onready var health: Health = (
	get_node_or_null(health_path) if String(health_path) != "" else
	(get_node_or_null("Health") as Health) if has_node("Health") else
	(get_node_or_null("../Health") as Health) if has_node("../Health") else
	(get_node_or_null("../../Health") as Health)
)

# Optional one-hit-per-physics-frame guard (per-hitbox)
var _already_hit: Dictionary = {}  # Dictionary<Area2D, bool>

func _ready() -> void:
	# Layers/masks: Hurtbox L=8 (1<<3), M=4 (1<<2)
	# TODO: is needed???
	collision_layer = 1 << 3
	collision_mask  = 1 << 2
	monitorable = true
	monitoring  = true

	var cs := get_node_or_null("CollisionShape2D")
	if cs and cs is CollisionShape2D:
		cs.set_deferred("disabled", false)

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	# Reset single-hit guard each physics frame (optional)
	get_tree().physics_frame.connect(func() -> void:
		_already_hit.clear()
	)

	print("[HURTBOX] ready on:", name, "  health=", health, "  path=", health_path)

func _on_area_entered(area: Area2D) -> void:
	# Accept only hitboxes that declare themselves and are active
	if not (area.has_method("is_hitbox") and area.is_hitbox()):
		return
	if area.has_method("is_active") and not area.is_active():
		return

	# Optional: prevent multiple hits from same hitbox within the frame
	if area is Hitbox2D:
		if _already_hit.has(area):
			return
		_already_hit[area] = true

	# Preferred: pull payload from the hitbox
	var payload: Dictionary = {}
	if area.has_method("get_payload"):
		payload = area.get_payload() as Dictionary

	var instigator: Node = payload.get("instigator", null) as Node

	# Better self-hit check: compare to the Health's parent (your character node)
	var self_entity: Node = null
	if health:
		self_entity = health.get_parent()
	if instigator == self_entity:
		return

	var dmg: int = int(payload.get("damage", 0))
	var kb: Vector2 = (payload.get("knockback", Vector2.ZERO) as Vector2)
	var stun_ms: int = int(payload.get("hitstun_ms", 0))
	var i_frames: float = float(payload.get("i_frames_on_hit", 0.0))

	_apply_damage_and_emit(dmg, instigator, kb, stun_ms, i_frames)

func _apply_damage_and_emit(dmg: int, instigator: Node, kb: Vector2, stun_ms: int, i_frames: float) -> void:
	if dmg <= 0 or not health:
		return
	if health.invulnerable:
		return

	var self_entity: Node = health.get_parent() if health else null
	var who_name := (self_entity.name if self_entity else name)
	print("[HURTBOX] APPLY dmg=", dmg, " to=", who_name)

	health.apply_damage(dmg, instigator)
	if i_frames > 0.0:
		health.grant_i_frames(i_frames)

	emit_signal("got_hit", instigator, dmg, kb, stun_ms)
