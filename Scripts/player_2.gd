extends CharacterBody2D

# --- Movement constants ---
const SPEED := 130.0
const JUMP_VELOCITY := -300.0

# --- Animation names (must match your SpriteFrames) ---
const ANIM_IDLE := "Idle"
const ANIM_RUN  := "Run"
const ANIM_JUMP := "Jump"

# Input → Animation mapping for attacks
const ATTACKS := {
	"Attack1": "Attack1",
	"Attack2": "Attack2",
}

var is_attacking := false
var locked_flip_h := false      # remembers facing during attack
var current_attack := ""        # which attack animation is currently playing

@onready var animated_sprite: AnimatedSprite2D = $P2AnimatedSprite2D

# --- Collider root (set to "" if they are direct children, or "Colliders" if grouped) ---
const COLLIDER_ROOT := ""   # e.g. "Colliders"

# Safe relative lookup (does NOT clash with Godot virtuals)
func get_rel_node(path: String) -> Node:
	var full := path if COLLIDER_ROOT == "" else "%s/%s" % [COLLIDER_ROOT, path]
	return get_node_or_null(full)

# --- Four collider variants ---
@onready var col_idle_attack_lr: CollisionShape2D = get_rel_node("Collision_Idle_and_Attack_LR")
@onready var col_idle_attack_rl: CollisionShape2D = get_rel_node("Collision_Idle_and_Attack_RL")
@onready var col_run_jump_lr:   CollisionShape2D = get_rel_node("Collision_Run_and_Jump_LR")
@onready var col_run_jump_rl:   CollisionShape2D = get_rel_node("Collision_Run_and_Jump_RL")

func _ready() -> void:
	# Ensure attack animations are one-shot so animation_finished will fire
	for anim_name in ATTACKS.values():
		if animated_sprite.sprite_frames.has_animation(anim_name):
			animated_sprite.sprite_frames.set_animation_loop(anim_name, false)

	# Connect animation finished safely
	if not animated_sprite.animation_finished.is_connected(_on_animated_sprite_animation_finished):
		animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)

	# Check colliders exist
	var missing := []
	if col_idle_attack_lr == null: missing.append("Collision_Idle_and_Attack_LR")
	if col_idle_attack_rl == null: missing.append("Collision_Idle_and_Attack_RL")
	if col_run_jump_lr   == null: missing.append("Collision_Run_and_Jump_LR")
	if col_run_jump_rl   == null: missing.append("Collision_Run_and_Jump_RL")
	if not missing.is_empty():
		push_error("Missing collider(s): %s. Check node names/paths & parents." % ", ".join(missing))
		return  # prevent running with nulls

	# Start with correct collider for the active animation
	_apply_collision_for(animated_sprite.animation)

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
				_apply_collision_for(ANIM_IDLE)
			else:
				if animated_sprite.animation != ANIM_RUN:
					animated_sprite.play(ANIM_RUN)
				_apply_collision_for(ANIM_RUN)
		else:
			if animated_sprite.animation != ANIM_JUMP:
				animated_sprite.play(ANIM_JUMP)
			_apply_collision_for(ANIM_JUMP)

	# Horizontal movement (no movement while attacking)
	if not is_attacking:
		if direction != 0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _trigger_attack(action: String) -> void:
	is_attacking = true
	current_attack = ATTACKS[action]
	locked_flip_h = animated_sprite.flip_h   # store facing at attack start
	animated_sprite.play(current_attack)
	_apply_collision_for(current_attack)     # attacks use the Idle/Attack collider
	velocity.x = 0                           # stop horizontal movement during attack

func _on_animated_sprite_animation_finished() -> void:
	# Reset attack state when the current attack finishes
	if is_attacking and animated_sprite.animation == current_attack:
		is_attacking = false
		current_attack = ""

# --- Collision switching ---
func _disable_all_colliders() -> void:
	for c in [col_idle_attack_lr, col_idle_attack_rl, col_run_jump_lr, col_run_jump_rl]:
		if c != null:
			c.disabled = true

func _apply_collision_for(anim_name: String) -> void:
	# If any collider is missing, bail out safely
	if col_idle_attack_lr == null or col_idle_attack_rl == null or col_run_jump_lr == null or col_run_jump_rl == null:
		return

	# Decide which family (Idle/Attack vs Run/Jump)
	var lower := anim_name.to_lower()
	var use_run_jump := (lower == "run" or lower == "jump")

	# Facing: flip_h == true means facing LEFT
	var facing_left := (locked_flip_h if is_attacking else animated_sprite.flip_h)

	_disable_all_colliders()

	if use_run_jump:
		if facing_left:
			col_run_jump_rl.disabled = false  # LEFT-facing run/jump
		else:
			col_run_jump_lr.disabled = false  # RIGHT-facing run/jump
	else:
		# Idle and any Attack animations use the Idle/Attack set
		if facing_left:
			col_idle_attack_rl.disabled = false  # LEFT-facing idle/attack
		else:
			col_idle_attack_lr.disabled = false  # RIGHT-facing idle/attack


func _on_P2AnimatedSprite2D_animation_finished() -> void:
	_on_animated_sprite_animation_finished()

func _on_p_2_animated_sprite_2d_animation_finished() -> void:
	_on_animated_sprite_animation_finished()
