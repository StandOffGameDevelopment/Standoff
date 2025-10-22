extends Area2D
class_name Hurtbox2D

@export var health_path: NodePath
signal got_hit(instigator: Node, damage: int, knockback: Vector2, hitstun_ms: int)
signal parried(instigator: Node)
@export var parry_counter_knockback: Vector2 = Vector2(350, -50)
@export var parry_counter_stun_ms: int = 250

@onready var health: Health = (
	get_node_or_null(health_path) if String(health_path) != "" else
	(get_node_or_null("Health") as Health) if has_node("Health") else
	(get_node_or_null("../Health") as Health) if has_node("../Health") else
	(get_node_or_null("../../Health") as Health)
)

var _already_hit: Dictionary = {}

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
	# --- FORCE LAYERS/MASKS (L8 ↔ L7) ---
	for i in range(1, 33):
		set_collision_layer_value(i, false)
		set_collision_mask_value(i, false)
	set_collision_layer_value(8, true)  # hurtbox lives on layer 8
	set_collision_mask_value(7, true)   # and only collides with layer 7 (hitbox)

	set_deferred("monitorable", true)
	set_deferred("monitoring",  true)

	var cs := _find_2d_collider(self)
	if cs:
		cs.set_deferred("disabled", false)
	else:
		push_warning("[HURTBOX] %s needs a CollisionShape2D/Polygon child." % [name])

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	# single-hit guard per physics frame
	get_tree().physics_frame.connect(func() -> void: _already_hit.clear())

func _on_area_entered(area: Area2D) -> void:
	if not (area.has_method("is_hitbox") and area.is_hitbox()):
		return
	if area.has_method("is_active") and not area.is_active():
		return
	if area is Hitbox2D and _already_hit.has(area):
		return
	_already_hit[area] = true

	var payload: Dictionary = area.get_payload() if area.has_method("get_payload") else {}

	var instigator: Node = payload.get("instigator", null)

	# discard self-hits
	var self_entity: Node = health.get_parent() if health else null
	if instigator == null or instigator == self_entity:
		return

	# --- PARRY CHECK ---
	var entity := self_entity if self_entity != null else get_parent()
	if entity and entity.has_method("is_parrying_now") and entity.is_parrying_now():
		# cancel this strike immediately
		if area.has_method("mark_parried"):
			area.mark_parried()
		elif area.has_method("set_active"):
			area.set_active(false)

		# counter knockback to attacker
		if instigator:
			var dir: float = sign(instigator.global_position.x - entity.global_position.x)
			var counter_kb := Vector2(dir * abs(parry_counter_knockback.x), parry_counter_knockback.y)

			if instigator.has_method("apply_parry_knockback"):
				instigator.apply_parry_knockback(counter_kb, parry_counter_stun_ms, entity)
			elif instigator is CharacterBody2D:
				var cb := instigator as CharacterBody2D
				cb.velocity = counter_kb
				cb.move_and_slide()

		emit_signal("parried", instigator)
		return

	# --- NORMAL DAMAGE PATH ---
	var dmg: int = int(payload.get("damage", 0))
	var kb: Vector2 = (payload.get("knockback", Vector2.ZERO) as Vector2)
	var stun_ms: int = int(payload.get("hitstun_ms", 0))
	var i_frames: float = float(payload.get("i_frames_on_hit", 0.0))

	_apply_damage_and_emit(dmg, instigator, kb, stun_ms, i_frames)

func _apply_damage_and_emit(dmg: int, instigator: Node, kb: Vector2, stun_ms: int, i_frames: float) -> void:
	if dmg <= 0 or not health: return
	if health.invulnerable: return

	var self_entity: Node = health.get_parent() if health else null
	print("[HURTBOX] APPLY dmg=", dmg, " to=", (self_entity and self_entity.name))

	health.apply_damage(dmg, instigator)
	if i_frames > 0.0:
		health.grant_i_frames(i_frames)

	emit_signal("got_hit", instigator, dmg, kb, stun_ms)
