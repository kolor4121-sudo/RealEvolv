extends Node2D

enum TerrainType {
	WATER,
	GRASS,
	DESERT,
}

const INVALID_CELL := Vector2i(-1, -1)
const BASE_FOOD_CRATE_CAPACITY := 5
const UPGRADED_FOOD_CRATE_CAPACITY := 10
const BASE_HOUSE_CHILD_LIMIT := 1
const UPGRADED_HOUSE_CHILD_LIMIT := 3
const FOOD_CRATE_CAPACITY := BASE_FOOD_CRATE_CAPACITY
const INITIAL_NPC_COUNT := 3
const MAX_NPC_COUNT := 32
const NPC_CLICK_RADIUS := 96.0
const REPRODUCTION_FOOD_COST := 4
const REPRODUCTION_CHECK_INTERVAL := 1.2
const DAYS_PER_MONTH := 30
const MONTHS_PER_YEAR := 12
const DAY_DURATION_SECONDS := 8.0
const HOUSE_SCALE := 1.34
const UPGRADED_HOUSE_SCALE := 1.46
const CRATE_SCALE := 0.86
const FARM_BARN_SCALE := 1.28
const WAREHOUSE_SCALE := 1.22
const CORPSE_DECAY_DURATION := 24.0
const TILE_SIZE := Vector2i(64, 64)
const WATER_SOURCE_ID := 0
const GRASS_SOURCE_ID := 1
const DESERT_SOURCE_ID := 2

const WATER_TEXTURE := preload("uid://dc15wx153mkms")
const TREE_TEXTURE := preload("uid://b50vy2ijn5181")
const GRASS_TEXTURE := preload("uid://b27qg6yrxj1rs")
const CACTUS_TEXTURE := preload("uid://bxu5f65tp08p8")
const ROCK_TEXTURE := preload("uid://byd73yvhvfgmv")
const BUSH_TEXTURE := preload("uid://jolsjncf3oha")
const DESERT_TEXTURE := preload("uid://cohw4a3co85ig")
const WANDERER_SCRIPT := preload("res://scripts/wanderer.gd")
const WORM_SCRIPT := preload("res://scripts/worm.gd")
const COMBAT_SYSTEM_SCRIPT := preload("res://scripts/combat_system.gd")
const DEFENSE_SYSTEM_SCRIPT := preload("res://scripts/settlement_defense.gd")
const ENTITY_INDEX_SCRIPT := preload("res://scripts/core/entity_index.gd")
const NAVIGATION_SERVICE_SCRIPT := preload("res://scripts/core/navigation_service.gd")
const SPATIAL_HASH_2D_SCRIPT := preload("res://scripts/core/spatial_hash_2d.gd")
const LEADER_ROLE_PLANNER_SCRIPT := preload("res://scripts/core/leader_role_planner.gd")
const DEATH_LOG_CONTROLLER_SCRIPT := preload("res://scripts/ui/death_log_controller.gd")

const CARDINAL_DIRS := [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]

const EIGHT_DIRS := [
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
	Vector2i(1, 1),
]

@export_range(80, 320, 10) var map_width := 200
@export_range(80, 320, 10) var map_height := 200
@export_range(300.0, 3000.0, 50.0) var camera_speed := 1100.0
@export var seed_value := 0
@export_range(0.5, 3.0, 0.05) var tree_density_multiplier := 1.55
@export_range(0.5, 3.0, 0.05) var bush_density_multiplier := 1.45
@export_range(0.5, 3.0, 0.05) var rock_density_multiplier := 1.65
@export_range(0.0, 1.0, 0.01) var fish_success_chance := 0.20
@export_range(1, 8, 1) var tree_wood_yield := 2
@export_range(1, 5, 1) var rock_stone_yield := 1
@export_range(1, 8, 1) var food_gather_amount := 4
@export_range(1, 10, 1) var berry_seed_cost := 3
@export_range(4.0, 180.0, 1.0) var berry_growth_time := 36.0
@export_range(4.0, 240.0, 1.0) var tree_regrow_time := 70.0
@export_range(4.0, 240.0, 1.0) var rock_respawn_time := 90.0
@export_range(4.0, 240.0, 1.0) var sapling_growth_time := 120.0
@export_range(0.0, 1.0, 0.01) var tree_regrow_chance := 0.32
@export_range(0.0, 1.0, 0.01) var rock_respawn_chance := 0.26
@export_range(1.0, 80.0, 1.0) var npc_travel_food_distance := 40.0
@export_range(2.0, 30.0, 0.5) var npc_stuck_timeout := 7.0
@export_range(1, 30, 1) var chief_population_threshold := 10
@export_range(2.0, 30.0, 0.5) var chief_election_duration := 8.0
@export_range(1.0, 30.0, 0.5) var leader_role_check_interval := 6.0
@export_range(1, 30, 1) var farm_barn_wood_cost := 10
@export_range(1, 30, 1) var farm_barn_stone_cost := 10
@export_range(1, 10, 1) var warehouse_level_1_wood_cost := 1
@export_range(1, 10, 1) var warehouse_level_1_stone_cost := 1
@export_range(1, 30, 1) var warehouse_level_2_wood_cost := 15
@export_range(1, 30, 1) var warehouse_level_2_stone_cost := 15
@export_range(1, 20, 1) var farm_plot_limit := 6
@export_range(2, 12, 1) var farm_plot_radius := 6
@export_range(1, 10, 1) var reproduction_food_cost := 4
@export_range(4, 100, 1) var max_npc_count := 32
@export_range(1.0, 30.0, 0.5) var day_duration_seconds := 8.0
@export_range(80.0, 260.0, 5.0) var npc_move_speed := 140.0
@export_range(0.0, 60.0, 1.0) var npc_initial_age_min := 18.0
@export_range(0.0, 80.0, 1.0) var npc_initial_age_max := 32.0
@export_range(10.0, 120.0, 1.0) var npc_lifespan_min_years := 52.0
@export_range(10.0, 140.0, 1.0) var npc_lifespan_max_years := 74.0
@export_range(0.5, 0.95, 0.01) var npc_old_age_factor := 0.78
@export_range(0.1, 5.0, 0.05) var npc_hunger_decay := 0.68
@export_range(0.1, 5.0, 0.05) var npc_thirst_decay := 1.05
@export_range(10.0, 100.0, 1.0) var npc_hunger_restore := 42.0
@export_range(10.0, 100.0, 1.0) var npc_thirst_restore := 62.0
@export_range(0, 12, 1) var mega_boulder_count := 3
@export_range(2.0, 40.0, 0.5) var mega_boulder_spawn_interval := 6.0
@export_range(0, 12, 1) var worms_per_month := 3
@export_range(1, 12, 1) var worm_meat_drop_amount := 4

@onready var terrain_layer: TileMapLayer = $TerrainLayer
@onready var objects_root: Node2D = $Objects
@onready var characters_root: Node2D = $Characters
@onready var camera: Camera2D = $Camera2D
@onready var info_label: Label = $CanvasLayer/PanelContainer/MarginContainer/Label
@onready var npc_card_panel: PanelContainer = $CanvasLayer/NpcCard
@onready var npc_card_label: Label = $CanvasLayer/NpcCard/MarginContainer/Label

var _current_seed := 0
var _terrain_grid: Array = []
var _human_texture: Texture2D
var _leader_texture: Texture2D
var _fishing_texture: Texture2D
var _human_hurt_texture: Texture2D
var _worm_texture: Texture2D
var _worm_hurt_texture: Texture2D
var _worm_frames: SpriteFrames
var _human_frames: SpriteFrames
var _leader_frames: SpriteFrames
var _bungalow_texture: Texture2D
var _house_level_2_texture: Texture2D
var _free_house_sign_texture: Texture2D
var _farm_barn_texture: Texture2D
var _warehouse_level_1_texture: Texture2D
var _warehouse_level_2_texture: Texture2D
var _apple_texture: Texture2D
var _berry_texture: Texture2D
var _worm_meat_texture: Texture2D
var _loot_bag_texture: Texture2D
var _sapling_texture: Texture2D
var _mega_boulder_texture: Texture2D
var _tilled_soil_texture: Texture2D
var _seeded_soil_texture: Texture2D
var _crate_empty_texture: Texture2D
var _crate_full_texture: Texture2D
var _crate_level_2_empty_texture: Texture2D
var _crate_level_2_full_texture: Texture2D
var _dead_body_texture: Texture2D
var _dead_body_frames: SpriteFrames
var _tree_nodes: Dictionary = {}
var _tree_claims: Dictionary = {}
var _tree_food: Dictionary = {}
var _tree_regrow_timers: Dictionary = {}
var _sapling_nodes: Dictionary = {}
var _sapling_growth_timers: Dictionary = {}
var _bush_nodes: Dictionary = {}
var _bush_food: Dictionary = {}
var _bush_empty_timers: Dictionary = {}
var _food_claims: Dictionary = {}
var _rock_nodes: Dictionary = {}
var _rock_claims: Dictionary = {}
var _rock_respawn_timers: Dictionary = {}
var _mega_boulder_nodes: Dictionary = {}
var _mega_boulder_timers: Dictionary = {}
var _farm_plot_nodes: Dictionary = {}
var _farm_plot_states: Dictionary = {}
var _farm_growth_timers: Dictionary = {}
var _farm_claims: Dictionary = {}
var _farm_barn_nodes: Dictionary = {}
var _farm_barn_claims: Dictionary = {}
var _farm_barn_food := 0
var _farm_barn_berry_stock := 0
var _farm_barn_food_claims: Dictionary = {}
var _warehouse_nodes: Dictionary = {}
var _warehouse_claims: Dictionary = {}
var _warehouse_levels: Dictionary = {}
var _warehouse_wood := 0
var _warehouse_stone := 0
var _house_nodes: Dictionary = {}
var _house_claims: Dictionary = {}
var _vacant_house_claims: Dictionary = {}
var _house_levels: Dictionary = {}
var _house_owner_by_cell: Dictionary = {}
var _house_children_born: Dictionary = {}
var _house_crate_cells: Dictionary = {}
var _free_house_sign_nodes: Dictionary = {}
var _crate_nodes: Dictionary = {}
var _crate_claims: Dictionary = {}
var _crate_food: Dictionary = {}
var _crate_berry_stock: Dictionary = {}
var _crate_levels: Dictionary = {}
var _crate_home_cells: Dictionary = {}
var _loot_bag_nodes: Dictionary = {}
var _loot_bag_items: Dictionary = {}
var _loot_bag_claims: Dictionary = {}
var _worms: Dictionary = {}
var _worm_cells: Dictionary = {}
var _worm_meat_nodes: Dictionary = {}
var _worm_meat_food: Dictionary = {}
var _fishing_claims: Dictionary = {}
var _npc_home_cells: Dictionary = {}
var _npc_crate_cells: Dictionary = {}
var _npc_spawn_cells: Dictionary = {}
var _wanderers: Dictionary = {}
var _corpse_decay_timers: Dictionary = {}
var _selected_npc: Node2D
var _selected_structure_type := ""
var _selected_structure_cell := INVALID_CELL
var _camera_follow_npc: Node2D
var _next_npc_id := 0
var _reproduction_check_timer := REPRODUCTION_CHECK_INTERVAL
var _runtime_rng := RandomNumberGenerator.new()
var _mouse_left_was_down := false
var _key_o_was_down := false
var _key_f1_was_down := false
var _key_p_was_down := false
var _calendar_elapsed := 0.0
var _calendar_day_index := 0
var _dev_panel: PanelContainer
var _dev_hint_label: Label
var _dev_controls: Dictionary = {}
var _death_log_panel: PanelContainer
var _death_log_label: Label
var _death_log_entries: Array[String] = []
var _leader_npc_id := -1
var _leader_election_active := false
var _leader_election_timer := 0.0
var _leader_rally_cell := INVALID_CELL
var _settlement_center_cell := INVALID_CELL
var _leader_role_timer := 0.0
var _next_worm_id := 0
var _last_worm_spawn_month := -1
var _combat_system
var _defense_system
var _entity_index
var _navigation_service
var _death_log_ui
var _tree_index
var _food_index
var _rock_index
var _loot_bag_index
var _shore_cell_index
var _near_water_cells: Dictionary = {}
var _leader_role_planner
var _leader_role_plan_revision := 0
var _combat_wanderers_cache: Array = []
var _combat_worms_cache: Array = []
var _combat_cache_dirty := true
var _ui_refresh_timer := 0.0
var _elevation_noise := FastNoiseLite.new()
var _continent_noise := FastNoiseLite.new()
var _lake_noise := FastNoiseLite.new()
var _moisture_noise := FastNoiseLite.new()
var _heat_noise := FastNoiseLite.new()
var _flora_noise := FastNoiseLite.new()
var _rock_noise := FastNoiseLite.new()
var _variation_noise := FastNoiseLite.new()
var _month_names := [
	"Снеговей",
	"Талник",
	"Первоцвет",
	"Светолуг",
	"Травень",
	"Солнечник",
	"Жарник",
	"Спелень",
	"Листодар",
	"Ветродуй",
	"Сумерень",
	"Стужник",
]


func _ready() -> void:
	terrain_layer.tile_set = _build_tile_set()
	terrain_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	objects_root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	characters_root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	npc_card_panel.visible = false
	_load_human_frames()
	_load_structure_textures()
	_load_crate_textures()
	_load_resource_textures()
	_load_farming_textures()
	_load_dead_body_frames()
	_entity_index = ENTITY_INDEX_SCRIPT.new()
	_navigation_service = NAVIGATION_SERVICE_SCRIPT.new()
	_tree_index = SPATIAL_HASH_2D_SCRIPT.new(10)
	_food_index = SPATIAL_HASH_2D_SCRIPT.new(10)
	_rock_index = SPATIAL_HASH_2D_SCRIPT.new(10)
	_loot_bag_index = SPATIAL_HASH_2D_SCRIPT.new(8)
	_shore_cell_index = SPATIAL_HASH_2D_SCRIPT.new(12)
	_leader_role_planner = LEADER_ROLE_PLANNER_SCRIPT.new()
	_combat_system = COMBAT_SYSTEM_SCRIPT.new()
	_defense_system = DEFENSE_SYSTEM_SCRIPT.new()
	_build_dev_panel()
	_build_death_log_panel()
	generate_world()


func _process(delta: float) -> void:
	var direction := Vector2.ZERO
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	direction.x += float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	direction.y += float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))

	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	camera.position += direction * camera_speed * delta / camera.zoom.x
	_update_camera_follow(delta)
	_clamp_camera()
	_advance_calendar(delta)
	_update_corpse_decay(delta)
	_update_world_regrowth(delta)
	_update_leader_system(delta)
	_update_defense_system(delta)
	_update_combat_system(delta)

	var left_mouse_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if left_mouse_down and not _mouse_left_was_down:
		_try_select_npc_at(get_global_mouse_position())
	_mouse_left_was_down = left_mouse_down

	_reproduction_check_timer -= delta
	if _reproduction_check_timer <= 0.0:
		_reproduction_check_timer = REPRODUCTION_CHECK_INTERVAL
		_process_reproduction()
	_ui_refresh_timer -= delta
	if _ui_refresh_timer <= 0.0:
		_ui_refresh_timer = 0.2
		_update_npc_card()
		_update_info_label()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			seed_value = 0
			generate_world()
		elif event.keycode == KEY_F1:
			_toggle_dev_panel()
		elif event.keycode == KEY_P:
			_toggle_death_log()
		elif event.keycode == KEY_O:
			_close_npc_card()
		elif event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			_change_zoom(-0.12)
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			_change_zoom(0.12)

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_select_npc_at(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_cancel_camera_follow()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_change_zoom(-0.08)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_change_zoom(0.08)


func generate_world() -> void:
	var rng := RandomNumberGenerator.new()
	_current_seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system()) ^ int(Time.get_ticks_usec())
	rng.seed = _current_seed
	_runtime_rng.seed = _current_seed + 911
	_next_npc_id = 0
	_next_worm_id = 0
	_reproduction_check_timer = REPRODUCTION_CHECK_INTERVAL
	_selected_npc = null
	_camera_follow_npc = null
	_mouse_left_was_down = false
	_key_o_was_down = false
	_key_p_was_down = false
	_calendar_elapsed = 0.0
	_calendar_day_index = 0
	_leader_npc_id = -1
	_leader_election_active = false
	_leader_election_timer = 0.0
	_leader_rally_cell = INVALID_CELL
	_settlement_center_cell = INVALID_CELL
	_leader_role_timer = leader_role_check_interval
	_leader_role_plan_revision = 0
	_last_worm_spawn_month = 0
	_ui_refresh_timer = 0.0
	npc_card_panel.visible = false
	if _death_log_ui != null:
		_death_log_ui.hide()
	elif _death_log_panel != null:
		_death_log_panel.visible = false

	_configure_noises()
	_clear_objects()
	terrain_layer.clear()

	_terrain_grid = _generate_terrain_grid()
	_draw_terrain(_terrain_grid)
	_spawn_decorations(_terrain_grid, rng)
	_rebuild_static_spatial_data()

	var focus_cell := _find_best_view_cell(_terrain_grid)
	_settlement_center_cell = focus_cell
	_spawn_mega_boulders(rng, focus_cell)
	_spawn_characters(rng, focus_cell)
	_mark_combat_cache_dirty()
	camera.position = _cell_center(focus_cell)
	camera.reset_smoothing()
	_clamp_camera()
	_update_info_label()


func _build_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = TILE_SIZE
	_add_tile_source(tile_set, WATER_SOURCE_ID, WATER_TEXTURE)
	_add_tile_source(tile_set, GRASS_SOURCE_ID, GRASS_TEXTURE)
	_add_tile_source(tile_set, DESERT_SOURCE_ID, DESERT_TEXTURE)
	return tile_set


func _add_tile_source(tile_set: TileSet, source_id: int, texture: Texture2D) -> void:
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = TILE_SIZE
	source.create_tile(Vector2i.ZERO)
	tile_set.add_source(source, source_id)


func _configure_noises() -> void:
	_continent_noise.seed = _current_seed
	_continent_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_continent_noise.frequency = 0.0056
	_continent_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_continent_noise.fractal_octaves = 4
	_continent_noise.fractal_gain = 0.52

	_elevation_noise.seed = _current_seed + 101
	_elevation_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_elevation_noise.frequency = 0.012
	_elevation_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_elevation_noise.fractal_octaves = 4
	_elevation_noise.fractal_gain = 0.54

	_lake_noise.seed = _current_seed + 203
	_lake_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_lake_noise.frequency = 0.0105
	_lake_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_lake_noise.fractal_octaves = 3

	_moisture_noise.seed = _current_seed + 307
	_moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_moisture_noise.frequency = 0.008
	_moisture_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_moisture_noise.fractal_octaves = 4

	_heat_noise.seed = _current_seed + 401
	_heat_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_heat_noise.frequency = 0.0072
	_heat_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_heat_noise.fractal_octaves = 3

	_flora_noise.seed = _current_seed + 503
	_flora_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_flora_noise.frequency = 0.034

	_rock_noise.seed = _current_seed + 607
	_rock_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_rock_noise.frequency = 0.045

	_variation_noise.seed = _current_seed + 701
	_variation_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_variation_noise.frequency = 0.016


func _generate_terrain_grid() -> Array:
	var land_mask := _generate_land_mask()
	land_mask = _smooth_land_mask(land_mask, 2)
	_replace_small_regions(land_mask, 1, 55, 0)
	_replace_small_regions(land_mask, 0, 40, 1)
	land_mask = _smooth_land_mask(land_mask, 1)

	var terrain_grid := _assign_biomes(land_mask)
	terrain_grid = _smooth_biomes(terrain_grid, 2)
	_replace_small_regions(terrain_grid, TerrainType.DESERT, 70, TerrainType.GRASS)
	_green_shores(terrain_grid)
	return terrain_grid


