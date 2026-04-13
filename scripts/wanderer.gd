extends Node2D

enum WandererState {
	DECIDE,
	WALK_TO_TREE,
	CHOP_TREE,
	WALK_TO_ROCK,
	MINE_ROCK,
	WALK_TO_BUILD_HOME,
	BUILD_HOME,
	WALK_TO_OCCUPY_HOME,
	OCCUPY_HOME,
	WALK_TO_BUILD_CRATE,
	BUILD_CRATE,
	WALK_TO_BUILD_FARM,
	BUILD_FARM,
	WALK_TO_BUILD_WAREHOUSE,
	BUILD_WAREHOUSE,
	WALK_TO_UPGRADE_WAREHOUSE,
	UPGRADE_WAREHOUSE,
	WALK_TO_UPGRADE_HOME,
	UPGRADE_HOME,
	WALK_TO_UPGRADE_CRATE,
	UPGRADE_CRATE,
	WALK_TO_HARVEST_FOOD,
	HARVEST_FOOD,
	WALK_TO_FARM_PLOT,
	TILL_SOIL,
	WALK_TO_SOW_BERRIES,
	SOW_BERRIES,
	WALK_TO_FISH,
	FISH,
	WALK_TO_EAT,
	EAT,
	WALK_TO_DRINK,
	DRINK,
	WALK_TO_LOOT_BAG,
	LOOT_BAG,
	WALK_TO_BARN_SUPPLY,
	BARN_SUPPLY,
	WALK_TO_DEFEND,
	ROAM_HOME,
	DEAD,
}

const INVALID_CELL := Vector2i(-1, -1)
const TILE_SIZE := 64.0
const NEED_MAX := 100.0
const FOOD_RESERVE_TARGET := 3
const HUNGER_LOW_THRESHOLD := 58.0
const HUNGER_CRITICAL_THRESHOLD := 30.0
const THIRST_LOW_THRESHOLD := 52.0
const THIRST_CRITICAL_THRESHOLD := 24.0
const HUNGER_STOCKPILE_EAT_THRESHOLD := 44.0
const REPRODUCTION_HUNGER_THRESHOLD := 64.0
const REPRODUCTION_THIRST_THRESHOLD := 72.0
const REPRODUCTION_COOLDOWN_DURATION := 70.0
const STARVATION_DEATH_DAYS := 3.0
const DEHYDRATION_DEATH_DAYS := 2.0
const BASIC_HOME_WOOD_COST := 4
const BASIC_CRATE_WOOD_COST := 2
const HOUSE_UPGRADE_WOOD_COST := 2
const HOUSE_UPGRADE_STONE_COST := 3
const CRATE_UPGRADE_WOOD_COST := 1
const CRATE_UPGRADE_STONE_COST := 1
const FOOD_GATHER_AMOUNT := 4
const CANTEEN_CAPACITY := 2
const BASE_VILLAGER_HP := 25
const BASE_LEADER_HP := 50
const BASE_VILLAGER_DAMAGE := 2
const BASE_LEADER_DAMAGE := 4

@export var move_speed := 140.0
@export var idle_time_min := 0.12
@export var idle_time_max := 0.4
@export var chop_duration := 0.7
@export var mine_duration := 0.72
@export var build_duration := 1.0
@export var occupy_duration := 0.45
@export var harvest_food_duration := 0.85
@export var till_soil_duration := 1.0
@export var sow_duration := 0.75
@export var fish_duration := 1.2
@export var eat_duration := 0.8
@export var drink_duration := 0.6
@export var hunger_decay_per_second := 0.68
@export var thirst_decay_per_second := 1.05
@export var hunger_restore_amount := 42.0
@export var thirst_restore_amount := 62.0

var world
var npc_id := 0
var wood_count := 0
var stone_count := 0
var carried_food := 0
var canteen_water := 0
var hunger := NEED_MAX
var thirst := NEED_MAX
var age_days := 0.0
var lifespan_days := 0.0
var current_hp := BASE_VILLAGER_HP
var current_cell := INVALID_CELL
var spawn_cell := INVALID_CELL
var home_cell := INVALID_CELL
var crate_cell := INVALID_CELL
var fishing_cell := INVALID_CELL
var drink_cell := INVALID_CELL
var target_tree_cell := INVALID_CELL
var target_rock_cell := INVALID_CELL
var target_food_cell := INVALID_CELL
var farm_plot_cell := INVALID_CELL
var claimed_home_site := INVALID_CELL
var claimed_vacant_home_cell := INVALID_CELL
var claimed_crate_site := INVALID_CELL
var claimed_farm_barn_site := INVALID_CELL
var claimed_warehouse_site := INVALID_CELL
var upgrade_target_cell := INVALID_CELL
var target_cell := INVALID_CELL
var step_target_cell := INVALID_CELL
var reproduction_cooldown := 22.0
var starvation_days_at_zero := 0.0
var dehydration_days_at_zero := 0.0
var death_reason := ""
var assigned_role := "citizen"
var is_leader := false
var election_active := false
var election_rally_cell := INVALID_CELL
var loot_bag_cell := INVALID_CELL
var barn_supply_cell := INVALID_CELL
var barn_food_claimed := false
var travel_food_distance := 40.0
var stuck_timeout := 7.0
var old_age_factor := 0.78
var random_sapling_timer := 0.0
var defense_worm_id := -1

var _state := WandererState.DECIDE
var _moving := false
var _action_timer := 0.0
var _idle_timer := 0.0
var _rng := RandomNumberGenerator.new()
var _is_dead := false
var _in_combat := false
var _hurt_timer := 0.0
var _queued_target_cell := INVALID_CELL
var _queued_state := WandererState.DECIDE
var _queued_allow_tree_target := false
var _barn_supply_mode := ""
var _stuck_timer := 0.0
var _last_progress_cell := INVALID_CELL
var _last_progress_signature := ""
var _tree_query_cooldown := 0.0
var _rock_query_cooldown := 0.0
var _food_query_cooldown := 0.0
var _fishing_query_cooldown := 0.0
var _loot_query_cooldown := 0.0
var sprite: AnimatedSprite2D


func apply_balance_config(config: Dictionary) -> void:
	move_speed = float(config.get("move_speed", move_speed))
	hunger_decay_per_second = float(config.get("hunger_decay_per_second", hunger_decay_per_second))
	thirst_decay_per_second = float(config.get("thirst_decay_per_second", thirst_decay_per_second))
	hunger_restore_amount = float(config.get("hunger_restore_amount", hunger_restore_amount))
	thirst_restore_amount = float(config.get("thirst_restore_amount", thirst_restore_amount))
	travel_food_distance = float(config.get("travel_food_distance", travel_food_distance))
	stuck_timeout = float(config.get("stuck_timeout", stuck_timeout))
	old_age_factor = float(config.get("old_age_factor", old_age_factor))


func set_assigned_role(role_name: String) -> void:
	if assigned_role == role_name:
		return
	assigned_role = role_name
	if not _is_dead and not _in_combat:
		_release_claims_for_target()
		_force_rethink()


func set_leader_state(value: bool) -> void:
	var was_leader := is_leader
	is_leader = value
	if is_leader:
		assigned_role = "leader"
	if was_leader != is_leader:
		current_hp = mini(current_hp, _get_max_hp())
		if is_leader and current_hp < _get_max_hp():
			current_hp = _get_max_hp()


func set_election_state(active: bool, rally_cell: Vector2i) -> void:
	election_active = active
	election_rally_cell = rally_cell


func assign_defense_target(worm_id: int) -> void:
	if defense_worm_id == worm_id:
		return
	defense_worm_id = worm_id
	if not _is_dead and not _in_combat:
		_release_claims_for_target()
		_force_rethink()


func clear_defense_target() -> void:
	if defense_worm_id == -1:
		return
	defense_worm_id = -1
	if not _is_dead and not _in_combat and _state == WandererState.WALK_TO_DEFEND:
		_release_claims_for_target()
		_force_rethink()


func get_wealth_score() -> float:
	var home_bonus := 12.0 if home_cell != INVALID_CELL else 0.0
	var crate_bonus := 8.0 if crate_cell != INVALID_CELL else 0.0
	var crate_food := int(world.call("get_crate_food_amount", npc_id)) if world != null else 0
	return float(wood_count) * 1.4 + float(stone_count) * 1.8 + float(crate_food + carried_food) * 1.2 + home_bonus + crate_bonus + float(age_days) * 0.001


