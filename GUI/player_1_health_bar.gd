extends TextureProgressBar

@export var player: Node

func _ready() -> void:
	if player.has_signal("healthChange"):
		player.healthChange.connect(_on_player_health_change)
	# initial fill
	_on_player_health_change(player.get_current_health(), player.get_max_health())

func _on_player_health_change(current: int, max_h: int) -> void:
	max_value = 100
	value = int(round( float(current) / float(max_h) * 100.0 ))

	
