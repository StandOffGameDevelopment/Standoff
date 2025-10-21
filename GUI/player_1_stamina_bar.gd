extends TextureProgressBar

@export var player_path: NodePath    # optional initial wiring via Inspector
@export var stamina_path: NodePath   # optional initial wiring via Inspector

var player: Node = null
var stamina: Node = null

func _ready() -> void:
	# So the Respawner can easily find & rebind this bar
	add_to_group("hud_stamina")

	# ProgressBar setup (percent-based like your health bar)
	min_value = 0
	max_value = 100
	value = 100

	# Initial (editor) wiring, if provided
	var p := get_node_or_null(player_path)
	var s := get_node_or_null(stamina_path)
	if p:
		_bind_to_player_internal(p, s)
	else:
		# still try to init value if only stamina is present
		stamina = s
		call_deferred("_initial_fill")


func bind_to_player1(new_player: Node) -> void:
	# derive Stamina from the player if present
	var new_stamina: Node = null
	if new_player and new_player.has_node("Stamina"):
		new_stamina = new_player.get_node("Stamina")

	_bind_to_player_internal(new_player, new_stamina)


# --- Internal: disconnect old, connect new, and refresh once
func _bind_to_player_internal(new_player: Node, new_stamina: Node) -> void:
	# 1) disconnect old
	if player and player.has_signal("staminaChange"):
		if player.staminaChange.is_connected(_on_player_stamina_change):
			player.staminaChange.disconnect(_on_player_stamina_change)

	if stamina and stamina.has_signal("stamina_changed"):
		if stamina.stamina_changed.is_connected(_on_player_stamina_change):
			stamina.stamina_changed.disconnect(_on_player_stamina_change)

	# 2) swap refs
	player = new_player
	stamina = new_stamina

	# 3) connect to new
	if player and player.has_signal("staminaChange"):
		if not player.staminaChange.is_connected(_on_player_stamina_change):
			player.staminaChange.connect(_on_player_stamina_change)

	if stamina and stamina.has_signal("stamina_changed"):
		if not stamina.stamina_changed.is_connected(_on_player_stamina_change):
			stamina.stamina_changed.connect(_on_player_stamina_change)

	# 4) refresh value now
	_initial_fill()


func _initial_fill() -> void:
	if stamina:
		var cur := int(stamina.get("current_stamina"))
		var mx  := int(stamina.get("max_stamina"))
		_on_player_stamina_change(cur, mx)
	elif player and player.has_method("get_current_stamina") and player.has_method("get_max_stamina"):
		_on_player_stamina_change(int(player.get_current_stamina()), int(player.get_max_stamina()))


func _on_player_stamina_change(current: int, max_st: int) -> void:
	if max_st <= 0:
		max_st = 1
	value = int(round(float(current) * 100.0 / float(max_st)))