func setup(start_cell: Vector2i, world_ref, seed_value: int, npc_index: int, initial_age_years: float = -1.0) -> void:
	sprite = get_child(0) as AnimatedSprite2D
	world = world_ref
	npc_id = npc_index
	spawn_cell = start_cell
	current_cell = start_cell
	_last_progress_cell = start_cell
	position = _cell_to_position(start_cell)
	_rng.seed = int(seed_value) + npc_index * 9973
	hunger = _rng.randf_range(88.0, NEED_MAX)
	thirst = _rng.randf_range(84.0, NEED_MAX)
	canteen_water = CANTEEN_CAPACITY
	reproduction_cooldown = _rng.randf_range(16.0, 28.0)

	var days_in_year := maxf(float(world.call("get_days_in_year")), 360.0)
	var age_years := initial_age_years if initial_age_years >= 0.0 else _rng.randf_range(float(world.call("get_npc_initial_age_min")), float(world.call("get_npc_initial_age_max")))
	age_days = age_years * days_in_year
	lifespan_days = _rng.randf_range(float(world.call("get_npc_lifespan_min_years")), float(world.call("get_npc_lifespan_max_years"))) * days_in_year
	random_sapling_timer = float(world.call("get_day_duration_seconds")) / 3.0
	current_hp = _get_max_hp()
	_last_progress_signature = _build_progress_signature()

	_state = WandererState.DECIDE
	_idle_timer = _rng.randf_range(idle_time_min, idle_time_max)
	_play_walk()
	sprite.pause()


func _process(delta: float) -> void:
	if world == null or _is_dead:
		return

	_update_query_cooldowns(delta)
	_update_stuck_watchdog(delta)
	if _is_dead:
		return

	_update_life(delta)
	if _is_dead:
		return

	random_sapling_timer -= delta
	if assigned_role == "lumberjack" and random_sapling_timer <= 0.0:
		random_sapling_timer = float(world.call("get_day_duration_seconds")) / 3.0
		if _rng.randf() <= 0.15:
			world.call("try_plant_random_sapling_near", current_cell, 3)

	reproduction_cooldown = maxf(0.0, reproduction_cooldown - delta)

	if _hurt_timer > 0.0:
		_hurt_timer = maxf(0.0, _hurt_timer - delta)
		if _hurt_timer <= 0.0:
			_refresh_animation()

	if _in_combat:
		return

	if _moving:
		_update_movement(delta)
		return

	if _action_timer > 0.0:
		_action_timer -= delta
		if _action_timer <= 0.0:
			_finish_action()
		return

	_idle_timer -= delta
	if _idle_timer > 0.0:
		return

	match _state:
		WandererState.DECIDE:
			_decide_next_action()
		WandererState.WALK_TO_TREE:
			_move_towards_target(true)
		WandererState.WALK_TO_ROCK, WandererState.WALK_TO_BUILD_HOME, WandererState.WALK_TO_OCCUPY_HOME, WandererState.WALK_TO_BUILD_CRATE, WandererState.WALK_TO_BUILD_FARM, WandererState.WALK_TO_BUILD_WAREHOUSE, WandererState.WALK_TO_UPGRADE_WAREHOUSE, WandererState.WALK_TO_UPGRADE_HOME, WandererState.WALK_TO_UPGRADE_CRATE, WandererState.WALK_TO_HARVEST_FOOD, WandererState.WALK_TO_FARM_PLOT, WandererState.WALK_TO_SOW_BERRIES, WandererState.WALK_TO_FISH, WandererState.WALK_TO_EAT, WandererState.WALK_TO_DRINK, WandererState.WALK_TO_LOOT_BAG, WandererState.WALK_TO_BARN_SUPPLY, WandererState.WALK_TO_DEFEND, WandererState.ROAM_HOME:
			_move_towards_target(false)
		_:
			_state = WandererState.DECIDE


func _update_life(delta: float) -> void:
	hunger = maxf(0.0, hunger - hunger_decay_per_second * delta)
	thirst = maxf(0.0, thirst - thirst_decay_per_second * delta)
	var day_delta := delta * float(world.call("get_days_per_second"))
	age_days += day_delta

	if hunger <= 0.0:
		starvation_days_at_zero += day_delta
	else:
		starvation_days_at_zero = 0.0

	if thirst <= 0.0:
		dehydration_days_at_zero += day_delta
	else:
		dehydration_days_at_zero = 0.0

	if dehydration_days_at_zero >= DEHYDRATION_DEATH_DAYS:
		_die("умер от жажды")
		return
	if starvation_days_at_zero >= STARVATION_DEATH_DAYS:
		_die("умер от голода")
		return
	if age_days >= lifespan_days:
		_die("умер от старости")


func _update_stuck_watchdog(delta: float) -> void:
	var progress_signature := _build_progress_signature()
	if _moving:
		_stuck_timer = 0.0
		_last_progress_cell = current_cell
		_last_progress_signature = progress_signature
		return

	if current_cell != _last_progress_cell or progress_signature != _last_progress_signature:
		_last_progress_cell = current_cell
		_last_progress_signature = progress_signature
		_stuck_timer = 0.0
		return

	if _state == WandererState.DEAD:
		return
	if _state == WandererState.DECIDE and _idle_timer > 0.0:
		return

	_stuck_timer += delta
	if _stuck_timer < stuck_timeout:
		return

	_stuck_timer = 0.0
	_release_claims_for_target()
	_force_rethink()
	if canteen_water > 0 and thirst <= THIRST_LOW_THRESHOLD:
		_drink_from_canteen()
		return
	if thirst <= THIRST_LOW_THRESHOLD and _plan_drinking(_get_survival_anchor()):
		return
	if carried_food > 0 and hunger <= HUNGER_LOW_THRESHOLD:
		_eat_carried_food()
		return
	if hunger <= HUNGER_LOW_THRESHOLD:
		if _plan_eating():
			return
		if _plan_best_food_source():
			return
	_pick_local_idle_target()


func _force_rethink() -> void:
	_queued_target_cell = INVALID_CELL
	_queued_state = WandererState.DECIDE
	_queued_allow_tree_target = false
	_barn_supply_mode = ""
	step_target_cell = INVALID_CELL
	target_cell = INVALID_CELL
	upgrade_target_cell = INVALID_CELL
	_action_timer = 0.0
	_moving = false
	_state = WandererState.DECIDE
	_idle_timer = 0.0
	if sprite != null:
		sprite.pause()


func _update_query_cooldowns(delta: float) -> void:
	_tree_query_cooldown = maxf(0.0, _tree_query_cooldown - delta)
	_rock_query_cooldown = maxf(0.0, _rock_query_cooldown - delta)
	_food_query_cooldown = maxf(0.0, _food_query_cooldown - delta)
	_fishing_query_cooldown = maxf(0.0, _fishing_query_cooldown - delta)
	_loot_query_cooldown = maxf(0.0, _loot_query_cooldown - delta)


func _set_retry_pause(min_delay: float = 0.08, max_delay: float = 0.18) -> void:
	_state = WandererState.DECIDE
	_idle_timer = maxf(_idle_timer, _rng.randf_range(min_delay, max_delay))


func _build_progress_signature() -> String:
	return "%s|%d|%d|%d|%d|%s|%s" % [
		str(current_cell),
		wood_count,
		stone_count,
		carried_food,
		canteen_water,
		str(home_cell),
		str(crate_cell),
	]


func set_in_combat(value: bool) -> void:
	if _in_combat == value or _is_dead:
		return

	_in_combat = value
	if _in_combat:
		_release_claims_for_target()
		_action_timer = 0.0
		_moving = false
		step_target_cell = INVALID_CELL
		target_cell = INVALID_CELL
		position = _cell_to_position(current_cell)
		_state = WandererState.DECIDE
		_idle_timer = 0.0
		if sprite != null:
			sprite.play("walk")
			sprite.pause()
	else:
		_state = WandererState.DECIDE
		_idle_timer = 0.05
		_refresh_animation()


func receive_combat_damage(amount: int, attacker_team: String = "", _attacker_id: int = -1) -> void:
	if amount <= 0 or _is_dead:
		return

	current_hp = maxi(current_hp - amount, 0)
	_play_hurt()
	if current_hp <= 0:
		var reason := "Погиб в бою"
		if attacker_team == "worm":
			reason = "Убит гигантским червем"
		_die(reason)


func _die(reason: String) -> void:
	if _is_dead:
		return

	_is_dead = true
	death_reason = reason
	_state = WandererState.DEAD
	_release_claims_for_target()

	if sprite != null:
		sprite.stop()
		sprite.visible = false

	var body_cell := current_cell if current_cell != INVALID_CELL else spawn_cell
	world.call("unregister_npc_cell", npc_id)
	world.call("handle_npc_death", npc_id, body_cell, reason, age_days)
	queue_free()