func _generate_land_mask() -> Array:
	var grid := _make_grid(0)

	for y in range(map_height):
		for x in range(map_width):
			var elevation := _sample_land_value(x, y)
			grid[y][x] = 1 if elevation > 0.44 else 0

	return grid


func _sample_land_value(x: int, y: int) -> float:
	var fx := float(x)
	var fy := float(y)
	var continents := _noise01(_continent_noise, fx, fy)
	var elevation_detail := _noise01(_elevation_noise, fx + 380.0, fy - 220.0)
	var broad_variation := _noise01(_variation_noise, fx - 920.0, fy + 610.0)
	var lake_shape := _noise01(_lake_noise, fx + 1300.0, fy - 470.0)

	var nx := fx / float(max(map_width - 1, 1)) * 2.0 - 1.0
	var ny := fy / float(max(map_height - 1, 1)) * 2.0 - 1.0
	var edge_falloff := smoothstep(0.64, 1.08, max(absf(nx) * 0.92, absf(ny) * 0.88))

	var elevation := continents * 0.58 + elevation_detail * 0.27 + broad_variation * 0.15
	elevation -= edge_falloff * 0.16

	var lake_cut := clampf((0.18 - lake_shape) / 0.18, 0.0, 1.0)
	elevation -= lake_cut * 0.20
	return elevation


func _assign_biomes(land_mask: Array) -> Array:
	var terrain_grid := _make_grid(TerrainType.WATER)

	for y in range(map_height):
		for x in range(map_width):
			if land_mask[y][x] == 0:
				continue

			var fx := float(x)
			var fy := float(y)
			var moisture := _noise01(_moisture_noise, fx + 500.0, fy - 320.0)
			var heat := _noise01(_heat_noise, fx - 240.0, fy + 410.0)
			var latitude_heat := 1.0 - absf((fy / float(max(map_height - 1, 1))) * 2.0 - 1.0) * 0.34
			var broad_variation := _noise01(_variation_noise, fx + 1450.0, fy + 900.0)
			var dryness := (heat * 0.46) + ((1.0 - moisture) * 0.39) + (latitude_heat * 0.08) + (broad_variation * 0.07)

			if _count_neighbors(land_mask, x, y, 0) > 0:
				dryness -= 0.09

			terrain_grid[y][x] = TerrainType.DESERT if dryness > 0.62 else TerrainType.GRASS

	return terrain_grid


func _smooth_land_mask(grid: Array, iterations: int) -> Array:
	var result := _clone_grid(grid)

	for _iteration in range(iterations):
		var next_grid := _clone_grid(result)

		for y in range(map_height):
			for x in range(map_width):
				var land_neighbors := _count_neighbors(result, x, y, 1)
				if result[y][x] == 1:
					next_grid[y][x] = 1 if land_neighbors >= 3 else 0
				else:
					next_grid[y][x] = 1 if land_neighbors >= 5 else 0

		result = next_grid

	return result


func _smooth_biomes(grid: Array, iterations: int) -> Array:
	var result := _clone_grid(grid)

	for _iteration in range(iterations):
		var next_grid := _clone_grid(result)

		for y in range(map_height):
			for x in range(map_width):
				if result[y][x] == TerrainType.WATER:
					continue

				var desert_neighbors := _count_neighbors(result, x, y, TerrainType.DESERT)
				var grass_neighbors := _count_neighbors(result, x, y, TerrainType.GRASS)

				if result[y][x] == TerrainType.DESERT and grass_neighbors >= 5:
					next_grid[y][x] = TerrainType.GRASS
				elif result[y][x] == TerrainType.GRASS and desert_neighbors >= 6:
					next_grid[y][x] = TerrainType.DESERT

		result = next_grid

	return result


func _green_shores(grid: Array) -> void:
	for y in range(map_height):
		for x in range(map_width):
			if grid[y][x] != TerrainType.DESERT:
				continue

			var water_neighbors := _count_neighbors(grid, x, y, TerrainType.WATER)
			if water_neighbors >= 2:
				grid[y][x] = TerrainType.GRASS


func _draw_terrain(terrain_grid: Array) -> void:
	for y in range(map_height):
		for x in range(map_width):
			var terrain_type := int(terrain_grid[y][x])
			terrain_layer.set_cell(Vector2i(x, y), _terrain_source_id(terrain_type), Vector2i.ZERO)


func _spawn_decorations(terrain_grid: Array, rng: RandomNumberGenerator) -> void:
	var occupied := _make_grid(0)
	_tree_nodes.clear()
	_tree_claims.clear()
	_tree_food.clear()
	_tree_regrow_timers.clear()
	_sapling_nodes.clear()
	_sapling_growth_timers.clear()
	_bush_nodes.clear()
	_bush_food.clear()
	_bush_empty_timers.clear()
	_food_claims.clear()
	_rock_nodes.clear()
	_rock_claims.clear()
	_rock_respawn_timers.clear()
	_mega_boulder_nodes.clear()
	_mega_boulder_timers.clear()
	_farm_plot_nodes.clear()
	_farm_plot_states.clear()
	_farm_growth_timers.clear()
	_farm_claims.clear()
	_farm_barn_nodes.clear()
	_farm_barn_claims.clear()
	_farm_barn_food_claims.clear()
	_farm_barn_food = 0
	_farm_barn_berry_stock = 0
	_warehouse_nodes.clear()
	_warehouse_claims.clear()
	_warehouse_levels.clear()
	_warehouse_wood = 0
	_warehouse_stone = 0
	_house_nodes.clear()
	_house_claims.clear()
	_vacant_house_claims.clear()
	_house_levels.clear()
	_house_owner_by_cell.clear()
	_house_children_born.clear()
	_house_crate_cells.clear()
	_free_house_sign_nodes.clear()
	_crate_nodes.clear()
	_crate_claims.clear()
	_crate_food.clear()
	_crate_berry_stock.clear()
	_crate_levels.clear()
	_crate_home_cells.clear()
	_loot_bag_nodes.clear()
	_loot_bag_items.clear()
	_loot_bag_claims.clear()
	_worms.clear()
	_worm_meat_nodes.clear()
	_worm_meat_food.clear()
	_fishing_claims.clear()
	_near_water_cells.clear()
	_npc_home_cells.clear()
	_npc_crate_cells.clear()
	_npc_spawn_cells.clear()
	_corpse_decay_timers.clear()

	for y in range(map_height):
		for x in range(map_width):
			var terrain_type := int(terrain_grid[y][x])
			if terrain_type == TerrainType.WATER:
				continue

			var fx := float(x)
			var fy := float(y)
			var moisture := _noise01(_moisture_noise, fx + 500.0, fy - 320.0)
			var flora := _noise01(_flora_noise, fx - 150.0, fy + 210.0)
			var rockiness := _noise01(_rock_noise, fx + 910.0, fy + 620.0)
			var water_neighbors := _count_neighbors(terrain_grid, x, y, TerrainType.WATER)

			if terrain_type == TerrainType.GRASS:
				var tree_score := flora * 0.70 + moisture * 0.30 + minf(float(water_neighbors) * 0.03, 0.12)
				if tree_score > 0.57 and rng.randf() < minf(0.24 * tree_density_multiplier, 0.92) and _is_area_free(occupied, x, y, 1):
					_place_tree(Vector2i(x, y), rng)
					_mark_area(occupied, x, y, 1)
				elif (flora > 0.60 or water_neighbors >= 1) and rng.randf() < minf(0.10 * bush_density_multiplier, 0.86) and _is_area_free(occupied, x, y, 1):
					_place_bush(Vector2i(x, y), rng)
					_mark_area(occupied, x, y, 1)
				elif rockiness > 0.72 and rng.randf() < minf(0.10 * rock_density_multiplier, 0.88) and _is_area_free(occupied, x, y, 1):
					_place_rock(Vector2i(x, y), rng, 0.86, 1.06)
					_mark_area(occupied, x, y, 1)
			else:
				var cactus_score := flora * 0.55 + rockiness * 0.15
				if cactus_score > 0.47 and rng.randf() < 0.11 and _is_area_free(occupied, x, y, 2):
					_place_object(CACTUS_TEXTURE, Vector2i(x, y), rng, 0.94, 1.14)
					_mark_area(occupied, x, y, 2)
				elif rockiness > 0.66 and rng.randf() < minf(0.13 * rock_density_multiplier, 0.92) and _is_area_free(occupied, x, y, 1):
					_place_rock(Vector2i(x, y), rng, 0.9, 1.12)
					_mark_area(occupied, x, y, 1)


func _place_tree(cell: Vector2i, rng: RandomNumberGenerator) -> void:
	var tree := _place_object(TREE_TEXTURE, cell, rng, 0.95, 1.15)
	_tree_nodes[cell] = tree
	_tree_food[cell] = rng.randi_range(1, 4)
	if _tree_index != null:
		_tree_index.insert(cell)
	_sync_food_spatial_index(cell)
	_refresh_tree_food_visual(cell)
	_clear_path_cache()


func _place_bush(cell: Vector2i, rng: RandomNumberGenerator) -> void:
	var bush := _place_object(BUSH_TEXTURE, cell, rng, 0.92, 1.08)
	_bush_nodes[cell] = bush
	_bush_food[cell] = rng.randi_range(5, 15)
	_bush_empty_timers.erase(cell)
	_sync_food_spatial_index(cell)
	_refresh_bush_food_visual(cell)


func _place_rock(cell: Vector2i, rng: RandomNumberGenerator, min_scale: float, max_scale: float) -> void:
	var rock := _place_object(ROCK_TEXTURE, cell, rng, min_scale, max_scale)
	_rock_nodes[cell] = rock
	if _rock_index != null:
		_rock_index.insert(cell)


func _spawn_mega_boulders(rng: RandomNumberGenerator, focus_cell: Vector2i) -> void:
	if _mega_boulder_texture == null or mega_boulder_count <= 0:
		return

	var placed := 0
	var near_settlement := _find_mega_boulder_cell_near(focus_cell, 14)
	if near_settlement != INVALID_CELL:
		_place_mega_boulder(near_settlement)
		placed += 1

	while placed < mega_boulder_count:
		var random_cell := _find_mega_boulder_cell_near(Vector2i(rng.randi_range(6, map_width - 7), rng.randi_range(6, map_height - 7)), 28)
		if random_cell == INVALID_CELL:
			break
		if _mega_boulder_nodes.has(random_cell):
			break
		_place_mega_boulder(random_cell)
		placed += 1


func _find_mega_boulder_cell_near(origin_cell: Vector2i, radius: int) -> Vector2i:
	for search_radius in [maxi(6, radius), maxi(10, radius + 6), maxi(16, radius + 12)]:
		for y in range(max(origin_cell.y - search_radius, 3), min(origin_cell.y + search_radius, map_height - 4) + 1):
			for x in range(max(origin_cell.x - search_radius, 3), min(origin_cell.x + search_radius, map_width - 4) + 1):
				var cell := Vector2i(x, y)
				if not _is_valid_mega_boulder_cell(cell):
					continue
				if cell.distance_to(origin_cell) > float(search_radius):
					continue
				return cell
	return INVALID_CELL


func _is_valid_mega_boulder_cell(cell: Vector2i) -> bool:
	if not _is_inside(cell.x, cell.y):
		return false
	if _terrain_grid[cell.y][cell.x] != TerrainType.GRASS:
		return false
	if is_cell_near_water(cell):
		return false
	if _tree_nodes.has(cell) or _bush_nodes.has(cell) or _rock_nodes.has(cell) or _sapling_nodes.has(cell):
		return false
	if _house_nodes.has(cell) or _crate_nodes.has(cell) or _farm_plot_nodes.has(cell):
		return false
	for mega_cell in _mega_boulder_nodes.keys():
		if cell.distance_to(Vector2i(mega_cell)) < 10.0:
			return false
	return true


func _place_mega_boulder(cell: Vector2i) -> void:
	var mega := Sprite2D.new()
	mega.texture = _mega_boulder_texture
	mega.centered = true
	mega.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mega.position = _cell_center(cell) + Vector2(0.0, -10.0)
	mega.scale = Vector2.ONE * 1.22
	objects_root.add_child(mega)

	_mega_boulder_nodes[cell] = mega
	_mega_boulder_timers[cell] = mega_boulder_spawn_interval


func _count_rocks_around_mega_boulder(mega_cell: Vector2i) -> int:
	return _rock_index.count_in_radius(mega_cell, 2) if _rock_index != null else 0


func _spawn_rock_from_mega_boulder(mega_cell: Vector2i) -> void:
	for direction in EIGHT_DIRS:
		var rock_cell: Vector2i = mega_cell + Vector2i(direction)
		if not _can_respawn_rock(rock_cell):
			continue
		_place_rock(rock_cell, _runtime_rng, 0.9, 1.08)
		return


