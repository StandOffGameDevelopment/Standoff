extends Node2D
@onready var player1 = $Player1
@onready var player2 = $Player2
var closest_tower: Node2D = null

func _ready():
	pass

func _on_player_2_died() -> void:
	find_designated_tower_P1(player1)
	closest_tower._on_passage_left_right()


func find_designated_tower_P1(body) -> Node2D:
	var player1_x = body.global_position.x
	var smallest_distance = INF  # start with infinity

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
