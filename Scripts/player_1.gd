extends CharacterBody2D

class_name Player_1

# --- Signals ---
@warning_ignore("unused_signal")
signal healthChange(current: int, max: int)
signal staminaChange(current: int, max: int)
signal died

@onready var p1_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_front: Hitbox2D = $Hitbox/FrontSlash
@onready var hit_back: Hitbox2D = $Hitbox/BackSlash
@onready var health: Health = $Health

@onready var hb_idle: Hurtbox2D = $Hurtboxes/Idle
@onready var hb_run:  Hurtbox2D = $Hurtboxes/Run

@onready var body_shape: CollisionShape2D = $Collision # adjust path if different

# --- Movement constants ---
const SPEED := 400.0
const JUMP_VELOCITY := -700.0



var _attack_anims := { "FrontSlash": true, "BackSlash": true, "HeavySlash": true }


# --- Cost of every move that consumes stamina ---
const STAMINA_COST := {
	"FrontSlash" : 10,
	"BackSlash" : 10,
	"HeavySlash" : 25,
}


# --- Variables relates to x-axis movement
var move_left := false
var move_right := false
var direction := 0.0


# --- Variables relates to x-axis movement
var is_attacking := false
var locked_flip_h := false      # remembers direction during attack


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var maxStamina = 100
@onready var currentStamina: int = maxStamina 
var is_dead := false


func _ready() -> void:
	print("[DEBUG] p1_sprite name:", p1_sprite.name)
	print("[DEBUG] frame_changed connected:", p1_sprite.frame_changed.is_connected(_on_sprite_frame_changed))
	print("[DEBUG] animation_finished connected:", p1_sprite.animation_finished.is_connected(_on_anim_finished))

	regen_stamina()
	# Set this player as the instigator and start disabled
	if is_instance_valid(hit_front):
		hit_front.set_instigator(self)
		hit_front.set_active(false)
	if is_instance_valid(hit_back):
		hit_back.set_instigator(self)
		hit_back.set_active(false)

	# Toggle by animation frame
	if not p1_sprite.frame_changed.is_connected(_on_sprite_frame_changed):
		p1_sprite.frame_changed.connect(_on_sprite_frame_changed)
	if not p1_sprite.animation_finished.is_connected(_on_anim_finished):
		p1_sprite.animation_finished.connect(_on_anim_finished)

	# (Optional) If your UI bars listen to Player1's healthChange, relay Health to them later when we add P1's Hurtbox.
	if is_instance_valid(health) and not health.health_changed.is_connected(_on_health_changed):
		health.health_changed.connect(_on_health_changed)
		
	if is_instance_valid(health) and not health.died.is_connected(_on_died):
		health.died.connect(_on_died)
	
	await get_tree().process_frame
	_emit_health_now()



func _physics_process(delta: float) -> void:
	if is_dead:
		# let gravity settle (e.g., fall to ground), but no controls
		update_gravity(delta)
		move_and_slide()
		return
	
	update_gravity(delta)
	update_direction()
	update_animation()
	update_movement()
	move_and_slide()

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

func get_current_health() -> int:
	return health.current_health

func get_max_health() -> int:
	return health.max_health

func _on_health_changed(current: int, max_v: int) -> void:
	if has_signal("healthChange"):
		emit_signal("healthChange", current, max_v)

func _on_anim_finished() -> void:
	if _attack_ongoing():
		_set_all_hitboxes(false)

func _on_sprite_frame_changed() -> void:
	if is_dead:
		_set_all_hitboxes(false)
		return

	var anim: StringName = p1_sprite.animation
	var frame: int = p1_sprite.frame
	
	var front_on := false
	var back_on  := false
	
	match anim:
		"FrontSlash":
			front_on = frame == 3
		"BackSlash":
			back_on  = frame == 3
		"HeavySlash":
			# No heavy hitbox yet → keep off
			front_on = false
			back_on  = false
		_:
			_set_all_hitboxes(false)
			return
	
	if front_on: print("[P1] FRONT HITBOX ON at frame ", frame)
	if back_on:  print("[P1] BACK  HITBOX ON at frame ", frame)
	
	if is_instance_valid(hit_front) and front_on:
		print("[P1] TOGGLE front ON; node=", hit_front.name)
	if is_instance_valid(hit_back) and back_on:
		print("[P1] TOGGLE back  ON; node=", hit_back.name)

	if is_instance_valid(hit_front):
		hit_front.set_active(front_on)
	if is_instance_valid(hit_back):
		hit_back.set_active(back_on)

	if front_on or back_on:
		await get_tree().create_timer(0.05).timeout
		_set_all_hitboxes(false)


