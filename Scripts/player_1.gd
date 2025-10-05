extends CharacterBody2D

class_name Player_1

# --- Signals ---
@warning_ignore("unused_signal")
signal healthChange
signal staminaChange(current: int, max: int)


# --- Movement constants ---
const SPEED := 160.0
const JUMP_VELOCITY := -400.0


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

@export var maxHealth := 100
@onready var currentHealth: int = maxHealth

@export var maxStamina = 100
@onready var currentStamina: int = maxStamina 


func _ready() -> void:
	regen_stamina()


func _physics_process(delta: float) -> void:
	update_gravity(delta)
	update_direction()
	update_animation()
	update_movement()
	move_and_slide()


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


func regen_stamina() -> void:
	while is_inside_tree():
		await get_tree().create_timer(0.2).timeout
		if currentStamina < maxStamina:
			currentStamina = min(maxStamina, currentStamina + 1)
			staminaChange.emit(currentStamina, maxStamina)