func _decide_next_action() -> void:
	home_cell = world.call("get_home_cell", npc_id)
	crate_cell = world.call("get_crate_cell", npc_id)
	_sync_with_warehouse()

	var crate_food := int(world.call("get_crate_food_amount", npc_id))
	var barn_food := int(world.call("get_farm_barn_food_amount"))
	var crate_capacity := int(world.call("get_food_crate_capacity", npc_id))
	var reserve_target := mini(FOOD_RESERVE_TARGET, crate_capacity)
	var survival_anchor := _get_survival_anchor()
	var house_level := int(world.call("get_house_level", npc_id))
	var crate_level := int(world.call("get_crate_level", npc_id))

	if election_active and election_rally_cell != INVALID_CELL and _plan_election_rally():
		return

	if carried_food > 0 and hunger <= HUNGER_CRITICAL_THRESHOLD:
		_eat_carried_food()
		return

	if canteen_water > 0 and thirst <= THIRST_CRITICAL_THRESHOLD:
		_drink_from_canteen()
		return

	if thirst <= THIRST_CRITICAL_THRESHOLD and _plan_drinking(survival_anchor):
		return

	if crate_cell != INVALID_CELL and hunger <= HUNGER_CRITICAL_THRESHOLD and (crate_food > 0 or (bool(world.call("has_farm_barn")) and barn_food > 0)):
		if _plan_eating():
			return

	if _plan_defense_action():
		return

	if _plan_loot_bag():
		return

	if home_cell == INVALID_CELL:
		_pull_build_resources_from_warehouse(BASIC_HOME_WOOD_COST, 0)
		if _plan_vacant_house_claim():
			return
		if wood_count < BASIC_HOME_WOOD_COST:
			_plan_tree_gathering()
		else:
			_plan_house_build()
		return

	if crate_cell == INVALID_CELL:
		_pull_build_resources_from_warehouse(BASIC_CRATE_WOOD_COST, 0)
		if thirst <= THIRST_LOW_THRESHOLD:
			if canteen_water > 0:
				_drink_from_canteen()
				return
			if _plan_drinking(home_cell):
				return
		if wood_count < BASIC_CRATE_WOOD_COST:
			_plan_tree_gathering()
		else:
			_plan_crate_build()
		return

	if thirst <= THIRST_LOW_THRESHOLD:
		if canteen_water > 0:
			_drink_from_canteen()
			return
		if _plan_drinking(crate_cell):
			return

	if bool(world.call("has_farm_barn")) and crate_food < reserve_target and barn_food > 0 and _plan_barn_to_crate_restock():
		return

	if hunger <= HUNGER_LOW_THRESHOLD:
		if carried_food > 0:
			_eat_carried_food()
			return
		if (crate_food > 0 or barn_food > 0) and _plan_eating():
			return
		if _plan_best_food_source():
			return

	if assigned_role == "builder" and _plan_builder_work():
		return
	if assigned_role == "farmer" and _plan_farmer_work():
		return
	if assigned_role == "fisher" and _plan_fisher_work():
		return
	if assigned_role == "lumberjack" and _plan_tree_work():
		return
	if assigned_role == "miner" and _plan_miner_work():
		return

	if crate_food < reserve_target:
		if bool(world.call("has_farm_barn")) and barn_food > 0 and _plan_barn_to_crate_restock():
			return
		if _plan_best_food_source():
			return

	if crate_level < 2:
		_pull_build_resources_from_warehouse(CRATE_UPGRADE_WOOD_COST, CRATE_UPGRADE_STONE_COST)
		if wood_count >= CRATE_UPGRADE_WOOD_COST and stone_count >= CRATE_UPGRADE_STONE_COST and _plan_crate_upgrade():
			return
		if stone_count < CRATE_UPGRADE_STONE_COST and _plan_rock_gathering():
			return
		if wood_count < CRATE_UPGRADE_WOOD_COST:
			_plan_tree_gathering()
			return

	if house_level < 2:
		_pull_build_resources_from_warehouse(HOUSE_UPGRADE_WOOD_COST, HOUSE_UPGRADE_STONE_COST)
		if wood_count >= HOUSE_UPGRADE_WOOD_COST and stone_count >= HOUSE_UPGRADE_STONE_COST and _plan_house_upgrade():
			return
		if stone_count < HOUSE_UPGRADE_STONE_COST and _plan_rock_gathering():
			return
		if wood_count < HOUSE_UPGRADE_WOOD_COST:
			_plan_tree_gathering()
			return

	if crate_food < crate_capacity:
		if bool(world.call("has_farm_barn")) and barn_food > 0 and _plan_barn_to_crate_restock():
			return
		if hunger > HUNGER_STOCKPILE_EAT_THRESHOLD and _plan_best_food_source():
			return

	if int(world.call("get_crate_berry_stock", npc_id)) >= int(world.call("get_berry_seed_cost")):
		if _plan_berry_farming():
			return

	_pick_roam_target(crate_cell if crate_cell != INVALID_CELL else home_cell)


func _plan_warehouse_build() -> bool:
	if claimed_warehouse_site == INVALID_CELL:
		claimed_warehouse_site = world.call("claim_warehouse_site", home_cell if home_cell != INVALID_CELL else current_cell, npc_id)
	if claimed_warehouse_site == INVALID_CELL:
		return false

	target_cell = claimed_warehouse_site
	_state = WandererState.WALK_TO_BUILD_WAREHOUSE
	_move_towards_target(false)
	return true


func _plan_defense_action() -> bool:
	if defense_worm_id == -1:
		return false
	if hunger <= HUNGER_LOW_THRESHOLD or thirst <= THIRST_LOW_THRESHOLD:
		return false
	if current_hp < int(ceil(float(_get_max_hp()) * 0.45)):
		return false
	if not bool(world.call("worm_exists", defense_worm_id)):
		clear_defense_target()
		return false

	var access_cell: Vector2i = world.call("get_worm_access_cell", defense_worm_id, current_cell)
	if access_cell == INVALID_CELL:
		return false
	if access_cell == current_cell:
		_state = WandererState.DECIDE
		_idle_timer = 0.08
		return true

	target_cell = access_cell
	_state = WandererState.WALK_TO_DEFEND
	_move_towards_target(false)
	return true


func _plan_warehouse_upgrade() -> bool:
	var warehouse_cell: Vector2i = world.call("get_warehouse_upgrade_cell")
	if warehouse_cell == INVALID_CELL:
		return false
	var access_cell: Vector2i = world.call("get_specific_warehouse_access_cell", warehouse_cell, current_cell)
	if access_cell == INVALID_CELL:
		return false

	upgrade_target_cell = warehouse_cell
	target_cell = access_cell
	_state = WandererState.WALK_TO_UPGRADE_WAREHOUSE
	_move_towards_target(false)
	return true


func _sync_with_warehouse() -> void:
	if not bool(world.call("has_warehouse")):
		return

	if wood_count > 3:
		var stored_wood := int(world.call("store_wood_in_warehouse", wood_count - 3))
		wood_count = maxi(wood_count - stored_wood, 0)
	if stone_count > 3:
		var stored_stone := int(world.call("store_stone_in_warehouse", stone_count - 3))
		stone_count = maxi(stone_count - stored_stone, 0)


func _pull_build_resources_from_warehouse(wood_need: int, stone_need: int) -> void:
	if not bool(world.call("has_warehouse")):
		return
	if wood_count < wood_need:
		wood_count += int(world.call("take_wood_from_warehouse", wood_need - wood_count))
	if stone_count < stone_need:
		stone_count += int(world.call("take_stone_from_warehouse", stone_need - stone_count))


func _plan_tree_gathering() -> void:
	if target_tree_cell != INVALID_CELL and not bool(world.call("tree_exists", target_tree_cell)):
		target_tree_cell = INVALID_CELL

	if target_tree_cell == INVALID_CELL:
		if _tree_query_cooldown > 0.0:
			_set_retry_pause()
			return
		target_tree_cell = world.call("claim_nearest_tree", current_cell, npc_id)
		if target_tree_cell == INVALID_CELL:
			_tree_query_cooldown = _rng.randf_range(0.25, 0.55)

	if target_tree_cell == INVALID_CELL:
		_pick_local_idle_target()
		return

	target_cell = target_tree_cell
	_state = WandererState.WALK_TO_TREE
	_move_towards_target(true)


func _plan_loot_bag() -> bool:
	if loot_bag_cell != INVALID_CELL and not bool(world.call("loot_bag_exists", loot_bag_cell)):
		loot_bag_cell = INVALID_CELL

	if loot_bag_cell == INVALID_CELL:
		if _loot_query_cooldown > 0.0:
			return false
		loot_bag_cell = world.call("claim_nearest_loot_bag", current_cell, npc_id)
		if loot_bag_cell == INVALID_CELL:
			_loot_query_cooldown = _rng.randf_range(0.35, 0.70)

	if loot_bag_cell == INVALID_CELL:
		return false

	target_cell = loot_bag_cell
	_state = WandererState.WALK_TO_LOOT_BAG
	_move_towards_target(false)
	return true