func _place_object(texture: Texture2D, cell: Vector2i, rng: RandomNumberGenerator, min_scale: float, max_scale: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * rng.randf_range(min_scale, max_scale)
	sprite.flip_h = rng.randf() < 0.5
	sprite.position = Vector2(cell * TILE_SIZE) + Vector2(rng.randf_range(-6.0, 6.0), rng.randf_range(-4.0, 8.0))
	objects_root.add_child(sprite)
	return sprite


func _refresh_tree_food_visual(cell: Vector2i) -> void:
	_refresh_attached_food_visual(
		_tree_nodes.get(cell, null),
		int(_tree_food.get(cell, 0)),
		_apple_texture,
		Vector2(14.0, 8.0),
		Vector2(50.0, 30.0),
		0.9,
		1.05
	)


func _refresh_bush_food_visual(cell: Vector2i) -> void:
	_refresh_attached_food_visual(
		_bush_nodes.get(cell, null),
		int(_bush_food.get(cell, 0)),
		_berry_texture,
		Vector2(10.0, 16.0),
		Vector2(52.0, 42.0),
		0.8,
		0.95
	)


func _refresh_attached_food_visual(host, amount: int, texture: Texture2D, min_offset: Vector2, max_offset: Vector2, min_scale: float, max_scale: float) -> void:
	if host == null or not is_instance_valid(host):
		return

	var holder: Node2D = null
	if host.has_meta("food_holder"):
		holder = host.get_meta("food_holder") as Node2D
	if holder == null or not is_instance_valid(holder):
		holder = Node2D.new()
		holder.name = "FoodHolder"
		host.add_child(holder)
		host.set_meta("food_holder", holder)

	for child in holder.get_children():
		child.queue_free()

	if texture == null or amount <= 0:
		return

	var visible_amount := mini(amount, 4)
	for _index in range(visible_amount):
		var food_sprite := Sprite2D.new()
		food_sprite.texture = texture
		food_sprite.centered = true
		food_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		food_sprite.position = Vector2(
			_runtime_rng.randf_range(min_offset.x, max_offset.x),
			_runtime_rng.randf_range(min_offset.y, max_offset.y)
		)
		food_sprite.scale = Vector2.ONE * _runtime_rng.randf_range(min_scale, max_scale)
		holder.add_child(food_sprite)


func _spawn_characters(rng: RandomNumberGenerator, focus_cell: Vector2i) -> void:
	if _human_frames == null:
		return

	var used_cells := []

	for _npc_index in range(INITIAL_NPC_COUNT):
		var spawn_cell := _find_character_spawn_cell(rng, used_cells, focus_cell)
		if spawn_cell == INVALID_CELL:
			continue

		used_cells.append(spawn_cell)
		_spawn_wanderer(spawn_cell, _next_npc_id, rng.randf_range(npc_initial_age_min, npc_initial_age_max))
		_next_npc_id += 1

	_apply_balance_config_to_wanderers()


func _spawn_wanderer(spawn_cell: Vector2i, npc_id: int, initial_age_years: float = -1.0) -> Node2D:
	_npc_spawn_cells[npc_id] = spawn_cell

	var wanderer := Node2D.new()
	wanderer.set_script(WANDERER_SCRIPT)
	wanderer.name = "Wanderer%d" % npc_id
	wanderer.set_meta("npc_id", npc_id)

	var animated_sprite := AnimatedSprite2D.new()
	animated_sprite.centered = true
	animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	animated_sprite.sprite_frames = _human_frames
	animated_sprite.position = Vector2(0.0, -18.0)
	animated_sprite.scale = Vector2.ONE * 1.3
	wanderer.add_child(animated_sprite)

	characters_root.add_child(wanderer)
	_wanderers[npc_id] = wanderer
	_mark_combat_cache_dirty()
	wanderer.call("setup", spawn_cell, self, _current_seed, npc_id, initial_age_years)
	register_npc_cell(npc_id, spawn_cell)
	wanderer.call("apply_balance_config", _get_npc_balance_config())
	return wanderer


func _get_npc_balance_config() -> Dictionary:
	return {
		"move_speed": npc_move_speed,
		"hunger_decay_per_second": npc_hunger_decay,
		"thirst_decay_per_second": npc_thirst_decay,
		"hunger_restore_amount": npc_hunger_restore,
		"thirst_restore_amount": npc_thirst_restore,
		"travel_food_distance": npc_travel_food_distance,
		"stuck_timeout": npc_stuck_timeout,
		"old_age_factor": npc_old_age_factor,
	}


func _update_combat_system(delta: float) -> void:
	if _combat_system == null:
		return
	_cleanup_worms()
	_combat_system.update(delta, _wanderers, _worms, _entity_index)


func _update_defense_system(delta: float) -> void:
	if _defense_system == null:
		return
	_cleanup_worms()
	_defense_system.update(delta, _leader_npc_id, _wanderers, _worms, get_settlement_center_cell())


func _get_combat_wanderers() -> Array:
	if _combat_cache_dirty:
		_combat_wanderers_cache.clear()
		for wanderer in _wanderers.values():
			if is_instance_valid(wanderer):
				_combat_wanderers_cache.append(wanderer)
	return _combat_wanderers_cache


func _get_combat_worms() -> Array:
	if _combat_cache_dirty:
		_combat_worms_cache.clear()
		for worm in _worms.values():
			if is_instance_valid(worm):
				_combat_worms_cache.append(worm)
		_combat_cache_dirty = false
	return _combat_worms_cache


func _clear_path_cache() -> void:
	if _navigation_service != null:
		_navigation_service.clear_cache()


func _mark_combat_cache_dirty() -> void:
	_combat_cache_dirty = true


func _rebuild_static_spatial_data() -> void:
	_near_water_cells.clear()
	if _shore_cell_index != null:
		_shore_cell_index.clear()
	for y in range(1, map_height - 1):
		for x in range(1, map_width - 1):
			if _terrain_grid[y][x] == TerrainType.WATER:
				continue
			if _count_neighbors(_terrain_grid, x, y, TerrainType.WATER) <= 0:
				continue
			var cell := Vector2i(x, y)
			_near_water_cells[cell] = true
			if _shore_cell_index != null:
				_shore_cell_index.insert(cell)


func _sync_food_spatial_index(cell: Vector2i) -> void:
	if _food_index == null:
		return
	var has_food := int(_tree_food.get(cell, 0)) > 0 or int(_bush_food.get(cell, 0)) > 0 or int(_worm_meat_food.get(cell, 0)) > 0
	if has_food:
		_food_index.insert(cell)
	else:
		_food_index.remove(cell)


func _apply_balance_config_to_wanderers() -> void:
	var config := _get_npc_balance_config()
	for wanderer in _wanderers.values():
		if is_instance_valid(wanderer):
			wanderer.call("apply_balance_config", config)


func _find_character_spawn_cell(rng: RandomNumberGenerator, used_cells: Array, focus_cell: Vector2i) -> Vector2i:
	for radius in [8, 12, 18, 28]:
		for _attempt in range(120):
			var cell := Vector2i(
				clampi(focus_cell.x + rng.randi_range(-radius, radius), 2, map_width - 3),
				clampi(focus_cell.y + rng.randi_range(-radius, radius), 2, map_height - 3)
			)

			if not _is_valid_character_spawn(cell, used_cells):
				continue

			return cell

	for _attempt in range(500):
		var fallback_cell := Vector2i(rng.randi_range(2, map_width - 3), rng.randi_range(2, map_height - 3))
		if _is_valid_character_spawn(fallback_cell, used_cells):
			return fallback_cell

	return INVALID_CELL


func _is_valid_character_spawn(cell: Vector2i, used_cells: Array) -> bool:
	if _terrain_grid[cell.y][cell.x] == TerrainType.WATER:
		return false
	if _count_neighbors(_terrain_grid, cell.x, cell.y, TerrainType.WATER) > 0:
		return false
	if _tree_nodes.has(cell) or _bush_nodes.has(cell) or _rock_nodes.has(cell):
		return false
	if _mega_boulder_nodes.has(cell):
		return false

	for used_cell in used_cells:
		if cell.distance_to(used_cell) < 5.0:
			return false

	return true


func _process_reproduction() -> void:
	_cleanup_wanderers()
	if _wanderers.size() >= max_npc_count:
		return

	for wanderer in _wanderers.values():
		if not is_instance_valid(wanderer):
			continue
		if not bool(wanderer.call("can_reproduce")):
			continue

		var parent_id := int(wanderer.call("get_npc_id"))
		var home_cell := get_home_cell(parent_id)
		if home_cell == INVALID_CELL:
			continue
		if get_crate_food_amount(parent_id) < get_food_crate_capacity(parent_id):
			continue

		var child_cell := _find_child_spawn_cell(home_cell)
		if child_cell == INVALID_CELL:
			continue
		if consume_food_from_crate(parent_id, reproduction_food_cost) < reproduction_food_cost:
			continue

		wanderer.call("notify_reproduction")
		_house_children_born[home_cell] = int(_house_children_born.get(home_cell, 0)) + 1
		_spawn_wanderer(child_cell, _next_npc_id, _runtime_rng.randf_range(maxf(16.0, npc_initial_age_min), maxf(20.0, minf(npc_initial_age_max, 24.0))))
		_next_npc_id += 1
		return


func _update_leader_system(delta: float) -> void:
	_cleanup_wanderers()

	if _leader_npc_id != -1:
		var leader: Node2D = _wanderers.get(_leader_npc_id, null)
		if leader == null or not is_instance_valid(leader):
			_leader_npc_id = -1

	_poll_role_plan_result()

	if not _leader_election_active and _leader_npc_id == -1 and _wanderers.size() >= chief_population_threshold:
		_begin_leader_election()

	if _leader_election_active:
		_leader_election_timer -= delta
		if _leader_election_timer <= 0.0:
			_finish_leader_election()
		return

	if _leader_npc_id == -1:
		return

	_leader_role_timer -= delta
	if _leader_role_timer <= 0.0:
		_leader_role_timer = _get_dynamic_role_update_interval()
		_request_role_plan()


func _begin_leader_election() -> void:
	_leader_election_active = true
	_leader_election_timer = chief_election_duration
	_leader_role_timer = leader_role_check_interval
	_leader_rally_cell = _find_leader_rally_cell()
	for npc_id in _wanderers.keys():
		var wanderer: Node2D = _wanderers[npc_id]
		if is_instance_valid(wanderer):
			wanderer.call("set_election_state", true, _leader_rally_cell)


func _finish_leader_election() -> void:
	_leader_election_active = false
	var richest_id := _find_richest_npc_id()
	_set_leader_npc(richest_id)
	_request_role_plan()
	for npc_id in _wanderers.keys():
		var wanderer: Node2D = _wanderers[npc_id]
		if is_instance_valid(wanderer):
			wanderer.call("set_election_state", false, INVALID_CELL)


func _find_richest_npc_id() -> int:
	var richest_id := -1
	var best_wealth := -INF
	for npc_id in _wanderers.keys():
		var wanderer: Node2D = _wanderers[npc_id]
		if not is_instance_valid(wanderer):
			continue
		var wealth := float(wanderer.call("get_wealth_score"))
		if wealth > best_wealth:
			best_wealth = wealth
			richest_id = int(npc_id)
	return richest_id


func _set_leader_npc(npc_id: int) -> void:
	if _leader_role_planner != null:
		_leader_role_planner.shutdown()
	for other_id in _wanderers.keys():
		var wanderer: Node2D = _wanderers[other_id]
		if is_instance_valid(wanderer):
			wanderer.call("set_leader_state", int(other_id) == npc_id)
			if _human_frames != null:
				var sprite := wanderer.get_child(0) as AnimatedSprite2D
				if sprite != null:
					sprite.sprite_frames = _leader_frames if int(other_id) == npc_id and _leader_frames != null else _human_frames

	_leader_npc_id = npc_id


func _find_leader_rally_cell() -> Vector2i:
	for barn_cell in _farm_barn_nodes.keys():
		_settlement_center_cell = barn_cell
		return barn_cell
	for cell in _house_nodes.keys():
		_settlement_center_cell = cell
		return cell
	if _settlement_center_cell != INVALID_CELL:
		return _settlement_center_cell
	_settlement_center_cell = _find_best_view_cell(_terrain_grid)
	return _settlement_center_cell


func is_leader_election_active() -> bool:
	return _leader_election_active


func get_leader_rally_cell() -> Vector2i:
	return _leader_rally_cell


func get_leader_npc_id() -> int:
	return _leader_npc_id


func get_settlement_center_cell() -> Vector2i:
	if _settlement_center_cell != INVALID_CELL:
		return _settlement_center_cell
	return _find_leader_rally_cell()


func _assign_settlement_roles() -> void:
	_request_role_plan()


func _request_role_plan() -> void:
	if _leader_npc_id == -1 or _leader_role_planner == null:
		return
	if not _wanderers.has(_leader_npc_id):
		return
	if not _leader_role_planner.request_plan(_build_role_plan_payload()):
		return


func _poll_role_plan_result() -> void:
	if _leader_role_planner == null or not _leader_role_planner.has_result():
		return
	var result: Dictionary = _leader_role_planner.consume_result()
	if result.is_empty():
		return
	if int(result.get("revision", -1)) != _leader_role_plan_revision:
		return
	if int(result.get("leader_id", -1)) != _leader_npc_id:
		return
	var desired_roles: Dictionary = result.get("desired_roles", {})
	for npc_id in _wanderers.keys():
		var wanderer: Node2D = _wanderers[npc_id]
		if is_instance_valid(wanderer):
			wanderer.call("set_assigned_role", str(desired_roles.get(int(npc_id), "citizen")))


func _build_role_plan_payload() -> Dictionary:
	_leader_role_plan_revision += 1
	var total_food := get_farm_barn_food_amount()
	var total_wood := get_warehouse_wood_amount()
	var total_stone := get_warehouse_stone_amount()
	var total_berries := get_farm_barn_berry_stock()
	var homeless_count := 0
	var crate_less_count := 0
	var hungry_count := 0
	var thirsty_count := 0
	var injured_count := 0
	var candidates: Array = []

	for food_amount in _crate_food.values():
		total_food += int(food_amount)
	for berry_amount in _crate_berry_stock.values():
		total_berries += int(berry_amount)

	for npc_id in _wanderers.keys():
		var wanderer: Node2D = _wanderers[npc_id]
		if not is_instance_valid(wanderer):
			continue
		var has_home := _npc_home_cells.has(int(npc_id))
		var has_crate := _npc_crate_cells.has(int(npc_id))
		var metrics: Dictionary = wanderer.call("get_role_snapshot", has_home, has_crate)
		total_food += int(metrics.get("carried_food", 0))
		total_wood += int(metrics.get("wood", 0))
		total_stone += int(metrics.get("stone", 0))
		if int(npc_id) == _leader_npc_id:
			continue
		if not has_home:
			homeless_count += 1
		if not has_crate:
			crate_less_count += 1
		if float(metrics.get("hunger", 100.0)) < 55.0:
			hungry_count += 1
		if float(metrics.get("thirst", 100.0)) < 55.0:
			thirsty_count += 1
		if int(metrics.get("hp", 0)) < int(metrics.get("max_hp", 25)):
			injured_count += 1
		candidates.append(metrics)

	return {
		"revision": _leader_role_plan_revision,
		"leader_id": _leader_npc_id,
		"npc_count": _wanderers.size(),
		"total_food": total_food,
		"total_wood": total_wood,
		"total_stone": total_stone,
		"total_berries": total_berries,
		"homeless_count": homeless_count,
		"crate_less_count": crate_less_count,
		"hungry_count": hungry_count,
		"thirsty_count": thirsty_count,
		"injured_count": injured_count,
		"has_farm_barn": has_farm_barn(),
		"farm_barn_count": get_farm_barn_count(),
		"warehouse_count": get_warehouse_count(),
		"warehouse_level": get_warehouse_level(),
		"berry_seed_cost": berry_seed_cost,
		"candidates": candidates,
	}


func _get_dynamic_role_update_interval() -> float:
	if _leader_npc_id == -1:
		return leader_role_check_interval

	var settlement_food := get_farm_barn_food_amount()
	var hungry_count := 0
	var thirsty_count := 0
	for food_amount in _crate_food.values():
		settlement_food += int(food_amount)
	for npc_id in _wanderers.keys():
		var wanderer: Node2D = _wanderers[npc_id]
		if not is_instance_valid(wanderer):
			continue
		var has_home := _npc_home_cells.has(int(npc_id))
		var has_crate := _npc_crate_cells.has(int(npc_id))
		var metrics: Dictionary = wanderer.call("get_role_snapshot", has_home, has_crate)
		settlement_food += int(metrics.get("carried_food", 0))
		if float(metrics.get("hunger", 100.0)) < 45.0:
			hungry_count += 1
		if float(metrics.get("thirst", 100.0)) < 45.0:
			thirsty_count += 1

	if hungry_count > 0 or thirsty_count > 0 or settlement_food < _wanderers.size() * 4:
		return minf(leader_role_check_interval, 0.6)
	return minf(leader_role_check_interval, 1.5)


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


func _npc_should_focus_on_survival(candidate: Dictionary) -> bool:
	if float(candidate.get("hunger", 100.0)) < 38.0:
		return true
	if float(candidate.get("thirst", 100.0)) < 42.0:
		return true
	if float(candidate.get("hp", 25.0)) <= float(candidate.get("max_hp", 25.0)) * 0.45:
		return true
	return false


func _get_role_readiness(status: Dictionary) -> float:
	var hunger := float(status.get("hunger", 100.0))
	var thirst := float(status.get("thirst", 100.0))
	var hp := float(status.get("hp", 25.0))
	var max_hp := maxf(float(status.get("max_hp", 25.0)), 1.0)
	var home_bonus := 12.0 if bool(status.get("has_home", false)) else -8.0
	var crate_bonus := 8.0 if bool(status.get("has_crate", false)) else -6.0
	return hunger * 0.42 + thirst * 0.38 + (hp / max_hp) * 100.0 * 0.2 + home_bonus + crate_bonus


func _count_desired_role(desired_roles: Dictionary, role_name: String) -> int:
	var count := 0
	for value in desired_roles.values():
		if str(value) == role_name:
			count += 1
	return count


func _find_child_spawn_cell(home_cell: Vector2i) -> Vector2i:
	for origin in [home_cell]:
		for radius in [2, 4, 6, 8]:
			for _attempt in range(32):
				var candidate := Vector2i(
					clampi(origin.x + _runtime_rng.randi_range(-radius, radius), 1, map_width - 2),
					clampi(origin.y + _runtime_rng.randi_range(-radius, radius), 1, map_height - 2)
				)
				if _is_valid_child_spawn_cell(candidate):
					return candidate

	return INVALID_CELL


func _is_valid_child_spawn_cell(cell: Vector2i) -> bool:
	if not _can_npc_enter(cell, INVALID_CELL, false):
		return false
	if is_cell_near_water(cell):
		return false
	if _bush_nodes.has(cell) or _rock_nodes.has(cell):
		return false

	for wanderer in _wanderers.values():
		if not is_instance_valid(wanderer):
			continue
		var npc_cell: Vector2i = wanderer.call("get_status_snapshot").get("cell", INVALID_CELL)
		if npc_cell != INVALID_CELL and cell.distance_to(npc_cell) < 3.0:
			return false

	return true


func _cleanup_wanderers() -> void:
	if _selected_npc != null and not is_instance_valid(_selected_npc):
		_close_npc_card()

	var stale_ids := []
	for npc_id in _wanderers.keys():
		var wanderer: Node2D = _wanderers[npc_id]
		if is_instance_valid(wanderer):
			continue
		stale_ids.append(npc_id)

	for npc_id in stale_ids:
		var stale_wanderer: Node2D = _wanderers[npc_id]
		_wanderers.erase(npc_id)
		unregister_npc_cell(int(npc_id))
		if _selected_npc == stale_wanderer:
			_close_npc_card()
	if not stale_ids.is_empty():
		_mark_combat_cache_dirty()


func _try_select_npc_at(world_position: Vector2) -> void:
	_cleanup_wanderers()
	var best_match: Node2D = null
	var best_distance := NPC_CLICK_RADIUS

	for wanderer in _wanderers.values():
		if not is_instance_valid(wanderer):
			continue
		var click_center: Vector2 = wanderer.global_position + Vector2(0.0, -18.0)
		var distance := world_position.distance_to(click_center)
		if distance > best_distance:
			continue
		best_distance = distance
		best_match = wanderer

	if best_match != null:
		_selected_structure_type = ""
		_selected_structure_cell = INVALID_CELL
		_selected_npc = best_match
		_camera_follow_npc = best_match
		npc_card_panel.visible = true
		_update_npc_card()
		return

	_try_select_structure_at(world_position)


func _try_select_structure_at(world_position: Vector2) -> void:
	var clicked_cell := _world_to_cell(world_position)
	if _farm_barn_nodes.has(clicked_cell):
		_selected_npc = null
		_selected_structure_type = "farm_barn"
		_selected_structure_cell = clicked_cell
		npc_card_panel.visible = true
		_update_npc_card()
		return
	if _warehouse_nodes.has(clicked_cell):
		_selected_npc = null
		_selected_structure_type = "warehouse"
		_selected_structure_cell = clicked_cell
		npc_card_panel.visible = true
		_update_npc_card()
		return
	_close_npc_card()


func _close_npc_card() -> void:
	_selected_npc = null
	_selected_structure_type = ""
	_selected_structure_cell = INVALID_CELL
	npc_card_panel.visible = false


func _cancel_camera_follow() -> void:
	_camera_follow_npc = null


func _update_camera_follow(delta: float) -> void:
	if _camera_follow_npc == null:
		return
	if not is_instance_valid(_camera_follow_npc):
		_camera_follow_npc = null
		return

	var target_position := _camera_follow_npc.global_position
	camera.position = camera.position.lerp(target_position, clampf(delta * 8.0, 0.0, 1.0))


func _update_npc_card() -> void:
	if not npc_card_panel.visible:
		return
	if _selected_structure_type != "":
		_update_structure_card()
		return
	if _selected_npc == null or not is_instance_valid(_selected_npc):
		_close_npc_card()
		return

	var card_status: Dictionary = _selected_npc.call("get_status_snapshot")
	var card_home_text := "Нет"
	if bool(card_status.get("has_home", false)):
		card_home_text = "ур. %d" % int(card_status.get("house_level", 1))

	var card_crate_text := "Нет"
	if bool(card_status.get("has_crate", false)):
		card_crate_text = "%d/%d (ур. %d)" % [
			int(card_status.get("crate_food", 0)),
			int(card_status.get("crate_capacity", BASE_FOOD_CRATE_CAPACITY)),
			int(card_status.get("crate_level", 1)),
		]

	card_status["state"] = str(card_status.get("state", "Неизвестно"))
	card_status["reproduction_status"] = str(card_status.get("reproduction_status", "Нет"))
	card_status["cell"] = _format_cell_text(card_status.get("cell", INVALID_CELL))
	card_status["target_cell"] = _format_cell_text(card_status.get("target_cell", INVALID_CELL))

	npc_card_label.text = "Человечек #%d\nСостояние: %s\nРоль: %s%s\nВозраст: %s\nГолод: %.1f / 100\nЖажда: %.1f / 100\nФляга: %d / 2\nДревесина: %d\nКамни: %d\nЯгоды: %d\nДом: %s\nЯщик: %s\nДети: %d/%d\nРазмножение: %s\nКлетка: %s\nЦель: %s\nO - закрыть" % [
		int(card_status.get("id", -1)),
		str(card_status.get("state", "Неизвестно")),
		str(card_status.get("role", "citizen")),
		" (вождь)" if bool(card_status.get("is_leader", false)) else "",
		str(card_status.get("age_text", "0 лет")),
		float(card_status.get("hunger", 0.0)),
		float(card_status.get("thirst", 0.0)),
		int(card_status.get("canteen_water", 0)),
		int(card_status.get("wood", 0)),
		int(card_status.get("stone", 0)),
		int(card_status.get("berry_stock", 0)),
		card_home_text,
		card_crate_text,
		int(card_status.get("children_count", 0)),
		int(card_status.get("children_limit", BASE_HOUSE_CHILD_LIMIT)),
		str(card_status.get("reproduction_status", "Нет")),
		str(card_status.get("cell", INVALID_CELL)),
		str(card_status.get("target_cell", INVALID_CELL)),
	]
	return


func _update_structure_card() -> void:
	if _selected_structure_type == "farm_barn":
		npc_card_label.text = "Амбар\nЕда: %d\nЯгодный запас: %d\nКлетка: %s\nO - закрыть" % [
			_farm_barn_food,
			_farm_barn_berry_stock,
			_format_cell_text(_selected_structure_cell),
		]
		return
	if _selected_structure_type == "warehouse":
		npc_card_label.text = "Склад ур. %d\nДревесина: %d / %d\nКамни: %d / %d\nКлетка: %s\nO - закрыть" % [
			get_warehouse_level(),
			_warehouse_wood,
			get_warehouse_capacity(),
			_warehouse_stone,
			get_warehouse_capacity(),
			_format_cell_text(_selected_structure_cell),
		]
		return

	var status: Dictionary = _selected_npc.call("get_status_snapshot")
	var home_text := "Да" if bool(status.get("has_home", false)) else "Нет"
	var crate_text := "Нет"
	if bool(status.get("has_crate", false)):
		crate_text = "%d/%d" % [int(status.get("crate_food", 0)), int(status.get("crate_capacity", FOOD_CRATE_CAPACITY))]

	home_text = "Да" if bool(status.get("has_home", false)) else "Нет"
	if not bool(status.get("has_crate", false)):
		crate_text = "Нет"
	status["state"] = str(status.get("state", "Неизвестно"))
	status["reproduction_status"] = str(status.get("reproduction_status", "Нет"))
	status["cell"] = _format_cell_text(status.get("cell", INVALID_CELL))
	status["target_cell"] = _format_cell_text(status.get("target_cell", INVALID_CELL))

	var reproduction_text := String(status.get("reproduction_status", "Нет"))

	npc_card_label.text = "Человечек #%d\nСостояние: %s\nГолод: %.1f / 100\nЖажда: %.1f / 100\nДревесина: %d\nДом: %s\nЯщик: %s\nРазмножение: %s\nКлетка: %s\nЦель: %s\nO - закрыть" % [
		int(status.get("id", -1)),
		String(status.get("state", "Неизвестно")),
		float(status.get("hunger", 0.0)),
		float(status.get("thirst", 0.0)),
		int(status.get("wood", 0)),
		home_text,
		crate_text,
		reproduction_text,
		String(status.get("cell", INVALID_CELL)),
		String(status.get("target_cell", INVALID_CELL)),
	]


func _format_cell_text(value) -> String:
	if value is Vector2i:
		var cell: Vector2i = value
		return "(%d, %d)" % [cell.x, cell.y]
	return str(value)


func _load_human_frames() -> void:
	_human_hurt_texture = _load_texture_from_file("res://Land texture/Человечек получил урон.png")
	_worm_texture = _load_texture_from_file("res://Land texture/Гиганский червь-Sheet.png")
	_worm_hurt_texture = _load_texture_from_file("res://Land texture/Гиганский червь получил урон.png")
	_leader_texture = _load_texture_from_file("res://Land texture/Вождь.png")
	_human_texture = _load_texture_from_file("res://Land texture/Человечек.png")
	_fishing_texture = _load_texture_from_file("res://Land texture/Человечек рыбачит.png")
	if _human_texture == null:
		push_warning("Could not load human sprite sheet.")
		_human_frames = null
		_leader_frames = null
		_worm_frames = null
		return
	_human_frames = _build_human_frames()
	_leader_frames = _build_leader_frames()
	_worm_frames = _build_worm_frames()


func _build_human_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 6.0)

	for frame_index in [0, 1, 2, 1]:
		var atlas := AtlasTexture.new()
		atlas.atlas = _human_texture
		atlas.region = Rect2(frame_index * 64, 0, 64, 64)
		frames.add_frame("walk", atlas)

	if _fishing_texture != null:
		frames.add_animation("fish")
		frames.set_animation_loop("fish", true)
		frames.set_animation_speed("fish", 4.0)

		for frame_index in [0, 1, 2, 1]:
			var fishing_atlas := AtlasTexture.new()
			fishing_atlas.atlas = _fishing_texture
			fishing_atlas.region = Rect2(frame_index * 64, 0, 64, 64)
			frames.add_frame("fish", fishing_atlas)

	if _human_hurt_texture != null:
		frames.add_animation("hurt")
		frames.set_animation_loop("hurt", false)
		frames.set_animation_speed("hurt", 10.0)
		frames.add_frame("hurt", _human_hurt_texture)

	return frames


