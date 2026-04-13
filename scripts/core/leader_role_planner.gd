class_name LeaderRolePlanner
extends RefCounted

var _thread: Thread
var _result_ready := false
var _result_mutex := Mutex.new()


func request_plan(payload: Dictionary) -> bool:
	if _thread != null and _thread.is_started():
		return false
	_result_mutex.lock()
	_result_ready = false
	_result_mutex.unlock()
	_thread = Thread.new()
	return _thread.start(Callable(self, "_compute_plan").bind(payload)) == OK


func has_result() -> bool:
	_result_mutex.lock()
	var ready := _result_ready
	_result_mutex.unlock()
	return ready


func consume_result() -> Dictionary:
	if _thread == null or not _thread.is_started():
		return {}
	if not has_result():
		return {}
	var result = _thread.wait_to_finish()
	_thread = null
	_result_mutex.lock()
	_result_ready = false
	_result_mutex.unlock()
	return result if result is Dictionary else {}


func shutdown() -> void:
	if _thread != null and _thread.is_started():
		_thread.wait_to_finish()
	_thread = null
	_result_mutex.lock()
	_result_ready = false
	_result_mutex.unlock()


func _compute_plan(payload: Dictionary) -> Dictionary:
	var leader_id := int(payload.get("leader_id", -1))
	var revision := int(payload.get("revision", 0))
	var npc_count := int(payload.get("npc_count", 0))
	var free_workers := maxi(npc_count - 1, 0)
	var total_food := int(payload.get("total_food", 0))
	var total_wood := int(payload.get("total_wood", 0))
	var total_stone := int(payload.get("total_stone", 0))
	var total_berries := int(payload.get("total_berries", 0))
	var homeless_count := int(payload.get("homeless_count", 0))
	var crate_less_count := int(payload.get("crate_less_count", 0))
	var hungry_count := int(payload.get("hungry_count", 0))
	var thirsty_count := int(payload.get("thirsty_count", 0))
	var injured_count := int(payload.get("injured_count", 0))
	var has_farm_barn := bool(payload.get("has_farm_barn", false))
	var farm_barn_count := int(payload.get("farm_barn_count", 0))
	var warehouse_count := int(payload.get("warehouse_count", 0))
	var warehouse_level := int(payload.get("warehouse_level", 0))
	var berry_seed_cost := int(payload.get("berry_seed_cost", 0))
	var candidates: Array = (payload.get("candidates", []) as Array).duplicate(true)
	var desired_roles: Dictionary = {leader_id: "leader"}

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("readiness", 0.0)) > float(b.get("readiness", 0.0))
	)

	for candidate in candidates:
		if _should_focus_on_survival(candidate):
			desired_roles[int(candidate.get("id", -1))] = "citizen"

	free_workers = maxi(candidates.size() - _count_desired_role(desired_roles, "citizen"), 0)
	var structure_pressure := 0
	if homeless_count > 0 or crate_less_count > 0:
		structure_pressure += 1
	if farm_barn_count < 2 or warehouse_count < 2 or warehouse_level < 2:
		structure_pressure += 1

	var food_pressure := 0
	if total_food < npc_count * 4:
		food_pressure += 2
	elif total_food < npc_count * 7:
		food_pressure += 1
	if hungry_count > maxi(1, int(floor(float(npc_count) * 0.3))):
		food_pressure += 1

	var water_pressure := 1 if thirsty_count > maxi(1, int(floor(float(npc_count) * 0.35))) else 0
	var wood_pressure := 1 if total_wood < (npc_count * 4) + 10 else 0
	var stone_pressure := 1 if total_stone < (npc_count * 3) + 8 else 0
	var injury_pressure := 1 if injured_count > maxi(1, int(floor(float(npc_count) * 0.25))) else 0

	var min_farmer_count := mini(2, free_workers)
	if not has_farm_barn and total_berries < berry_seed_cost:
		min_farmer_count = mini(1, free_workers)
	var min_lumberjack_count := mini(2, maxi(free_workers - min_farmer_count, 0))

	_assign_role_from_candidates(candidates, desired_roles, "builder", mini(structure_pressure, candidates.size()))
	_assign_role_from_candidates(candidates, desired_roles, "farmer", min_farmer_count + food_pressure)
	_assign_role_from_candidates(candidates, desired_roles, "lumberjack", min_lumberjack_count + wood_pressure)
	_assign_role_from_candidates(candidates, desired_roles, "fisher", maxi(1, food_pressure + water_pressure))
	_assign_role_from_candidates(candidates, desired_roles, "miner", stone_pressure + (1 if structure_pressure > 0 else 0))
	if injury_pressure > 0:
		_assign_role_from_candidates(candidates, desired_roles, "citizen", injury_pressure)

	for candidate in candidates:
		var candidate_id := int(candidate.get("id", -1))
		if desired_roles.has(candidate_id):
			continue
		if total_food < npc_count * 5:
			desired_roles[candidate_id] = "fisher"
		elif total_wood < total_stone:
			desired_roles[candidate_id] = "lumberjack"
		elif structure_pressure > 0:
			desired_roles[candidate_id] = "builder"
		else:
			desired_roles[candidate_id] = "citizen"

	_result_mutex.lock()
	_result_ready = true
	_result_mutex.unlock()
	return {
		"leader_id": leader_id,
		"revision": revision,
		"desired_roles": desired_roles,
	}


func _assign_role_from_candidates(candidates: Array, desired_roles: Dictionary, role_name: String, count: int) -> void:
	var remaining := maxi(count, 0)
	if remaining <= 0:
		return

	for candidate in candidates:
		if remaining <= 0:
			return
		var candidate_id := int(candidate.get("id", -1))
		if desired_roles.has(candidate_id):
			continue
		desired_roles[candidate_id] = role_name
		remaining -= 1


func _should_focus_on_survival(candidate: Dictionary) -> bool:
	if float(candidate.get("hunger", 100.0)) < 38.0:
		return true
	if float(candidate.get("thirst", 100.0)) < 42.0:
		return true
	if float(candidate.get("hp", 25.0)) <= float(candidate.get("max_hp", 25.0)) * 0.45:
		return true
	return false


func _count_desired_role(desired_roles: Dictionary, role_name: String) -> int:
	var count := 0
	for value in desired_roles.values():
		if str(value) == role_name:
			count += 1
	return count
