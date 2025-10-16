extends Node2D
signal spawn2(loc: Vector2)

func _ready():
	pass

func _on_player_2_died() -> void:
	var player1 = $Player1
	var closest_tower_P1: Node2D = null
	var spawn_tower: Node2D = null
	var spawn_location: Vector2
	
	closest_tower_P1 = find_closest_tower_right(player1)
	closest_tower_P1._on_passage_left_right()
	spawn_tower = find_closest_tower_right(closest_tower_P1)
	print("[DEBUG]", closest_tower_P1.name)
	print("[DEBUG]", closest_tower_P1.global_position)
	spawn_location = findspawn_location_P2(spawn_tower)
	print("[DEBUG]", spawn_tower.name)
	print("[DEBUG]", spawn_tower.global_position)
	emit_signal("spawn2", spawn_location)


func find_closest_tower_right(body) -> Node2D:
	var player1_x = body.global_position.x
	var smallest_distance = INF  # start with infinity
	var closest_tower: Node2D = null

	# Get all towers in a group called "Towers"
	for tower in get_tree().get_nodes_in_group("Tower"):
		if not (tower is Node2D):
			continue

		var tower_x = tower.global_position.x

		# Only consider towers to the right of Player1
		if tower_x > player1_x:
			var distance = tower_x - player1_x

			# If it's closer than what we had before, update
			if distance < smallest_distance:
				smallest_distance = distance
				closest_tower = tower

	return closest_tower

func findspawn_location_P2(body) -> Vector2:
	if body:
		var marker = body.get_node_or_null("Spawn_P2")
		if marker:
			print("[DEBUG]", marker.global_position)
			return marker.global_position
	return Vector2.ZERO

func _on_player_1_died() -> void:
	var player2 = $Player2
	var closest_tower_P2: Node2D = null
	var spawn_tower: Node2D = null
	var spawn_location: Vector2
	
	closest_tower_P2 = find_closest_tower_left(player2)
	closest_tower_P2._on_passage_right_left()
	print("[DEBUG]", closest_tower_P2.name)
	print("[DEBUG]", closest_tower_P2.global_position)
	spawn_tower = find_closest_tower_left(closest_tower_P2)
	spawn_location = findspawn_location_P1(spawn_tower)
	
func find_closest_tower_left(body) -> Node2D:
	var player2_x = body.global_position.x
	var smallest_distance = INF  # start with infinity
	var closest_tower: Node2D = null
	
	# Get all towers in a group called "Towers"
	for tower in get_tree().get_nodes_in_group("Tower"):
		if not (tower is Node2D):
			continue

		var tower_x = tower.global_position.x

		# Only consider towers to the right of Player1
		if tower_x < player2_x:
			var distance = player2_x - tower_x

			# If it's closer than what we had before, update
			if distance < smallest_distance:
				smallest_distance = distance
				closest_tower = tower

	return closest_tower
	
func findspawn_location_P1(body) -> Vector2:
	if body:
		var marker = body.get_node_or_null("Spawn_P1")
		if marker:
			print("[DEBUG]", marker.global_position)
			return marker.global_position
	return Vector2.ZERO
