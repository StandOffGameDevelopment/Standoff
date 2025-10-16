extends Node
class_name Health

signal health_changed(current: int, max: int)
signal took_hit(amount: int, instigator: Node)
signal died

@export var max_health: int = 100
var current_health: int = 100
var invulnerable: bool = false

var _iframes_timer: Timer

func _ready() -> void:
	current_health = max_health
	_iframes_timer = Timer.new()
	_iframes_timer.one_shot = true
	add_child(_iframes_timer)
	_iframes_timer.timeout.connect(func() -> void:
		invulnerable = false
	)
	emit_signal("health_changed", current_health, max_health)

func apply_damage(amount: int, instigator: Node) -> void:
	if invulnerable or amount <= 0:
		return
	current_health = max(0, current_health - amount)
	print("[HEALTH] apply_damage:", amount, "→", current_health, "/", max_health)
	emit_signal("took_hit", amount, instigator)
	emit_signal("health_changed", current_health, max_health)
	if current_health == 0:
		emit_signal("died")

func heal(amount: int) -> void:
	if amount <= 0:
		return
	current_health = min(max_health, current_health + amount)
	emit_signal("health_changed", current_health, max_health)

func grant_i_frames(seconds: float) -> void:
	invulnerable = true
	_iframes_timer.start(seconds)
