extends RefCounted

const EVALUATE_INTERVAL := 6.0
const MAX_THREAT_RADIUS := 12.0
const CLOSE_THREAT_RADIUS := 6.0
const MID_THREAT_RADIUS := 10.0

var _evaluation_timer := 0.0
var _active_assignments: Dictionary = {}
var _last_threat_signature := ""


func update(delta: float, leader_id: int, wanderers: Dictionary, worms: Dictionary, settlement_center: Vector2i) -> void:
	_evaluation_timer -= delta
	if _evaluation_timer > 0.0:
		return

	_evaluation_timer = EVALUATE_INTERVAL
	if leader_id == -1:
		_clear_current_orders(wanderers)
		return

	var threats := _collect_threats(worms, settlement_center)
	if threats.is_empty():
		_clear_current_orders(wanderers)
		return

	var threat_signature := _build_threat_signature(threats)
	if threat_signature == _last_threat_signature and not _active_assignments.is_empty():
		return

	var defender_pool := _collect_defender_pool(wanderers, leader_id, settlement_center)
	if defender_pool.is_empty():
		_clear_current_orders(wanderers)
		return

	var total_threat := 0.0
	for threat in threats:
		total_threat += float(threat.get("score", 1.0))

	var squad_size := clampi(maxi(1, int(ceil(total_threat * 0.3))), 1, mini(defender_pool.size(), 2))
	var assignments := _build_assignments(defender_pool, threats, squad_size)
	_apply_orders(wanderers, assignments)
	_last_threat_signature = threat_signature


func _collect_threats(worms: Dictionary, settlement_center: Vector2i) -> Array:
	var threats: Array = []
	for worm_id in worms.keys():
		var worm = worms[worm_id]
		if not is_instance_valid(worm) or not bool(worm.call("is_combat_alive")):
			continue

		var worm_cell: Vector2i = worm.call("get_current_cell")
		var distance := settlement_center.distance_to(worm_cell)
		if distance > MAX_THREAT_RADIUS:
			continue

		var score := 1.0
		if distance <= CLOSE_THREAT_RADIUS:
			score += 2.0
		elif distance <= MID_THREAT_RADIUS:
			score += 1.0
		score += float(worm.call("get_current_hp")) / 12.0

		threats.append({
			"id": int(worm_id),
			"cell": worm_cell,
			"distance": distance,
			"score": score,
		})

	threats.sort_custom(func(a, b): return float(a.get("score", 0.0)) > float(b.get("score", 0.0)))
	return threats


func _build_threat_signature(threats: Array) -> String:
	var parts: Array[String] = []
	for threat in threats:
		var cell: Vector2i = threat.get("cell", Vector2i.ZERO)
		parts.append("%d:%d:%d" % [int(threat.get("id", -1)), cell.x, cell.y])
	return "|".join(parts)


func _collect_defender_pool(wanderers: Dictionary, leader_id: int, settlement_center: Vector2i) -> Array:
	var pool: Array = []
	var reserve_leader: Dictionary = {}

	for npc_id in wanderers.keys():
		var wanderer = wanderers[npc_id]
		if not is_instance_valid(wanderer) or not bool(wanderer.call("is_combat_alive")):
			continue

		var metrics: Dictionary = wanderer.call("get_role_snapshot", true, true)
		var hp := float(metrics.get("hp", 25.0))
		var max_hp := maxf(float(metrics.get("max_hp", 25.0)), 1.0)
		var hunger := float(metrics.get("hunger", 100.0))
		var thirst := float(metrics.get("thirst", 100.0))
		if hp / max_hp < 0.55:
			continue
		if hunger < 48.0 or thirst < 52.0:
			continue

		var cell: Vector2i = wanderer.call("get_current_cell")
		var readiness := hunger * 0.32 + thirst * 0.32 + (hp / max_hp) * 100.0 * 0.36 - settlement_center.distance_to(cell) * 0.18
		var entry := {
			"id": int(npc_id),
			"cell": cell,
			"readiness": readiness,
		}

		if int(npc_id) == leader_id:
			reserve_leader = entry
			continue

		pool.append(entry)

	pool.sort_custom(func(a, b): return float(a.get("readiness", 0.0)) > float(b.get("readiness", 0.0)))
	if pool.size() < 2 and not reserve_leader.is_empty():
		pool.append(reserve_leader)
	return pool


func _build_assignments(defender_pool: Array, threats: Array, squad_size: int) -> Dictionary:
	var assignments: Dictionary = {}
	var assigned_per_threat: Dictionary = {}

	for defender_index in range(mini(squad_size, defender_pool.size())):
		var defender: Dictionary = defender_pool[defender_index]
		var defender_cell: Vector2i = defender.get("cell", Vector2i.ZERO)
		var best_threat_id := -1
		var best_score := INF

		for threat in threats:
			var threat_id := int(threat.get("id", -1))
			var threat_cell: Vector2i = threat.get("cell", Vector2i.ZERO)
			var assigned_count := int(assigned_per_threat.get(threat_id, 0))
			var score := defender_cell.distance_squared_to(threat_cell) + float(assigned_count) * 36.0 - float(threat.get("score", 1.0)) * 14.0
			if score < best_score:
				best_score = score
				best_threat_id = threat_id

		if best_threat_id == -1:
			continue

		assignments[int(defender.get("id", -1))] = best_threat_id
		assigned_per_threat[best_threat_id] = int(assigned_per_threat.get(best_threat_id, 0)) + 1

	return assignments


func _apply_orders(wanderers: Dictionary, assignments: Dictionary) -> void:
	for npc_id in _active_assignments.keys():
		if assignments.has(npc_id):
			continue
		if wanderers.has(npc_id) and is_instance_valid(wanderers[npc_id]):
			wanderers[npc_id].call("clear_defense_target")

	for npc_id in assignments.keys():
		var target_worm_id := int(assignments[npc_id])
		if int(_active_assignments.get(npc_id, -1)) == target_worm_id:
			continue
		if wanderers.has(npc_id) and is_instance_valid(wanderers[npc_id]):
			wanderers[npc_id].call("assign_defense_target", target_worm_id)

	_active_assignments = assignments


func _clear_current_orders(wanderers: Dictionary) -> void:
	for npc_id in _active_assignments.keys():
		if wanderers.has(npc_id) and is_instance_valid(wanderers[npc_id]):
			wanderers[npc_id].call("clear_defense_target")
	_active_assignments.clear()
	_last_threat_signature = ""