func _plan_barn_to_crate_restock(force := false) -> bool:
	if not bool(world.call("has_farm_barn")):
		return false
	var barn_food := int(world.call("get_farm_barn_food_amount"))
	if barn_food <= 0:
		return false
	var crate_food := int(world.call("get_crate_food_amount", npc_id))
	if not force:
		if crate_food > 0 and barn_food < 2:
			return false
		if crate_food >= 2:
			return false
	if not barn_food_claimed:
		if not bool(world.call("claim_farm_barn_food", npc_id, 1)):
			return false
		barn_food_claimed = true

	var access_cell: Vector2i = world.call("get_farm_barn_access_cell", current_cell)
	if access_cell == INVALID_CELL:
		world.call("release_farm_barn_food_claim", npc_id)
		barn_food_claimed = false
		return false

	barn_supply_cell = access_cell
	_barn_supply_mode = "crate_food"
	target_cell = access_cell
	_state = WandererState.WALK_TO_BARN_SUPPLY
	_move_towards_target(false)
	return true


func _plan_barn_berry_restock() -> bool:
	if not bool(world.call("has_farm_barn")):
		return false
	if int(world.call("get_farm_barn_berry_stock")) < int(world.call("get_berry_seed_cost")):
		return false

	var access_cell: Vector2i = world.call("get_farm_barn_access_cell", current_cell)
	if access_cell == INVALID_CELL:
		return false

	barn_supply_cell = access_cell
	_barn_supply_mode = "crate_berries"
	target_cell = access_cell
	_state = WandererState.WALK_TO_BARN_SUPPLY
	_move_towards_target(false)
	return true


func _should_fetch_travel_food(destination: Vector2i) -> bool:
	if destination == INVALID_CELL or carried_food > 0:
		return false
	if home_cell == INVALID_CELL:
		return false
	if destination.distance_to(home_cell) <= travel_food_distance:
		return false
	if _state == WandererState.WALK_TO_BARN_SUPPLY or _state == WandererState.BARN_SUPPLY:
		return false
	if int(world.call("get_farm_barn_food_amount")) <= 0 and int(world.call("get_crate_food_amount", npc_id)) <= 0:
		return false
	return true


func _plan_take_travel_food_for_trip(destination: Vector2i, queued_state: int, allow_tree_target: bool) -> bool:
	var supply_cell := INVALID_CELL
	if bool(world.call("has_farm_barn")) and int(world.call("get_farm_barn_food_amount")) > 0:
		supply_cell = world.call("get_farm_barn_access_cell", current_cell)
		_barn_supply_mode = "travel_food"
	elif crate_cell != INVALID_CELL and int(world.call("get_crate_food_amount", npc_id)) > 0:
		supply_cell = world.call("get_crate_access_cell", npc_id, current_cell)
		_barn_supply_mode = "travel_food"
	else:
		return false

	if supply_cell == INVALID_CELL:
		return false

	_queued_target_cell = destination
	_queued_state = queued_state
	_queued_allow_tree_target = allow_tree_target
	barn_supply_cell = supply_cell
	target_cell = supply_cell
	_state = WandererState.WALK_TO_BARN_SUPPLY
	_move_towards_target(false)
	return true


func _resume_queued_task() -> void:
	if _queued_target_cell == INVALID_CELL:
		return
	target_cell = _queued_target_cell
	_state = _queued_state
	var queued_allow_tree := _queued_allow_tree_target
	_queued_target_cell = INVALID_CELL
	_queued_state = WandererState.DECIDE
	_queued_allow_tree_target = false
	_move_towards_target(queued_allow_tree)


func _eat_carried_food() -> void:
	if carried_food <= 0:
		return
	carried_food -= 1
	hunger = minf(NEED_MAX, hunger + hunger_restore_amount)


func _drink_from_canteen() -> void:
	if canteen_water <= 0:
		return
	canteen_water -= 1
	thirst = minf(NEED_MAX, thirst + thirst_restore_amount * 0.78)


func _plan_rock_gathering() -> bool:
	if target_rock_cell != INVALID_CELL and not bool(world.call("rock_exists", target_rock_cell)):
		target_rock_cell = INVALID_CELL

	if target_rock_cell == INVALID_CELL:
		if _rock_query_cooldown > 0.0:
			return false
		target_rock_cell = world.call("claim_nearest_rock", current_cell, npc_id)
		if target_rock_cell == INVALID_CELL:
			_rock_query_cooldown = _rng.randf_range(0.25, 0.55)

	if target_rock_cell == INVALID_CELL:
		return false

	target_cell = target_rock_cell
	_state = WandererState.WALK_TO_ROCK
	_move_towards_target(false)
	return true


func _plan_tree_work() -> bool:
	if wood_count < int(world.call("get_farm_barn_wood_cost")) + 2:
		_plan_tree_gathering()
		return true
	return false


func _plan_miner_work() -> bool:
	return _plan_rock_gathering()


func _plan_fisher_work() -> bool:
	if bool(world.call("has_farm_barn")):
		return _plan_fishing()
	if int(world.call("get_free_food_capacity", npc_id)) > 0:
		return _plan_fishing()
	return _plan_best_food_source()


func _plan_farmer_work() -> bool:
	if bool(world.call("has_farm_barn")):
		if int(world.call("get_crate_berry_stock", npc_id)) < int(world.call("get_berry_seed_cost")) and _plan_barn_berry_restock():
			return true
	if int(world.call("get_crate_berry_stock", npc_id)) >= int(world.call("get_berry_seed_cost")) and _plan_berry_farming():
		return true
	if bool(world.call("has_farm_barn")) and int(world.call("get_farm_barn_food_amount")) > 0 and _plan_barn_to_crate_restock():
		return true
	return _plan_food_gathering()


func _plan_builder_work() -> bool:
	if int(world.call("get_farm_barn_count")) < 2:
		var wood_need := int(world.call("get_farm_barn_wood_cost"))
		var stone_need := int(world.call("get_farm_barn_stone_cost"))
		_pull_build_resources_from_warehouse(wood_need, stone_need)
		if wood_count < wood_need:
			_plan_tree_gathering()
			return true
		if stone_count < stone_need:
			return _plan_rock_gathering()
		return _plan_farm_barn_build()
	if int(world.call("get_warehouse_count")) < 2:
		var warehouse_wood_need := int(world.call("get_warehouse_level_1_wood_cost"))
		var warehouse_stone_need := int(world.call("get_warehouse_level_1_stone_cost"))
		_pull_build_resources_from_warehouse(warehouse_wood_need, warehouse_stone_need)
		if wood_count < warehouse_wood_need:
			_plan_tree_gathering()
			return true
		if stone_count < warehouse_stone_need:
			return _plan_rock_gathering()
		return _plan_warehouse_build()
	if world.call("get_warehouse_upgrade_cell") != INVALID_CELL:
		var warehouse_upgrade_wood_need := int(world.call("get_warehouse_level_2_wood_cost"))
		var warehouse_upgrade_stone_need := int(world.call("get_warehouse_level_2_stone_cost"))
		_pull_build_resources_from_warehouse(warehouse_upgrade_wood_need, warehouse_upgrade_stone_need)
		if wood_count < warehouse_upgrade_wood_need:
			_plan_tree_gathering()
			return true
		if stone_count < warehouse_upgrade_stone_need:
			return _plan_rock_gathering()
		return _plan_warehouse_upgrade()
	if int(world.call("get_farm_barn_food_amount")) > 0 and int(world.call("get_crate_food_amount", npc_id)) < mini(FOOD_RESERVE_TARGET, int(world.call("get_food_crate_capacity", npc_id))):
		return _plan_barn_to_crate_restock()
	return false


func _plan_election_rally() -> bool:
	if current_cell.distance_to(election_rally_cell) <= 2.5:
		return false
	target_cell = election_rally_cell
	_state = WandererState.ROAM_HOME
	_move_towards_target(false)
	return true


func _plan_house_build() -> void:
	if claimed_home_site == INVALID_CELL:
		claimed_home_site = world.call("claim_house_site", spawn_cell, npc_id)

	if claimed_home_site == INVALID_CELL:
		_pick_local_idle_target()
		return

	target_cell = claimed_home_site
	_state = WandererState.WALK_TO_BUILD_HOME
	_move_towards_target(false)


func _plan_vacant_house_claim() -> bool:
	if claimed_vacant_home_cell != INVALID_CELL and bool(world.call("has_house", npc_id)):
		claimed_vacant_home_cell = INVALID_CELL

	if claimed_vacant_home_cell == INVALID_CELL:
		var origin := current_cell if current_cell != INVALID_CELL else spawn_cell
		claimed_vacant_home_cell = world.call("claim_vacant_house", origin, npc_id)

	if claimed_vacant_home_cell == INVALID_CELL:
		return false

	var access_cell: Vector2i = world.call("get_house_access_cell", claimed_vacant_home_cell, current_cell)
	if access_cell == INVALID_CELL:
		world.call("release_vacant_house_claim", claimed_vacant_home_cell, npc_id)
		claimed_vacant_home_cell = INVALID_CELL
		return false

	target_cell = access_cell
	_state = WandererState.WALK_TO_OCCUPY_HOME
	_move_towards_target(false)
	return true


