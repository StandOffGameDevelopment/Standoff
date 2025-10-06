extends TextureProgressBar

@export var player_path: NodePath   # drag Player_2 here
@export var health_path: NodePath   # optional: drag Player_2/Health

var player: Node = null
var health: Node = null

func _ready() -> void:
	# ProgressBar setup
	min_value = 0
	max_value = 100
	value = 100

	player = get_node_or_null(player_path)
	health = get_node_or_null(health_path)

	# Listen to Player_2’s relay
	if player and player.has_signal("healthChange") and not player.healthChange.is_connected(_on_player_health_change):
		player.healthChange.connect(_on_player_health_change)

	# Also listen directly to Health (safety net)
	if health and health.has_signal("health_changed") and not health.health_changed.is_connected(_on_player_health_change):
		health.health_changed.connect(_on_player_health_change)

	# If no signal has come yet (first frame), read directly once
	call_deferred("_initial_fill")

func _initial_fill() -> void:
	if health:
		var cur := int(health.get("current_health"))
		var mx  := int(health.get("max_health"))
		_on_player_health_change(cur, mx)
	elif player and player.has_method("get_current_health") and player.has_method("get_max_health"):
		_on_player_health_change(int(player.get_current_health()), int(player.get_max_health()))

func _on_player_health_change(current: int, max_h: int) -> void:
	if max_h <= 0:
		max_h = 1
	value = int(round( float(current) * 100.0 / float(max_h) ))
