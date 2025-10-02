extends CharacterBody2D

# --- Signals ---
@warning_ignore("unused_signal")
signal healthChange
signal staminaChange(current: int, max: int)

# --- Movement constants ---
const SPEED := 160.0
const JUMP_VELOCITY := -400.0

# --- Animation names (must match your SpriteFrames) ---
const ANIM_IDLE := "Idle"
const ANIM_RUN  := "Run"
const ANIM_JUMP := "Jump"

# Input → Animation mapping for attacks
const ATTACKS := {
	"Attack1": "Attack1",
	"Attack2": "Attack2",
}

const ATTACK_STAMINA_COST := {
	"Attack1" : 15,
	"Attack2" : 25,
}


var is_attacking := false
var locked_flip_h := false      # remembers facing during attack
var current_attack := ""        # which attack animation is currently playing

@onready var animated_sprite: AnimatedSprite2D = $P2AnimatedSprite2D

@export var maxHealth := 100
@onready var currentHealth: int = maxHealth

@export var maxStamina = 100
@onready var currentStamina: int = maxStamina 


func _ready() -> void:
	regen_stamina()
	# Ensure attack animations are one-shot so animation_finished will fire
	for anim_name in ATTACKS.values():
		if animated_sprite.sprite_frames.has_animation(anim_name):
			animated_sprite.sprite_frames.set_animation_loop(anim_name, false)

	# Connect animation finished safely
	if not animated_sprite.animation_finished.is_connected(_on_animated_sprite_animation_finished):
		animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif velocity.y > 0:
		velocity.y = 0

	# Jump
	if Input.is_action_just_pressed("P2_jump") and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY

	# Get input direction only when not attacking
	var direction := 0.0
	if not is_attacking:
		direction = Input.get_axis("P2_moveLeft", "P2_moveRight")

	# Flip sprite based on direction (freeze during attack)
	if not is_attacking:
		if direction != 0:
			animated_sprite.flip_h = direction < 0
	else:
		animated_sprite.flip_h = locked_flip_h

	# Handle attacks (grounded, not currently attacking)
	if not is_attacking and is_on_floor():
		for action in ATTACKS.keys():
			if Input.is_action_just_pressed(action):
				_trigger_attack(action)
				return

	# Locomotion animations (and collider switch) when not attacking
	if not is_attacking:
		if is_on_floor():
			if direction == 0:
				if animated_sprite.animation != ANIM_IDLE:
					animated_sprite.play(ANIM_IDLE)
			else:
				if animated_sprite.animation != ANIM_RUN:
					animated_sprite.play(ANIM_RUN)
				
		else:
			if animated_sprite.animation != ANIM_JUMP:
				animated_sprite.play(ANIM_JUMP)

	# Horizontal movement (no movement while attacking)
	if not is_attacking:
		if direction != 0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _trigger_attack(action: String) -> void:
	# Check stamina
	var cost = ATTACK_STAMINA_COST.get(action, 0)
	if currentStamina < cost:
		return 
		
	# Spend stamina 
	currentStamina -= cost
	staminaChange.emit(currentStamina, maxStamina)
	
	is_attacking = true
	current_attack = ATTACKS[action]
	locked_flip_h = animated_sprite.flip_h   # store facing at attack start
	animated_sprite.play(current_attack)
	velocity.x = 0                           # stop horizontal movement during attack

func _on_animated_sprite_animation_finished() -> void:
	# Reset attack state when the current attack finishes
	if is_attacking and animated_sprite.animation == current_attack:
		is_attacking = false
		current_attack = ""


func _on_P2AnimatedSprite2D_animation_finished() -> void:
	_on_animated_sprite_animation_finished()

func _on_p_2_animated_sprite_2d_animation_finished() -> void:
	_on_animated_sprite_animation_finished()
	
func regen_stamina() -> void:
	while is_inside_tree():
		await get_tree().create_timer(0.25).timeout
		if currentStamina < maxStamina:
			currentStamina = min(maxStamina, currentStamina + 2)
			staminaChange.emit(currentStamina, maxStamina)
