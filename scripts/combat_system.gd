extends RefCounted

const TURN_INTERVAL := 0.7
const NEIGHBOR_DIRS := [
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
	Vector2i(1, 1),
]

var _engagements: Dictionary = {}
var _engaged_villagers: Dictionary = {}
var _engaged_worms: Dictionary = {}


func update(delta: float, villagers: Dictionary, worms: Dictionary, entity_index) -> void:
	if entity_index == null:
		return

	var adjacent_villagers_by_worm: Dictionary = {}
	var villager_engaged: Dictionary = {}
	var worm_engaged: Dictionary = {}

	for worm_id in worms.keys():
		var worm = worms[worm_id]
		if not is_instance_valid(worm) or not bool(worm.call("is_combat_alive")):
			continue

		var worm_cell: Vector2i = worm.call("get_combat_cell")
		var adjacent_villagers: Array = []
		for direction in NEIGHBOR_DIRS:
			var villager_id := int(entity_index.get_npc_id_on_cell(worm_cell + direction))
			if villager_id == -1 or not villagers.has(villager_id):
				continue
			var villager = villagers[villager_id]
			if not is_instance_valid(villager) or not bool(villager.call("is_combat_alive")):
				continue
			adjacent_villagers.append(villager)
			villager_engaged[villager_id] = true

		if adjacent_villagers.is_empty():
			continue

		adjacent_villagers.sort_custom(func(a, b): return int(a.call("get_unit_id")) < int(b.call("get_unit_id")))
		adjacent_villagers_by_worm[int(worm_id)] = {
			"worm": worm,
			"villagers": adjacent_villagers,
		}
		worm_engaged[int(worm_id)] = true

	_apply_engagement_state(villagers, worms, villager_engaged, worm_engaged)

	var stale_engagements: Array = []
	for worm_id in _engagements.keys():
		if not adjacent_villagers_by_worm.has(worm_id):
			stale_engagements.append(worm_id)
	for worm_id in stale_engagements:
		_engagements.erase(worm_id)

	for worm_id in adjacent_villagers_by_worm.keys():
		var combatants: Dictionary = adjacent_villagers_by_worm[worm_id]
		var engagement: Dictionary = _engagements.get(worm_id, {
			"turn_timer": TURN_INTERVAL,
			"turn_index": 0,
		})

		engagement["turn_timer"] = float(engagement.get("turn_timer", TURN_INTERVAL)) - delta
		if float(engagement["turn_timer"]) > 0.0:
			_engagements[worm_id] = engagement
			continue

		var worm = combatants.get("worm", null)
		var villagers_in_fight: Array = combatants.get("villagers", [])
		var turn_order := _build_turn_order(villagers_in_fight, worm)
		if turn_order.is_empty():
			_engagements.erase(worm_id)
			continue

		var turn_index := posmod(int(engagement.get("turn_index", 0)), turn_order.size())
		var actor: Dictionary = turn_order[turn_index]
		_perform_attack(actor, worm, villagers_in_fight)

		engagement["turn_timer"] = TURN_INTERVAL
		engagement["turn_index"] = (turn_index + 1) % turn_order.size()
		_engagements[worm_id] = engagement


func _apply_engagement_state(villagers: Dictionary, worms: Dictionary, villager_engaged: Dictionary, worm_engaged: Dictionary) -> void:
	for villager_id in _engaged_villagers.keys():
		if villager_engaged.has(villager_id):
			continue
		if villagers.has(villager_id) and is_instance_valid(villagers[villager_id]):
			villagers[villager_id].call("set_in_combat", false)
	for villager_id in villager_engaged.keys():
		if _engaged_villagers.has(villager_id):
			continue
		if villagers.has(villager_id) and is_instance_valid(villagers[villager_id]):
			villagers[villager_id].call("set_in_combat", true)

	for worm_id in _engaged_worms.keys():
		if worm_engaged.has(worm_id):
			continue
		if worms.has(worm_id) and is_instance_valid(worms[worm_id]):
			worms[worm_id].call("set_in_combat", false)
	for worm_id in worm_engaged.keys():
		if _engaged_worms.has(worm_id):
			continue
		if worms.has(worm_id) and is_instance_valid(worms[worm_id]):
			worms[worm_id].call("set_in_combat", true)

	_engaged_villagers = villager_engaged
	_engaged_worms = worm_engaged


func _build_turn_order(villagers: Array, worm) -> Array:
	var turn_order: Array = []
	if not is_instance_valid(worm) or not bool(worm.call("is_combat_alive")):
		return turn_order

	for villager in villagers:
		if not is_instance_valid(villager) or not bool(villager.call("is_combat_alive")):
			continue
		turn_order.append({
			"team": "villager",
			"unit": villager,
		})
		turn_order.append({
			"team": "worm",
			"unit": worm,
		})

	return turn_order


func _perform_attack(actor: Dictionary, worm, villagers: Array) -> void:
	var team := str(actor.get("team", ""))
	var unit = actor.get("unit", null)
	if not is_instance_valid(unit):
		return

	if team == "villager":
		if not is_instance_valid(worm) or not bool(worm.call("is_combat_alive")):
			return
		worm.call("receive_combat_damage", int(unit.call("get_attack_damage")), "villager", int(unit.call("get_unit_id")))
		return

	var target = _pick_worm_target(villagers)
	if target == null:
		return
	target.call("receive_combat_damage", int(unit.call("get_attack_damage")), "worm", int(unit.call("get_unit_id")))


func _pick_worm_target(villagers: Array):
	var best_target = null
	var lowest_hp := INF
	for villager in villagers:
		if not is_instance_valid(villager) or not bool(villager.call("is_combat_alive")):
			continue
		var hp := float(villager.call("get_current_hp"))
		if hp < lowest_hp:
			lowest_hp = hp
			best_target = villager
	return best_target
