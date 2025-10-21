extends Area2D
class_name Hurtbox2D

@export var health_path: NodePath
signal got_hit(instigator: Node, damage: int, knockback: Vector2, hitstun_ms: int)
signal parried(instigator: Node)
@export var parry_counter_knockback: Vector2 = Vector2(350, -50)
@export var parry_counter_stun_ms: int = 250


# TODO: remove not needed links
@onready var health: Health = (
	get_node_or_null(health_path) if String(health_path) != "" else
	(get_node_or_null("Health") as Health) if has_node("Health") else
	(get_node_or_null("../Health") as Health) if has_node("../Health") else
	(get_node_or_null("../../Health") as Health)
)

# Optional one-hit-per-physics-frame guard (per-hitbox)
var _already_hit: Dictionary = {}  # Dictionary<Area2D, bool>

func _find_2d_collider(node: Node) -> Node:
	var n = node.get_node_or_null("CollisionShape2D")
	if n == null: n = node.get_node_or_null("CollisionPolygon2D")
	if n == null: n = node.get_node_or_null("Shape")
	if n == null:
		for c in node.get_children():
			if c is CollisionShape2D or c is CollisionPolygon2D:
				return c
	return n


func _ready() -> void:
	set_deferred("monitorable", true)
	set_deferred("monitoring",  true)

	var cs := _find_2d_collider(self)
	if cs:
		cs.set_deferred("disabled", false)
	else:
		push_warning("[HURTBOX] %s needs a CollisionShape2D/CollisionPolygon2D child." % [name])

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

	# Early-outs to prevent self hits / invalid hits
	if instigator == null:
		return

	# Better self-hit check: compare to the Health's parent (your character node)
	var self_entity: Node = null
	if health:
		self_entity = health.get_parent()
	if instigator == self_entity:
		return
		
	# --- PARRY CHECK: if entity is parrying, cancel this hit and counter ---
	var entity := (health.get_parent() if health else get_parent())
	if entity and entity.has_method("is_parrying_now") and entity.is_parrying_now():
		if area.has_method("set_active"):
			area.set_active(false)

		if instigator:
			# knock back AWAY from defender
			var dir: float = sign(instigator.global_position.x - entity.global_position.x)
			var counter_kb_vec: Vector2 = Vector2(dir * abs(parry_counter_knockback.x), parry_counter_knockback.y)

			if instigator.has_method("apply_parry_stun"):
				instigator.apply_parry_stun(counter_kb_vec, parry_counter_stun_ms, entity)
			elif instigator is CharacterBody2D:
				var cb := instigator as CharacterBody2D
				cb.velocity.x = counter_kb_vec.x
				cb.velocity.y = counter_kb_vec.y
				if cb.has_method("move_and_slide"):
					cb.move_and_slide()

		emit_signal("parried", instigator)
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
