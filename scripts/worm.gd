extends Node2D

const INVALID_CELL := Vector2i(-1, -1)
const TILE_SIZE := 64.0
const BASE_MOVE_SPEED := 96.0
const MAX_HP := 20
const ATTACK_DAMAGE := 2

var world
var worm_id := 0
var current_cell := INVALID_CELL
var target_cell := INVALID_CELL
var step_target_cell := INVALID_CELL
var sprite: AnimatedSprite2D

var _rng := RandomNumberGenerator.new()
var _moving := false
var _idle_timer := 0.0
var _in_combat := false
var _current_hp := MAX_HP
var _hurt_timer := 0.0


func setup(start_cell: Vector2i, world_ref, seed_value: int, unit_id: int) -> void:
	world = world_ref
	worm_id = unit_id
	current_cell = start_cell
	target_cell = start_cell
	position = _cell_to_position(start_cell)
	_rng.seed = int(seed_value) + unit_id * 14341
	_idle_timer = _rng.randf_range(0.3, 1.0)
	sprite = get_child(0) as AnimatedSprite2D
	_current_hp = MAX_HP
	if sprite != null:
		sprite.play("walk")
		sprite.pause()


func _process(delta: float) -> void:
	if world == null:
		return

	if _hurt_timer > 0.0:
		_hurt_timer = maxf(0.0, _hurt_timer - delta)
		if _hurt_timer <= 0.0:
			_refresh_animation()

	if _in_combat:
		return

	if _moving:
		_update_movement(delta)
		return

	_idle_timer -= delta
	if _idle_timer > 0.0:
		return

	if target_cell == INVALID_CELL or target_cell == current_cell:
		_choose_next_target()
		if target_cell == INVALID_CELL:
			_idle_timer = _rng.randf_range(0.25, 0.8)
			return

	var next_cell: Vector2i = world.call("find_worm_next_step", current_cell, target_cell, worm_id)
	if next_cell == INVALID_CELL:
		target_cell = INVALID_CELL
		_idle_timer = _rng.randf_range(0.25, 0.8)
		return

	_start_move_to(next_cell)


func set_in_combat(value: bool) -> void:
	if _in_combat == value:
		return

	_in_combat = value
	if _in_combat:
		_moving = false
		target_cell = current_cell
		step_target_cell = INVALID_CELL
		position = _cell_to_position(current_cell)
		if sprite != null:
			sprite.play("walk")
			sprite.pause()
	else:
		_idle_timer = _rng.randf_range(0.15, 0.5)
		_refresh_animation()


func is_combat_alive() -> bool:
	return _current_hp > 0


func get_unit_id() -> int:
	return worm_id


func get_unit_team() -> String:
	return "worm"


func get_combat_cell() -> Vector2i:
	return current_cell


func get_current_cell() -> Vector2i:
	return current_cell


func get_current_hp() -> int:
	return _current_hp


func get_max_hp() -> int:
	return MAX_HP


func get_attack_damage() -> int:
	return ATTACK_DAMAGE


func receive_combat_damage(amount: int, _attacker_team: String = "", _attacker_id: int = -1) -> void:
	if amount <= 0 or _current_hp <= 0:
		return

	_current_hp = maxi(_current_hp - amount, 0)
	_play_hurt()
	if _current_hp <= 0:
		_die()


func _choose_next_target() -> void:
	for radius in [2, 4, 6]:
		for _attempt in range(14):
			var candidate := Vector2i(
				current_cell.x + _rng.randi_range(-radius, radius),
				current_cell.y + _rng.randi_range(-radius, radius)
			)
			if candidate == current_cell:
				continue
			if not bool(world.call("is_cell_walkable_for_worm", candidate, worm_id)):
				continue
			target_cell = candidate
			return

	target_cell = INVALID_CELL


func _start_move_to(next_cell: Vector2i) -> void:
	step_target_cell = next_cell
	_moving = true
	if sprite != null:
		sprite.play("walk")
		sprite.flip_h = step_target_cell.x < current_cell.x


func _update_movement(delta: float) -> void:
	var target_position := _cell_to_position(step_target_cell)
	position = position.move_toward(target_position, BASE_MOVE_SPEED * delta)
	if position.distance_to(target_position) > 1.0:
		return

	position = target_position
	var previous_cell := current_cell
	current_cell = step_target_cell
	world.call("update_worm_cell", worm_id, previous_cell, current_cell)
	_moving = false
	if current_cell == target_cell:
		target_cell = INVALID_CELL
		_idle_timer = _rng.randf_range(0.2, 0.7)
		if sprite != null:
			sprite.pause()
	else:
		_idle_timer = 0.0


func _play_hurt() -> void:
	_hurt_timer = 0.28
	if sprite == null:
		return
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")
	else:
		sprite.play("walk")
		sprite.pause()


func _refresh_animation() -> void:
	if sprite == null:
		return
	if _moving:
		sprite.play("walk")
		return
	sprite.play("walk")
	sprite.pause()


func _die() -> void:
	if world != null:
		world.call("unregister_worm_cell", worm_id)
		world.call("handle_worm_death", worm_id, current_cell)
	queue_free()


func _cell_to_position(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * TILE_SIZE, (cell.y + 0.5) * TILE_SIZE)