func _plan_crate_build() -> void:
	if claimed_crate_site == INVALID_CELL:
		claimed_crate_site = world.call("claim_crate_site", home_cell, npc_id)

	if claimed_crate_site == INVALID_CELL:
		_pick_roam_target(home_cell)
		return

	target_cell = claimed_crate_site
	_state = WandererState.WALK_TO_BUILD_CRATE
	_move_towards_target(false)


func _plan_farm_barn_build() -> bool:
	if claimed_farm_barn_site == INVALID_CELL:
		claimed_farm_barn_site = world.call("claim_farm_barn_site", home_cell if home_cell != INVALID_CELL else current_cell, npc_id)
	if claimed_farm_barn_site == INVALID_CELL:
		return false

	target_cell = claimed_farm_barn_site
	_state = WandererState.WALK_TO_BUILD_FARM
	_move_towards_target(false)
	return true


func _plan_house_upgrade() -> bool:
	if home_cell == INVALID_CELL:
		return false

	var access_cell: Vector2i = world.call("get_house_access_cell", home_cell, current_cell)
	if access_cell == INVALID_CELL:
		return false

	upgrade_target_cell = home_cell
	target_cell = access_cell
	_state = WandererState.WALK_TO_UPGRADE_HOME
	_move_towards_target(false)
	return true


func _plan_crate_upgrade() -> bool:
	if crate_cell == INVALID_CELL:
		return false

	var access_cell: Vector2i = world.call("get_crate_access_cell", npc_id, current_cell)
	if access_cell == INVALID_CELL:
		return false

	upgrade_target_cell = crate_cell
	target_cell = access_cell
	_state = WandererState.WALK_TO_UPGRADE_CRATE
	_move_towards_target(false)
	return true


func _plan_food_gathering() -> bool:
	if crate_cell == INVALID_CELL:
		return false
	if not bool(world.call("has_farm_barn")) and int(world.call("get_free_food_capacity", npc_id)) <= 0:
		return false

	if target_food_cell != INVALID_CELL and not bool(world.call("food_source_exists", target_food_cell)):
		target_food_cell = INVALID_CELL

	if target_food_cell == INVALID_CELL:
		if _food_query_cooldown > 0.0:
			return false
		target_food_cell = world.call("claim_nearest_food_source", current_cell, npc_id)
		if target_food_cell == INVALID_CELL:
			_food_query_cooldown = _rng.randf_range(0.22, 0.50)

	if target_food_cell == INVALID_CELL:
		return false

	var access_cell: Vector2i = world.call("get_food_source_access_cell", target_food_cell, current_cell)
	if access_cell == INVALID_CELL:
		world.call("release_food_claim", target_food_cell, npc_id)
		target_food_cell = INVALID_CELL
		return false

	target_cell = access_cell
	_state = WandererState.WALK_TO_HARVEST_FOOD
	_move_towards_target(false)
	return true


func _plan_best_food_source() -> bool:
	var gather_distance := float(world.call("get_nearest_food_source_distance", current_cell, npc_id))
	var fishing_origin := crate_cell if crate_cell != INVALID_CELL else home_cell
	var fishing_distance := float(world.call("get_nearest_fishing_spot_distance", current_cell, fishing_origin, npc_id))

	if gather_distance == INF and fishing_distance == INF:
		return false
	if gather_distance <= fishing_distance:
		if _plan_food_gathering():
			return true
		return _plan_fishing()
	if _plan_fishing():
		return true
	return _plan_food_gathering()


func _plan_berry_farming() -> bool:
	if home_cell == INVALID_CELL:
		return false

	var tilled_cell: Vector2i = world.call("get_nearest_farm_plot", home_cell, npc_id)
	if tilled_cell != INVALID_CELL:
		farm_plot_cell = tilled_cell
		target_cell = tilled_cell
		_state = WandererState.WALK_TO_SOW_BERRIES
		_move_towards_target(false)
		return true

	var new_plot_cell: Vector2i = world.call("claim_farm_plot", home_cell, npc_id)
	if new_plot_cell == INVALID_CELL:
		return false

	farm_plot_cell = new_plot_cell
	target_cell = new_plot_cell
	_state = WandererState.WALK_TO_FARM_PLOT
	_move_towards_target(false)
	return true


func _plan_fishing() -> bool:
	if crate_cell == INVALID_CELL and not bool(world.call("has_farm_barn")):
		return false
	if fishing_cell == INVALID_CELL or not bool(world.call("is_cell_near_water", fishing_cell)):
		if _fishing_query_cooldown > 0.0:
			return false
		if fishing_cell != INVALID_CELL:
			world.call("release_fishing_spot", fishing_cell, npc_id)
		var fishing_origin := crate_cell if crate_cell != INVALID_CELL else home_cell
		if bool(world.call("has_farm_barn")):
			fishing_origin = world.call("get_farm_barn_cell")
		fishing_cell = world.call("claim_fishing_spot", fishing_origin, npc_id)
		if fishing_cell == INVALID_CELL:
			_fishing_query_cooldown = _rng.randf_range(0.25, 0.60)

	if fishing_cell == INVALID_CELL:
		return false

	target_cell = fishing_cell
	_state = WandererState.WALK_TO_FISH
	_move_towards_target(false)
	return true


func _plan_eating() -> bool:
	if crate_cell == INVALID_CELL:
		return false
	if int(world.call("get_crate_food_amount", npc_id)) <= 0 and bool(world.call("has_farm_barn")) and int(world.call("get_farm_barn_food_amount")) > 0:
		return _plan_barn_to_crate_restock(true)

	var access_cell: Vector2i = world.call("get_crate_access_cell", npc_id, current_cell)
	if access_cell == INVALID_CELL:
		return false

	target_cell = access_cell
	_state = WandererState.WALK_TO_EAT
	_move_towards_target(false)
	return true


func _plan_drinking(preferred_origin: Vector2i) -> bool:
	var search_origin := current_cell if current_cell != INVALID_CELL else preferred_origin
	drink_cell = world.call("find_nearest_water_access_cell", search_origin)
	if drink_cell == INVALID_CELL and preferred_origin != INVALID_CELL and preferred_origin != search_origin:
		drink_cell = world.call("find_nearest_water_access_cell", preferred_origin)

	if drink_cell == INVALID_CELL:
		return false

	target_cell = drink_cell
	_state = WandererState.WALK_TO_DRINK
	_move_towards_target(false)
	return true


func _pick_roam_target(center_cell: Vector2i) -> void:
	target_tree_cell = INVALID_CELL
	target_rock_cell = INVALID_CELL
	target_food_cell = INVALID_CELL
	claimed_home_site = INVALID_CELL
	claimed_vacant_home_cell = INVALID_CELL
	claimed_crate_site = INVALID_CELL
	upgrade_target_cell = INVALID_CELL

	var origin := center_cell if center_cell != INVALID_CELL else current_cell
	for radius in [3, 5, 7]:
		for _attempt in range(20):
			var candidate := Vector2i(
				origin.x + _rng.randi_range(-radius, radius),
				origin.y + _rng.randi_range(-radius, radius)
			)
			if not bool(world.call("is_cell_walkable", candidate)):
				continue
			if candidate == current_cell:
				continue

			target_cell = candidate
			_state = WandererState.ROAM_HOME
			_move_towards_target(false)
			return

	_state = WandererState.DECIDE
	_idle_timer = _rng.randf_range(idle_time_min, idle_time_max)


func _pick_local_idle_target() -> void:
	for radius in [2, 3, 5]:
		for _attempt in range(12):
			var candidate := Vector2i(
				current_cell.x + _rng.randi_range(-radius, radius),
				current_cell.y + _rng.randi_range(-radius, radius)
			)
			if not bool(world.call("is_cell_walkable", candidate)):
				continue
			if candidate == current_cell:
				continue

			target_cell = candidate
			_state = WandererState.ROAM_HOME
			_move_towards_target(false)
			return

	_state = WandererState.DECIDE
	_idle_timer = _rng.randf_range(0.15, 0.35)


func _move_towards_target(allow_tree_target: bool) -> void:
	if target_cell == INVALID_CELL:
		_state = WandererState.DECIDE
		_idle_timer = _rng.randf_range(0.1, 0.25)
		return

	if _should_fetch_travel_food(target_cell):
		if _plan_take_travel_food_for_trip(target_cell, _state, allow_tree_target):
			return

	if current_cell == target_cell:
		_arrive_at_target()
		return

	step_target_cell = world.call("find_next_step", current_cell, target_cell, allow_tree_target)
	if step_target_cell == INVALID_CELL:
		_release_claims_for_target()
		_state = WandererState.DECIDE
		_idle_timer = _rng.randf_range(0.1, 0.25)
		return

	_start_move_to(step_target_cell)


func _start_move_to(next_cell: Vector2i) -> void:
	step_target_cell = next_cell
	_moving = true
	_play_walk()
	sprite.flip_h = step_target_cell.x < current_cell.x