func _build_leader_frames() -> SpriteFrames:
	if _leader_texture == null:
		return _human_frames

	var frames := SpriteFrames.new()
	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 6.0)

	for frame_index in [0, 1, 2, 1]:
		var atlas := AtlasTexture.new()
		atlas.atlas = _leader_texture
		atlas.region = Rect2(frame_index * 64, 0, 64, 64)
		frames.add_frame("walk", atlas)

	if _fishing_texture != null:
		frames.add_animation("fish")
		frames.set_animation_loop("fish", true)
		frames.set_animation_speed("fish", 4.0)

		for frame_index in [0, 1, 2, 1]:
			var fishing_atlas := AtlasTexture.new()
			fishing_atlas.atlas = _fishing_texture
			fishing_atlas.region = Rect2(frame_index * 64, 0, 64, 64)
			frames.add_frame("fish", fishing_atlas)

	if _human_hurt_texture != null:
		frames.add_animation("hurt")
		frames.set_animation_loop("hurt", false)
		frames.set_animation_speed("hurt", 10.0)
		frames.add_frame("hurt", _human_hurt_texture)

	return frames


func _build_worm_frames() -> SpriteFrames:
	if _worm_texture == null:
		return null

	var frames := SpriteFrames.new()
	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 5.0)

	for frame_index in [0, 1, 2, 1]:
		var atlas := AtlasTexture.new()
		atlas.atlas = _worm_texture
		atlas.region = Rect2(frame_index * 64, 0, 64, 64)
		frames.add_frame("walk", atlas)

	if _worm_hurt_texture != null:
		frames.add_animation("hurt")
		frames.set_animation_loop("hurt", false)
		frames.set_animation_speed("hurt", 10.0)
		frames.add_frame("hurt", _worm_hurt_texture)

	return frames


func _load_structure_textures() -> void:
	_bungalow_texture = _load_texture_from_file("res://Land texture/Бунгало.png")
	_house_level_2_texture = _load_texture_from_file("res://Land texture/Дом 2уровень камень.png")
	_free_house_sign_texture = _load_texture_from_file("res://Land texture/Дом свободен.png")
	_farm_barn_texture = _load_texture_from_file("res://Land texture/Ферма+Амбар.png")
	_warehouse_level_1_texture = _load_texture_from_file("res://Land texture/Склад 1го уровня .png")
	_warehouse_level_2_texture = _load_texture_from_file("res://Land texture/Склад 2го уровня.png")


func _load_crate_textures() -> void:
	var crate_sheet := _load_texture_from_file("res://Land texture/Ящик для еды.png")
	if crate_sheet == null:
		_crate_empty_texture = null
		_crate_full_texture = null
	else:
		var empty_atlas := AtlasTexture.new()
		empty_atlas.atlas = crate_sheet
		empty_atlas.region = Rect2(0, 0, 64, 64)
		_crate_empty_texture = empty_atlas

		var full_atlas := AtlasTexture.new()
		full_atlas.atlas = crate_sheet
		full_atlas.region = Rect2(64, 0, 64, 64)
		_crate_full_texture = full_atlas

	var crate_level_2_sheet := _load_texture_from_file("res://Land texture/Ящик 2го уровня камень.png")
	if crate_level_2_sheet == null:
		_crate_level_2_empty_texture = null
		_crate_level_2_full_texture = null
		return

	var level_2_empty_atlas := AtlasTexture.new()
	level_2_empty_atlas.atlas = crate_level_2_sheet
	level_2_empty_atlas.region = Rect2(0, 0, 64, 64)
	_crate_level_2_empty_texture = level_2_empty_atlas

	var level_2_full_atlas := AtlasTexture.new()
	level_2_full_atlas.atlas = crate_level_2_sheet
	level_2_full_atlas.region = Rect2(64, 0, 64, 64)
	_crate_level_2_full_texture = level_2_full_atlas


func _load_resource_textures() -> void:
	_apple_texture = _load_texture_from_file("res://Land texture/Яблоко для дерева.png")
	_berry_texture = _load_texture_from_file("res://Land texture/Ягодка для куста.png")
	_worm_meat_texture = _load_texture_from_file("res://Land texture/Мясо гиганского червя.png")
	_loot_bag_texture = _load_texture_from_file("res://Land texture/Мешок с вещами.png")
	_sapling_texture = _load_texture_from_file("res://Land texture/Сажанец дерева.png")
	_mega_boulder_texture = _load_texture_from_file("res://Land texture/Мега валун.png")


func _load_farming_textures() -> void:
	_tilled_soil_texture = _load_texture_from_file("res://Land texture/Возделаная земля1.png")
	_seeded_soil_texture = _load_texture_from_file("res://Land texture/Возделаная земля и засеяная семенами ягодных кустов.png")


func _load_dead_body_frames() -> void:
	_dead_body_texture = _load_texture_from_file("res://Land texture/мёртвый человечек и его разложение.png")
	if _dead_body_texture == null:
		_dead_body_frames = null
		return

	_dead_body_frames = SpriteFrames.new()
	_dead_body_frames.add_animation("decay")
	_dead_body_frames.set_animation_loop("decay", false)
	_dead_body_frames.set_animation_speed("decay", 2.0)

	for frame_index in range(4):
		var frame := AtlasTexture.new()
		frame.atlas = _dead_body_texture
		frame.region = Rect2(frame_index * 32, 0, 32, 32)
		_dead_body_frames.add_frame("decay", frame)


