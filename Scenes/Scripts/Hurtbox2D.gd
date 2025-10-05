extends Area2D
class_name Hurtbox2D

@export var health_path: NodePath

# Robust resolver: uses health_path if set, otherwise tries common fallbacks.
@onready var health: Health = (
	get_node_or_null(health_path) if String(health_path) != "" else
	(get_node_or_null("Health") as Health) if has_node("Health") else
	(get_node_or_null("../Health") as Health) if has_node("../Health") else
	(get_node_or_null("../../Health") as Health)
)

signal got_hit(instigator: Node, damage: int, knockback: Vector2, hitstun_ms: int)


func _ready() -> void:
	# 4 = Hurtboxes, 3 = Hitboxes
	collision_layer = 1 << 3
	collision_mask  = 1 << 2
	monitoring = true
	monitorable = true
	area_entered.connect(_on_area_entered)
	print("[HURTBOX] ready on:", name, "  health=", health, "  path=", health_path)

func _on_area_entered(area: Area2D) -> void:
	# print("[HURTBOX] area_entered by:", area.name)
	if not area.has_method("is_hitbox") or not area.is_hitbox():
		return

	if area.has_method("is_active") and not area.is_active():
		# print("[HURTBOX] ignored inactive hitbox:", area.name)
		return

	if not area.has_method("get_payload"):
		return

	var payload: Dictionary = area.get_payload()
	var instigator: Node = payload.get("instigator", null)
	if instigator == get_owner():
		return

	var dmg: int = int(payload.get("damage", 0))
	var kb: Vector2 = payload.get("knockback", Vector2.ZERO)
	var stun_ms: int = int(payload.get("hitstun_ms", 0))
	var i_frames: float = float(payload.get("i_frames_on_hit", 0.0))

	if health and not health.invulnerable and dmg > 0:
		print("[HURTBOX] APPLY dmg=", dmg, " to=", get_owner().name)
		health.apply_damage(dmg, instigator)
		if i_frames > 0.0:
			health.grant_i_frames(i_frames)

	emit_signal("got_hit", instigator, dmg, kb, stun_ms)
