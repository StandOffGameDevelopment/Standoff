extends CharacterBody2D

# --- Constants ---
const SPEED := 130.0
const JUMP_VELOCITY := -300.0

# Animation names 
const ANIM_IDLE := "P2_Idle"
const ANIM_RUN := "P2_Run"
const ANIM_JUMP := "P2_Jump"
const ANIM_ATTACK := "P2_Attack1"

var is_attacking := false
var locked_flip_h := false  # remembers flip state during attack
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	# Make sure Attack1 is not looping so signal will fire !!!! KEY STEP !!!!
	if animated_sprite_2d.sprite_frames.has_animation(ANIM_ATTACK):
		animated_sprite_2d.sprite_frames.set_animation_loop(ANIM_ATTACK, false)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif velocity.y > 0:
		velocity.y = 0  # avoid tiny downward drift when grounded

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
			animated_sprite_2d.flip_h = direction < 0
	else:
		animated_sprite_2d.flip_h = locked_flip_h

	# Attack
	if Input.is_action_just_pressed("P2_Attack1") and not is_attacking:
		is_attacking = true
		locked_flip_h = animated_sprite_2d.flip_h  # store facing direction at attack start
		animated_sprite_2d.play(ANIM_ATTACK)
		velocity.x = 0  # stop horizontal movement during attack
		return

	# Play animations only if not attacking
	if not is_attacking:
		if is_on_floor():
			if direction == 0:
				animated_sprite_2d.play(ANIM_IDLE)
			else:
				animated_sprite_2d.play(ANIM_RUN)
		else:
			animated_sprite_2d.play(ANIM_JUMP)

	# Movement
	if not is_attacking:
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _on_animated_sprite_2d_animation_finished() -> void:
	# Reset attack state when attack animation finishes
	if animated_sprite_2d.animation == ANIM_ATTACK:
		is_attacking = false
