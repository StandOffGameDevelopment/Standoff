extends Node2D

@export var player_scene: PackedScene = preload("res://Scenes/Elements/Player2.tscn")
@onready var player := $"../Player2"

func _enter_tree() -> void:
	print("[RESPAWNER] enter tree at path ", get_path())
	
func _ready() -> void:
	print("[RESPAWNER] _ready at", get_path(), "  current_scene=", get_tree().current_scene)
	_find_and_connect_player()
	get_tree().node_added.connect(_on_node_added)
		
		
		
func _find_and_connect_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Player_2
		_connect_to_player(player)
		print("Connected to player")
	else:
		print("cant find player")
		
func _on_node_added(n: Node) -> void:
	if n.is_in_group("player"):
		print("Respawner: new player entered tree:", n.name)
		player = n as Player_2
		_connect_to_player(player)
	
func _connect_to_player(p) -> void:
	if not is_instance_valid(p):
		print("Respawner: player node invalid at connect")
		return
	# avoid duplicate connections
	if not p.died.is_connected(_on_player_died):
		p.died.connect(_on_player_died)
		print("Respawner: connected to player.died")
		
func _on_player_died() -> void:
	print("respawner detected player died")
	await get_tree().create_timer(1.0).timeout  # Wait for 2 seconds

	respawn_player()
	
func respawn_player() -> void:
	if player_scene == null:
		push_error("Player scene null")
		return
		
		
	var new_player = player_scene.instantiate() as Player_2
	new_player.global_position = global_position
	get_tree().current_scene.add_child(new_player)
	print("Player 2 Respawned!")
	
	player = new_player
	_connect_to_player(player)
	
	# rebind all health bars to this new player
	for bar in get_tree().get_nodes_in_group("hud_health"):
		if bar.has_method("bind_to_player"):
			bar.bind_to_player(player)