func _update_movement(delta: float) -> void:
	var target_position := _cell_to_position(step_target_cell)
	position = position.move_toward(target_position, _current_move_speed() * delta)
	if position.distance_to(target_position) > 1.0:
		return

	position = target_position
	var previous_cell := current_cell
	current_cell = step_target_cell
	world.call("update_npc_cell", npc_id, previous_cell, current_cell)
	_moving = false

	if _should_interrupt_for_survival():
		_release_claims_for_target()
		_state = WandererState.DECIDE
		_idle_timer = 0.0
		return

	if current_cell == target_cell:
		_arrive_at_target()
	else:
		match _state:
			WandererState.WALK_TO_TREE:
				_move_towards_target(true)
			WandererState.WALK_TO_ROCK, WandererState.WALK_TO_BUILD_HOME, WandererState.WALK_TO_OCCUPY_HOME, WandererState.WALK_TO_BUILD_CRATE, WandererState.WALK_TO_BUILD_FARM, WandererState.WALK_TO_BUILD_WAREHOUSE, WandererState.WALK_TO_UPGRADE_WAREHOUSE, WandererState.WALK_TO_UPGRADE_HOME, WandererState.WALK_TO_UPGRADE_CRATE, WandererState.WALK_TO_HARVEST_FOOD, WandererState.WALK_TO_FARM_PLOT, WandererState.WALK_TO_SOW_BERRIES, WandererState.WALK_TO_FISH, WandererState.WALK_TO_EAT, WandererState.WALK_TO_DRINK, WandererState.WALK_TO_LOOT_BAG, WandererState.WALK_TO_BARN_SUPPLY, WandererState.WALK_TO_DEFEND, WandererState.ROAM_HOME:
				_move_towards_target(false)
			_:
				_state = WandererState.DECIDE


func _arrive_at_target() -> void:
	sprite.pause()

	match _state:
		WandererState.WALK_TO_TREE:
			_state = WandererState.CHOP_TREE
			_action_timer = chop_duration
		WandererState.WALK_TO_ROCK:
			_state = WandererState.MINE_ROCK
			_action_timer = mine_duration
		WandererState.WALK_TO_BUILD_HOME:
			_state = WandererState.BUILD_HOME
			_action_timer = build_duration
		WandererState.WALK_TO_OCCUPY_HOME:
			_state = WandererState.OCCUPY_HOME
			_action_timer = occupy_duration
		WandererState.WALK_TO_BUILD_CRATE:
			_state = WandererState.BUILD_CRATE
			_action_timer = build_duration * 0.8
		WandererState.WALK_TO_BUILD_FARM:
			_state = WandererState.BUILD_FARM
			_action_timer = build_duration * 1.25
		WandererState.WALK_TO_BUILD_WAREHOUSE:
			_state = WandererState.BUILD_WAREHOUSE
			_action_timer = build_duration * 1.05
		WandererState.WALK_TO_UPGRADE_WAREHOUSE:
			_state = WandererState.UPGRADE_WAREHOUSE
			_action_timer = build_duration * 1.2
		WandererState.WALK_TO_UPGRADE_HOME:
			_state = WandererState.UPGRADE_HOME
			_action_timer = build_duration * 1.05
		WandererState.WALK_TO_UPGRADE_CRATE:
			_state = WandererState.UPGRADE_CRATE
			_action_timer = build_duration * 0.9
		WandererState.WALK_TO_HARVEST_FOOD:
			_state = WandererState.HARVEST_FOOD
			_action_timer = harvest_food_duration
		WandererState.WALK_TO_FARM_PLOT:
			_state = WandererState.TILL_SOIL
			_action_timer = till_soil_duration
		WandererState.WALK_TO_SOW_BERRIES:
			_state = WandererState.SOW_BERRIES
			_action_timer = sow_duration
		WandererState.WALK_TO_FISH:
			_state = WandererState.FISH
			_action_timer = fish_duration
			_play_fish()
		WandererState.WALK_TO_EAT:
			_state = WandererState.EAT
			_action_timer = eat_duration
		WandererState.WALK_TO_DRINK:
			_state = WandererState.DRINK
			_action_timer = drink_duration
		WandererState.WALK_TO_DEFEND:
			_state = WandererState.DECIDE
			_idle_timer = 0.08
		WandererState.WALK_TO_LOOT_BAG:
			_state = WandererState.LOOT_BAG
			_action_timer = 0.45
		WandererState.WALK_TO_BARN_SUPPLY:
			_state = WandererState.BARN_SUPPLY
			_action_timer = 0.5
		WandererState.ROAM_HOME:
			_state = WandererState.DECIDE
			_idle_timer = _rng.randf_range(idle_time_min, idle_time_max)
		_:
			_state = WandererState.DECIDE
			_idle_timer = _rng.randf_range(idle_time_min, idle_time_max)


