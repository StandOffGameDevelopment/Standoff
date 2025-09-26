extends CharacterBody2D

# --- Constants ---
const SPEED := 130.0
const JUMP_VELOCITY := -300.0

# Animation names
const ANIM_IDLE := "Idle"
const ANIM_RUN := "Run"
const ANIM_JUMP := "Jump"

# Input→Animation mapping for attacks (add more here)
const ATTACKS := {
	"P1_Attack1": "Attack1",
	"P1_Attack2": "Attack2",
}

var is_attacking := false
var locked_flip_h := false      # remembers facing during attack
var current_attack := ""        # which attack animation is currently playing

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Ensure all attack animations are one-shot so animation_finished will fire
	for anim_name in ATTACKS.values():
		if animated_sprite.sprite_frames.has_animation(anim_name):
			animated_sprite.sprite_frames.set_animation_loop(anim_name, false)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif velocity.y > 0:
		velocity.y = 0  # avoid tiny downward drift when grounded

	# Jump
	if Input.is_action_just_pressed("P1_jump") and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY

	# Get input direction: -1, 0, 1 (only if not attacking)
	var direction := 0.0
	if not is_attacking:
		direction = Input.get_axis("P1_moveLeft", "P1_moveRight")

	# Flip sprite based on direction (but freeze during attack)
	if not is_attacking:
		if direction != 0:
			animated_sprite.flip_h = direction < 0
	else:
		animated_sprite.flip_h = locked_flip_h

	# Handle attacks (data-driven)
	if not is_attacking and is_on_floor():
		for action in ATTACKS.keys():
			if Input.is_action_just_pressed(action):
				_trigger_attack(action)
				return

	# Play animations only if not attacking
	if not is_attacking:
		if is_on_floor():
			if direction == 0:
				animated_sprite.play(ANIM_IDLE)
			else:
				animated_sprite.play(ANIM_RUN)
		else:
			animated_sprite.play(ANIM_JUMP)

	# Movement
	if not is_attacking:
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _trigger_attack(action: String) -> void:
	is_attacking = true
	current_attack = ATTACKS[action]
	locked_flip_h = animated_sprite.flip_h  # store facing at attack start
	animated_sprite.play(current_attack)
	velocity.x = 0  # stop horizontal movement during attack

func _on_animated_sprite_2d_animation_finished() -> void:
	# Reset attack state when the current attack finishes
	if is_attacking and animated_sprite.animation == current_attack:
		is_attacking = false
		current_attack = ""
