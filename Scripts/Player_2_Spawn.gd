extends Node2D

@export var player_scene: PackedScene = preload("res://Scenes/Elements/Player2.tscn")
@onready var player := $"../Player2"
signal player2_respawned(new_player: Player_2)
var spawn : Vector2

func _enter_tree() -> void:
	print("[RESPAWNER] enter tree at path ", get_path())
	
func _ready() -> void:
	print("[RESPAWNER] _ready at", get_path(), "  current_scene=", get_tree().current_scene)
	_find_and_connect_player()
	get_tree().node_added.connect(_on_node_added)
	# Connect every tower’s signal to Game
	for tower in get_tree().get_nodes_in_group("Tower"):
		if not tower.can_respawn1.is_connected(_on_tower_can_respawn):
			tower.can_respawn1.connect(_on_tower_can_respawn)
	
	var game = get_parent()
	if game and game.has_signal("spawn2"):
		var cb := Callable(self, "_on_spawn_received2")
		if not game.is_connected("spawn2", cb):
			game.connect("spawn2", cb)

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
	var game = get_parent()  # adjust if your GameManager node path differs
	if game and not p.died.is_connected(game._on_player_2_died):
		p.died.connect(game._on_player_2_died)

func _on_spawn_received(spawn_location: Vector2) -> void:
	print("[Spawner] Received spawn signal! Location:", spawn_location)
	spawn = spawn_location
	pass
	
func _on_tower_can_respawn() -> void:
	print("[DEBUG] Tower allows respawn!")
	call_deferred("respawn_player", spawn)

func respawn_player(spawn_pos: Vector2) -> void:
	if player_scene == null:
		push_error("Player scene null")
		return
		
		
	var new_player = player_scene.instantiate() as Player_2
	new_player.global_position = spawn_pos
	get_tree().current_scene.add_child(new_player)
	print("Player 2 Respawned!")
	
	player = new_player
	_connect_to_player(player)
	
	# rebind all health bars to this new player
	for bar in get_tree().get_nodes_in_group("hud_health"):
		if bar.has_method("bind_to_player2"):
			bar.bind_to_player2(player)
			
	emit_signal("player2_respawned", new_player)
