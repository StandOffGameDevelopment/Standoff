extends CharacterBody2D

# --- Constants ---
const SPEED := 130.0
const JUMP_VELOCITY := -300.0

# Animation names 
const ANIM_IDLE := "Idle"
const ANIM_RUN := "Run"
const ANIM_JUMP := "Jump"

# Attacks stored in a dictionary: key = input action, value = animation name
const ATTACKS := {
	"Attack1": "Attack1",
	"Attack2": "Attack2",
	# "P2_Attack3": "P2_Attack3"
}

var is_attacking := false
var locked_flip_h := false  # remembers flip state during attack
var current_attack := ""     # stores which attack is currently playing

@onready var p_2_animated_sprite_2d: AnimatedSprite2D = $P2AnimatedSprite2D

func _ready() -> void:
	p_2_animated_sprite_2d.flip_h = true
	# Make sure all attack animations are not looping so signals fire
	for attack_anim in ATTACKS.values():
		if p_2_animated_sprite_2d.sprite_frames.has_animation(attack_anim):
			p_2_animated_sprite_2d.sprite_frames.set_animation_loop(attack_anim, false)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif velocity.y > 0:
		velocity.y = 0

	# Jump
	if Input.is_action_just_pressed("P2_jump") and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY

	# Get input direction: -1, 0, 1 (only if not attacking)
	var direction := 0.0
	if not is_attacking:
		direction = Input.get_axis("P2_moveLeft", "P2_moveRight")

	# Flip sprite based on direction (but freeze during attack)
	if not is_attacking:
		if direction != 0:
			p_2_animated_sprite_2d.flip_h = direction < 0
	else:
		p_2_animated_sprite_2d.flip_h = locked_flip_h

	# Handle attacks
	if not is_attacking and is_on_floor():
		for action in ATTACKS.keys():
			if Input.is_action_just_pressed(action):
				_trigger_attack(action)
				return

	# Play animations only if not attacking
	if not is_attacking:
		if is_on_floor():
			if direction == 0:
				p_2_animated_sprite_2d.play(ANIM_IDLE)
			else:
				p_2_animated_sprite_2d.play(ANIM_RUN)
		else:
			p_2_animated_sprite_2d.play(ANIM_JUMP)

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
	locked_flip_h = p_2_animated_sprite_2d.flip_h
	p_2_animated_sprite_2d.play(current_attack)
	velocity.x = 0

func _on_p_2_animated_sprite_2d_animation_finished() -> void:
	if is_attacking and p_2_animated_sprite_2d.animation == current_attack:
		is_attacking = false
		current_attack = ""
