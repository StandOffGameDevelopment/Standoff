extends CharacterBody2D

# --- Signals ---
signal healthChange
signal staminaChange(current: int, max: int)

# --- Movement constants ---
const SPEED := 160.0
const JUMP_VELOCITY := -400.0

# --- Animation names ---
const ANIM_IDLE := "Idle"
const ANIM_RUN  := "Run"
const ANIM_JUMP := "Jump"

# Input → Animation mapping for attacks (keys are Input actions)
const ATTACKS := {
	"P1_Attack1": "Attack1",
	"P1_Attack2": "Attack2",
}
const ATTACK_STAMINA_COST := {
	"P1_Attack1": 15,
	"P1_Attack2": 25,
}

# --- State ---
var is_attacking := false
var locked_flip_h := false
var current_attack := ""

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var maxHealth: int = 100
var currentHealth: int

@export var maxStamina: int = 100
var currentStamina: int

var external_knockback := Vector2.ZERO
@export var knock_decay: float = 10.0

var invincible := false
@export var iframe_time: float = 0.25

func _ready() -> void:
	currentHealth = maxHealth
	currentStamina = maxStamina
	regen_stamina()

	# Attack anims one-shot so animation_finished fires
	for anim_name in ATTACKS.values():
		if animated_sprite.sprite_frames.has_animation(anim_name):
			animated_sprite.sprite_frames.set_animation_loop(anim_name, false)

	if not animated_sprite.animation_finished.is_connected(_on_animated_sprite_animation_finished):
		animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif velocity.y > 0:
		velocity.y = 0

	# Jump
	if Input.is_action_just_pressed("P1_jump") and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY

	# Horizontal input (frozen while attacking)
	var direction := 0.0
	if not is_attacking:
		direction = Input.get_axis("P1_moveLeft", "P1_moveRight")

	# Facing
	if not is_attacking:
		if direction != 0:
			animated_sprite.flip_h = direction < 0
	else:
		animated_sprite.flip_h = locked_flip_h

	# Knockback integration
	velocity += external_knockback
	external_knockback = external_knockback.move_toward(Vector2.ZERO, knock_decay * delta)

	# Attack input (only grounded, only if not already attacking)
	if not is_attacking and is_on_floor():
		for action in ATTACKS.keys():
			if Input.is_action_just_pressed(action):
				_trigger_attack(action)
				return

	# Locomotion anims when not attacking
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

	# Horizontal movement (no move while attacking)
	if not is_attacking:
		if direction != 0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _trigger_attack(action: String) -> void:
	var cost: int = int(ATTACK_STAMINA_COST.get(action, 0))
	if currentStamina < cost:
		return
	currentStamina -= cost
	staminaChange.emit(currentStamina, maxStamina)

	is_attacking = true
	current_attack = String(ATTACKS.get(action, ""))
	locked_flip_h = animated_sprite.flip_h
	animated_sprite.play(current_attack)
	velocity.x = 0


func _on_animated_sprite_animation_finished() -> void:
	if is_attacking and animated_sprite.animation == current_attack:
		is_attacking = false
		current_attack = ""

# --- Combat helpers (taking damage/knockback) ---
func apply_knockback(kb: Vector2) -> void:
	external_knockback = kb

func take_damage(amount: int, instigator: Node, kb: Vector2) -> void:
	if invincible:
		return
	currentHealth = max(0, currentHealth - amount)
	healthChange.emit()
	# push away from the attacker
	var attacker := instigator as Node2D
	var dir: float = 0.0
	if attacker:
		dir = sign(global_position.x - attacker.global_position.x)
	apply_knockback(Vector2(kb.x * dir, kb.y))
	invincible = true
	await get_tree().create_timer(iframe_time).timeout
	invincible = false

# --- Stamina regen ---
func regen_stamina() -> void:
	while is_inside_tree():
		await get_tree().create_timer(0.25).timeout
		if currentStamina < maxStamina:
			currentStamina = min(maxStamina, currentStamina + 2)
			staminaChange.emit(currentStamina, maxStamina)