func _finish_action() -> void:
	match _state:
		WandererState.CHOP_TREE:
			if target_tree_cell != INVALID_CELL:
				wood_count += int(world.call("harvest_tree", target_tree_cell, npc_id))
				if assigned_role == "lumberjack":
					world.call("plant_tree_sapling", target_tree_cell)
			target_tree_cell = INVALID_CELL
			target_cell = INVALID_CELL
			_state = WandererState.DECIDE
		WandererState.MINE_ROCK:
			if target_rock_cell != INVALID_CELL:
				stone_count += int(world.call("harvest_rock", target_rock_cell, npc_id))
			target_rock_cell = INVALID_CELL
			target_cell = INVALID_CELL
			_state = WandererState.DECIDE
		WandererState.BUILD_HOME:
			if claimed_home_site != INVALID_CELL and bool(world.call("build_house", claimed_home_site, npc_id)):
				wood_count = maxi(wood_count - BASIC_HOME_WOOD_COST, 0)
				home_cell = claimed_home_site
			claimed_home_site = INVALID_CELL
			target_cell = INVALID_CELL
			_state = WandererState.DECIDE
		WandererState.OCCUPY_HOME:
			if claimed_vacant_home_cell != INVALID_CELL and bool(world.call("occupy_vacant_house", claimed_vacant_home_cell, npc_id)):
				home_cell = claimed_vacant_home_cell
				crate_cell = world.call("get_crate_cell", npc_id)
			claimed_vacant_home_cell = INVALID_CELL
			target_cell = INVALID_CELL
			_state = WandererState.DECIDE
		WandererState.BUILD_CRATE:
			if claimed_crate_site != INVALID_CELL and bool(world.call("build_crate", claimed_crate_site, npc_id)):
				wood_count = maxi(wood_count - BASIC_CRATE_WOOD_COST, 0)
				crate_cell = claimed_crate_site
			claimed_crate_site = INVALID_CELL
			target_cell = INVALID_CELL
			_state = WandererState.DECIDE
		WandererState.BUILD_FARM:
			if claimed_farm_barn_site != INVALID_CELL and bool(world.call("build_farm_barn", claimed_farm_barn_site, npc_id)):
				wood_count = maxi(wood_count - int(world.call("get_farm_barn_wood_cost")), 0)
				stone_count = maxi(stone_count - int(world.call("get_farm_barn_stone_cost")), 0)
			claimed_farm_barn_site = INVALID_CELL
			target_cell = INVALID_CELL
			_state = WandererState.DECIDE
		WandererState.BUILD_WAREHOUSE:
			if claimed_warehouse_site != INVALID_CELL and bool(world.call("build_warehouse", claimed_warehouse_site, npc_id)):
				wood_count = maxi(wood_count - int(world.call("get_warehouse_level_1_wood_cost")), 0)
				stone_count = maxi(stone_count - int(world.call("get_warehouse_level_1_stone_cost")), 0)
			claimed_warehouse_site = INVALID_CELL
			target_cell = INVALID_CELL
			_state = WandererState.DECIDE
		WandererState.UPGRADE_WAREHOUSE:
			if upgrade_target_cell != INVALID_CELL and bool(world.call("upgrade_warehouse", upgrade_target_cell)):
				wood_count = maxi(wood_count - int(world.call("get_warehouse_level_2_wood_cost")), 0)
				stone_count = maxi(stone_count - int(world.call("get_warehouse_level_2_stone_cost")), 0)
			upgrade_target_cell = INVALID_CELL
			target_cell = INVALID_CELL
			_state = WandererState.DECIDE
		WandererState.UPGRADE_HOME:
			if home_cell != INVALID_CELL and bool(world.call("upgrade_house", npc_id)):
				wood_count = maxi(wood_count - HOUSE_UPGRADE_WOOD_COST, 0)
				stone_count = maxi(stone_count - HOUSE_UPGRADE_STONE_COST, 0)
			upgrade_target_cell = INVALID_CELL
			target_cell = INVALID_CELL
			_state = WandererState.DECIDE
		WandererState.UPGRADE_CRATE:
			if crate_cell != INVALID_CELL and bool(world.call("upgrade_crate", npc_id)):
				wood_count = maxi(wood_count - CRATE_UPGRADE_WOOD_COST, 0)
				stone_count = maxi(stone_count - CRATE_UPGRADE_STONE_COST, 0)
			upgrade_target_cell = INVALID_CELL
			target_cell = INVALID_CELL
			_state = WandererState.DECIDE
		WandererState.HARVEST_FOOD:
			if target_food_cell != INVALID_CELL:
				var free_space := int(world.call("get_free_food_capacity", npc_id))
				if bool(world.call("has_farm_barn")):
					free_space = maxi(free_space, int(world.call("get_food_gather_amount")))
				if free_space > 0:
					var harvest_amount := mini(int(world.call("get_food_gather_amount")), free_space)
					var harvested := int(world.call("harvest_food_source", target_food_cell, npc_id, harvest_amount))
					if harvested > 0:
						if bool(world.call("food_source_is_bush", target_food_cell)):
							if bool(world.call("has_farm_barn")):
								world.call("store_berries_in_farm_barn", harvested)
							else:
								world.call("store_berries_in_crate", npc_id, harvested)
						else:
							if bool(world.call("has_farm_barn")):
								world.call("store_food_in_farm_barn", harvested)
							else:
								world.call("store_food_in_crate", npc_id, harvested)
				world.call("release_food_claim", target_food_cell, npc_id)
			target_food_cell = INVALID_CELL
			target_cell = INVALID_CELL
			_state = WandererState.DECIDE
		WandererState.TILL_SOIL:
			if farm_plot_cell != INVALID_CELL:
				world.call("create_tilled_plot", farm_plot_cell, npc_id)
			target_cell = INVALID_CELL
			_state = WandererState.DECIDE
		WandererState.SOW_BERRIES:
			if farm_plot_cell != INVALID_CELL:
				world.call("sow_berry_plot", farm_plot_cell, npc_id)
			target_cell = INVALID_CELL
			farm_plot_cell = INVALID_CELL
			_state = WandererState.DECIDE
		WandererState.FISH:
			if _rng.randf() < float(world.call("get_fish_success_chance")):
				if bool(world.call("has_farm_barn")):
					world.call("store_food_in_farm_barn", 1)
				else:
					world.call("store_food_in_crate", npc_id, 1)
			if fishing_cell != INVALID_CELL:
				world.call("release_fishing_spot", fishing_cell, npc_id)
			fishing_cell = INVALID_CELL
			target_cell = INVALID_CELL
			_state = WandererState.DECIDE
		WandererState.EAT:
			if int(world.call("consume_food_from_crate", npc_id, 1)) > 0:
				hunger = minf(NEED_MAX, hunger + hunger_restore_amount)
			target_cell = INVALID_CELL
			_state = WandererState.DECIDE
		WandererState.DRINK:
			thirst = minf(NEED_MAX, thirst + thirst_restore_amount)
			canteen_water = CANTEEN_CAPACITY
			drink_cell = INVALID_CELL
			target_cell = INVALID_CELL
			_state = WandererState.DECIDE
		WandererState.LOOT_BAG:
			if loot_bag_cell != INVALID_CELL:
				var picked: Dictionary = world.call("pickup_loot_bag", loot_bag_cell, npc_id)
				wood_count += int(picked.get("wood", 0))
				stone_count += int(picked.get("stone", 0))
				carried_food += int(picked.get("food", 0)) + int(picked.get("berries", 0))
			loot_bag_cell = INVALID_CELL
			target_cell = INVALID_CELL
			_state = WandererState.DECIDE
		WandererState.BARN_SUPPLY:
			var resume_trip := false
			if _barn_supply_mode == "crate_food":
				world.call("transfer_food_from_farm_barn_to_crate", npc_id, maxi(1, mini(3, int(world.call("get_food_crate_capacity", npc_id)) - int(world.call("get_crate_food_amount", npc_id)))))
			elif _barn_supply_mode == "crate_berries":
				world.call("transfer_berries_from_farm_barn_to_crate", npc_id, int(world.call("get_berry_seed_cost")))
			elif _barn_supply_mode == "travel_food":
				carried_food += int(world.call("take_travel_food", npc_id, 1))
				resume_trip = true
			barn_supply_cell = INVALID_CELL
			_barn_supply_mode = ""
			barn_food_claimed = false
			target_cell = INVALID_CELL
			_state = WandererState.DECIDE
			if resume_trip:
				_resume_queued_task()
				return
		_:
			_state = WandererState.DECIDE

	_idle_timer = _rng.randf_range(idle_time_min, idle_time_max)
	_play_walk()
	if sprite != null:
		sprite.pause()


func _release_claims_for_target() -> void:
	if target_tree_cell != INVALID_CELL:
		world.call("release_tree_claim", target_tree_cell, npc_id)
		target_tree_cell = INVALID_CELL

	if target_rock_cell != INVALID_CELL:
		world.call("release_rock_claim", target_rock_cell, npc_id)
		target_rock_cell = INVALID_CELL

	if target_food_cell != INVALID_CELL:
		world.call("release_food_claim", target_food_cell, npc_id)
		target_food_cell = INVALID_CELL

	if farm_plot_cell != INVALID_CELL:
		world.call("release_farm_plot_claim", farm_plot_cell, npc_id)
		farm_plot_cell = INVALID_CELL

	if claimed_home_site != INVALID_CELL:
		world.call("release_house_site", claimed_home_site, npc_id)
		claimed_home_site = INVALID_CELL

	if claimed_vacant_home_cell != INVALID_CELL:
		world.call("release_vacant_house_claim", claimed_vacant_home_cell, npc_id)
		claimed_vacant_home_cell = INVALID_CELL

	if claimed_crate_site != INVALID_CELL:
		world.call("release_crate_site", claimed_crate_site, npc_id)
		claimed_crate_site = INVALID_CELL

	if claimed_farm_barn_site != INVALID_CELL:
		world.call("release_farm_barn_site", claimed_farm_barn_site, npc_id)
		claimed_farm_barn_site = INVALID_CELL

	if claimed_warehouse_site != INVALID_CELL:
		world.call("release_warehouse_site", claimed_warehouse_site, npc_id)
		claimed_warehouse_site = INVALID_CELL

	if fishing_cell != INVALID_CELL:
		world.call("release_fishing_spot", fishing_cell, npc_id)
		fishing_cell = INVALID_CELL

	if barn_food_claimed:
		world.call("release_farm_barn_food_claim", npc_id)
		barn_food_claimed = false

	if loot_bag_cell != INVALID_CELL:
		world.call("release_loot_bag_claim", loot_bag_cell, npc_id)
		loot_bag_cell = INVALID_CELL

	drink_cell = INVALID_CELL
	barn_supply_cell = INVALID_CELL
	_barn_supply_mode = ""
	_queued_target_cell = INVALID_CELL
	_queued_state = WandererState.DECIDE
	_queued_allow_tree_target = false
	upgrade_target_cell = INVALID_CELL
	target_cell = INVALID_CELL


func _should_interrupt_for_survival() -> bool:
	if _state == WandererState.WALK_TO_EAT or _state == WandererState.EAT:
		return false
	if _state == WandererState.WALK_TO_DRINK or _state == WandererState.DRINK:
		return false
	if canteen_water > 0 and thirst <= THIRST_CRITICAL_THRESHOLD:
		return true
	if thirst <= THIRST_CRITICAL_THRESHOLD:
		return true

	if carried_food > 0:
		return hunger <= HUNGER_CRITICAL_THRESHOLD
	if crate_cell == INVALID_CELL:
		return false

	return hunger <= HUNGER_CRITICAL_THRESHOLD and (int(world.call("get_crate_food_amount", npc_id)) > 0 or int(world.call("get_farm_barn_food_amount")) > 0)


func _current_move_speed() -> float:
	var lowest_need := minf(hunger, thirst)
	if lowest_need >= 40.0:
		return move_speed

	var ratio := clampf(lowest_need / 40.0, 0.0, 1.0)
	return lerpf(move_speed * 0.76, move_speed, ratio)


func _get_survival_anchor() -> Vector2i:
	if bool(world.call("has_farm_barn")):
		var barn_cell: Vector2i = world.call("get_farm_barn_cell")
		if barn_cell != INVALID_CELL:
			return barn_cell
	if crate_cell != INVALID_CELL:
		return crate_cell
	if home_cell != INVALID_CELL:
		return home_cell
	if spawn_cell != INVALID_CELL:
		return spawn_cell
	return current_cell


func get_npc_id() -> int:
	return npc_id


func can_reproduce() -> bool:
	if _is_dead:
		return false

	home_cell = world.call("get_home_cell", npc_id)
	crate_cell = world.call("get_crate_cell", npc_id)

	if reproduction_cooldown > 0.0:
		reproduction_cooldown = 0.0
	if home_cell == INVALID_CELL or crate_cell == INVALID_CELL:
		return false
	if hunger < REPRODUCTION_HUNGER_THRESHOLD or thirst < REPRODUCTION_THIRST_THRESHOLD:
		return false
	if age_days >= lifespan_days * old_age_factor:
		return false
	if _state != WandererState.DECIDE and _state != WandererState.ROAM_HOME:
		return false

	var crate_food := int(world.call("get_crate_food_amount", npc_id))
	var crate_capacity := int(world.call("get_food_crate_capacity", npc_id))
	return crate_food >= crate_capacity


