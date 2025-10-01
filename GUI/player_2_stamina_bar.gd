extends TextureProgressBar

@export var player: Node

func _ready() -> void:
	max_value = player.maxStamina
	value = player.currentStamina
	player.staminaChange.connect(_on_player_stamina_change)


func _on_player_stamina_change(current: int, max_st: int) -> void:
	value = current
	max_value = max_st
	