func _build_dev_panel() -> void:
	var canvas_layer := get_node("CanvasLayer") as CanvasLayer
	if canvas_layer == null:
		return

	_dev_panel = PanelContainer.new()
	_dev_panel.name = "DeveloperPanel"
	_dev_panel.visible = false
	_dev_panel.offset_left = 16.0
	_dev_panel.offset_top = 190.0
	_dev_panel.offset_right = 420.0
	_dev_panel.offset_bottom = 760.0
	canvas_layer.add_child(_dev_panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dev_panel.add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.set("theme_override_constants/margin_left", 12)
	margin.set("theme_override_constants/margin_top", 10)
	margin.set("theme_override_constants/margin_right", 12)
	margin.set("theme_override_constants/margin_bottom", 10)
	scroll.add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var title := Label.new()
	title.text = "Developer Tool"
	root.add_child(title)

	_dev_hint_label = Label.new()
	_dev_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dev_hint_label.text = "F1 - открыть/закрыть. Параметры NPC применяются сразу, генерация меняется после кнопки Regenerate."
	root.add_child(_dev_hint_label)

	_add_dev_number_control(root, "Map Width", "map_width", 80.0, 320.0, 10.0, map_width)
	_add_dev_number_control(root, "Map Height", "map_height", 80.0, 320.0, 10.0, map_height)
	_add_dev_number_control(root, "Tree Density", "tree_density_multiplier", 0.5, 3.0, 0.05, tree_density_multiplier)
	_add_dev_number_control(root, "Bush Density", "bush_density_multiplier", 0.5, 3.0, 0.05, bush_density_multiplier)
	_add_dev_number_control(root, "Rock Density", "rock_density_multiplier", 0.5, 3.0, 0.05, rock_density_multiplier)
	_add_dev_number_control(root, "Fish Chance", "fish_success_chance", 0.0, 1.0, 0.01, fish_success_chance)
	_add_dev_number_control(root, "Tree Wood Yield", "tree_wood_yield", 1.0, 8.0, 1.0, tree_wood_yield)
	_add_dev_number_control(root, "Rock Yield", "rock_stone_yield", 1.0, 5.0, 1.0, rock_stone_yield)
	_add_dev_number_control(root, "Gather Food", "food_gather_amount", 1.0, 8.0, 1.0, food_gather_amount)
	_add_dev_number_control(root, "Berry Seed Cost", "berry_seed_cost", 1.0, 10.0, 1.0, berry_seed_cost)
	_add_dev_number_control(root, "Berry Growth Time", "berry_growth_time", 4.0, 180.0, 1.0, berry_growth_time)
	_add_dev_number_control(root, "Sapling Growth", "sapling_growth_time", 4.0, 240.0, 1.0, sapling_growth_time)
	_add_dev_number_control(root, "Tree Regrow Time", "tree_regrow_time", 4.0, 240.0, 1.0, tree_regrow_time)
	_add_dev_number_control(root, "Tree Regrow Chance", "tree_regrow_chance", 0.0, 1.0, 0.01, tree_regrow_chance)
	_add_dev_number_control(root, "Rock Respawn Time", "rock_respawn_time", 4.0, 240.0, 1.0, rock_respawn_time)
	_add_dev_number_control(root, "Rock Respawn Chance", "rock_respawn_chance", 0.0, 1.0, 0.01, rock_respawn_chance)
	_add_dev_number_control(root, "Reproduction Cost", "reproduction_food_cost", 1.0, 10.0, 1.0, reproduction_food_cost)
	_add_dev_number_control(root, "Population Cap", "max_npc_count", 4.0, 100.0, 1.0, max_npc_count)
	_add_dev_number_control(root, "Day Seconds", "day_duration_seconds", 1.0, 30.0, 0.5, day_duration_seconds)
	_add_dev_number_control(root, "NPC Move Speed", "npc_move_speed", 80.0, 260.0, 5.0, npc_move_speed)
	_add_dev_number_control(root, "Age Min", "npc_initial_age_min", 0.0, 60.0, 1.0, npc_initial_age_min)
	_add_dev_number_control(root, "Age Max", "npc_initial_age_max", 0.0, 80.0, 1.0, npc_initial_age_max)
	_add_dev_number_control(root, "Life Min", "npc_lifespan_min_years", 10.0, 120.0, 1.0, npc_lifespan_min_years)
	_add_dev_number_control(root, "Life Max", "npc_lifespan_max_years", 10.0, 140.0, 1.0, npc_lifespan_max_years)
	_add_dev_number_control(root, "Old Age Start", "npc_old_age_factor", 0.5, 0.95, 0.01, npc_old_age_factor)
	_add_dev_number_control(root, "Hunger Decay", "npc_hunger_decay", 0.1, 5.0, 0.05, npc_hunger_decay)
	_add_dev_number_control(root, "Thirst Decay", "npc_thirst_decay", 0.1, 5.0, 0.05, npc_thirst_decay)
	_add_dev_number_control(root, "Hunger Restore", "npc_hunger_restore", 10.0, 100.0, 1.0, npc_hunger_restore)
	_add_dev_number_control(root, "Thirst Restore", "npc_thirst_restore", 10.0, 100.0, 1.0, npc_thirst_restore)
	_add_dev_number_control(root, "Travel Food Dist", "npc_travel_food_distance", 1.0, 80.0, 1.0, npc_travel_food_distance)
	_add_dev_number_control(root, "NPC Stuck Timeout", "npc_stuck_timeout", 2.0, 30.0, 0.5, npc_stuck_timeout)
	_add_dev_number_control(root, "Mega Boulders", "mega_boulder_count", 0.0, 12.0, 1.0, mega_boulder_count)
	_add_dev_number_control(root, "Mega Spawn Time", "mega_boulder_spawn_interval", 2.0, 40.0, 0.5, mega_boulder_spawn_interval)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	root.add_child(buttons)

	var regenerate_button := Button.new()
	regenerate_button.text = "Regenerate"
	regenerate_button.pressed.connect(generate_world)
	buttons.add_child(regenerate_button)

	var apply_button := Button.new()
	apply_button.text = "Apply NPC"
	apply_button.pressed.connect(_apply_balance_config_to_wanderers)
	buttons.add_child(apply_button)


func _add_dev_number_control(parent: VBoxContainer, label_text: String, key: String, min_value: float, max_value: float, step: float, initial_value: float) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(170.0, 0.0)
	row.add_child(label)

	var box := SpinBox.new()
	box.min_value = min_value
	box.max_value = max_value
	box.step = step
	box.value = initial_value
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.value_changed.connect(func(value: float) -> void:
		_apply_dev_value(key, value)
	)
	row.add_child(box)
	_dev_controls[key] = box


func _apply_dev_value(key: String, value: float) -> void:
	match key:
		"map_width":
			map_width = int(value)
		"map_height":
			map_height = int(value)
		"tree_density_multiplier":
			tree_density_multiplier = value
		"bush_density_multiplier":
			bush_density_multiplier = value
		"rock_density_multiplier":
			rock_density_multiplier = value
		"fish_success_chance":
			fish_success_chance = value
		"tree_wood_yield":
			tree_wood_yield = int(value)
		"rock_stone_yield":
			rock_stone_yield = int(value)
		"food_gather_amount":
			food_gather_amount = int(value)
		"berry_seed_cost":
			berry_seed_cost = int(value)
		"berry_growth_time":
			berry_growth_time = value
		"sapling_growth_time":
			sapling_growth_time = value
		"tree_regrow_time":
			tree_regrow_time = value
		"tree_regrow_chance":
			tree_regrow_chance = value
		"rock_respawn_time":
			rock_respawn_time = value
		"rock_respawn_chance":
			rock_respawn_chance = value
		"reproduction_food_cost":
			reproduction_food_cost = int(value)
		"max_npc_count":
			max_npc_count = int(value)
		"day_duration_seconds":
			day_duration_seconds = value
		"npc_move_speed":
			npc_move_speed = value
		"npc_initial_age_min":
			npc_initial_age_min = value
		"npc_initial_age_max":
			npc_initial_age_max = value
		"npc_lifespan_min_years":
			npc_lifespan_min_years = value
		"npc_lifespan_max_years":
			npc_lifespan_max_years = value
		"npc_old_age_factor":
			npc_old_age_factor = value
		"npc_hunger_decay":
			npc_hunger_decay = value
		"npc_thirst_decay":
			npc_thirst_decay = value
		"npc_hunger_restore":
			npc_hunger_restore = value
		"npc_thirst_restore":
			npc_thirst_restore = value
		"npc_travel_food_distance":
			npc_travel_food_distance = value
		"npc_stuck_timeout":
			npc_stuck_timeout = value
		"mega_boulder_count":
			mega_boulder_count = int(value)
		"mega_boulder_spawn_interval":
			mega_boulder_spawn_interval = value

	_apply_balance_config_to_wanderers()


func _toggle_dev_panel() -> void:
	if _dev_panel == null:
		return
	_dev_panel.visible = not _dev_panel.visible


func _build_death_log_panel() -> void:
	var canvas_layer := get_node("CanvasLayer") as CanvasLayer
	if canvas_layer == null:
		return
	_death_log_ui = DEATH_LOG_CONTROLLER_SCRIPT.new()
	_death_log_ui.build(canvas_layer)
	return

	_death_log_panel = PanelContainer.new()
	_death_log_panel.name = "DeathLog"
	_death_log_panel.visible = false
	_death_log_panel.offset_left = 760.0
	_death_log_panel.offset_top = 16.0
	_death_log_panel.offset_right = 1190.0
	_death_log_panel.offset_bottom = 520.0
	canvas_layer.add_child(_death_log_panel)

	var margin := MarginContainer.new()
	margin.set("theme_override_constants/margin_left", 12)
	margin.set("theme_override_constants/margin_top", 10)
	margin.set("theme_override_constants/margin_right", 12)
	margin.set("theme_override_constants/margin_bottom", 10)
	_death_log_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var title := Label.new()
	title.text = "Журнал смертей"
	root.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.custom_minimum_size = Vector2(380.0, 0.0)
	scroll.add_child(content)

	_death_log_label = Label.new()
	_death_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_death_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_death_log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_death_log_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_death_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_death_log_label.text = "Пока никто не умер."
	content.add_child(_death_log_label)


func _toggle_death_log() -> void:
	if _death_log_ui != null:
		_death_log_ui.toggle()
		return
	if _death_log_panel == null:
		return
	_death_log_panel.visible = not _death_log_panel.visible


func _append_death_log(entry: String) -> void:
	if _death_log_ui != null:
		_death_log_ui.append(entry)
		return
	_death_log_entries.push_front(entry)
	if _death_log_entries.size() > 60:
		_death_log_entries.resize(60)
	if _death_log_label != null:
		_death_log_label.text = "\n\n".join(_death_log_entries) if not _death_log_entries.is_empty() else "Пока никто не умер."


func _load_texture_from_file(resource_path: String) -> Texture2D:
	var image := Image.new()
	var load_result := image.load(ProjectSettings.globalize_path(resource_path))
	if load_result != OK:
		return null
	return ImageTexture.create_from_image(image)


func claim_nearest_tree(from_cell: Vector2i, npc_id: int) -> Vector2i:
	var best_cell := INVALID_CELL
	var best_score := INF

	var tree_candidates: Array = _tree_index.get_candidates(from_cell, maxi(map_width, map_height), 256) if _tree_index != null else _tree_nodes.keys()
	for cell in tree_candidates:
		var claimed_by := int(_tree_claims.get(cell, -1))
		if claimed_by != -1 and claimed_by != npc_id:
			continue

		var score := from_cell.distance_squared_to(cell)
		if score < best_score:
			best_score = score
			best_cell = cell

	if best_cell != INVALID_CELL:
		_tree_claims[best_cell] = npc_id

	return best_cell


func release_tree_claim(cell: Vector2i, npc_id: int) -> void:
	if int(_tree_claims.get(cell, -1)) == npc_id:
		_tree_claims.erase(cell)


func tree_exists(cell: Vector2i) -> bool:
	return _tree_nodes.has(cell)


func harvest_tree(cell: Vector2i, npc_id: int) -> int:
	if not _tree_nodes.has(cell):
		release_tree_claim(cell, npc_id)
		return 0

	var claimed_by := int(_tree_claims.get(cell, -1))
	if claimed_by != -1 and claimed_by != npc_id:
		return 0

	var tree_sprite: Sprite2D = _tree_nodes[cell]
	if is_instance_valid(tree_sprite):
		tree_sprite.queue_free()

	_tree_nodes.erase(cell)
	_tree_food.erase(cell)
	_tree_claims.erase(cell)
	_food_claims.erase(cell)
	if _tree_index != null:
		_tree_index.remove(cell)
	_sync_food_spatial_index(cell)
	if _terrain_grid[cell.y][cell.x] == TerrainType.GRASS and _runtime_rng.randf() <= tree_regrow_chance:
		_tree_regrow_timers[cell] = tree_regrow_time
	_clear_path_cache()
	return tree_wood_yield


func plant_tree_sapling(cell: Vector2i) -> bool:
	if _sapling_texture == null:
		return false
	if not _can_place_sapling(cell):
		return false

	var sapling := Sprite2D.new()
	sapling.texture = _sapling_texture
	sapling.centered = true
	sapling.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sapling.position = _cell_center(cell) + Vector2(0.0, -10.0)
	sapling.scale = Vector2.ONE * 1.0
	objects_root.add_child(sapling)

	_sapling_nodes[cell] = sapling
	_sapling_growth_timers[cell] = sapling_growth_time
	_tree_regrow_timers.erase(cell)
	_clear_path_cache()
	return true


func try_plant_random_sapling_near(origin_cell: Vector2i, radius: int = 3) -> bool:
	for search_radius in [maxi(1, radius), maxi(2, radius + 1)]:
		for _attempt in range(8):
			var cell := Vector2i(
				clampi(origin_cell.x + _runtime_rng.randi_range(-search_radius, search_radius), 1, map_width - 2),
				clampi(origin_cell.y + _runtime_rng.randi_range(-search_radius, search_radius), 1, map_height - 2)
			)
			if plant_tree_sapling(cell):
				return true
	return false


func _can_place_sapling(cell: Vector2i) -> bool:
	if not _is_inside(cell.x, cell.y):
		return false
	if _terrain_grid[cell.y][cell.x] != TerrainType.GRASS:
		return false
	if _tree_nodes.has(cell) or _sapling_nodes.has(cell) or _bush_nodes.has(cell) or _rock_nodes.has(cell):
		return false
	if _house_nodes.has(cell) or _crate_nodes.has(cell) or _farm_plot_nodes.has(cell):
		return false
	if _farm_barn_nodes.has(cell):
		return false
	return true


func claim_nearest_food_source(from_cell: Vector2i, npc_id: int) -> Vector2i:
	var best_cell := INVALID_CELL
	var best_score := INF

	var food_candidates: Array = _food_index.get_candidates(from_cell, maxi(map_width, map_height), 320) if _food_index != null else []
	for cell in food_candidates:
		var claimed_by := int(_food_claims.get(cell, -1))
		if claimed_by != -1 and claimed_by != npc_id:
			continue
		var tree_food := int(_tree_food.get(cell, 0))
		var bush_food := int(_bush_food.get(cell, 0))
		var worm_food := int(_worm_meat_food.get(cell, 0))
		if tree_food <= 0 and bush_food <= 0 and worm_food <= 0:
			continue

		var score := from_cell.distance_squared_to(cell)
		if bush_food > 0:
			score -= float(mini(bush_food, 8)) * 0.35
		elif worm_food > 0:
			score -= float(mini(worm_food, 6)) * 0.55
		if score < best_score:
			best_score = score
			best_cell = cell

	if best_cell != INVALID_CELL:
		_food_claims[best_cell] = npc_id

	return best_cell


func get_nearest_food_source_distance(from_cell: Vector2i, npc_id: int) -> float:
	var best_score := INF

	var food_candidates: Array = _food_index.get_candidates(from_cell, maxi(map_width, map_height), 320) if _food_index != null else []
	for cell in food_candidates:
		var claimed_by := int(_food_claims.get(cell, -1))
		if claimed_by != -1 and claimed_by != npc_id:
			continue
		if int(_tree_food.get(cell, 0)) <= 0 and int(_bush_food.get(cell, 0)) <= 0 and int(_worm_meat_food.get(cell, 0)) <= 0:
			continue

		var access_cell := get_food_source_access_cell(cell, from_cell)
		if access_cell == INVALID_CELL:
			continue

		best_score = minf(best_score, from_cell.distance_squared_to(access_cell))

	return best_score


func release_food_claim(cell: Vector2i, npc_id: int) -> void:
	if int(_food_claims.get(cell, -1)) == npc_id:
		_food_claims.erase(cell)


func food_source_exists(cell: Vector2i) -> bool:
	return int(_tree_food.get(cell, 0)) > 0 or int(_bush_food.get(cell, 0)) > 0 or int(_worm_meat_food.get(cell, 0)) > 0


func food_source_is_bush(cell: Vector2i) -> bool:
	return _bush_nodes.has(cell)


func get_food_source_access_cell(source_cell: Vector2i, from_cell: Vector2i) -> Vector2i:
	if _tree_nodes.has(source_cell):
		return _find_nearest_access_cell(source_cell, from_cell)
	if _bush_nodes.has(source_cell) and _can_npc_enter(source_cell, INVALID_CELL, false):
		return source_cell
	if _worm_meat_nodes.has(source_cell) and _can_npc_enter(source_cell, INVALID_CELL, false):
		return source_cell
	return _find_nearest_access_cell(source_cell, from_cell)


func harvest_food_source(cell: Vector2i, npc_id: int, amount: int) -> int:
	if amount <= 0:
		return 0

	var claimed_by := int(_food_claims.get(cell, -1))
	if claimed_by != -1 and claimed_by != npc_id:
		return 0

	if _tree_nodes.has(cell):
		var harvested_tree_food := mini(amount, int(_tree_food.get(cell, 0)))
		if harvested_tree_food <= 0:
			release_food_claim(cell, npc_id)
			return 0
		_tree_food[cell] = int(_tree_food.get(cell, 0)) - harvested_tree_food
		_refresh_tree_food_visual(cell)
		if int(_tree_food.get(cell, 0)) <= 0:
			_food_claims.erase(cell)
		_sync_food_spatial_index(cell)
		return harvested_tree_food

	if _bush_nodes.has(cell):
		var harvested_bush_food := mini(amount, int(_bush_food.get(cell, 0)))
		if harvested_bush_food <= 0:
			release_food_claim(cell, npc_id)
			return 0
		_bush_food[cell] = int(_bush_food.get(cell, 0)) - harvested_bush_food
		_refresh_bush_food_visual(cell)
		if int(_bush_food.get(cell, 0)) <= 0:
			_food_claims.erase(cell)
			_bush_empty_timers[cell] = day_duration_seconds * DAYS_PER_MONTH
		else:
			_bush_empty_timers.erase(cell)
		_sync_food_spatial_index(cell)
		return harvested_bush_food

	if _worm_meat_nodes.has(cell):
		var harvested_meat := mini(amount, int(_worm_meat_food.get(cell, 0)))
		if harvested_meat <= 0:
			release_food_claim(cell, npc_id)
			return 0
		_worm_meat_food[cell] = int(_worm_meat_food.get(cell, 0)) - harvested_meat
		if int(_worm_meat_food.get(cell, 0)) <= 0:
			var meat_node: Sprite2D = _worm_meat_nodes.get(cell, null)
			if is_instance_valid(meat_node):
				meat_node.queue_free()
			_worm_meat_nodes.erase(cell)
			_worm_meat_food.erase(cell)
			_food_claims.erase(cell)
		_sync_food_spatial_index(cell)
		return harvested_meat

	release_food_claim(cell, npc_id)
	return 0


func claim_nearest_rock(from_cell: Vector2i, npc_id: int) -> Vector2i:
	var best_cell := INVALID_CELL
	var best_score := INF

	var rock_candidates: Array = _rock_index.get_candidates(from_cell, maxi(map_width, map_height), 256) if _rock_index != null else _rock_nodes.keys()
	for cell in rock_candidates:
		var claimed_by := int(_rock_claims.get(cell, -1))
		if claimed_by != -1 and claimed_by != npc_id:
			continue

		var score := from_cell.distance_squared_to(cell)
		if score < best_score:
			best_score = score
			best_cell = cell

	if best_cell != INVALID_CELL:
		_rock_claims[best_cell] = npc_id

	return best_cell


func release_rock_claim(cell: Vector2i, npc_id: int) -> void:
	if int(_rock_claims.get(cell, -1)) == npc_id:
		_rock_claims.erase(cell)


func rock_exists(cell: Vector2i) -> bool:
	return _rock_nodes.has(cell)


func harvest_rock(cell: Vector2i, npc_id: int) -> int:
	if not _rock_nodes.has(cell):
		release_rock_claim(cell, npc_id)
		return 0

	var claimed_by := int(_rock_claims.get(cell, -1))
	if claimed_by != -1 and claimed_by != npc_id:
		return 0

	var rock_sprite: Sprite2D = _rock_nodes[cell]
	if is_instance_valid(rock_sprite):
		rock_sprite.queue_free()

	_rock_nodes.erase(cell)
	_rock_claims.erase(cell)
	if _rock_index != null:
		_rock_index.remove(cell)
	if _runtime_rng.randf() <= rock_respawn_chance:
		_rock_respawn_timers[cell] = rock_respawn_time
	return rock_stone_yield


func claim_farm_plot(origin_cell: Vector2i, npc_id: int) -> Vector2i:
	var best_cell := INVALID_CELL
	var best_score := INF

	for radius in [2, 4, 6, 8]:
		for y in range(max(origin_cell.y - radius, 1), min(origin_cell.y + radius, map_height - 2) + 1):
			for x in range(max(origin_cell.x - radius, 1), min(origin_cell.x + radius, map_width - 2) + 1):
				var cell := Vector2i(x, y)
				if not _is_valid_farm_plot_cell(cell, npc_id):
					continue

				var score := origin_cell.distance_squared_to(cell)
				if score < best_score:
					best_score = score
					best_cell = cell

		if best_cell != INVALID_CELL:
			break

	if best_cell != INVALID_CELL:
		_farm_claims[best_cell] = npc_id

	return best_cell


func claim_farm_barn_site(origin_cell: Vector2i, npc_id: int) -> Vector2i:
	if _farm_barn_claims.has(npc_id):
		return _farm_barn_claims[npc_id]
	if _farm_barn_nodes.size() >= 2:
		return INVALID_CELL

	var best_cell := INVALID_CELL
	var best_score := -INF
	for radius in [3, 5, 8, 12]:
		for y in range(max(origin_cell.y - radius, 2), min(origin_cell.y + radius, map_height - 3) + 1):
			for x in range(max(origin_cell.x - radius, 2), min(origin_cell.x + radius, map_width - 3) + 1):
				var cell := Vector2i(x, y)
				if not _is_valid_farm_barn_cell(cell, npc_id):
					continue
				var score := 24.0 - origin_cell.distance_squared_to(cell) * 0.16 + float(_count_tree_cells_in_radius(cell, 6)) * 0.1
				if score > best_score:
					best_score = score
					best_cell = cell
		if best_cell != INVALID_CELL:
			break

	if best_cell != INVALID_CELL:
		_farm_barn_claims[npc_id] = best_cell
	return best_cell


func release_farm_barn_site(cell: Vector2i, npc_id: int) -> void:
	if _farm_barn_claims.get(npc_id, INVALID_CELL) == cell:
		_farm_barn_claims.erase(npc_id)


func build_farm_barn(cell: Vector2i, npc_id: int) -> bool:
	if _farm_barn_texture == null:
		return false
	if _farm_barn_nodes.has(cell):
		return true
	if _farm_barn_claims.get(npc_id, INVALID_CELL) != cell:
		return false
	if not _is_valid_farm_barn_cell(cell, npc_id):
		return false

	var farm_sprite := Sprite2D.new()
	farm_sprite.texture = _farm_barn_texture
	farm_sprite.centered = true
	farm_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	farm_sprite.position = _cell_center(cell) + Vector2(0.0, -14.0)
	farm_sprite.scale = Vector2.ONE * FARM_BARN_SCALE
	objects_root.add_child(farm_sprite)

	_farm_barn_nodes[cell] = farm_sprite
	_farm_barn_claims.erase(npc_id)
	_settlement_center_cell = cell
	_clear_path_cache()
	return true


func has_warehouse() -> bool:
	return not _warehouse_nodes.is_empty()


func get_warehouse_count() -> int:
	return _warehouse_nodes.size()


func get_warehouse_level() -> int:
	var best_level := 0
	for level in _warehouse_levels.values():
		best_level = max(best_level, int(level))
	return best_level


func get_warehouse_upgrade_cell() -> Vector2i:
	for warehouse_cell in _warehouse_levels.keys():
		if int(_warehouse_levels[warehouse_cell]) < 2:
			return warehouse_cell
	return INVALID_CELL


func get_warehouse_capacity() -> int:
	var capacity := 0
	for level in _warehouse_levels.values():
		capacity += 100 if int(level) >= 2 else 50
	return capacity


func get_warehouse_wood_amount() -> int:
	return _warehouse_wood


func get_warehouse_stone_amount() -> int:
	return _warehouse_stone


func get_warehouse_cell() -> Vector2i:
	for warehouse_cell in _warehouse_nodes.keys():
		return warehouse_cell
	return INVALID_CELL


func get_warehouse_access_cell(from_cell: Vector2i) -> Vector2i:
	if _warehouse_nodes.is_empty():
		return INVALID_CELL
	var best_access := INVALID_CELL
	var best_score := INF
	for warehouse_cell in _warehouse_nodes.keys():
		var access_cell := _find_nearest_access_cell(Vector2i(warehouse_cell), from_cell)
		if access_cell == INVALID_CELL:
			continue
		var score := from_cell.distance_squared_to(access_cell)
		if score < best_score:
			best_score = score
			best_access = access_cell
	return best_access


func get_specific_warehouse_access_cell(warehouse_cell: Vector2i, from_cell: Vector2i) -> Vector2i:
	if not _warehouse_nodes.has(warehouse_cell):
		return INVALID_CELL
	return _find_nearest_access_cell(warehouse_cell, from_cell)


func claim_warehouse_site(origin_cell: Vector2i, npc_id: int) -> Vector2i:
	if _warehouse_claims.has(npc_id):
		return _warehouse_claims[npc_id]
	if _warehouse_nodes.size() >= 2:
		return INVALID_CELL

	var best_cell := INVALID_CELL
	var best_score := -INF
	for radius in [2, 4, 6, 10]:
		for y in range(max(origin_cell.y - radius, 2), min(origin_cell.y + radius, map_height - 3) + 1):
			for x in range(max(origin_cell.x - radius, 2), min(origin_cell.x + radius, map_width - 3) + 1):
				var cell := Vector2i(x, y)
				if not _is_valid_warehouse_cell(cell, npc_id):
					continue
				var score := 18.0 - origin_cell.distance_squared_to(cell) * 0.18
				for barn_cell in _farm_barn_nodes.keys():
					score += 10.0 - cell.distance_squared_to(Vector2i(barn_cell)) * 0.1
					break
				if score > best_score:
					best_score = score
					best_cell = cell
		if best_cell != INVALID_CELL:
			break

	if best_cell != INVALID_CELL:
		_warehouse_claims[npc_id] = best_cell
	return best_cell


func release_warehouse_site(cell: Vector2i, npc_id: int) -> void:
	if _warehouse_claims.get(npc_id, INVALID_CELL) == cell:
		_warehouse_claims.erase(npc_id)


func build_warehouse(cell: Vector2i, npc_id: int) -> bool:
	if _warehouse_level_1_texture == null:
		return false
	if _warehouse_nodes.has(cell):
		return true
	if _warehouse_claims.get(npc_id, INVALID_CELL) != cell:
		return false
	if not _is_valid_warehouse_cell(cell, npc_id):
		return false

	var warehouse_sprite := Sprite2D.new()
	warehouse_sprite.texture = _warehouse_level_1_texture
	warehouse_sprite.centered = true
	warehouse_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	warehouse_sprite.position = _cell_center(cell) + Vector2(0.0, -8.0)
	warehouse_sprite.scale = Vector2.ONE * WAREHOUSE_SCALE
	objects_root.add_child(warehouse_sprite)

	_warehouse_nodes[cell] = warehouse_sprite
	_warehouse_levels[cell] = 1
	_warehouse_claims.erase(npc_id)
	_clear_path_cache()
	return true


func upgrade_warehouse(cell: Vector2i) -> bool:
	if not _warehouse_nodes.has(cell) or int(_warehouse_levels.get(cell, 1)) >= 2:
		return false
	if _warehouse_level_2_texture == null:
		return false
	var warehouse_node: Sprite2D = _warehouse_nodes[cell]
	if warehouse_node == null or not is_instance_valid(warehouse_node):
		return false
	_warehouse_levels[cell] = 2
	warehouse_node.texture = _warehouse_level_2_texture
	warehouse_node.position = _cell_center(cell) + Vector2(0.0, -8.0)
	warehouse_node.scale = Vector2.ONE * (WAREHOUSE_SCALE * 1.04)
	_clear_path_cache()
	return true


func store_wood_in_warehouse(amount: int) -> int:
	if _warehouse_nodes.is_empty() or amount <= 0:
		return 0
	var stored := mini(amount, get_warehouse_capacity() - _warehouse_wood)
	if stored <= 0:
		return 0
	_warehouse_wood += stored
	return stored


func store_stone_in_warehouse(amount: int) -> int:
	if _warehouse_nodes.is_empty() or amount <= 0:
		return 0
	var stored := mini(amount, get_warehouse_capacity() - _warehouse_stone)
	if stored <= 0:
		return 0
	_warehouse_stone += stored
	return stored


func take_wood_from_warehouse(amount: int) -> int:
	if _warehouse_nodes.is_empty() or amount <= 0:
		return 0
	var taken := mini(amount, _warehouse_wood)
	_warehouse_wood -= taken
	return taken


func take_stone_from_warehouse(amount: int) -> int:
	if _warehouse_nodes.is_empty() or amount <= 0:
		return 0
	var taken := mini(amount, _warehouse_stone)
	_warehouse_stone -= taken
	return taken


func has_farm_barn() -> bool:
	return not _farm_barn_nodes.is_empty()


func get_farm_barn_count() -> int:
	return _farm_barn_nodes.size()


func get_farm_barn_cell() -> Vector2i:
	for barn_cell in _farm_barn_nodes.keys():
		return barn_cell
	return INVALID_CELL


func get_farm_barn_access_cell(from_cell: Vector2i) -> Vector2i:
	if _farm_barn_nodes.is_empty():
		return INVALID_CELL
	var best_access := INVALID_CELL
	var best_score := INF
	for barn_cell in _farm_barn_nodes.keys():
		var access_cell := _find_nearest_access_cell(Vector2i(barn_cell), from_cell)
		if access_cell == INVALID_CELL:
			continue
		var score := from_cell.distance_squared_to(access_cell)
		if score < best_score:
			best_score = score
			best_access = access_cell
	return best_access


func release_farm_plot_claim(cell: Vector2i, npc_id: int) -> void:
	if int(_farm_claims.get(cell, -1)) == npc_id:
		_farm_claims.erase(cell)


func create_tilled_plot(cell: Vector2i, npc_id: int) -> bool:
	if _tilled_soil_texture == null:
		return false
	if int(_farm_claims.get(cell, -1)) != npc_id:
		return false
	if not _is_valid_farm_plot_cell(cell, npc_id):
		return false

	var plot := Sprite2D.new()
	plot.texture = _tilled_soil_texture
	plot.centered = false
	plot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	plot.position = Vector2(cell * TILE_SIZE)
	objects_root.add_child(plot)

	_farm_plot_nodes[cell] = plot
	_farm_plot_states[cell] = "tilled"
	_farm_claims.erase(cell)
	return true


func sow_berry_plot(cell: Vector2i, npc_id: int) -> bool:
	if not _farm_plot_nodes.has(cell):
		return false
	if str(_farm_plot_states.get(cell, "")) != "tilled":
		return false
	if consume_berries_from_crate(npc_id, berry_seed_cost) < berry_seed_cost:
		return false

	var plot: Sprite2D = _farm_plot_nodes[cell]
	if is_instance_valid(plot) and _seeded_soil_texture != null:
		plot.texture = _seeded_soil_texture

	_farm_plot_states[cell] = "seeded"
	_farm_growth_timers[cell] = berry_growth_time
	return true


func has_tilled_plot(cell: Vector2i) -> bool:
	return _farm_plot_nodes.has(cell)


func get_nearest_farm_plot(origin_cell: Vector2i, npc_id: int) -> Vector2i:
	var best_cell := INVALID_CELL
	var best_score := INF

	for cell in _farm_plot_nodes.keys():
		if str(_farm_plot_states.get(cell, "")) != "tilled":
			continue
		var score := origin_cell.distance_squared_to(cell)
		if score < best_score:
			best_score = score
			best_cell = cell

	return best_cell


func _is_valid_farm_plot_cell(cell: Vector2i, npc_id: int) -> bool:
	if not _is_inside(cell.x, cell.y):
		return false
	if _terrain_grid[cell.y][cell.x] != TerrainType.GRASS:
		return false
	if _farm_barn_nodes.is_empty():
		return false
	var near_any_barn := false
	for barn_cell in _farm_barn_nodes.keys():
		if cell.distance_to(Vector2i(barn_cell)) <= float(farm_plot_radius):
			near_any_barn = true
			break
	if not near_any_barn:
		return false
	if _count_active_farm_plots() >= farm_plot_limit:
		return false
	if is_cell_near_water(cell):
		return false
	if _tree_nodes.has(cell) or _sapling_nodes.has(cell) or _bush_nodes.has(cell) or _rock_nodes.has(cell) or _house_nodes.has(cell) or _crate_nodes.has(cell):
		return false
	if _farm_plot_nodes.has(cell):
		return false
	var claimed_by := int(_farm_claims.get(cell, -1))
	return claimed_by == -1 or claimed_by == npc_id


func _is_valid_farm_barn_cell(cell: Vector2i, npc_id: int) -> bool:
	if not _is_inside(cell.x, cell.y):
		return false
	if _terrain_grid[cell.y][cell.x] != TerrainType.GRASS:
		return false
	if is_cell_near_water(cell):
		return false
	if _tree_nodes.has(cell) or _sapling_nodes.has(cell) or _bush_nodes.has(cell) or _rock_nodes.has(cell) or _house_nodes.has(cell) or _crate_nodes.has(cell) or _farm_plot_nodes.has(cell):
		return false
	for claimant_id in _farm_barn_claims.keys():
		if claimant_id == npc_id:
			continue
		if Vector2i(_farm_barn_claims[claimant_id]) == cell:
			return false
	return true


func _is_valid_warehouse_cell(cell: Vector2i, npc_id: int) -> bool:
	if not _is_inside(cell.x, cell.y):
		return false
	if _terrain_grid[cell.y][cell.x] != TerrainType.GRASS:
		return false
	if is_cell_near_water(cell):
		return false
	if _tree_nodes.has(cell) or _sapling_nodes.has(cell) or _bush_nodes.has(cell) or _rock_nodes.has(cell) or _house_nodes.has(cell) or _crate_nodes.has(cell) or _farm_plot_nodes.has(cell):
		return false
	if _farm_barn_nodes.has(cell):
		return false
	for claimant_id in _warehouse_claims.keys():
		if claimant_id == npc_id:
			continue
		if Vector2i(_warehouse_claims[claimant_id]) == cell:
			return false
	return true


func _count_active_farm_plots() -> int:
	var count := 0
	for state in _farm_plot_states.values():
		if str(state) == "tilled" or str(state) == "seeded" or str(state) == "grown":
			count += 1
	return count


func _update_world_regrowth(delta: float) -> void:
	for mega_cell in _mega_boulder_nodes.keys():
		var timer_left := float(_mega_boulder_timers.get(mega_cell, mega_boulder_spawn_interval)) - delta
		if timer_left > 0.0:
			_mega_boulder_timers[mega_cell] = timer_left
			continue
		_mega_boulder_timers[mega_cell] = mega_boulder_spawn_interval
		if _count_rocks_around_mega_boulder(Vector2i(mega_cell)) >= 8:
			continue
		_spawn_rock_from_mega_boulder(Vector2i(mega_cell))

	var ready_sapling_cells := []
	for cell in _sapling_growth_timers.keys():
		var sapling_time_left := float(_sapling_growth_timers[cell]) - delta
		if sapling_time_left <= 0.0:
			ready_sapling_cells.append(cell)
		else:
			_sapling_growth_timers[cell] = sapling_time_left

	for cell in ready_sapling_cells:
		_sapling_growth_timers.erase(cell)
		var sapling_node: Sprite2D = _sapling_nodes.get(cell, null)
		if is_instance_valid(sapling_node):
			sapling_node.queue_free()
		_sapling_nodes.erase(cell)
		if _can_regrow_tree(cell):
			_place_tree(cell, _runtime_rng)

	var ready_tree_cells := []
	for cell in _tree_regrow_timers.keys():
		var time_left := float(_tree_regrow_timers[cell]) - delta
		if time_left <= 0.0:
			ready_tree_cells.append(cell)
		else:
			_tree_regrow_timers[cell] = time_left

	for cell in ready_tree_cells:
		_tree_regrow_timers.erase(cell)
		if _can_regrow_tree(cell):
			_place_tree(cell, _runtime_rng)

	var ready_rock_cells := []
	for cell in _rock_respawn_timers.keys():
		var rock_time_left := float(_rock_respawn_timers[cell]) - delta
		if rock_time_left <= 0.0:
			ready_rock_cells.append(cell)
		else:
			_rock_respawn_timers[cell] = rock_time_left

	for cell in ready_rock_cells:
		_rock_respawn_timers.erase(cell)
		if _can_respawn_rock(cell):
			_place_rock(cell, _runtime_rng, 0.9, 1.08)

	var ready_farm_cells := []
	for cell in _farm_growth_timers.keys():
		var grow_time_left := float(_farm_growth_timers[cell]) - delta
		if grow_time_left <= 0.0:
			ready_farm_cells.append(cell)
		else:
			_farm_growth_timers[cell] = grow_time_left

	for cell in ready_farm_cells:
		_farm_growth_timers.erase(cell)
		_grow_seeded_plot(cell)

	var dead_bush_cells := []
	for cell in _bush_empty_timers.keys():
		var bush_time_left := float(_bush_empty_timers[cell]) - delta
		if bush_time_left <= 0.0:
			dead_bush_cells.append(cell)
		else:
			_bush_empty_timers[cell] = bush_time_left

	for cell in dead_bush_cells:
		_bush_empty_timers.erase(cell)
		_remove_bush(cell)


func _grow_seeded_plot(cell: Vector2i) -> void:
	if not _farm_plot_nodes.has(cell):
		return

	var plot: Sprite2D = _farm_plot_nodes[cell]
	if is_instance_valid(plot):
		plot.queue_free()
	_farm_plot_nodes.erase(cell)
	_farm_plot_states[cell] = "grown"
	_place_bush(cell, _runtime_rng)


func _remove_bush(cell: Vector2i) -> void:
	if not _bush_nodes.has(cell):
		return

	var bush: Sprite2D = _bush_nodes[cell]
	if is_instance_valid(bush):
		bush.queue_free()
	_bush_nodes.erase(cell)
	_bush_food.erase(cell)
	_food_claims.erase(cell)
	_sync_food_spatial_index(cell)
	if str(_farm_plot_states.get(cell, "")) == "grown":
		_farm_plot_states.erase(cell)


func _can_regrow_tree(cell: Vector2i) -> bool:
	if not _is_inside(cell.x, cell.y):
		return false
	if _terrain_grid[cell.y][cell.x] != TerrainType.GRASS:
		return false
	if _tree_nodes.has(cell) or _sapling_nodes.has(cell) or _bush_nodes.has(cell) or _rock_nodes.has(cell) or _house_nodes.has(cell) or _crate_nodes.has(cell) or _farm_plot_nodes.has(cell):
		return false
	if _mega_boulder_nodes.has(cell):
		return false
	return true


func _can_respawn_rock(cell: Vector2i) -> bool:
	if not _is_inside(cell.x, cell.y):
		return false
	if _terrain_grid[cell.y][cell.x] == TerrainType.WATER:
		return false
	if _tree_nodes.has(cell) or _sapling_nodes.has(cell) or _bush_nodes.has(cell) or _rock_nodes.has(cell) or _house_nodes.has(cell) or _crate_nodes.has(cell) or _farm_plot_nodes.has(cell):
		return false
	if _mega_boulder_nodes.has(cell):
		return false
	return true


func claim_house_site(origin_cell: Vector2i, npc_id: int) -> Vector2i:
	if _npc_home_cells.has(npc_id):
		return _npc_home_cells[npc_id]

	if _house_claims.has(npc_id):
		return _house_claims[npc_id]

	var best_cell := INVALID_CELL
	var best_score := -INF

	for radius in [4, 7, 10, 14, 20]:
		for y in range(max(origin_cell.y - radius, 2), min(origin_cell.y + radius, map_height - 3) + 1):
			for x in range(max(origin_cell.x - radius, 2), min(origin_cell.x + radius, map_width - 3) + 1):
				var cell := Vector2i(x, y)
				var score := _score_house_site(cell, origin_cell)
				if score > best_score:
					best_score = score
					best_cell = cell

		if best_cell != INVALID_CELL:
			break

	if best_cell != INVALID_CELL:
		_house_claims[npc_id] = best_cell

	return best_cell


func release_house_site(cell: Vector2i, npc_id: int) -> void:
	if _house_claims.get(npc_id, INVALID_CELL) == cell:
		_house_claims.erase(npc_id)


func build_house(cell: Vector2i, npc_id: int) -> bool:
	if _bungalow_texture == null:
		return false
	if _npc_home_cells.has(npc_id):
		return true
	if _house_claims.get(npc_id, INVALID_CELL) != cell:
		return false
	if not _is_buildable_house_cell(cell, npc_id):
		return false

	var house_sprite := Sprite2D.new()
	house_sprite.texture = _bungalow_texture
	house_sprite.centered = true
	house_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	house_sprite.position = _cell_center(cell) + Vector2(0.0, -16.0)
	house_sprite.scale = Vector2.ONE * HOUSE_SCALE
	objects_root.add_child(house_sprite)

	_house_nodes[cell] = house_sprite
	_house_levels[cell] = 1
	_house_owner_by_cell[cell] = npc_id
	_house_children_born[cell] = 0
	_npc_home_cells[npc_id] = cell
	if _settlement_center_cell == INVALID_CELL:
		_settlement_center_cell = cell
	_house_claims.erase(npc_id)
	_clear_path_cache()
	return true


func claim_vacant_house(origin_cell: Vector2i, npc_id: int) -> Vector2i:
	if _npc_home_cells.has(npc_id):
		return _npc_home_cells[npc_id]
	if _vacant_house_claims.has(npc_id):
		return _vacant_house_claims[npc_id]

	var best_cell := INVALID_CELL
	var best_score := INF

	for house_cell in _house_nodes.keys():
		if int(_house_owner_by_cell.get(house_cell, -2)) != -1:
			continue
		if _is_house_claimed_by_other(house_cell, npc_id):
			continue

		var score := origin_cell.distance_squared_to(house_cell)
		if score < best_score:
			best_score = score
			best_cell = house_cell

	if best_cell != INVALID_CELL:
		_vacant_house_claims[npc_id] = best_cell

	return best_cell


func release_vacant_house_claim(house_cell: Vector2i, npc_id: int) -> void:
	if _vacant_house_claims.get(npc_id, INVALID_CELL) == house_cell:
		_vacant_house_claims.erase(npc_id)


func occupy_vacant_house(house_cell: Vector2i, npc_id: int) -> bool:
	if int(_house_owner_by_cell.get(house_cell, -2)) != -1:
		return false
	if _vacant_house_claims.get(npc_id, INVALID_CELL) != house_cell:
		return false

	_house_owner_by_cell[house_cell] = npc_id
	_npc_home_cells[npc_id] = house_cell
	_house_children_born[house_cell] = 0
	_vacant_house_claims.erase(npc_id)
	_hide_free_house_sign(house_cell)

	var crate_cell := Vector2i(_house_crate_cells.get(house_cell, INVALID_CELL))
	if crate_cell != INVALID_CELL and _crate_nodes.has(crate_cell):
		_npc_crate_cells[npc_id] = crate_cell

	return true


func get_house_access_cell(house_cell: Vector2i, from_cell: Vector2i) -> Vector2i:
	if house_cell == INVALID_CELL:
		return INVALID_CELL
	return _find_nearest_access_cell(house_cell, from_cell)


func get_house_level(npc_id: int) -> int:
	var house_cell := get_home_cell(npc_id)
	if house_cell == INVALID_CELL:
		return 0
	return int(_house_levels.get(house_cell, 1))


func get_house_child_limit(npc_id: int) -> int:
	var house_level := get_house_level(npc_id)
	if house_level >= 2:
		return UPGRADED_HOUSE_CHILD_LIMIT
	if house_level >= 1:
		return BASE_HOUSE_CHILD_LIMIT
	return 0


func get_house_children_count(npc_id: int) -> int:
	var house_cell := get_home_cell(npc_id)
	if house_cell == INVALID_CELL:
		return 0
	return int(_house_children_born.get(house_cell, 0))


func upgrade_house(npc_id: int) -> bool:
	var house_cell := get_home_cell(npc_id)
	if house_cell == INVALID_CELL:
		return false
	if int(_house_levels.get(house_cell, 1)) >= 2:
		return true
	if _house_level_2_texture == null:
		return false
	if not _house_nodes.has(house_cell):
		return false

	var house_sprite: Sprite2D = _house_nodes[house_cell]
	if not is_instance_valid(house_sprite):
		return false

	house_sprite.texture = _house_level_2_texture
	house_sprite.scale = Vector2.ONE * UPGRADED_HOUSE_SCALE
	house_sprite.position = _cell_center(house_cell) + Vector2(0.0, -18.0)
	_house_levels[house_cell] = 2
	return true


func _is_house_claimed_by_other(house_cell: Vector2i, npc_id: int) -> bool:
	for claimant_id in _vacant_house_claims.keys():
		if claimant_id == npc_id:
			continue
		if Vector2i(_vacant_house_claims[claimant_id]) == house_cell:
			return true
	return false


func claim_crate_site(home_cell: Vector2i, npc_id: int) -> Vector2i:
	if _npc_crate_cells.has(npc_id):
		return _npc_crate_cells[npc_id]

	if _crate_claims.has(npc_id):
		return _crate_claims[npc_id]

	var best_cell := INVALID_CELL
	var best_score := -INF

	for radius in [1, 2, 3]:
		for y in range(max(home_cell.y - radius, 1), min(home_cell.y + radius, map_height - 2) + 1):
			for x in range(max(home_cell.x - radius, 1), min(home_cell.x + radius, map_width - 2) + 1):
				var cell := Vector2i(x, y)
				var score := _score_crate_site(cell, home_cell, npc_id)
				if score > best_score:
					best_score = score
					best_cell = cell

		if best_cell != INVALID_CELL:
			break

	if best_cell != INVALID_CELL:
		_crate_claims[npc_id] = best_cell

	return best_cell


func release_crate_site(cell: Vector2i, npc_id: int) -> void:
	if _crate_claims.get(npc_id, INVALID_CELL) == cell:
		_crate_claims.erase(npc_id)


func build_crate(cell: Vector2i, npc_id: int) -> bool:
	if _crate_empty_texture == null:
		return false
	if _npc_crate_cells.has(npc_id):
		return true
	if _crate_claims.get(npc_id, INVALID_CELL) != cell:
		return false
	if not _is_buildable_crate_cell(cell, npc_id):
		return false

	var crate_sprite := Sprite2D.new()
	crate_sprite.texture = _crate_empty_texture
	crate_sprite.centered = true
	crate_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	crate_sprite.position = _cell_center(cell) + Vector2(0.0, 9.0)
	crate_sprite.scale = Vector2.ONE * CRATE_SCALE
	objects_root.add_child(crate_sprite)

	_crate_nodes[cell] = crate_sprite
	_crate_food[cell] = 0
	_crate_berry_stock[cell] = 0
	_crate_levels[cell] = 1
	_npc_crate_cells[npc_id] = cell
	_crate_home_cells[cell] = get_home_cell(npc_id)
	if get_home_cell(npc_id) != INVALID_CELL:
		_house_crate_cells[get_home_cell(npc_id)] = cell
	_crate_claims.erase(npc_id)
	_clear_path_cache()
	return true


func get_crate_level(npc_id: int) -> int:
	var crate_cell := get_crate_cell(npc_id)
	if crate_cell == INVALID_CELL:
		return 0
	return int(_crate_levels.get(crate_cell, 1))


func upgrade_crate(npc_id: int) -> bool:
	var crate_cell := get_crate_cell(npc_id)
	if crate_cell == INVALID_CELL:
		return false
	if int(_crate_levels.get(crate_cell, 1)) >= 2:
		return true
	if _crate_level_2_empty_texture == null:
		return false
	if not _crate_nodes.has(crate_cell):
		return false

	var crate_sprite: Sprite2D = _crate_nodes[crate_cell]
	if not is_instance_valid(crate_sprite):
		return false

	_crate_levels[crate_cell] = 2
	_update_crate_visual(crate_cell)
	crate_sprite.position = _cell_center(crate_cell) + Vector2(0.0, 9.0)
	crate_sprite.scale = Vector2.ONE * (CRATE_SCALE * 0.98)
	return true


func has_crate(npc_id: int) -> bool:
	return _npc_crate_cells.has(npc_id)


func get_crate_cell(npc_id: int) -> Vector2i:
	return _npc_crate_cells.get(npc_id, INVALID_CELL)


func get_crate_food_amount(npc_id: int) -> int:
	var crate_cell := get_crate_cell(npc_id)
	if crate_cell == INVALID_CELL:
		return 0
	return int(_crate_food.get(crate_cell, 0))


func get_farm_barn_food_amount() -> int:
	return _farm_barn_food if not _farm_barn_nodes.is_empty() else 0


func get_farm_barn_berry_stock() -> int:
	return _farm_barn_berry_stock if not _farm_barn_nodes.is_empty() else 0


func claim_farm_barn_food(npc_id: int, amount: int) -> bool:
	if _farm_barn_nodes.is_empty() or amount <= 0:
		return false
	var reserved := 0
	for value in _farm_barn_food_claims.values():
		reserved += int(value)
	var already_reserved := int(_farm_barn_food_claims.get(npc_id, 0))
	if (_farm_barn_food - reserved + already_reserved) < amount:
		return false
	_farm_barn_food_claims[npc_id] = amount
	return true


func release_farm_barn_food_claim(npc_id: int) -> void:
	_farm_barn_food_claims.erase(npc_id)


func store_food_in_farm_barn(amount: int) -> int:
	if _farm_barn_nodes.is_empty() or amount <= 0:
		return 0
	_farm_barn_food += amount
	return amount


func store_berries_in_farm_barn(amount: int) -> int:
	if _farm_barn_nodes.is_empty() or amount <= 0:
		return 0
	_farm_barn_food += amount
	_farm_barn_berry_stock += amount
	return amount


func consume_food_from_farm_barn(amount: int) -> int:
	if _farm_barn_nodes.is_empty() or amount <= 0:
		return 0
	var consumed := mini(amount, _farm_barn_food)
	if consumed <= 0:
		return 0
	_farm_barn_food -= consumed
	if _farm_barn_berry_stock > _farm_barn_food:
		_farm_barn_berry_stock = _farm_barn_food
	return consumed


func consume_berries_from_farm_barn(amount: int) -> int:
	if _farm_barn_nodes.is_empty() or amount <= 0:
		return 0
	var consumed := mini(amount, _farm_barn_berry_stock)
	if consumed <= 0:
		return 0
	_farm_barn_berry_stock -= consumed
	_farm_barn_food = maxi(_farm_barn_food - consumed, 0)
	return consumed


func transfer_food_from_farm_barn_to_crate(npc_id: int, amount: int) -> int:
	if amount <= 0:
		return 0
	var crate_cell := get_crate_cell(npc_id)
	if crate_cell == INVALID_CELL:
		return 0
	var free_capacity := get_food_crate_capacity(npc_id) - int(_crate_food.get(crate_cell, 0))
	var moved := mini(mini(amount, free_capacity), _farm_barn_food)
	if moved <= 0:
		release_farm_barn_food_claim(npc_id)
		return 0
	_farm_barn_food -= moved
	release_farm_barn_food_claim(npc_id)
	if _farm_barn_berry_stock > _farm_barn_food:
		var berry_part := _farm_barn_berry_stock - _farm_barn_food
		_farm_barn_berry_stock = _farm_barn_food
		_crate_berry_stock[crate_cell] = int(_crate_berry_stock.get(crate_cell, 0)) + berry_part
	_crate_food[crate_cell] = int(_crate_food.get(crate_cell, 0)) + moved
	_update_crate_visual(crate_cell)
	return moved


func transfer_berries_from_farm_barn_to_crate(npc_id: int, amount: int) -> int:
	if amount <= 0:
		return 0
	var crate_cell := get_crate_cell(npc_id)
	if crate_cell == INVALID_CELL:
		return 0
	var free_capacity := get_food_crate_capacity(npc_id) - int(_crate_food.get(crate_cell, 0))
	var moved := mini(mini(amount, free_capacity), mini(_farm_barn_berry_stock, _farm_barn_food))
	if moved <= 0:
		return 0
	_farm_barn_berry_stock -= moved
	_farm_barn_food -= moved
	_crate_food[crate_cell] = int(_crate_food.get(crate_cell, 0)) + moved
	_crate_berry_stock[crate_cell] = int(_crate_berry_stock.get(crate_cell, 0)) + moved
	_update_crate_visual(crate_cell)
	return moved


func take_travel_food(npc_id: int, amount: int) -> int:
	var from_barn := consume_food_from_farm_barn(amount)
	release_farm_barn_food_claim(npc_id)
	if from_barn >= amount:
		return from_barn
	return from_barn + consume_food_from_crate(npc_id, amount - from_barn)


func store_food_in_crate(npc_id: int, amount: int) -> int:
	if amount <= 0:
		return 0

	var crate_cell := get_crate_cell(npc_id)
	if crate_cell == INVALID_CELL:
		return 0

	var current_food := int(_crate_food.get(crate_cell, 0))
	var stored_amount := mini(amount, get_food_crate_capacity(npc_id) - current_food)
	if stored_amount <= 0:
		return 0

	_crate_food[crate_cell] = current_food + stored_amount
	_update_crate_visual(crate_cell)
	return stored_amount


func store_berries_in_crate(npc_id: int, amount: int) -> int:
	var stored_amount := store_food_in_crate(npc_id, amount)
	if stored_amount <= 0:
		return 0

	var crate_cell := get_crate_cell(npc_id)
	if crate_cell == INVALID_CELL:
		return 0

	_crate_berry_stock[crate_cell] = int(_crate_berry_stock.get(crate_cell, 0)) + stored_amount
	return stored_amount


func get_free_food_capacity(npc_id: int) -> int:
	var crate_cell := get_crate_cell(npc_id)
	if crate_cell == INVALID_CELL:
		return 0
	return maxi(get_food_crate_capacity(npc_id) - int(_crate_food.get(crate_cell, 0)), 0)


func consume_food_from_crate(npc_id: int, amount: int) -> int:
	if amount <= 0:
		return 0

	var crate_cell := get_crate_cell(npc_id)
	if crate_cell == INVALID_CELL:
		return 0

	var current_food := int(_crate_food.get(crate_cell, 0))
	var consumed_amount := mini(amount, current_food)
	if consumed_amount <= 0:
		return 0

	_crate_food[crate_cell] = current_food - consumed_amount
	var current_berries := int(_crate_berry_stock.get(crate_cell, 0))
	if current_berries > 0:
		_crate_berry_stock[crate_cell] = maxi(current_berries - consumed_amount, 0)
	_update_crate_visual(crate_cell)
	return consumed_amount


func get_crate_berry_stock(npc_id: int) -> int:
	var crate_cell := get_crate_cell(npc_id)
	if crate_cell == INVALID_CELL:
		return 0
	return int(_crate_berry_stock.get(crate_cell, 0))


func consume_berries_from_crate(npc_id: int, amount: int) -> int:
	if amount <= 0:
		return 0

	var crate_cell := get_crate_cell(npc_id)
	if crate_cell == INVALID_CELL:
		return 0

	var current_berries := int(_crate_berry_stock.get(crate_cell, 0))
	var consumed := mini(amount, current_berries)
	if consumed <= 0:
		return 0

	_crate_berry_stock[crate_cell] = current_berries - consumed
	_crate_food[crate_cell] = maxi(int(_crate_food.get(crate_cell, 0)) - consumed, 0)
	_update_crate_visual(crate_cell)
	return consumed


func get_crate_access_cell(npc_id: int, from_cell: Vector2i) -> Vector2i:
	var crate_cell := get_crate_cell(npc_id)
	if crate_cell == INVALID_CELL:
		return INVALID_CELL

	return _find_nearest_access_cell(crate_cell, from_cell)


func find_nearest_water_access_cell(origin_cell: Vector2i) -> Vector2i:
	var shore_candidates: Array = _shore_cell_index.get_candidates(origin_cell, maxi(map_width, map_height), 160) if _shore_cell_index != null else []
	for cell in shore_candidates:
		if _can_npc_enter(cell, INVALID_CELL, false):
			return cell
	return INVALID_CELL


func claim_fishing_spot(origin_cell: Vector2i, npc_id: int) -> Vector2i:
	var best_cell := INVALID_CELL
	var best_score := INF

	var shore_candidates: Array = _shore_cell_index.get_candidates(origin_cell, maxi(map_width, map_height), 160) if _shore_cell_index != null else []
	for cell in shore_candidates:
		if not _is_valid_fishing_spot(cell, npc_id):
			continue

		var score := origin_cell.distance_squared_to(cell)
		if score < best_score:
			best_score = score
			best_cell = cell

	if best_cell != INVALID_CELL:
		_fishing_claims[best_cell] = npc_id

	return best_cell


func get_nearest_fishing_spot_distance(from_cell: Vector2i, origin_cell: Vector2i, npc_id: int) -> float:
	var best_score := INF

	var shore_candidates: Array = _shore_cell_index.get_candidates(origin_cell, maxi(map_width, map_height), 160) if _shore_cell_index != null else []
	for cell in shore_candidates:
		if not _is_valid_fishing_spot(cell, npc_id):
			continue
		best_score = minf(best_score, from_cell.distance_squared_to(cell))

	return best_score


func release_fishing_spot(cell: Vector2i, npc_id: int) -> void:
	if int(_fishing_claims.get(cell, -1)) == npc_id:
		_fishing_claims.erase(cell)


func is_cell_near_water(cell: Vector2i) -> bool:
	return _near_water_cells.has(cell)


func get_food_crate_capacity(npc_id: int = -1) -> int:
	if npc_id == -1:
		return FOOD_CRATE_CAPACITY

	var crate_cell := get_crate_cell(npc_id)
	if crate_cell == INVALID_CELL:
		return FOOD_CRATE_CAPACITY
	return UPGRADED_FOOD_CRATE_CAPACITY if int(_crate_levels.get(crate_cell, 1)) >= 2 else FOOD_CRATE_CAPACITY


func get_fish_success_chance() -> float:
	return fish_success_chance


func get_food_gather_amount() -> int:
	return food_gather_amount


func get_berry_seed_cost() -> int:
	return berry_seed_cost


func get_farm_barn_wood_cost() -> int:
	return farm_barn_wood_cost


func get_farm_barn_stone_cost() -> int:
	return farm_barn_stone_cost


func get_warehouse_level_1_wood_cost() -> int:
	return warehouse_level_1_wood_cost


func get_warehouse_level_1_stone_cost() -> int:
	return warehouse_level_1_stone_cost


func get_warehouse_level_2_wood_cost() -> int:
	return warehouse_level_2_wood_cost


func get_warehouse_level_2_stone_cost() -> int:
	return warehouse_level_2_stone_cost


func get_npc_initial_age_min() -> float:
	return npc_initial_age_min


func get_npc_initial_age_max() -> float:
	return npc_initial_age_max


func get_npc_lifespan_min_years() -> float:
	return npc_lifespan_min_years


func get_npc_lifespan_max_years() -> float:
	return npc_lifespan_max_years


func has_house(npc_id: int) -> bool:
	return _npc_home_cells.has(npc_id)


func get_home_cell(npc_id: int) -> Vector2i:
	return _npc_home_cells.get(npc_id, INVALID_CELL)


func get_spawn_cell(npc_id: int) -> Vector2i:
	return _npc_spawn_cells.get(npc_id, INVALID_CELL)


func get_days_per_second() -> float:
	return 1.0 / maxf(day_duration_seconds, 0.1)


func get_day_duration_seconds() -> float:
	return day_duration_seconds


func get_days_in_year() -> int:
	return DAYS_PER_MONTH * MONTHS_PER_YEAR


func handle_worm_death(worm_id: int, body_cell: Vector2i) -> void:
	if _worms.has(worm_id):
		_worms.erase(worm_id)
	unregister_worm_cell(worm_id)
	_mark_combat_cache_dirty()
	_spawn_worm_meat_drop(body_cell, worm_meat_drop_amount)


func worm_exists(worm_id: int) -> bool:
	if not _worms.has(worm_id):
		return false
	var worm: Node2D = _worms[worm_id]
	return is_instance_valid(worm) and bool(worm.call("is_combat_alive"))


func get_worm_access_cell(worm_id: int, from_cell: Vector2i) -> Vector2i:
	if not worm_exists(worm_id):
		return INVALID_CELL
	var worm: Node2D = _worms[worm_id]
	var worm_cell: Vector2i = worm.call("get_current_cell")
	return _find_nearest_access_cell(worm_cell, from_cell)


func register_worm_cell(worm_id: int, cell: Vector2i) -> void:
	if _entity_index != null:
		_entity_index.register_worm(worm_id, cell)


func update_worm_cell(worm_id: int, old_cell: Vector2i, new_cell: Vector2i) -> void:
	if _entity_index != null:
		_entity_index.update_worm(worm_id, old_cell, new_cell)


func unregister_worm_cell(worm_id: int) -> void:
	if _entity_index != null:
		_entity_index.unregister_worm(worm_id)


func _spawn_worm_meat_drop(origin_cell: Vector2i, amount: int) -> void:
	if amount <= 0 or _worm_meat_texture == null:
		return

	var drop_cell := origin_cell
	if not _can_npc_enter(drop_cell, INVALID_CELL, false):
		drop_cell = _find_loot_bag_cell(origin_cell)
	if drop_cell == INVALID_CELL:
		return

	if _worm_meat_nodes.has(drop_cell):
		_worm_meat_food[drop_cell] = int(_worm_meat_food.get(drop_cell, 0)) + amount
		_sync_food_spatial_index(drop_cell)
		return

	var meat := Sprite2D.new()
	meat.texture = _worm_meat_texture
	meat.centered = true
	meat.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	meat.position = _cell_center(drop_cell) + Vector2(0.0, -6.0)
	meat.scale = Vector2.ONE * 0.92
	objects_root.add_child(meat)

	_worm_meat_nodes[drop_cell] = meat
	_worm_meat_food[drop_cell] = amount
	_sync_food_spatial_index(drop_cell)


func handle_npc_death(npc_id: int, body_cell: Vector2i, death_reason: String, age_days: float) -> void:
	var drop_items := {}
	if _wanderers.has(npc_id):
		var dead_wanderer: Node2D = _wanderers[npc_id]
		if is_instance_valid(dead_wanderer) and dead_wanderer.has_method("get_drop_inventory"):
			drop_items = dead_wanderer.call("get_drop_inventory")

	_release_owned_structures(npc_id)
	_spawn_corpse(body_cell, death_reason, age_days)
	_spawn_loot_bag_near(body_cell, drop_items)
	_append_death_log("%s | NPC #%d | Причина: %s | Возраст: %.1f дней | Клетка: %s" % [
		_current_date_text(),
		npc_id,
		death_reason,
		age_days,
		_format_cell_text(body_cell),
	])

	if _wanderers.has(npc_id):
		var dead_wanderer: Node2D = _wanderers[npc_id]
		_wanderers.erase(npc_id)
		unregister_npc_cell(npc_id)
		_mark_combat_cache_dirty()
		if _selected_npc == dead_wanderer:
			_close_npc_card()


func _release_owned_structures(npc_id: int) -> void:
	var home_cell := get_home_cell(npc_id)
	if home_cell != INVALID_CELL:
		_npc_home_cells.erase(npc_id)
		_house_owner_by_cell[home_cell] = -1
		_house_children_born[home_cell] = 0
		_show_free_house_sign(home_cell)

	var crate_cell := get_crate_cell(npc_id)
	if crate_cell != INVALID_CELL:
		_npc_crate_cells.erase(npc_id)


func _spawn_loot_bag_near(origin_cell: Vector2i, items: Dictionary) -> void:
	if items.is_empty():
		return
	if _total_loot_item_count(items) <= 0:
		return

	var spawn_cell := _find_loot_bag_cell(origin_cell)
	if spawn_cell == INVALID_CELL or _loot_bag_texture == null:
		return

	var bag := Sprite2D.new()
	bag.texture = _loot_bag_texture
	bag.centered = true
	bag.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bag.position = _cell_center(spawn_cell) + Vector2(0.0, -8.0)
	bag.scale = Vector2.ONE * 1.0
	objects_root.add_child(bag)

	_loot_bag_nodes[spawn_cell] = bag
	_loot_bag_items[spawn_cell] = {
		"wood": int(items.get("wood", 0)),
		"stone": int(items.get("stone", 0)),
		"food": int(items.get("food", 0)),
		"berries": int(items.get("berries", 0)),
	}
	if _loot_bag_index != null:
		_loot_bag_index.insert(spawn_cell)


func _find_loot_bag_cell(origin_cell: Vector2i) -> Vector2i:
	var candidates := [origin_cell]
	for dir in CARDINAL_DIRS:
		candidates.append(origin_cell + dir)
	for dir in EIGHT_DIRS:
		candidates.append(origin_cell + dir)

	for cell in candidates:
		if not _is_inside(cell.x, cell.y):
			continue
		if _loot_bag_nodes.has(cell):
			continue
		if not _can_npc_enter(cell, INVALID_CELL, false):
			continue
		return cell
	return INVALID_CELL


func _total_loot_item_count(items: Dictionary) -> int:
	return int(items.get("wood", 0)) + int(items.get("stone", 0)) + int(items.get("food", 0)) + int(items.get("berries", 0))


func claim_nearest_loot_bag(from_cell: Vector2i, npc_id: int) -> Vector2i:
	var best_cell := INVALID_CELL
	var best_score := INF

	var loot_candidates: Array = _loot_bag_index.get_candidates(from_cell, maxi(map_width, map_height), 128) if _loot_bag_index != null else _loot_bag_nodes.keys()
	for cell in loot_candidates:
		if _total_loot_item_count(_loot_bag_items.get(cell, {})) <= 0:
			continue
		var claimed_by := int(_loot_bag_claims.get(cell, -1))
		if claimed_by != -1 and claimed_by != npc_id:
			continue
		var score := from_cell.distance_squared_to(cell)
		if score < best_score:
			best_score = score
			best_cell = cell

	if best_cell != INVALID_CELL:
		_loot_bag_claims[best_cell] = npc_id
	return best_cell


func release_loot_bag_claim(cell: Vector2i, npc_id: int) -> void:
	if int(_loot_bag_claims.get(cell, -1)) == npc_id:
		_loot_bag_claims.erase(cell)


func loot_bag_exists(cell: Vector2i) -> bool:
	return _loot_bag_nodes.has(cell) and _total_loot_item_count(_loot_bag_items.get(cell, {})) > 0


func pickup_loot_bag(cell: Vector2i, npc_id: int) -> Dictionary:
	if not _loot_bag_nodes.has(cell):
		release_loot_bag_claim(cell, npc_id)
		return {}
	var claimed_by := int(_loot_bag_claims.get(cell, -1))
	if claimed_by != -1 and claimed_by != npc_id:
		return {}

	var items: Dictionary = _loot_bag_items.get(cell, {})
	var picked := {
		"wood": int(items.get("wood", 0)),
		"stone": int(items.get("stone", 0)),
		"food": int(items.get("food", 0)),
		"berries": int(items.get("berries", 0)),
	}

	var bag: Sprite2D = _loot_bag_nodes.get(cell, null)
	if is_instance_valid(bag):
		bag.queue_free()
	_loot_bag_nodes.erase(cell)
	_loot_bag_items.erase(cell)
	_loot_bag_claims.erase(cell)
	if _loot_bag_index != null:
		_loot_bag_index.remove(cell)
	return picked


func _show_free_house_sign(house_cell: Vector2i) -> void:
	if _free_house_sign_texture == null or not _house_nodes.has(house_cell):
		return

	var existing: Sprite2D = _free_house_sign_nodes.get(house_cell, null)
	if existing != null and is_instance_valid(existing):
		existing.visible = true
		return

	var sign := Sprite2D.new()
	sign.texture = _free_house_sign_texture
	sign.centered = true
	sign.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sign.scale = Vector2.ONE * 3.2
	sign.position = _cell_center(house_cell) + Vector2(24.0, -38.0)
	objects_root.add_child(sign)
	_free_house_sign_nodes[house_cell] = sign


func _hide_free_house_sign(house_cell: Vector2i) -> void:
	if not _free_house_sign_nodes.has(house_cell):
		return

	var sign: Sprite2D = _free_house_sign_nodes[house_cell]
	if is_instance_valid(sign):
		sign.queue_free()
	_free_house_sign_nodes.erase(house_cell)


func _spawn_corpse(cell: Vector2i, death_reason: String, age_days: float) -> void:
	if _dead_body_frames == null:
		return

	var corpse := AnimatedSprite2D.new()
	corpse.sprite_frames = _dead_body_frames
	corpse.animation = "decay"
	corpse.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	corpse.centered = true
	corpse.position = _cell_center(cell) + Vector2(0.0, 12.0)
	corpse.rotation_degrees = 90.0
	corpse.scale = Vector2.ONE * 1.18
	corpse.set_meta("death_reason", death_reason)
	corpse.set_meta("age_days", age_days)
	objects_root.add_child(corpse)
	corpse.play("decay")
	_corpse_decay_timers[corpse] = CORPSE_DECAY_DURATION


func get_population_count() -> int:
	_cleanup_wanderers()
	return _wanderers.size()


func register_npc_cell(npc_id: int, cell: Vector2i) -> void:
	if _entity_index != null:
		_entity_index.register_npc(npc_id, cell)


func update_npc_cell(npc_id: int, old_cell: Vector2i, new_cell: Vector2i) -> void:
	if _entity_index != null:
		_entity_index.update_npc(npc_id, old_cell, new_cell)


func unregister_npc_cell(npc_id: int) -> void:
	if _entity_index != null:
		_entity_index.unregister_npc(npc_id)


func get_house_count() -> int:
	return _house_nodes.size()


func get_crate_count() -> int:
	return _crate_nodes.size()


func is_cell_walkable(cell: Vector2i) -> bool:
	return _can_npc_enter(cell, INVALID_CELL, false)


func is_cell_walkable_for_worm(cell: Vector2i, worm_id: int = -1) -> bool:
	return _can_worm_enter(cell, worm_id)


func find_worm_next_step(start_cell: Vector2i, target_cell: Vector2i, worm_id: int = -1) -> Vector2i:
	if _navigation_service == null:
		return INVALID_CELL
	return _navigation_service.find_worm_next_step(self, start_cell, target_cell, worm_id)


func find_next_step(start_cell: Vector2i, target_cell: Vector2i, allow_tree_target: bool) -> Vector2i:
	if _navigation_service == null:
		return INVALID_CELL
	return _navigation_service.find_npc_next_step(self, start_cell, target_cell, allow_tree_target)


func _can_npc_enter(cell: Vector2i, target_cell: Vector2i, allow_tree_target: bool) -> bool:
	if not _is_inside(cell.x, cell.y):
		return false
	if _terrain_grid.is_empty():
		return false
	if _terrain_grid[cell.y][cell.x] == TerrainType.WATER:
		return false
	if _house_nodes.has(cell):
		return false
	if _crate_nodes.has(cell):
		return false
	if _farm_barn_nodes.has(cell):
		return false
	if _warehouse_nodes.has(cell):
		return false
	if _mega_boulder_nodes.has(cell):
		return false
	if _sapling_nodes.has(cell):
		return false
	if _is_worm_on_cell(cell):
		return false
	if _tree_nodes.has(cell) and (cell != target_cell or not allow_tree_target):
		return false
	return true


func _can_worm_enter(cell: Vector2i, worm_id: int = -1) -> bool:
	if not _is_inside(cell.x, cell.y):
		return false
	if _terrain_grid.is_empty():
		return false
	if _terrain_grid[cell.y][cell.x] == TerrainType.WATER:
		return false
	if _house_nodes.has(cell) or _crate_nodes.has(cell) or _farm_barn_nodes.has(cell) or _warehouse_nodes.has(cell):
		return false
	if _mega_boulder_nodes.has(cell) or _sapling_nodes.has(cell):
		return false
	if _tree_nodes.has(cell) or _rock_nodes.has(cell) or _bush_nodes.has(cell):
		return false
	if _loot_bag_nodes.has(cell) or _worm_meat_nodes.has(cell):
		return false
	if _is_worm_on_cell(cell, worm_id):
		return false
	if _is_npc_on_cell(cell):
		return false
	return true


func _is_npc_on_cell(cell: Vector2i, ignore_npc_id: int = -1) -> bool:
	if _entity_index == null:
		return false
	return _entity_index.is_npc_on_cell(cell, ignore_npc_id)


func _is_worm_on_cell(cell: Vector2i, ignore_worm_id: int = -1) -> bool:
	if _entity_index == null:
		return false
	return _entity_index.is_worm_on_cell(cell, ignore_worm_id)


func _cleanup_worms() -> void:
	var stale_ids: Array = []
	for worm_id in _worms.keys():
		var worm: Node2D = _worms[worm_id]
		if is_instance_valid(worm):
			continue
		stale_ids.append(worm_id)

	for worm_id in stale_ids:
		_worms.erase(worm_id)
		unregister_worm_cell(int(worm_id))
	if not stale_ids.is_empty():
		_mark_combat_cache_dirty()


func _update_crate_visual(crate_cell: Vector2i) -> void:
	if not _crate_nodes.has(crate_cell):
		return

	var crate_sprite: Sprite2D = _crate_nodes[crate_cell]
	if not is_instance_valid(crate_sprite):
		return

	var food_amount := int(_crate_food.get(crate_cell, 0))
	var crate_level := int(_crate_levels.get(crate_cell, 1))
	if crate_level >= 2:
		crate_sprite.texture = _crate_level_2_full_texture if food_amount > 0 else _crate_level_2_empty_texture
	else:
		crate_sprite.texture = _crate_full_texture if food_amount > 0 else _crate_empty_texture


func _find_nearest_access_cell(target_cell: Vector2i, from_cell: Vector2i) -> Vector2i:
	var best_cell := INVALID_CELL
	var best_score := INF

	for direction in CARDINAL_DIRS:
		var access_cell: Vector2i = target_cell + direction
		if not _can_npc_enter(access_cell, INVALID_CELL, false):
			continue

		var score := from_cell.distance_squared_to(access_cell)
		if score < best_score:
			best_score = score
			best_cell = access_cell

	return best_cell


func _score_crate_site(cell: Vector2i, home_cell: Vector2i, npc_id: int) -> float:
	if not _is_buildable_crate_cell(cell, npc_id):
		return -INF

	var distance_penalty := home_cell.distance_squared_to(cell) * 0.9
	var water_bonus := float(_count_in_radius(_terrain_grid, cell.x, cell.y, 4, TerrainType.WATER)) * 0.1
	return 12.0 + water_bonus - distance_penalty


func _is_buildable_crate_cell(cell: Vector2i, npc_id: int) -> bool:
	if not _is_inside(cell.x, cell.y):
		return false
	if _terrain_grid.is_empty():
		return false
	if _terrain_grid[cell.y][cell.x] == TerrainType.WATER:
		return false
	if _tree_nodes.has(cell) or _bush_nodes.has(cell) or _rock_nodes.has(cell) or _house_nodes.has(cell) or _crate_nodes.has(cell):
		return false

	for claimant_id in _crate_claims.keys():
		if claimant_id == npc_id:
			continue
		var claimed_cell: Vector2i = _crate_claims[claimant_id]
		if cell == claimed_cell:
			return false

	return true


func _is_valid_fishing_spot(cell: Vector2i, npc_id: int) -> bool:
	if not _can_npc_enter(cell, INVALID_CELL, false):
		return false
	if not is_cell_near_water(cell):
		return false

	var claimed_by := int(_fishing_claims.get(cell, -1))
	return claimed_by == -1 or claimed_by == npc_id


func _score_house_site(cell: Vector2i, origin_cell: Vector2i) -> float:
	if not _is_buildable_house_cell(cell, -1):
		return -INF

	var terrain_bonus := 5.0 if _terrain_grid[cell.y][cell.x] == TerrainType.GRASS else 2.0
	var distance_penalty := origin_cell.distance_squared_to(cell) * 0.08
	var nearby_trees := _count_tree_cells_in_radius(cell, 6)
	var nearby_water := _count_in_radius(_terrain_grid, cell.x, cell.y, 5, TerrainType.WATER)
	return terrain_bonus + float(nearby_trees) * 0.18 + float(nearby_water) * 0.03 - distance_penalty


func _is_buildable_house_cell(cell: Vector2i, npc_id: int) -> bool:
	if not _is_inside(cell.x, cell.y):
		return false
	if _terrain_grid.is_empty():
		return false
	if _terrain_grid[cell.y][cell.x] == TerrainType.WATER:
		return false
	if _tree_nodes.has(cell) or _bush_nodes.has(cell) or _rock_nodes.has(cell) or _crate_nodes.has(cell):
		return false

	for house_cell in _house_nodes.keys():
		if cell.distance_to(house_cell) < 4.0:
			return false

	for claimant_id in _house_claims.keys():
		if claimant_id == npc_id:
			continue
		var claimed_cell: Vector2i = _house_claims[claimant_id]
		if cell == claimed_cell or cell.distance_to(claimed_cell) < 3.0:
			return false

	return _count_neighbors(_terrain_grid, cell.x, cell.y, TerrainType.WATER) == 0


func _count_tree_cells_in_radius(center_cell: Vector2i, radius: int) -> int:
	return _tree_index.count_in_radius(center_cell, radius) if _tree_index != null else 0


func _find_best_view_cell(terrain_grid: Array) -> Vector2i:
	var best_cell := Vector2i(map_width / 2, map_height / 2)
	var best_score := -1.0
	var radius := 6
	var sample_size := float((radius * 2 + 1) * (radius * 2 + 1))

	for y in range(8, map_height - 8):
		for x in range(8, map_width - 8):
			if terrain_grid[y][x] != TerrainType.GRASS:
				continue

			var water_score := _count_in_radius(terrain_grid, x, y, radius, TerrainType.WATER)
			var grass_score := _count_in_radius(terrain_grid, x, y, radius, TerrainType.GRASS)
			var desert_score := _count_in_radius(terrain_grid, x, y, radius, TerrainType.DESERT)
			var water_ratio := float(water_score) / sample_size
			var land_mix := minf(float(grass_score), float(desert_score))
			var flora_bonus := _noise01(_flora_noise, float(x) + 280.0, float(y) - 160.0)

			if grass_score < 26:
				continue
			if water_ratio < 0.05 or water_ratio > 0.30:
				continue

			var score := (1.0 - absf(water_ratio - 0.22) * 4.0) * 24.0
			score += land_mix * 0.22
			score += float(grass_score) * 0.06
			score += flora_bonus * 12.0
			score += float(_count_neighbors(terrain_grid, x, y, TerrainType.WATER)) * 1.1
			score += float(_count_neighbors(terrain_grid, x, y, TerrainType.DESERT)) * 0.55
			score += minf(float(desert_score), 22.0) * 0.10
			score += 4.0

			if score > best_score:
				best_score = score
				best_cell = Vector2i(x, y)

	return best_cell


func _replace_small_regions(grid: Array, target_value: int, min_size: int, replacement_value: int) -> void:
	var visited := _make_grid(false)

	for y in range(map_height):
		for x in range(map_width):
			if visited[y][x] or int(grid[y][x]) != target_value:
				continue

			var region := []
			var stack := [Vector2i(x, y)]
			visited[y][x] = true

			while not stack.is_empty():
				var cell: Vector2i = stack.pop_back()
				region.append(cell)

				for direction in CARDINAL_DIRS:
					var next_cell: Vector2i = cell + direction
					if not _is_inside(next_cell.x, next_cell.y):
						continue
					if visited[next_cell.y][next_cell.x]:
						continue
					if int(grid[next_cell.y][next_cell.x]) != target_value:
						continue

					visited[next_cell.y][next_cell.x] = true
					stack.append(next_cell)

			if region.size() < min_size:
				for cell in region:
					grid[cell.y][cell.x] = replacement_value


func _make_grid(fill_value) -> Array:
	var grid := []
	grid.resize(map_height)

	for y in range(map_height):
		var row := []
		row.resize(map_width)
		row.fill(fill_value)
		grid[y] = row

	return grid


func _clone_grid(grid: Array) -> Array:
	var clone := []
	clone.resize(grid.size())

	for y in range(grid.size()):
		clone[y] = grid[y].duplicate()

	return clone


func _count_neighbors(grid: Array, x: int, y: int, target_value: int) -> int:
	var count := 0

	for direction in EIGHT_DIRS:
		var nx: int = x + direction.x
		var ny: int = y + direction.y
		if not _is_inside(nx, ny):
			continue
		if int(grid[ny][nx]) == target_value:
			count += 1

	return count


func _count_in_radius(grid: Array, x: int, y: int, radius: int, target_value: int) -> int:
	var count := 0

	for offset_y in range(-radius, radius + 1):
		for offset_x in range(-radius, radius + 1):
			var nx := x + offset_x
			var ny := y + offset_y
			if not _is_inside(nx, ny):
				continue
			if int(grid[ny][nx]) == target_value:
				count += 1

	return count


func _is_area_free(occupied: Array, x: int, y: int, radius: int) -> bool:
	for offset_y in range(-radius, radius + 1):
		for offset_x in range(-radius, radius + 1):
			var nx := x + offset_x
			var ny := y + offset_y
			if not _is_inside(nx, ny):
				continue
			if occupied[ny][nx]:
				return false

	return true


func _mark_area(occupied: Array, x: int, y: int, radius: int) -> void:
	for offset_y in range(-radius, radius + 1):
		for offset_x in range(-radius, radius + 1):
			var nx := x + offset_x
			var ny := y + offset_y
			if not _is_inside(nx, ny):
				continue
			occupied[ny][nx] = true


func _advance_calendar(delta: float) -> void:
	_calendar_elapsed += delta
	_calendar_day_index = int(floor(_calendar_elapsed / DAY_DURATION_SECONDS))
	var month_index := int(floor(float(_calendar_day_index) / float(DAYS_PER_MONTH)))
	if _calendar_day_index > 0 and month_index > _last_worm_spawn_month:
		_last_worm_spawn_month = month_index
		_spawn_monthly_worms()


func _spawn_monthly_worms() -> void:
	if worms_per_month <= 0 or _worm_frames == null:
		return

	var spawn_origin := _find_leader_rally_cell()
	for spawn_index in range(worms_per_month):
		var spawn_cell := _find_worm_spawn_cell(spawn_origin, spawn_index == 0)
		if spawn_cell == INVALID_CELL:
			continue
		_spawn_worm(spawn_cell)


func _find_worm_spawn_cell(origin_cell: Vector2i, prefer_near_origin: bool) -> Vector2i:
	if prefer_near_origin and origin_cell != INVALID_CELL:
		for radius in [18, 24, 32]:
			for _attempt in range(36):
				var candidate := Vector2i(
					clampi(origin_cell.x + _runtime_rng.randi_range(-radius, radius), 1, map_width - 2),
					clampi(origin_cell.y + _runtime_rng.randi_range(-radius, radius), 1, map_height - 2)
				)
				if candidate.distance_to(origin_cell) < 10.0:
					continue
				if _can_worm_enter(candidate):
					return candidate

	for _attempt in range(300):
		var fallback := Vector2i(_runtime_rng.randi_range(1, map_width - 2), _runtime_rng.randi_range(1, map_height - 2))
		if _can_worm_enter(fallback):
			return fallback

	return INVALID_CELL


func _spawn_worm(spawn_cell: Vector2i) -> void:
	if spawn_cell == INVALID_CELL or _worm_frames == null:
		return

	var worm := Node2D.new()
	worm.set_script(WORM_SCRIPT)
	worm.name = "Worm%d" % _next_worm_id
	worm.set_meta("worm_id", _next_worm_id)

	var animated_sprite := AnimatedSprite2D.new()
	animated_sprite.centered = true
	animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	animated_sprite.sprite_frames = _worm_frames
	animated_sprite.position = Vector2(0.0, -16.0)
	animated_sprite.scale = Vector2.ONE * 1.45
	worm.add_child(animated_sprite)

	characters_root.add_child(worm)
	_worms[_next_worm_id] = worm
	_mark_combat_cache_dirty()
	worm.call("setup", spawn_cell, self, _current_seed + 400000, _next_worm_id)
	register_worm_cell(_next_worm_id, spawn_cell)
	_next_worm_id += 1


func _current_date_text() -> String:
	var absolute_day := _calendar_day_index
	var year := int(floor(float(absolute_day) / float(get_days_in_year()))) + 1
	var day_in_year := absolute_day % get_days_in_year()
	var month_index := int(floor(float(day_in_year) / float(DAYS_PER_MONTH)))
	var day := (day_in_year % DAYS_PER_MONTH) + 1
	var month_name: String = _month_names[clampi(month_index, 0, _month_names.size() - 1)]
	return "Дата: %d_%s_%d" % [year, month_name, day]


func _update_corpse_decay(delta: float) -> void:
	var stale_corpses := []
	for corpse in _corpse_decay_timers.keys():
		var time_left := float(_corpse_decay_timers[corpse]) - delta
		if not is_instance_valid(corpse) or time_left <= 0.0:
			stale_corpses.append(corpse)
			continue
		_corpse_decay_timers[corpse] = time_left

	for corpse in stale_corpses:
		if is_instance_valid(corpse):
			corpse.queue_free()
		_corpse_decay_timers.erase(corpse)


func _clear_objects() -> void:
	for child in objects_root.get_children():
		child.queue_free()
	for child in characters_root.get_children():
		child.queue_free()
	_tree_nodes.clear()
	_tree_claims.clear()
	_tree_food.clear()
	_tree_regrow_timers.clear()
	_sapling_nodes.clear()
	_sapling_growth_timers.clear()
	_bush_nodes.clear()
	_bush_food.clear()
	_bush_empty_timers.clear()
	_food_claims.clear()
	_rock_nodes.clear()
	_rock_claims.clear()
	_rock_respawn_timers.clear()
	_mega_boulder_nodes.clear()
	_mega_boulder_timers.clear()
	_farm_plot_nodes.clear()
	_farm_plot_states.clear()
	_farm_growth_timers.clear()
	_farm_claims.clear()
	_farm_barn_nodes.clear()
	_farm_barn_claims.clear()
	_farm_barn_food_claims.clear()
	_farm_barn_food = 0
	_farm_barn_berry_stock = 0
	_warehouse_nodes.clear()
	_warehouse_claims.clear()
	_warehouse_levels.clear()
	_warehouse_wood = 0
	_warehouse_stone = 0
	_house_nodes.clear()
	_house_claims.clear()
	_vacant_house_claims.clear()
	_house_levels.clear()
	_house_owner_by_cell.clear()
	_house_children_born.clear()
	_house_crate_cells.clear()
	_free_house_sign_nodes.clear()
	_crate_nodes.clear()
	_crate_claims.clear()
	_crate_food.clear()
	_crate_berry_stock.clear()
	_crate_levels.clear()
	_crate_home_cells.clear()
	_loot_bag_nodes.clear()
	_loot_bag_items.clear()
	_loot_bag_claims.clear()
	_worms.clear()
	_worm_cells.clear()
	_worm_meat_nodes.clear()
	_worm_meat_food.clear()
	_fishing_claims.clear()
	_npc_home_cells.clear()
	_npc_crate_cells.clear()
	_npc_spawn_cells.clear()
	_wanderers.clear()
	_corpse_decay_timers.clear()
	if _entity_index != null:
		_entity_index.clear()
	if _tree_index != null:
		_tree_index.clear()
	if _food_index != null:
		_food_index.clear()
	if _rock_index != null:
		_rock_index.clear()
	if _loot_bag_index != null:
		_loot_bag_index.clear()
	if _shore_cell_index != null:
		_shore_cell_index.clear()
	if _leader_role_planner != null:
		_leader_role_planner.shutdown()
	_combat_wanderers_cache.clear()
	_combat_worms_cache.clear()
	_combat_cache_dirty = true
	_clear_path_cache()
	_death_log_entries.clear()
	if _death_log_ui != null:
		_death_log_ui.clear()
	elif _death_log_label != null:
		_death_log_label.text = "Пока никто не умер."
	_selected_npc = null
	_selected_structure_type = ""
	_selected_structure_cell = INVALID_CELL
	npc_card_panel.visible = false


func _terrain_source_id(terrain_type: int) -> int:
	match terrain_type:
		TerrainType.WATER:
			return WATER_SOURCE_ID
		TerrainType.DESERT:
			return DESERT_SOURCE_ID
		_:
			return GRASS_SOURCE_ID


func _change_zoom(step: float) -> void:
	var zoom_value := clampf(camera.zoom.x + step, 0.45, 1.8)
	camera.zoom = Vector2.ONE * zoom_value
	_clamp_camera()


func _clamp_camera() -> void:
	var map_size := _map_pixel_size()
	var half_screen := get_viewport_rect().size * 0.5 * camera.zoom

	if map_size.x <= half_screen.x * 2.0:
		camera.position.x = map_size.x * 0.5
	else:
		camera.position.x = clampf(camera.position.x, half_screen.x, map_size.x - half_screen.x)

	if map_size.y <= half_screen.y * 2.0:
		camera.position.y = map_size.y * 0.5
	else:
		camera.position.y = clampf(camera.position.y, half_screen.y, map_size.y - half_screen.y)


func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * TILE_SIZE.x, (cell.y + 0.5) * TILE_SIZE.y)


func _world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(
		clampi(int(floor(world_position.x / float(TILE_SIZE.x))), 0, map_width - 1),
		clampi(int(floor(world_position.y / float(TILE_SIZE.y))), 0, map_height - 1)
	)


func _map_pixel_size() -> Vector2:
	return Vector2(map_width * TILE_SIZE.x, map_height * TILE_SIZE.y)


func _update_info_label() -> void:
	info_label.text = "%s\nНаселение: %d | Дома: %d\nSeed: %s\nR - new map\nF1 - developer tool\nP - death log\nWASD / arrows - move\nMouse wheel / +/- - zoom\nLMB on villager/barn/warehouse - info\nMMB - stop follow\nO - close card" % [
		_current_date_text(),
		get_population_count(),
		get_house_count(),
		_current_seed,
	]


func _is_inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < map_width and y < map_height


func _noise01(noise: FastNoiseLite, x: float, y: float) -> float:
	return noise.get_noise_2d(x, y) * 0.5 + 0.5