func notify_reproduction() -> void:
	reproduction_cooldown = 0.0
	hunger = maxf(48.0, hunger - 18.0)
	thirst = maxf(50.0, thirst - 20.0)
	_idle_timer = _rng.randf_range(0.4, 0.9)


func get_drop_inventory() -> Dictionary:
	return {
		"wood": wood_count,
		"stone": stone_count,
		"food": carried_food,
		"berries": 0,
	}


func get_role_snapshot(has_home: bool, has_crate: bool) -> Dictionary:
	var max_hp := _get_max_hp()
	return {
		"id": npc_id,
		"hunger": hunger,
		"thirst": thirst,
		"hp": current_hp,
		"max_hp": max_hp,
		"wood": wood_count,
		"stone": stone_count,
		"carried_food": carried_food,
		"has_home": has_home,
		"has_crate": has_crate,
		"readiness": _get_role_readiness_from_flags(has_home, has_crate, max_hp),
	}


func get_status_snapshot() -> Dictionary:
	home_cell = world.call("get_home_cell", npc_id)
	crate_cell = world.call("get_crate_cell", npc_id)
	var ready_to_reproduce := can_reproduce()

	return {
		"id": npc_id,
		"state": "Сражается" if _in_combat else _state_name(_state),
		"hunger": snapped(hunger, 0.1),
		"thirst": snapped(thirst, 0.1),
		"hp": current_hp,
		"max_hp": _get_max_hp(),
		"wood": wood_count,
		"stone": stone_count,
		"carried_food": carried_food,
		"canteen_water": canteen_water,
		"age_days": snapped(age_days, 0.1),
		"age_text": _age_text(),
		"has_home": home_cell != INVALID_CELL,
		"has_crate": crate_cell != INVALID_CELL,
		"house_level": int(world.call("get_house_level", npc_id)),
		"crate_level": int(world.call("get_crate_level", npc_id)),
		"crate_food": int(world.call("get_crate_food_amount", npc_id)),
		"berry_stock": int(world.call("get_crate_berry_stock", npc_id)),
		"crate_capacity": int(world.call("get_food_crate_capacity", npc_id)),
		"children_count": int(world.call("get_house_children_count", npc_id)),
		"children_limit": int(world.call("get_house_child_limit", npc_id)),
		"ready_to_reproduce": ready_to_reproduce,
		"reproduction_status": _reproduction_status_text(ready_to_reproduce),
		"reproduction_cooldown": snapped(reproduction_cooldown, 0.1),
		"role": assigned_role,
		"is_leader": is_leader,
		"defense_target": defense_worm_id,
		"death_reason": death_reason,
		"cell": current_cell,
		"target_cell": target_cell,
	}


func get_current_cell() -> Vector2i:
	return current_cell


func get_combat_cell() -> Vector2i:
	return current_cell


func get_unit_id() -> int:
	return npc_id


func get_current_hp() -> int:
	return current_hp


func get_attack_damage() -> int:
	return BASE_LEADER_DAMAGE if is_leader else BASE_VILLAGER_DAMAGE


func get_max_hp() -> int:
	return _get_max_hp()


func is_combat_alive() -> bool:
	return not _is_dead and current_hp > 0


func _age_text() -> String:
	var days_in_year := maxf(float(world.call("get_days_in_year")), 360.0)
	var total_days := int(floor(age_days))
	var years := int(floor(float(total_days) / days_in_year))
	var months := int(floor(float(total_days % int(days_in_year)) / 30.0))
	return "%d г %d мес" % [years, months]


func _get_role_readiness_from_flags(has_home: bool, has_crate: bool, max_hp_value: int = -1) -> float:
	var resolved_max_hp := float(max_hp_value if max_hp_value > 0 else _get_max_hp())
	var home_bonus := 12.0 if has_home else -8.0
	var crate_bonus := 8.0 if has_crate else -6.0
	return hunger * 0.42 + thirst * 0.38 + (float(current_hp) / maxf(resolved_max_hp, 1.0)) * 100.0 * 0.2 + home_bonus + crate_bonus


func _reproduction_status_text(ready_to_reproduce: bool) -> String:
	if ready_to_reproduce:
		return "Готов"
	if home_cell == INVALID_CELL:
		return "Нет дома"
	if crate_cell == INVALID_CELL:
		return "Нет ящика"
	var crate_food := int(world.call("get_crate_food_amount", npc_id))
	var crate_capacity := int(world.call("get_food_crate_capacity", npc_id))
	if crate_food < crate_capacity:
		return "Ящик не заполнен"
	if age_days >= lifespan_days * old_age_factor:
		return "Престарелый возраст"
	if hunger < REPRODUCTION_HUNGER_THRESHOLD:
		return "Нужно наесться"
	if thirst < REPRODUCTION_THIRST_THRESHOLD:
		return "Нужно напиться"
	return "Готов к ребенку"


func _state_name(state: int) -> String:
	match state:
		WandererState.WALK_TO_TREE:
			return "Идет к дереву"
		WandererState.CHOP_TREE:
			return "Рубит дерево"
		WandererState.WALK_TO_ROCK:
			return "Идет к камню"
		WandererState.MINE_ROCK:
			return "Собирает камень"
		WandererState.WALK_TO_BUILD_HOME:
			return "Идет строить дом"
		WandererState.BUILD_HOME:
			return "Строит дом"
		WandererState.WALK_TO_OCCUPY_HOME:
			return "Идет к пустому дому"
		WandererState.OCCUPY_HOME:
			return "Заселяется"
		WandererState.WALK_TO_BUILD_CRATE:
			return "Идет строить ящик"
		WandererState.BUILD_CRATE:
			return "Строит ящик"
		WandererState.WALK_TO_BUILD_FARM:
			return "Идет строить ферму"
		WandererState.BUILD_FARM:
			return "Строит ферму"
		WandererState.WALK_TO_BUILD_WAREHOUSE:
			return "Идет строить склад"
		WandererState.BUILD_WAREHOUSE:
			return "Строит склад"
		WandererState.WALK_TO_UPGRADE_WAREHOUSE:
			return "Идет улучшать склад"
		WandererState.UPGRADE_WAREHOUSE:
			return "Улучшает склад"
		WandererState.WALK_TO_UPGRADE_HOME:
			return "Идет улучшать дом"
		WandererState.UPGRADE_HOME:
			return "Улучшает дом"
		WandererState.WALK_TO_UPGRADE_CRATE:
			return "Идет улучшать ящик"
		WandererState.UPGRADE_CRATE:
			return "Улучшает ящик"
		WandererState.WALK_TO_HARVEST_FOOD:
			return "Идет за едой"
		WandererState.HARVEST_FOOD:
			return "Собирает яблоки и ягоды"
		WandererState.WALK_TO_FARM_PLOT:
			return "Идет делать грядку"
		WandererState.TILL_SOIL:
			return "Возделывает землю"
		WandererState.WALK_TO_SOW_BERRIES:
			return "Идет сеять ягоды"
		WandererState.SOW_BERRIES:
			return "Сеет куст"
		WandererState.WALK_TO_FISH:
			return "Идет рыбачить"
		WandererState.FISH:
			return "Рыбачит"
		WandererState.WALK_TO_EAT:
			return "Идет есть"
		WandererState.EAT:
			return "Ест"
		WandererState.WALK_TO_DRINK:
			return "Идет пить"
		WandererState.DRINK:
			return "Пьет и наполняет флягу"
		WandererState.WALK_TO_DEFEND:
			return "Идет защищать поселение"
		WandererState.ROAM_HOME:
			return "Гуляет"
		WandererState.DEAD:
			return "Мертв"
		_:
			return "Думает"


func _play_walk() -> void:
	if sprite == null:
		return
	sprite.visible = true
	sprite.play("walk")


func _play_fish() -> void:
	if sprite == null:
		return
	sprite.visible = true
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("fish"):
		sprite.play("fish")
	else:
		sprite.play("walk")
		sprite.pause()


func _play_hurt() -> void:
	_hurt_timer = 0.28
	if sprite == null:
		return
	sprite.visible = true
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")
	else:
		sprite.play("walk")
		sprite.pause()


func _refresh_animation() -> void:
	if sprite == null or _is_dead:
		return
	if _in_combat:
		sprite.play("walk")
		sprite.pause()
		return
	if _moving:
		_play_walk()
		return
	if _state == WandererState.FISH:
		_play_fish()
		return
	_play_walk()
	sprite.pause()


func _get_max_hp() -> int:
	return BASE_LEADER_HP if is_leader else BASE_VILLAGER_HP


func _cell_to_position(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * TILE_SIZE, (cell.y + 0.5) * TILE_SIZE)
