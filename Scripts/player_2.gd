extends CharacterBody2D
class_name Player_2

# --- Signals ---
@warning_ignore("unused_signal")
signal healthChange(current: int, max: int)
signal staminaChange(current: int, max: int)
signal died

@onready var animated_sprite: AnimatedSprite2D = $P2AnimatedSprite2D

# Hit / Hurt
@onready var hit_front: Hitbox2D = $Hitboxes/FrontSlash
@onready var hit_back:  Hitbox2D = $Hitboxes/BackSlash
@onready var hit_heavy: Hitbox2D = $Hitboxes/HeavySlash
@onready var hb_idle:   Hurtbox2D = $Hurtboxes/Idl
@onready var hb_run:    Hurtbox2D = $Hurtboxes/Run

# Containers we mirror for left/right
@onready var hit_container:  Node2D = $Hitboxes
@onready var hurt_container: Node2D = $Hurtboxes

# Health / stamina
@onready var health:  Health  = $Health
@export   var maxStamina: int = 100
@onready  var currentStamina: int = maxStamina

@onready var body_shape: CollisionShape2D = $Collision # adjust if different

# --- Movement constants ---
const SPEED := 400.0
const JUMP_VELOCITY := -700.0

# Parry window frames
const PARRY_START_FRAME := 1
const PARRY_END_FRAME   := 3

# Attack names used for timing/lookups
var _attack_anims := { "FrontSlash": true, "BackSlash": true, "HeavySlash": true }

# Parry state
var _parry_active: bool = false

# Input → movement
var move_left := false
var move_right := false
var direction := 0.0

# Attack state
var is_attacking := false
var locked_facing_left: bool = false  # lock facing during an attack

# Authoritative facing flag (do NOT auto-snap when idle)
var facing_left: bool = false

# Stamina costs
const STAMINA_COST := {
	"FrontSlash": 10,
	"BackSlash":  10,
	"HeavySlash": 25,
}

var is_dead := false


func _ready() -> void:
	add_to_group("player")
	print("[PLAYER2] added to group 'player' at ", get_path())

	# Enable exactly one Hurtbox
	_enable_hurtbox(hb_idle, true)
	_enable_hurtbox(hb_run,  false)

	# Stamina regen loop
	regen_stamina()

	# Prepare hitboxes (disabled until anim frame says ON)
	if is_instance_valid(hit_front):
		hit_front.set_instigator(self)
		hit_front.set_active(false)
	if is_instance_valid(hit_back):
		hit_back.set_instigator(self)
		hit_back.set_active(false)
	if is_instance_valid(hit_heavy):
		hit_heavy.set_instigator(self)
		hit_heavy.set_active(false)


	# Ensure consistent initial orientation (start facing right; set true to start left)
	_apply_facing(true)

	# Animation-driven toggles
	if not animated_sprite.frame_changed.is_connected(_on_sprite_frame_changed):
		animated_sprite.frame_changed.connect(_on_sprite_frame_changed)

	# Connect animation_finished to the handler that UNLOCKS attacks
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)

	# Relay Health → UI
	if is_instance_valid(health) and not health.health_changed.is_connected(_on_health_changed):
		health.health_changed.connect(_on_health_changed)

	# Listen for death
	if is_instance_valid(health) and not health.died.is_connected(_on_died):
		health.died.connect(_on_died)

	# Emit health once AFTER everyone is ready & connected
	await get_tree().process_frame
	_emit_health_now()


func is_parrying_now() -> bool:
	return _parry_active and not is_dead


func _physics_process(delta: float) -> void:
	if is_dead:
		update_gravity(delta)
		move_and_slide()
		return

	update_gravity(delta)
	update_direction()
	update_animation()
	update_movement()
	move_and_slide()


# ------------------ Facing / Mirroring ------------------

func _apply_facing(new_left: bool) -> void:
	# 1) flip visuals
	animated_sprite.flip_h = new_left
	# 2) mirror hit/hurt containers so hitboxes/hurtboxes swap sides
	if is_instance_valid(hit_container):
		hit_container.scale.x = (-1.0 if new_left else 1.0)
	if is_instance_valid(hurt_container):
		hurt_container.scale.x = (-1.0 if new_left else 1.0)
	facing_left = new_left


func update_direction() -> void:
	# Compute movement intent (no changes while attacking besides facing lock)
	direction = 0.0
	if not is_attacking:
		if move_left:  direction -= 1.0
		if move_right: direction += 1.0

	# Decide desired facing:
	# - If attacking: use the facing we locked at attack start
	# - Else if moving: face according to movement direction
	# - Else (idle): keep current facing (do NOT auto-snap to the right)
	var desired_left := facing_left
	if is_attacking:
		desired_left = locked_facing_left
	elif direction != 0.0:
		desired_left = (direction < 0.0)

	# Apply only when changed
	if desired_left != facing_left:
		_apply_facing(desired_left)


# ------------------ Movement / Animations ------------------

func update_animation() -> void:
	if is_dead:
		if animated_sprite.animation != "Death":
			animated_sprite.play("Death")
		return

	if not is_attacking:
		if is_on_floor():
			if direction == 0.0:
				if animated_sprite.animation != "Idle":
					animated_sprite.play("Idle")
			else:
				if animated_sprite.animation != "Run":
					animated_sprite.play("Run")
		else:
			if animated_sprite.animation != "Jump":
				animated_sprite.play("Jump")

	_update_active_hurtbox()


func update_movement() -> void:
	if not is_attacking:
		if direction != 0.0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)


func update_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif velocity.y > 0:
		velocity.y = 0


# ------------------ Hurtboxes / Hitboxes ------------------

