class_name NavigationService
extends RefCounted

var _path_cache: Dictionary = {}
var _path_cache_order: Array[String] = []


func clear_cache() -> void:
	_path_cache.clear()
	_path_cache_order.clear()


func find_worm_next_step(world, start_cell: Vector2i, target_cell: Vector2i, worm_id: int = -1) -> Vector2i:
	if start_cell == target_cell:
		return start_cell
	if not world._is_inside(target_cell.x, target_cell.y):
		return world.INVALID_CELL

	var direct_step := _find_direct_step_toward(world, start_cell, target_cell, false, worm_id)
	if direct_step != world.INVALID_CELL:
		return direct_step

	var cache_key := "worm|%d|%d|%d|%d|%d" % [start_cell.x, start_cell.y, target_cell.x, target_cell.y, worm_id]
	if _path_cache.has(cache_key):
		var cached_step: Vector2i = _path_cache[cache_key]
		if cached_step == world.INVALID_CELL or world._can_worm_enter(cached_step, worm_id):
			return cached_step
		_path_cache.erase(cache_key)

	var frontier: Array[Vector2i] = [start_cell]
	var came_from: Dictionary = {start_cell: world.INVALID_CELL}
	var head := 0

	while head < frontier.size():
		var current: Vector2i = frontier[head]
		head += 1

		for direction in world.CARDINAL_DIRS:
			var next_cell: Vector2i = current + direction
			if came_from.has(next_cell):
				continue
			if not world._can_worm_enter(next_cell, worm_id):
				continue

			came_from[next_cell] = current
			if next_cell == target_cell:
				var path := _reconstruct_path(world, came_from, start_cell, target_cell)
				if path.size() >= 2:
					_store_worm_path_cache(path, target_cell, worm_id)
					return path[1]
				_store_cache(cache_key, world.INVALID_CELL)
				return world.INVALID_CELL

			frontier.append(next_cell)

	_store_cache(cache_key, world.INVALID_CELL)
	return world.INVALID_CELL


func find_npc_next_step(world, start_cell: Vector2i, target_cell: Vector2i, allow_tree_target: bool) -> Vector2i:
	if start_cell == target_cell:
		return start_cell
	if not world._is_inside(target_cell.x, target_cell.y):
		return world.INVALID_CELL

	var direct_step := _find_direct_step_toward(world, start_cell, target_cell, allow_tree_target)
	if direct_step != world.INVALID_CELL:
		return direct_step

	var cache_key := "npc|%d|%d|%d|%d|%d" % [start_cell.x, start_cell.y, target_cell.x, target_cell.y, int(allow_tree_target)]
	if _path_cache.has(cache_key):
		var cached_step: Vector2i = _path_cache[cache_key]
		if cached_step == world.INVALID_CELL or world._can_npc_enter(cached_step, target_cell, allow_tree_target):
			return cached_step
		_path_cache.erase(cache_key)

	var frontier: Array[Vector2i] = [start_cell]
	var came_from: Dictionary = {start_cell: world.INVALID_CELL}
	var head := 0

	while head < frontier.size():
		var current: Vector2i = frontier[head]
		head += 1

		for direction in world.CARDINAL_DIRS:
			var next_cell: Vector2i = current + direction
			if came_from.has(next_cell):
				continue
			if not world._can_npc_enter(next_cell, target_cell, allow_tree_target):
				continue

			came_from[next_cell] = current
			if next_cell == target_cell:
				var path := _reconstruct_path(world, came_from, start_cell, target_cell)
				if path.size() >= 2:
					_store_npc_path_cache(path, target_cell, allow_tree_target)
					return path[1]
				_store_cache(cache_key, world.INVALID_CELL)
				return world.INVALID_CELL

			frontier.append(next_cell)

	_store_cache(cache_key, world.INVALID_CELL)
	return world.INVALID_CELL


func _find_direct_step_toward(world, start_cell: Vector2i, target_cell: Vector2i, allow_tree_target: bool, worm_id: int = -1) -> Vector2i:
	var delta := target_cell - start_cell
	var candidates: Array[Vector2i] = []
	if abs(delta.x) >= abs(delta.y):
		if delta.x != 0:
			candidates.append(start_cell + Vector2i(sign(delta.x), 0))
		if delta.y != 0:
			candidates.append(start_cell + Vector2i(0, sign(delta.y)))
	else:
		if delta.y != 0:
			candidates.append(start_cell + Vector2i(0, sign(delta.y)))
		if delta.x != 0:
			candidates.append(start_cell + Vector2i(sign(delta.x), 0))

	for candidate in candidates:
		if worm_id != -1:
			if world._can_worm_enter(candidate, worm_id):
				return candidate
		elif world._can_npc_enter(candidate, target_cell, allow_tree_target):
			return candidate

	return world.INVALID_CELL


func _reconstruct_path(world, came_from: Dictionary, start_cell: Vector2i, target_cell: Vector2i) -> Array[Vector2i]:
	var reversed_path: Array[Vector2i] = [target_cell]
	var current: Vector2i = target_cell

	while current != start_cell:
		current = came_from.get(current, world.INVALID_CELL)
		if current == world.INVALID_CELL:
			return []
		reversed_path.append(current)

	reversed_path.reverse()
	return reversed_path


func _store_npc_path_cache(path: Array[Vector2i], target_cell: Vector2i, allow_tree_target: bool) -> void:
	for index in range(path.size() - 1):
		var start_cell: Vector2i = path[index]
		var next_cell: Vector2i = path[index + 1]
		var cache_key := "npc|%d|%d|%d|%d|%d" % [start_cell.x, start_cell.y, target_cell.x, target_cell.y, int(allow_tree_target)]
		_store_cache(cache_key, next_cell)


func _store_worm_path_cache(path: Array[Vector2i], target_cell: Vector2i, worm_id: int) -> void:
	for index in range(path.size() - 1):
		var start_cell: Vector2i = path[index]
		var next_cell: Vector2i = path[index + 1]
		var cache_key := "worm|%d|%d|%d|%d|%d" % [start_cell.x, start_cell.y, target_cell.x, target_cell.y, worm_id]
		_store_cache(cache_key, next_cell)


func _store_cache(key: String, step: Vector2i) -> void:
	if _path_cache.has(key):
		_path_cache[key] = step
		return
	_path_cache[key] = step
	_path_cache_order.append(key)
	if _path_cache_order.size() <= 20000:
		return
	var stale_key: String = _path_cache_order.pop_front()
	_path_cache.erase(stale_key)
