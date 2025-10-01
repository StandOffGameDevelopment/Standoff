extends TextureProgressBar

@export var player: Node

func _ready():
	player.healthChange.connect(update)
	update()

func update():
	value = player.currentHealth * 100 / player.maxHealth
	
