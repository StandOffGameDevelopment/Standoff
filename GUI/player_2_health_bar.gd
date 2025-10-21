extends TextureProgressBar

@export var player_path: NodePath   # optional initial wiring via Inspector
@export var health_path: NodePath   # optional initial wiring via Inspector

var player: Node = null
var health: Node = null

func _ready() -> void:
	# so the Respawner can easily find & rebind this bar
	add_to_group("hud_health")

	# ProgressBar setup
	min_value = 0
	max_value = 100
	value = 100

	# Initial (editor) wiring, if provided
	var p := get_node_or_null(player_path)
	var h := get_node_or_null(health_path)
	if p:
		_bind_to_player_internal(p, h)
	else:
		# still try to init value if only health is present
		health = h
		call_deferred("_initial_fill")


func bind_to_player2(new_player: Node) -> void:
	# derive Health from the player if present
	var new_health: Node = null
	if new_player and new_player.has_node("Health"):
		new_health = new_player.get_node("Health")

	_bind_to_player_internal(new_player, new_health)


# --- Internal: disconnect old, connect new, and refresh once
func _bind_to_player_internal(new_player: Node, new_health: Node) -> void:
	# 1) disconnect old
	if player and player.has_signal("healthChange"):
		if player.healthChange.is_connected(_on_player_health_change):
			player.healthChange.disconnect(_on_player_health_change)

	if health and health.has_signal("health_changed"):
		if health.health_changed.is_connected(_on_player_health_change):
			health.health_changed.disconnect(_on_player_health_change)

	# 2) swap refs
	player = new_player
	health = new_health

	# 3) connect to new
	if player and player.has_signal("healthChange"):
		if not player.healthChange.is_connected(_on_player_health_change):
			player.healthChange.connect(_on_player_health_change)

	if health and health.has_signal("health_changed"):
		if not health.health_changed.is_connected(_on_player_health_change):
			health.health_changed.connect(_on_player_health_change)

	# 4) refresh value now
	_initial_fill()


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
	value = int(round(float(current) * 100.0 / float(max_h)))
