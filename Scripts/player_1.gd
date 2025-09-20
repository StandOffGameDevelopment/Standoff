extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0

var is_attacking := false
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("P1_jump") and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY

	# Get input direction: -1, 0, 1
	var direction := Input.get_axis("P1_moveLeft", "P1_moveRight")

	# Flip sprite based on direction
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# Attack
	if Input.is_action_just_pressed("P1_Attack1") and not is_attacking:
		is_attacking = true
		animated_sprite.play("Attack1")
		velocity.x = 0 # stop horizontal movement during attack
		return

	# Play animations only if not attacking
	if not is_attacking:
		if is_on_floor():
			if direction == 0:
				animated_sprite.play("Idle")
			else:
				animated_sprite.play("Run")
		else:
			animated_sprite.play("Jump")

	# Movement
	if direction and not is_attacking:
		velocity.x = direction * SPEED
	elif not is_attacking:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _on_animated_sprite_2d_animation_finished() -> void:
	# Reset attack state when attack animation finishes
	if animated_sprite.animation == "Attack1":
		is_attacking = false
