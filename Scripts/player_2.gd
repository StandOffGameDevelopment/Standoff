extends CharacterBody2D

# --- Signals ---
signal healthChange
signal staminaChange(current: int, max: int)

# --- Movement constants ---
const SPEED: float = 160.0
const JUMP_VELOCITY: float = -400.0

# --- Animation names ---
const ANIM_IDLE := "Idle"
const ANIM_RUN  := "Run"
const ANIM_JUMP := "Jump"

# Input → Animation mapping for attacks (keys are Input actions)
const ATTACKS: Dictionary = {
	"Attack1": "Attack1",
	"Attack2": "Attack2",
}

const ATTACK_STAMINA_COST: Dictionary = {
	"Attack1": 15,
	"Attack2": 25,
}

# Which frames (0-based) the hitbox should be active (tweak to match your sprites)
const ATTACK_ACTIVE_FRAMES: Dictionary = {
	"Attack1": Vector2i(2, 3),
	"Attack2": Vector2i(3, 4),
}

# --- State ---
var is_attacking := false
var locked_flip_h := false
var current_attack: String = ""
var _attack_side := "front"   # "front" or "back"

@onready var animated_sprite: AnimatedSprite2D = $P2AnimatedSprite2D
@onready var hb_front: Hitbox2D = $"Hitboxes/Hit Front Slash"
@onready var hb_back:  Hitbox2D = $"Hitboxes/Hit Back Slash"

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

	# Make attack animations one-shot so animation_finished will fire.
	for anim_name in ATTACKS.values():
		var name_str := String(anim_name)
		if animated_sprite.sprite_frames.has_animation(name_str):
			animated_sprite.sprite_frames.set_animation_loop(name_str, false)

	# Connect signals (Callable form for Godot 4)
	var finished_cb := Callable(self, "_on_animated_sprite_animation_finished")
	if not animated_sprite.animation_finished.is_connected(finished_cb):
		animated_sprite.animation_finished.connect(finished_cb)

	var frame_cb := Callable(self, "_on_anim_frame_changed")
	if not animated_sprite.frame_changed.is_connected(frame_cb):
		animated_sprite.frame_changed.connect(frame_cb)

	_disable_all_hitboxes()

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0

	# Jump
	if Input.is_action_just_pressed("P2_jump") and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY

	# Horizontal input (frozen while attacking)
	var direction: float = 0.0
	if not is_attacking:
		direction = Input.get_axis("P2_moveLeft", "P2_moveRight")

	# Facing
	if not is_attacking:
		if direction != 0.0:
			animated_sprite.flip_h = direction < 0.0
	else:
		animated_sprite.flip_h = locked_flip_h

	# Knockback integration
	velocity += external_knockback
	external_knockback = external_knockback.move_toward(Vector2.ZERO, knock_decay * delta)

	# Attack input (only grounded, only if not already attacking)
	if not is_attacking and is_on_floor():
		for action in ATTACKS.keys():
			if Input.is_action_just_pressed(String(action)):
				_trigger_attack(String(action))
				return

	# Locomotion anims when not attacking
	if not is_attacking:
		if is_on_floor():
			if direction == 0.0:
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
		if direction != 0.0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)

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
	# OLD: _attack_side = (animated_sprite.flip_h) ? "back" : "front"
	_attack_side = "back" if animated_sprite.flip_h else "front"
	_disable_all_hitboxes()
	animated_sprite.play(current_attack)
	velocity.x = 0.0

func _on_animated_sprite_animation_finished() -> void:
	if is_attacking and animated_sprite.animation == current_attack:
		is_attacking = false
		current_attack = ""
		_disable_all_hitboxes()

func _on_anim_frame_changed() -> void:
	if not is_attacking:
		_disable_all_hitboxes()
		return

	var win: Vector2i = ATTACK_ACTIVE_FRAMES.get(current_attack, Vector2i(-1, -1))
	var f: int = animated_sprite.frame
	var active_now := (f >= win.x and f <= win.y)

	if active_now:
		# OLD: var hb := (_attack_side == "back") ? hb_back : hb_front
		var hb: Hitbox2D = hb_back if _attack_side == "back" else hb_front
		if hb:
			hb.instigator = self
			hb.set_active(true)
	else:
		_disable_all_hitboxes()

func _disable_all_hitboxes() -> void:
	if is_instance_valid(hb_front): hb_front.set_active(false)
	if is_instance_valid(hb_back):  hb_back.set_active(false)

# --- Combat helpers (taking damage/knockback) ---
func apply_knockback(kb: Vector2) -> void:
	external_knockback = kb

func take_damage(amount: int, instigator: Node, kb: Vector2) -> void:
	if invincible:
		return
	currentHealth = max(0, currentHealth - amount)
	healthChange.emit()

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