func _set_all_hitboxes(on: bool) -> void:
	if is_instance_valid(hit_front):
		hit_front.set_active(on)
	if is_instance_valid(hit_back):
		hit_back.set_active(on)

func _attack_ongoing() -> bool:
	return bool(_attack_anims.get(p1_sprite.animation, false))


func update_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif velocity.y > 0:
		velocity.y = 0


func update_direction() -> void:
	# Update direction every frame
	direction = 0.0
	if not is_attacking:
		if move_left: direction -= 1
		if move_right: direction += 1
		
	# Flip sprite based on direction (freeze during attack)
	if is_attacking:
		animated_sprite.flip_h = locked_flip_h
	elif direction != 0:
		animated_sprite.flip_h = direction < 0


func update_animation() -> void:
	# Locomotion animations (and collider switch) when not attacking
	if is_dead:
		if animated_sprite.animation != "Death":
			animated_sprite.play("Death")
		return

	if not is_attacking:
		if is_on_floor():
			if direction == 0:
				if animated_sprite.animation != "Idle":
					animated_sprite.play("Idle")
			else:
				if animated_sprite.animation != "Run":
					animated_sprite.play("Run")
				
		else:
			if animated_sprite.animation != "Jump":
				animated_sprite.play("Jump")


func update_movement() -> void:
	# Horizontal movement (no movement while attacking)
	if not is_attacking:
		if direction != 0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)


func _on_animation_finished() -> void:
	# Reset attack state when the current attack finishes
	if is_attacking:
		is_attacking = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("P1_MoveLeft"):
		move_left = true
		# print("Left true")
	
	if event.is_action_released("P1_MoveLeft"):
		move_left = false
		# print("Left false")
	
	if event.is_action_pressed("P1_MoveRight"):
		move_right = true
		# print("Right true")
	
	if event.is_action_released("P1_MoveRight"):
		move_right = false
		# print("Right false")
		
	if event.is_action_pressed("P1_Jump"):
		# print("Jump pressed")
		if is_on_floor() and not is_attacking:
			velocity.y = JUMP_VELOCITY
		
	if event.is_action_pressed("P1_AttackFront"):
		handle_move("FrontSlash")
		
	if event.is_action_pressed("P1_AttackBack"):
		handle_move("BackSlash")
		
	if event.is_action_pressed("P1_AttackHeavy"):
		handle_move("HeavySlash")
		
	#TODO: add sounds


func handle_move(move: String) -> void:
	# print(move + "pressed")
	if (not is_attacking) and (STAMINA_COST[move] <= currentStamina):
		spend_stamina(move)
		is_attacking = true
		locked_flip_h = animated_sprite.flip_h   # store facing at attack start
		animated_sprite.play(move)
		velocity.x = 0


func spend_stamina(move: String) -> void:
	currentStamina -= STAMINA_COST[move]
	staminaChange.emit(currentStamina, maxStamina)
	
func _emit_health_now() -> void:
	if is_instance_valid(health) and has_signal("healthChange"):
		emit_signal("healthChange", health.current_health, health.max_health)

func regen_stamina() -> void:
	while is_inside_tree():
		await get_tree().create_timer(0.2).timeout
		if currentStamina < maxStamina:
			currentStamina = min(maxStamina, currentStamina + 1)
			staminaChange.emit(currentStamina, maxStamina)

func _on_died() -> void:
	if is_dead:
		return
	is_dead = true
	print("Player 1 died")
	emit_signal("died")
	
	# Play death once
	if is_instance_valid(animated_sprite):
		animated_sprite.play("Death")
		
		
	## Stop combat interactions immediately
	_set_all_hitboxes(false)
	_kill_hurtbox(hb_idle)
	_kill_hurtbox(hb_run)
	
	# Set horizontal movement to 0 and disable physics
	velocity.x = 0
	set_physics_process(false)
	set_deferred("collision_layer", 0)

	# Block player control AFTER death (this is the part that stops movement post-death)
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