func _enable_hurtbox(hb: Hurtbox2D, on: bool) -> void:
	if not is_instance_valid(hb):
		return
	hb.set_deferred("monitoring", on)
	hb.set_deferred("monitorable", on)
	var cs := hb.get_node_or_null("CollisionShape2D")
	if cs and cs is CollisionShape2D:
		cs.set_deferred("disabled", not on)

func _update_active_hurtbox() -> void:
	var anim: StringName = animated_sprite.animation
	var use_run := anim == "Run"
	_enable_hurtbox(hb_run,  use_run)
	_enable_hurtbox(hb_idle, not use_run)

func _set_all_hitboxes(on: bool) -> void:
	if is_instance_valid(hit_front):
		hit_front.set_active(on)
	if is_instance_valid(hit_back):
		hit_back.set_active(on)
	if is_instance_valid(hit_heavy):
		hit_heavy.set_active(on)

func _attack_ongoing() -> bool:
	return bool(_attack_anims.get(animated_sprite.animation, false))


# ------------------ Animation Callbacks ------------------

func _on_animation_finished() -> void:
	# Turn off any attack hitboxes and UNLOCK attacks
	if _attack_ongoing():
		_set_all_hitboxes(false)
	is_attacking = false

func _on_sprite_frame_changed() -> void:
	_parry_active = false
	if is_dead:
		_set_all_hitboxes(false)
		return

	var anim: StringName = animated_sprite.animation
	var frame: int = animated_sprite.frame

	var front_on := false
	var back_on  := false

	match anim:
		"FrontSlash":
			front_on = frame == 3
		"BackSlash":
			_parry_active = (frame >= PARRY_START_FRAME and frame <= PARRY_END_FRAME)
			if is_instance_valid(hit_front): hit_front.set_active(false)
			if is_instance_valid(hit_back):  hit_back.set_active(false)
		"HeavySlash":
			var heavy_on := (frame >= 3 and frame <= 4)
			if is_instance_valid(hit_heavy):
				hit_heavy.set_active(heavy_on)
			# Make sure other hitboxes are off if you want heavy to be exclusive
			front_on = false
			back_on  = false

		_:
			_set_all_hitboxes(false)
			return

	if is_instance_valid(hit_front):
		hit_front.set_active(front_on)
	if is_instance_valid(hit_back):
		hit_back.set_active(back_on)


# ------------------ Input ------------------

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("P2_MoveLeft"):
		move_left = true
	if event.is_action_released("P2_MoveLeft"):
		move_left = false

	if event.is_action_pressed("P2_MoveRight"):
		move_right = true
	if event.is_action_released("P2_MoveRight"):
		move_right = false

	if event.is_action_pressed("P2_Jump"):
		if is_on_floor() and not is_attacking:
			velocity.y = JUMP_VELOCITY

	if event.is_action_pressed("P2_AttackFront"):
		handle_move("FrontSlash")

	if event.is_action_pressed("P2_AttackBack"):
		_start_parry()

	if event.is_action_pressed("P2_AttackHeavy"):
		handle_move("HeavySlash")


# ------------------ Combat ------------------

func _start_parry() -> void:
	if is_attacking: return
	if STAMINA_COST["BackSlash"] > currentStamina: return
	spend_stamina("BackSlash")
	is_attacking = true
	locked_facing_left = facing_left           # lock current facing for the parry anim
	animated_sprite.play("BackSlash")
	velocity.x = 0

func handle_move(move: String) -> void:
	if (not is_attacking) and (STAMINA_COST[move] <= currentStamina):
		spend_stamina(move)
		is_attacking = true
		locked_facing_left = facing_left        # lock current facing for the whole attack
		animated_sprite.play(move)
		velocity.x = 0


# ------------------ Stamina / Health ------------------

func spend_stamina(move: String) -> void:
	currentStamina -= STAMINA_COST[move]
	staminaChange.emit(currentStamina, maxStamina)

func _on_health_changed(current: int, max_v: int) -> void:
	if has_signal("healthChange"):
		emit_signal("healthChange", current, max_v)

func get_current_health() -> int:
	return health.current_health if is_instance_valid(health) else 0

func get_max_health() -> int:
	return health.max_health if is_instance_valid(health) else 1

func _emit_health_now() -> void:
	if is_instance_valid(health) and has_signal("healthChange"):
		emit_signal("healthChange", health.current_health, health.max_health)

func regen_stamina() -> void:
	while is_inside_tree():
		await get_tree().create_timer(0.2).timeout
		if currentStamina < maxStamina:
			currentStamina = min(maxStamina, currentStamina + 1)
			staminaChange.emit(currentStamina, maxStamina)


# ------------------ Death ------------------

func _on_died() -> void:
	if is_dead:
		return
	is_dead = true
	print("Player2 died")
	emit_signal("died")

	if is_instance_valid(animated_sprite):
		animated_sprite.play("Death")

	_set_all_hitboxes(false)
	_kill_hurtbox(hb_idle)
	_kill_hurtbox(hb_run)

	velocity.x = 0
	set_physics_process(false)
	set_deferred("collision_layer", 0)
	set_process_input(false)

func _kill_hurtbox(hb: Hurtbox2D) -> void:
	if not is_instance_valid(hb): return
	hb.set_deferred("monitoring", false)
	hb.set_deferred("monitorable", false)
	hb.set_deferred("collision_layer", 0)
	hb.set_deferred("collision_mask", 0)
	var cs := hb.get_node_or_null("CollisionShape2D")
	if cs and cs is CollisionShape2D:
		cs.set_deferred("disabled", true)


# ------------------ Knockback ------------------

func apply_parry_knockback(counter_kb: Vector2, _stun_ms: int, _by: Node) -> void:
	velocity.x = counter_kb.x
	velocity.y = counter_kb.y
	move_and_slide()
