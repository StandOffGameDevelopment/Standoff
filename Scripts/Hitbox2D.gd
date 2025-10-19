extends Area2D
class_name Hitbox2D

@export var damage: int = 50
@export var knockback: Vector2 = Vector2.ZERO
@export var hitstun_ms: int = 0
@export var i_frames_on_hit: float = 0.1

var instigator: Node = null
var active: bool = false

func _ready() -> void:
	set_deferred("monitorable", true)
	set_deferred("monitoring",  false)

	var poly := _find_collision_polygon()
	if poly:
		if poly.polygon.is_empty():
			push_warning("[HITBOX] %s has an empty CollisionPolygon2D." % name)
		poly.set_deferred("disabled", false)
	else:
		push_warning("[HITBOX] %s is missing a CollisionPolygon2D child." % name)

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


func _find_collision_polygon() -> CollisionPolygon2D:
	for c in get_children():
		if c is CollisionPolygon2D:
			return c
	return null


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

func _on_area_entered(area: Area2D) -> void:
	if not (area.has_method("is_hitbox") and area.is_hitbox()):
		return
	if area.has_method("is_active") and not area.is_active():
		return

	# --- DEBUG: who hit whom, and are layers overlapping?
	var inst: Node = null
	if area.has_method("get_payload"):
		inst = area.get_payload().get("instigator", null) as Node

	var hb_layer: int = collision_layer
	var hb_mask: int = collision_mask
	var hits_us: bool = bool(area.collision_mask & hb_layer)

	prints("[HIT]", name, "<-", (inst and inst.name),
	   	"| A.mask & HB.layer? ", hits_us,
	   	"| HB L/M=", hb_layer, hb_mask,
	   	"| A L/M=", area.collision_layer, area.collision_mask)
