extends Node
class_name Stamina

signal stamina_changed(current: int, max: int)
signal stamina_spent(amount: int)
signal stamina_depleted
signal stamina_full

@export var max_stamina: int = 100
@export var regen_per_second: float = 15.0      # how many stamina per second to restore
@export var regen_delay: float = 1.0            # delay before regen starts after any spend
@export var exhaust_cooldown: float = 0.5       # extra delay if stamina hits zero
@export var tick_interval: float = 0.1          # regen tick granularity (seconds)

var current_stamina: int = 100

var _regen_timer: Timer
var _delay_timer: Timer

func _ready() -> void:
	current_stamina = clamp(current_stamina, 0, max_stamina)
	
	# --- Regen ticker (repeating)
	_regen_timer = Timer.new()
	_regen_timer.one_shot = false
	_regen_timer.wait_time = max(0.01, tick_interval)
	add_child(_regen_timer)
	_regen_timer.timeout.connect(_on_regen_tick)
	_regen_timer.start()

	# --- Delay timer (one-shot)
	_delay_timer = Timer.new()
	_delay_timer.one_shot = true
	add_child(_delay_timer)
	# no callback needed; we poll time_left in _on_regen_tick

	emit_stamina()

# -- Public API ---------------------------------------------------------------

func can_spend(amount: int) -> bool:
	return amount <= current_stamina

func spend(amount: int) -> bool:
	# returns true if stamina was spent; false if insufficient
	if amount <= 0:
		return true
	if amount > current_stamina:
		return false

	current_stamina -= amount
	emit_signal("stamina_spent", amount)
	emit_stamina()

	# start delay; add extra cooldown if fully depleted
	if current_stamina == 0:
		_start_regen_delay(regen_delay + exhaust_cooldown)
		emit_signal("stamina_depleted")
	else:
		_start_regen_delay(regen_delay)

	return true

func recover(amount: int) -> void:
	if amount <= 0:
		return
	var prev := current_stamina
	current_stamina = min(max_stamina, current_stamina + amount)
	if current_stamina != prev:
		emit_stamina()
		if current_stamina == max_stamina:
			emit_signal("stamina_full")

func set_max_stamina(new_max: int, keep_ratio: bool = true) -> void:
	new_max = max(1, new_max)
	if keep_ratio:
		var ratio := 0.0
		if max_stamina > 0:
			ratio = float(current_stamina) / float(max_stamina)
		max_stamina = new_max
		current_stamina = clamp(int(round(ratio * max_stamina)), 0, max_stamina)
	else:
		max_stamina = new_max
		current_stamina = clamp(current_stamina, 0, max_stamina)
	emit_stamina()

func get_current_stamina() -> int:
	return current_stamina

func get_max_stamina() -> int:
	return max_stamina

# -- Internal -----------------------------------------------------------------

func _on_regen_tick() -> void:
	# if delay is active, skip regen this tick
	if _delay_timer.time_left > 0.0:
		return

	if current_stamina >= max_stamina or regen_per_second <= 0.0:
		return

	var add_amount := int(round(regen_per_second * _regen_timer.wait_time))
	# ensure at least 1 per tick if regen is positive but very small
	if add_amount <= 0 and regen_per_second > 0.0:
		add_amount = 1

	var prev := current_stamina
	current_stamina = min(max_stamina, current_stamina + add_amount)

	if current_stamina != prev:
		emit_stamina()
		if current_stamina == max_stamina:
			emit_signal("stamina_full")

func _start_regen_delay(seconds: float) -> void:
	_delay_timer.stop()
	_delay_timer.start(max(0.0, seconds))

func emit_stamina() -> void:
	emit_signal("stamina_changed", current_stamina, max_stamina)
