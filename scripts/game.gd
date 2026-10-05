extends Node2D
class_name KitchenChaosGame

# ─── STATES ──────────────────────────────────────────────────────────────────
enum GameState {
	SPLASH, MENU, PLAYING, BOSS_FIGHT,
	PAUSED, PAUSE_OPTIONS, PAUSE_RECIPE,
	ROUND_COMPLETE, GAME_OVER, VICTORY,
	UPGRADES, SETTINGS, CREDITS, SAVE_SLOTS
}

# ─── CONSTANTS ───────────────────────────────────────────────────────────────
const ARENA        := Rect2(0, 0, 960, 540)
const HUD_TOP_H    := 60
const VERSION      := "v1.0"
const W            := 960
const H            := 540

# ─── NODES ───────────────────────────────────────────────────────────────────
var bg_sprite:         Sprite2D
var jeff_menu_sprite:  Sprite2D   # Jeff shown on main menu (right side)

# ─── MANAGERS ────────────────────────────────────────────────────────────────
var player:          ChefPlayer
var order_manager:   OrderManager
var sound_manager:   SoundManager
var upgrade_manager: UpgradeManager
var current_boss:    KitchenBoss

# ─── GAME VARS ────────────────────────────────────────────────────────────────
var state:            GameState = GameState.SPLASH
var round_num:        int   = 1
var max_rounds:       int   = 15
var round_timer:      float = 0.0
var coins:            int   = 0
var chaos_meter:      float = 0.0
var max_chaos:        float = 100.0
var completed_orders: int   = 0
var required_orders:  int   = 3
var game_over_reason: String = ""
var highest_round:    int   = 1
var total_orders:     int   = 0

# ─── MENU STATE ──────────────────────────────────────────────────────────────
var menu_idx:     int = 0
var upg_idx:      int = 0
var pause_idx:    int = 0
var settings_idx: int = 0
var recipe_page:  int = 0
var slot_idx: int = 0
var slot_mode: String = "new"
var slot_overwrite_confirm: bool = false
var slot_notice: String = ""
var slot_summaries: Array[Dictionary] = []

const MENU_OPTS    := ["NEW GAME", "CONTINUE", "UPGRADES", "RECIPE BOOK", "SETTINGS", "CREDITS", "QUIT"]
const PAUSE_OPTS   := ["RESUME", "OPTIONS", "RECIPE BOOK", "MAIN MENU"]
const UPG_NAMES    := ["speed_boots", "chef_timer", "extra_life"]
const UPG_LABELS   := ["Speed Boots", "Chef Timer", "Extra Life Token"]
const UPG_DESCS    := [
	"Move faster around the kitchen",
	"Complete cooking tasks faster",
	"Revive once when HP hits zero"
]
const UPG_ICONS    := ["👟", "⏱", "❤"]

const SETTINGS_OPTS := ["Master Vol", "SFX Vol", "Screen Shake", "Flash Effects", "Back"]
var master_vol:    int  = 80
var sfx_vol:       int  = 90
var screen_shake:  bool = true
var flash_effects: bool = true

# Recipe Book pages
const RECIPES := [
	{
		"name": "Pork Adobo",
		"icon": "🍖",
		"ingredients": ["Pork", "Soy Sauce", "Vinegar", "Garlic"],
		"steps": ["1. Chop the pork at the cutting board",
				  "2. Cook on the stove until browned",
				  "3. Place on plate at assembly station",
				  "4. Deliver to the pass window"],
		"reward": 15
	},
	{
		"name": "Sinigang",
		"icon": "🍲",
		"ingredients": ["Pork", "Tomato", "Vegetable", "Water"],
		"steps": ["1. Chop pork and tomato",
				  "2. Cook everything on the stove",
				  "3. Plate at assembly station",
				  "4. Deliver to the pass window"],
		"reward": 15
	},
	{
		"name": "Lumpia",
		"icon": "🌮",
		"ingredients": ["Pork", "Carrot", "Wrapper"],
		"steps": ["1. Chop pork and carrot",
				  "2. Wrap at assembly station",
				  "3. Fry on the stove",
				  "4. Deliver to the pass window"],
		"reward": 30
	},
	{
		"name": "Turon",
		"icon": "🍌",
		"ingredients": ["Banana", "Wrapper", "Rice"],
		"steps": ["1. Slice banana at cutting board",
				  "2. Wrap at assembly station",
				  "3. Fry until golden on stove",
				  "4. Deliver to the pass window"],
		"reward": 30
	},
	{
		"name": "Lechon",
		"icon": "🐷",
		"ingredients": ["Pork", "Rice", "Carrot", "Tomato"],
		"steps": ["1. Chop all ingredients",
				  "2. Slow cook on stove (takes longer!)",
				  "3. Plate carefully at assembly",
				  "4. Rush to the pass window!"],
		"reward": 55
	}
]

# ─── TIMERS / FLAGS ──────────────────────────────────────────────────────────
var splash_timer:       float = 3.0
var enemy_spawn_timer:  float = 5.0
var interact_was_down:  bool  = false
var stations:           Array[KitchenStation] = []
var enemies:            Array[KitchenEnemy]   = []
var map_obstacles:      Array[StaticBody2D]   = []

# Menu animation
var menu_anim_t: float = 0.0
var steam_particles: Array[Dictionary] = []
var camera_shake: float = 0.0
var flash_amount: float = 0.0

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()

	# Background sprite (drawn behind everything)
	bg_sprite = Sprite2D.new()
	bg_sprite.centered = true
	bg_sprite.position = Vector2(W / 2, H / 2)
	bg_sprite.z_index = -10
	add_child(bg_sprite)
	bg_sprite.texture = load("res://assets/processed/bg_day.png") as Texture2D

	# Jeff menu sprite (shown on main menu right side)
	jeff_menu_sprite = Sprite2D.new()
	jeff_menu_sprite.centered = true
	jeff_menu_sprite.position = Vector2(780, 350)
	jeff_menu_sprite.scale = Vector2(1.4, 1.4)
	jeff_menu_sprite.z_index = 5
	jeff_menu_sprite.visible = false
	jeff_menu_sprite.texture = load("res://assets/processed/jeff_idle.png") as Texture2D
	add_child(jeff_menu_sprite)

	sound_manager   = SoundManager.new();    add_child(sound_manager)
	upgrade_manager = UpgradeManager.new();  add_child(upgrade_manager)
	upgrade_manager.load_data()
	order_manager   = OrderManager.new()
	order_manager.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(order_manager)
	order_manager.order_completed.connect(_on_order_completed)
	order_manager.order_expired.connect(_on_order_expired)

	var sd := SaveManager.load_game()
	coins         = sd.get("coins", 0)
	highest_round = sd.get("highest_round", 1)
	master_vol    = int(sd.get("master_vol", master_vol))
	sfx_vol       = int(sd.get("sfx_vol", sfx_vol))
	_sync_audio_settings()

	_init_steam_particles()
	change_state(GameState.SPLASH)

func _init_steam_particles() -> void:
	for i in range(18):
		steam_particles.append({
			"x": randf_range(100, 860),
			"y": randf_range(100, 500),
			"vy": randf_range(-18.0, -8.0),
			"alpha": randf(),
			"size": randf_range(3, 8)
		})

# ─── PROCESS ─────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	menu_anim_t += delta
	flash_amount = maxf(flash_amount - delta * 2.5, 0.0)
	if screen_shake and camera_shake > 0.0:
		camera_shake = maxf(camera_shake - delta * 18.0, 0.0)
		position = Vector2(randf_range(-camera_shake, camera_shake), randf_range(-camera_shake, camera_shake))
	else:
		camera_shake = 0.0
		position = Vector2.ZERO

	# Animate steam particles in menu / splash
	if state == GameState.MENU or state == GameState.SPLASH:
		for p in steam_particles:
			p["y"] += p["vy"] * delta
			p["alpha"] -= delta * 0.15
			if p["alpha"] <= 0 or p["y"] < 50:
				p["x"]     = randf_range(100, 860)
				p["y"]     = randf_range(380, 500)
				p["vy"]    = randf_range(-22.0, -10.0)
				p["alpha"] = randf_range(0.3, 0.9)
				p["size"]  = randf_range(3, 8)

	match state:
		GameState.SPLASH:
			splash_timer -= delta
			if splash_timer <= 0:
				change_state(GameState.MENU)

		GameState.PLAYING:
			_process_playing(delta)

		GameState.BOSS_FIGHT:
			_process_boss_fight(delta)

	queue_redraw()

func _process_playing(delta: float) -> void:
	round_timer  -= delta
	chaos_meter   = clamp(chaos_meter - delta * 0.25, 0.0, max_chaos)

	if chaos_meter >= max_chaos:
		_trigger_game_over("The kitchen exploded! Too much chaos!")
		return
	if round_timer <= 0.0:
		if completed_orders >= required_orders:
			_complete_round()
		else:
			_trigger_game_over("Time's Up! Shift is over.")
		return

	_handle_enemy_spawn(delta)
	_handle_interact()
	_update_station_proximity()

func _process_boss_fight(delta: float) -> void:
	chaos_meter = clamp(chaos_meter + delta * 0.8, 0.0, max_chaos)
	if chaos_meter >= max_chaos:
		_trigger_game_over("The kitchen exploded! Too much chaos!")

func _update_station_proximity() -> void:
	if not is_instance_valid(player): return
	for s in stations:
		if is_instance_valid(s):
			s.player_nearby = player.global_position.distance_to(s.global_position) < 55.0

func _handle_enemy_spawn(delta: float) -> void:
	enemy_spawn_timer -= delta
	if enemy_spawn_timer <= 0.0:
		enemy_spawn_timer = max(8.0 - round_num * 0.35, 2.0)
		_spawn_enemy()

func _handle_interact() -> void:
	var e_down := Input.is_physical_key_pressed(KEY_E)
	if e_down and not interact_was_down:
		if is_instance_valid(player):
			for s in stations:
				if is_instance_valid(s) and player.global_position.distance_to(s.global_position) < 55.0:
					s.interact(player)
					break
	interact_was_down = e_down

func _spawn_enemy() -> void:
	if not is_instance_valid(player): return
	var spawn_pts: Array[Vector2] = [
		Vector2(50, 120), Vector2(910, 120),
		Vector2(50, 460),  Vector2(910, 460),
		Vector2(480, 80),  Vector2(480, 510)
	]
	var sp: Vector2 = spawn_pts[randi() % spawn_pts.size()]
	var enemy := KitchenEnemy.new()
	enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
	enemy.show_behind_parent = true
	enemy.global_position = sp
	enemy.target     = player
	var types := ["angry_pan", "living_ingredient"]
	if round_num >= 6:  types.append("flying_knife")
	enemy.type       = types[randi() % types.size()]
	enemy.move_speed = 80.0 + round_num * 3.0
	if round_num >= 11: enemy.hp = 5; enemy.max_hp = 5
	elif round_num >= 6: enemy.hp = 4; enemy.max_hp = 4
	enemy.enemy_died.connect(_on_enemy_died)
	add_child(enemy)
	enemies.append(enemy)

# ─── INPUT ────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if (state == GameState.PLAYING or state == GameState.BOSS_FIGHT) and is_instance_valid(player):
			player.attack_at(get_global_mouse_position())

	if event is InputEventKey and event.pressed:
		# Debug keys
		if event.keycode == KEY_F2 and (state == GameState.PLAYING or state == GameState.BOSS_FIGHT):
			coins += 100
		elif event.keycode == KEY_F3 and is_instance_valid(player):
			player.heal(3)
		elif event.keycode == KEY_F4 and state == GameState.PLAYING:
			_complete_round()
		elif event.keycode == KEY_F7:
			round_num = 4; start_round()
		elif event.keycode == KEY_F8:
			round_num = 14; start_round()

	match state:
		GameState.MENU:          _input_menu(event)
		GameState.SAVE_SLOTS:    _input_save_slots(event)
		GameState.UPGRADES:      _input_upgrades(event)
		GameState.SETTINGS:      _input_settings(event)
		GameState.CREDITS:       _input_back_on_any(event)
		GameState.PAUSED:        _input_pause(event)
		GameState.PAUSE_OPTIONS: _input_pause_options(event)
		GameState.PAUSE_RECIPE:  _input_recipe(event)
		GameState.PLAYING, GameState.BOSS_FIGHT:
			if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
				change_state(GameState.PAUSED)
		GameState.GAME_OVER:
			if event is InputEventKey and event.pressed:
				change_state(GameState.MENU)
		GameState.ROUND_COMPLETE:
			if event is InputEventKey and event.pressed:
				if event.keycode in [KEY_ENTER, KEY_SPACE]:
					start_round()
		GameState.VICTORY:
			if event is InputEventKey and event.pressed:
				change_state(GameState.MENU)

func _input_menu(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed:
		match ev.keycode:
			KEY_UP, KEY_W:    menu_idx = (menu_idx - 1 + MENU_OPTS.size()) % MENU_OPTS.size()
			KEY_DOWN, KEY_S:  menu_idx = (menu_idx + 1) % MENU_OPTS.size()
			KEY_ENTER, KEY_SPACE: _on_menu_select()
			KEY_ESCAPE:       get_tree().quit()
		for i in range(MENU_OPTS.size()):
			if ev.keycode == KEY_1 + i:
				menu_idx = i; _on_menu_select(); break

func _input_save_slots(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed:
		match ev.keycode:
			KEY_UP, KEY_W:
				slot_idx = (slot_idx - 1 + SaveManager.SLOT_COUNT) % SaveManager.SLOT_COUNT
				slot_overwrite_confirm = false
				slot_notice = ""
			KEY_DOWN, KEY_S:
				slot_idx = (slot_idx + 1) % SaveManager.SLOT_COUNT
				slot_overwrite_confirm = false
				slot_notice = ""
			KEY_ENTER, KEY_SPACE:
				_select_save_slot()
			KEY_ESCAPE:
				if slot_overwrite_confirm:
					slot_overwrite_confirm = false
					slot_notice = ""
				else:
					change_state(GameState.MENU)

func _select_save_slot() -> void:
	var selected_slot := slot_idx + 1
	var save_data := SaveManager.load_slot(selected_slot)
	if slot_mode == "continue":
		if not save_data.has("round_num"):
			slot_notice = "This slot is empty. Choose a saved game to continue."
			return
		_load_selected_slot(selected_slot, save_data)
		return

	if save_data.has("round_num") and not slot_overwrite_confirm:
		slot_overwrite_confirm = true
		slot_notice = "This will overwrite this slot. Press Enter again to confirm."
		return
	_start_new_game_in_slot(selected_slot, save_data)

func _load_selected_slot(selected_slot: int, save_data: Dictionary) -> void:
	SaveManager.set_active_slot(selected_slot)
	upgrade_manager.load_data()
	round_num = int(save_data.get("round_num", 1))
	coins = int(save_data.get("coins", 0))
	highest_round = int(save_data.get("highest_round", 1))
	master_vol = int(save_data.get("master_vol", master_vol))
	sfx_vol = int(save_data.get("sfx_vol", sfx_vol))
	_sync_audio_settings()
	slot_overwrite_confirm = false
	slot_notice = ""
	start_round()

func _start_new_game_in_slot(selected_slot: int, previous_data: Dictionary) -> void:
	SaveManager.set_active_slot(selected_slot)
	upgrade_manager.load_data()
	coins = 0
	round_num = 1
	highest_round = int(previous_data.get("highest_round", 1))
	master_vol = int(previous_data.get("master_vol", master_vol))
	sfx_vol = int(previous_data.get("sfx_vol", sfx_vol))
	_sync_audio_settings()
	upgrade_manager.reset_for_new_game()
	SaveManager.save_game({
		"coins": coins,
		"round_num": round_num,
		"highest_round": highest_round
	})
	slot_overwrite_confirm = false
	slot_notice = ""
	start_round()

func _input_upgrades(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed:
		var total := UPG_NAMES.size() + 1  # +1 for Back
		match ev.keycode:
			KEY_UP, KEY_W:   upg_idx = (upg_idx - 1 + total) % total
			KEY_DOWN, KEY_S: upg_idx = (upg_idx + 1) % total
			KEY_ENTER, KEY_SPACE: _on_upgrades_select()
			KEY_ESCAPE:      change_state(GameState.MENU)

func _input_settings(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed:
		match ev.keycode:
			KEY_UP, KEY_W:
				settings_idx = (settings_idx - 1 + SETTINGS_OPTS.size()) % SETTINGS_OPTS.size()
			KEY_DOWN, KEY_S:
				settings_idx = (settings_idx + 1) % SETTINGS_OPTS.size()
			KEY_LEFT:  _settings_adjust(-1)
			KEY_RIGHT: _settings_adjust(1)
			KEY_ENTER, KEY_SPACE: _settings_adjust(1)
			KEY_ESCAPE: change_state(GameState.MENU)

func _settings_adjust(dir: int) -> void:
	match settings_idx:
		0:
			master_vol = clamp(master_vol + dir * 10, 0, 100)
			_sync_audio_settings()
			SaveManager.save_game({"master_vol": master_vol, "sfx_vol": sfx_vol})
		1:
			sfx_vol = clamp(sfx_vol + dir * 10, 0, 100)
			_sync_audio_settings()
			SaveManager.save_game({"master_vol": master_vol, "sfx_vol": sfx_vol})
		2: screen_shake  = not screen_shake
		3: flash_effects = not flash_effects
		4: change_state(GameState.MENU)

func _sync_audio_settings() -> void:
	sound_manager.set_volumes(float(master_vol) / 100.0, float(sfx_vol) / 100.0)

func _input_pause(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed:
		match ev.keycode:
			KEY_UP, KEY_W:   pause_idx = (pause_idx - 1 + PAUSE_OPTS.size()) % PAUSE_OPTS.size()
			KEY_DOWN, KEY_S: pause_idx = (pause_idx + 1) % PAUSE_OPTS.size()
			KEY_ENTER, KEY_SPACE: _on_pause_select()
			KEY_ESCAPE:      change_state(GameState.PLAYING)

func _input_pause_options(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed:
		match ev.keycode:
			KEY_UP, KEY_W:
				settings_idx = (settings_idx - 1 + SETTINGS_OPTS.size()) % SETTINGS_OPTS.size()
			KEY_DOWN, KEY_S:
				settings_idx = (settings_idx + 1) % SETTINGS_OPTS.size()
			KEY_LEFT:  _settings_adjust(-1)
			KEY_RIGHT: _settings_adjust(1)
			KEY_ENTER, KEY_SPACE: _settings_adjust(1)
			KEY_ESCAPE: change_state(GameState.PAUSED)

func _input_recipe(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed:
		match ev.keycode:
			KEY_RIGHT, KEY_D: recipe_page = (recipe_page + 1) % RECIPES.size()
			KEY_LEFT,  KEY_A: recipe_page = (recipe_page - 1 + RECIPES.size()) % RECIPES.size()
			KEY_ESCAPE, KEY_B: change_state(GameState.PAUSED if state == GameState.PAUSE_RECIPE else GameState.MENU)

func _input_back_on_any(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed:
		change_state(GameState.MENU)

# ─── MENU ACTIONS ─────────────────────────────────────────────────────────────
func _on_menu_select() -> void:
	match MENU_OPTS[menu_idx]:
		"NEW GAME":
			slot_mode = "new"
			slot_idx = 0
			slot_overwrite_confirm = false
			slot_notice = ""
			_refresh_slot_summaries()
			change_state(GameState.SAVE_SLOTS)
		"CONTINUE":
			slot_mode = "continue"
			slot_idx = 0
			slot_overwrite_confirm = false
			slot_notice = ""
			_refresh_slot_summaries()
			change_state(GameState.SAVE_SLOTS)
		"UPGRADES":    change_state(GameState.UPGRADES)
		"RECIPE BOOK": change_state(GameState.PAUSE_RECIPE)
		"SETTINGS":    change_state(GameState.SETTINGS)
		"CREDITS":     change_state(GameState.CREDITS)
		"QUIT":        get_tree().quit()

func _on_upgrades_select() -> void:
	if upg_idx >= UPG_NAMES.size():
		change_state(GameState.MENU); return
	var key: String = UPG_NAMES[upg_idx]
	var cost := upgrade_manager.get_upgrade_cost(key)
	if cost > 0 and coins >= cost:
		if upgrade_manager.buy_upgrade(key, coins):
			coins -= cost

func _on_pause_select() -> void:
	match PAUSE_OPTS[pause_idx]:
		"RESUME":       change_state(GameState.PLAYING)
		"OPTIONS":      change_state(GameState.PAUSE_OPTIONS)
		"RECIPE BOOK":  change_state(GameState.PAUSE_RECIPE)
		"MAIN MENU":
			_clear_level()
			change_state(GameState.MENU)

# ─── ROUND MANAGEMENT ────────────────────────────────────────────────────────
func start_round() -> void:
	_clear_level()
	completed_orders = 0
	chaos_meter      = 0.0
	enemy_spawn_timer = 5.0
	required_orders  = mini(3 + (round_num - 1), 8)
	round_timer      = maxf(90.0 - round_num * 3.0, 45.0)

	player = ChefPlayer.new()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.show_behind_parent = true
	player.global_position = Vector2(480, 310)
	add_child(player)
	player.died.connect(_on_player_died)
	player.health_changed.connect(_on_player_health_changed)
	player.damaged.connect(_on_player_damaged)
	player.damaged.connect(sound_manager.play_hit)
	player.dashed.connect(sound_manager.play_dash)
	player.knife_thrown.connect(sound_manager.play_knife)
	upgrade_manager.apply_to_player(player)

	_setup_kitchen_layout()

	order_manager.set_difficulty(round_num)
	order_manager.clear_orders()
	for i in range(mini(3, required_orders)):
		order_manager.spawn_order()

	# Set background and state
	if round_num <= 4:
		_set_bg("bg_day");       change_state(GameState.PLAYING)
	elif round_num == 5:
		_set_bg("bg_xiangling"); _start_boss("Xiangling")
	elif round_num <= 9:
		_set_bg("bg_night");     change_state(GameState.PLAYING)
	elif round_num == 10:
		_set_bg("bg_xiangling"); _start_boss("XianglingRematch")
	elif round_num <= 14:
		_set_bg("bg_rotoven");   change_state(GameState.PLAYING)
	elif round_num == 15:
		_set_bg("bg_rotoven");   _start_boss("Rotoven")

func _set_bg(name: String) -> void:
	bg_sprite.texture = load("res://assets/processed/" + name + ".png") as Texture2D
	_clear_map_obstacles()
	var blockers: Array[Rect2] = []
	match name:
		"bg_day", "bg_night":
			blockers = [
				Rect2(165, 220, 242, 140),
				Rect2(575, 220, 133, 140),
				Rect2(742, 220, 68, 140),
				Rect2(877, 220, 68, 125)
			]
		"bg_xiangling":
			blockers = [
				Rect2(76, 126, 51, 61),
				Rect2(267, 137, 68, 40),
				Rect2(400, 137, 68, 40),
				Rect2(334, 211, 88, 45),
				Rect2(247, 301, 86, 40),
				Rect2(383, 301, 82, 41),
				Rect2(570, 123, 38, 59),
				Rect2(570, 190, 38, 64),
				Rect2(695, 124, 50, 50),
				Rect2(825, 124, 50, 50),
				Rect2(695, 225, 50, 50),
				Rect2(825, 225, 50, 50),
				Rect2(695, 326, 50, 50),
				Rect2(825, 326, 50, 50)
			]
		"bg_rotoven":
			blockers = [
				Rect2(28, 168, 77, 45),
				Rect2(220, 135, 68, 44),
				Rect2(373, 135, 85, 44),
				Rect2(140, 245, 54, 49),
				Rect2(220, 210, 96, 46),
				Rect2(373, 210, 86, 46),
				Rect2(500, 212, 38, 46),
				Rect2(205, 326, 89, 42),
				Rect2(370, 326, 88, 42),
				Rect2(40, 402, 66, 38),
				Rect2(204, 391, 90, 44),
				Rect2(370, 391, 88, 44),
				Rect2(468, 396, 83, 42)
			]
	for rect in blockers:
		var obstacle := StaticBody2D.new()
		obstacle.process_mode = Node.PROCESS_MODE_PAUSABLE
		obstacle.position = rect.position + rect.size / 2.0
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		obstacle.add_child(collision)
		add_child(obstacle)
		map_obstacles.append(obstacle)

func _clear_map_obstacles() -> void:
	for obstacle in map_obstacles:
		if is_instance_valid(obstacle):
			obstacle.queue_free()
	map_obstacles.clear()

func _setup_kitchen_layout() -> void:
	stations.clear()
	var crates := ["Pork", "Tomato", "Banana", "Rice", "Carrot"]
	for i in range(crates.size()):
		stations.append(_make_station(Vector2(90 + i * 75, 108), "crate", crates[i]))
	stations.append(_make_station(Vector2(475, 108), "plate_crate"))
	stations.append(_make_station(Vector2(558, 108), "cutting_board"))
	stations.append(_make_station(Vector2(638, 108), "cutting_board"))
	stations.append(_make_station(Vector2(700, 108), "stove"))
	stations.append(_make_station(Vector2(760, 108), "stove"))
	stations.append(_make_station(Vector2(160, 472), "assembly"))
	stations.append(_make_station(Vector2(260, 472), "assembly"))
	var ps := _make_station(Vector2(480, 472), "pass")
	ps.order_served.connect(_on_order_served)
	stations.append(ps)
	stations.append(_make_station(Vector2(640, 472), "plate_return"))
	stations.append(_make_station(Vector2(785, 472), "sink"))

func _make_station(pos: Vector2, stype: String, item: String = "") -> KitchenStation:
	var s := KitchenStation.new()
	s.process_mode = Node.PROCESS_MODE_PAUSABLE
	s.show_behind_parent = true
	s.global_position = pos
	s.station_type    = stype
	s.crate_item      = item
	upgrade_manager.apply_to_station(s)
	add_child(s)
	return s

func _start_boss(bname: String) -> void:
	order_manager.clear_orders()
	current_boss = KitchenBoss.new()
	current_boss.process_mode = Node.PROCESS_MODE_PAUSABLE
	current_boss.show_behind_parent = true
	current_boss.global_position = Vector2(800, 250)
	add_child(current_boss)
	current_boss.setup_boss(bname, Rect2(650, 80, 285, 350))
	if is_instance_valid(player):
		player.global_position = Vector2(785, 390)
		player.movement_bounds = Rect2(650, 125, 285, 300)
	current_boss.boss_defeated.connect(_on_boss_defeated)
	current_boss.spawn_projectile.connect(_on_boss_projectile)
	change_state(GameState.BOSS_FIGHT)

func _clear_level() -> void:
	_clear_map_obstacles()
	if is_instance_valid(player):     player.queue_free();       player = null
	if is_instance_valid(current_boss): current_boss.queue_free(); current_boss = null
	for s in stations: if is_instance_valid(s): s.queue_free()
	stations.clear()
	for e in enemies:  if is_instance_valid(e): e.queue_free()
	enemies.clear()
	for c in get_children():
		if c is Projectile or c is KitchenHazard: c.queue_free()

func _complete_round() -> void:
	if highest_round < round_num: highest_round = round_num
	SaveManager.save_game({"coins": coins, "round_num": round_num + 1, "highest_round": highest_round})
	if round_num >= max_rounds:
		change_state(GameState.VICTORY)
	else:
		round_num += 1
		change_state(GameState.ROUND_COMPLETE)

func _trigger_game_over(reason: String) -> void:
	game_over_reason = reason
	if highest_round < round_num: highest_round = round_num
	SaveManager.save_game({
		"coins": coins,
		"round_num": round_num,
		"highest_round": highest_round
	})
	change_state(GameState.GAME_OVER)

func change_state(new_state: GameState) -> void:
	if state != new_state:
		if new_state == GameState.GAME_OVER:
			sound_manager.play_game_over()
		elif new_state == GameState.VICTORY:
			sound_manager.play_victory()
	# Show/hide menu Jeff sprite
	jeff_menu_sprite.visible = (new_state == GameState.MENU)
	# Manage bg visibility
	bg_sprite.visible = true

	state = new_state
	get_tree().paused = (state == GameState.PAUSED or state == GameState.PAUSE_OPTIONS or state == GameState.PAUSE_RECIPE)
	queue_redraw()

# ─── SIGNAL HANDLERS ─────────────────────────────────────────────────────────
func _on_player_damaged() -> void:
	trigger_screen_shake(7.5)
	trigger_hit_flash(0.75)

func _on_player_died() -> void:
	trigger_screen_shake(11.0)
	trigger_hit_flash(1.0)
	_trigger_game_over("Chef Jeff has been defeated!")

func _on_player_health_changed(_h: int) -> void:
	queue_redraw()

func _on_boss_defeated() -> void:
	if is_instance_valid(current_boss): current_boss.queue_free(); current_boss = null
	coins += 500
	trigger_screen_shake(10.0)
	trigger_hit_flash(0.9)
	_complete_round()

func _on_order_completed(reward: int) -> void:
	coins += reward
	completed_orders += 1
	total_orders += 1
	chaos_meter = maxf(0.0, chaos_meter - 10.0)
	trigger_screen_shake(2.5)
	sound_manager.play_order_complete()
	if completed_orders < required_orders:
		order_manager.spawn_order()

func _on_order_expired() -> void:
	chaos_meter = minf(max_chaos, chaos_meter + 20.0)
	trigger_screen_shake(1.5)
	order_manager.spawn_order()

func _on_order_served(_recipe: String) -> void:
	order_manager.try_complete_order("any")

func _on_enemy_died(_type: String) -> void:
	coins += 5
	chaos_meter = maxf(0.0, chaos_meter - 3.0)

func _on_boss_projectile(pos: Vector2, dir: Vector2) -> void:
	var proj := Projectile.new()
	proj.process_mode = Node.PROCESS_MODE_PAUSABLE
	proj.show_behind_parent = true
	proj.global_position = pos
	proj.direction = dir
	proj.damage = 1
	add_child(proj)

# ═════════════════════════════════════════════════════════════════════════════
# DRAWING
# ═════════════════════════════════════════════════════════════════════════════
func _draw() -> void:
	if flash_effects and flash_amount > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(1.0, 0.88, 0.7, clampf(flash_amount * 0.35, 0.0, 0.55)))

	match state:
		GameState.SPLASH:          _draw_splash()
		GameState.MENU:            _draw_menu()
		GameState.SAVE_SLOTS:      _draw_save_slots()
		GameState.UPGRADES:        _draw_upgrades()
		GameState.SETTINGS:        _draw_settings()
		GameState.CREDITS:         _draw_credits()
		GameState.PLAYING:         _draw_playing_hud()
		GameState.BOSS_FIGHT:      _draw_boss_hud()
		GameState.PAUSED:          _draw_pause_menu()
		GameState.PAUSE_OPTIONS:   _draw_pause_options()
		GameState.PAUSE_RECIPE:    _draw_recipe_book()
		GameState.ROUND_COMPLETE:  _draw_round_complete()
		GameState.GAME_OVER:       _draw_game_over()
		GameState.VICTORY:         _draw_victory()

# ── helpers ───────────────────────────────────────────────────────────────────
func _f() -> Font: return ThemeDB.fallback_font

func _panel(rect: Rect2, fill: Color, border: Color = Color.TRANSPARENT, radius: float = 0.0) -> void:
	draw_rect(rect, fill)
	if border != Color.TRANSPARENT:
		draw_rect(rect, border, false, 1.5)

func _label(text: String, pos: Vector2, size: int, col: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1) -> void:
	draw_string(_f(), pos, text, align, width, size, col)

func _steam(alpha_mul: float = 1.0) -> void:
	for p in steam_particles:
		var a: float = clampf(p["alpha"] * alpha_mul, 0.0, 0.6)
		draw_circle(Vector2(p["x"], p["y"]), p["size"], Color(0.9, 0.9, 0.9, a))

func _bar(rect: Rect2, ratio: float, fill: Color, bg: Color = Color(0.1,0.1,0.1), border: Color = Color.WHITE) -> void:
	draw_rect(rect, bg)
	if ratio > 0:
		draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(ratio,0,1), rect.size.y)), fill)
	draw_rect(rect, border, false, 1.0)

func trigger_screen_shake(strength: float = 5.0) -> void:
	if not screen_shake:
		return
	camera_shake = maxf(camera_shake, strength)

func trigger_hit_flash(intensity: float = 0.65) -> void:
	if not flash_effects:
		return
	flash_amount = maxf(flash_amount, intensity)

# ── SPLASH ────────────────────────────────────────────────────────────────────
func _draw_splash() -> void:
	draw_rect(Rect2(0,0,W,H), Color(0.04,0.04,0.08))
	_steam(0.6)
	var a: float = clampf(1.0 - (splash_timer / 3.0) * 2.0 + 1.0, 0, 1)
	_label("PHANTOMSIX GAMES", Vector2(0,H/2-20), 42, Color(1,1,1,a), HORIZONTAL_ALIGNMENT_CENTER, W)
	_label("presents", Vector2(0,H/2+30), 22, Color(0.75,0.75,0.75,a), HORIZONTAL_ALIGNMENT_CENTER, W)

# ── MAIN MENU ─────────────────────────────────────────────────────────────────
func _draw_menu() -> void:
	# Dark gradient overlay
	draw_rect(Rect2(0,0,W,H), Color(0,0,0,0.68))
	_steam(0.4)

	# Left panel
	_panel(Rect2(0,0,520,H), Color(0,0,0,0.55))

	# Title block
	_label("KITCHEN", Vector2(40,90), 62, Color(1.0,0.85,0.1))
	_label("CHAOS",   Vector2(40,155), 62, Color(1.0,0.45,0.1))
	_label("PhantomSix Games  " + VERSION, Vector2(40,185), 14, Color(0.55,0.55,0.55))

	# Stats row
	_panel(Rect2(30,198,460,32), Color(0,0,0,0.4))
	_label("🪙 " + str(coins) + "   Best: Round " + str(highest_round), Vector2(40,218), 16, Color(0.95,0.85,0.45))

	# Menu options
	for i in range(MENU_OPTS.size()):
		var y := 248 + i * 40
		var sel := i == menu_idx
		if sel:
			_panel(Rect2(26, y-24, 468, 36), Color(1,0.85,0.1,0.18))
			draw_rect(Rect2(26, y-24, 4, 36), Color(1,0.85,0.1))
		var col := Color(1.0,0.92,0.3) if sel else Color(0.88,0.88,0.88)
		var prefix := "▶ " if sel else "   "
		_label(prefix + MENU_OPTS[i], Vector2(38, y), 24, col)

	# Bottom hint
	_label("W/S • Navigate    Enter • Confirm    ESC • Quit",
		Vector2(0, H-12), 13, Color(0.45,0.45,0.45), HORIZONTAL_ALIGNMENT_CENTER, W)

	# Decorative animated glow behind Jeff
	var pulse := 0.18 + sin(menu_anim_t * 2.5) * 0.07
	draw_circle(Vector2(780, 340), 95, Color(1,0.7,0.2,pulse))

# ── SAVE SLOTS ────────────────────────────────────────────────────────────────
func _draw_save_slots() -> void:
	draw_rect(Rect2(0,0,W,H), Color(0.03,0.04,0.08))
	_panel(Rect2(W/2-310,48,620,436), Color(0.06,0.07,0.12), Color(0.3,0.28,0.16))
	var title := "CHOOSE A SAVE SLOT"
	_label(title, Vector2(W/2-290,92), 32, Color(1,0.85,0.1), HORIZONTAL_ALIGNMENT_CENTER, 580)
	var action := "Continue a saved kitchen" if slot_mode == "continue" else "Start a new kitchen"
	_label(action, Vector2(W/2-290,119), 16, Color(0.65,0.65,0.7), HORIZONTAL_ALIGNMENT_CENTER, 580)

	for i in range(SaveManager.SLOT_COUNT):
		var slot := i + 1
		var data: Dictionary = slot_summaries[i] if i < slot_summaries.size() else {}
		var occupied := data.has("round_num")
		var y := 145 + i * 94
		var selected := i == slot_idx
		var fill := Color(0.18,0.16,0.08) if selected else Color(0.09,0.11,0.17)
		var border := Color(1,0.85,0.1) if selected else Color(0.25,0.28,0.38)
		_panel(Rect2(W/2-260,y,520,78), fill, border)
		if selected:
			draw_rect(Rect2(W/2-260,y,5,78), Color(1,0.85,0.1))
		_label("SLOT " + str(slot), Vector2(W/2-238,y+29), 20, Color(1,0.92,0.55) if selected else Color.WHITE)
		if occupied:
			var status := "Best round: %d     Coins: %d" % [
				int(data.get("highest_round", data.get("round_num", 1))),
				int(data.get("coins", 0))
			]
			_label(status, Vector2(W/2-238,y+54), 15, Color(0.72,0.78,0.72))
			var prompt := "OVERWRITE" if slot_mode == "new" else "CONTINUE"
			_label(prompt, Vector2(W/2+88,y+45), 16, Color(1,0.75,0.3), HORIZONTAL_ALIGNMENT_CENTER, 165)
		else:
			_label("Empty slot", Vector2(W/2-238,y+54), 15, Color(0.5,0.53,0.6))
			_label("NEW GAME" if slot_mode == "new" else "EMPTY", Vector2(W/2+88,y+45), 16, Color(0.62,0.7,0.75), HORIZONTAL_ALIGNMENT_CENTER, 165)

	if slot_notice != "":
		var notice_color := Color(1.0,0.55,0.35) if slot_overwrite_confirm else Color(0.95,0.75,0.4)
		_label(slot_notice, Vector2(W/2-300,443), 14, notice_color, HORIZONTAL_ALIGNMENT_CENTER, 600)
	else:
		_label("W/S • Select    Enter • Confirm    ESC • Back", Vector2(0,463), 14, Color(0.5,0.52,0.58), HORIZONTAL_ALIGNMENT_CENTER, W)

func _refresh_slot_summaries() -> void:
	slot_summaries.clear()
	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		slot_summaries.append(SaveManager.load_slot(slot))

# ── UPGRADES ─────────────────────────────────────────────────────────────────
func _draw_upgrades() -> void:
	draw_rect(Rect2(0,0,W,H), Color(0.03,0.05,0.10))
	_panel(Rect2(0,0,W,60), Color(0,0,0,0.7))
	_label("UPGRADES", Vector2(0,44), 36, Color(1.0,0.85,0.1), HORIZONTAL_ALIGNMENT_CENTER, W)
	_panel(Rect2(W-180,14,170,34), Color(0.12,0.10,0.02))
	_label("🪙 " + str(coins) + " coins", Vector2(W-170,38), 18, Color(0.95,0.85,0.4))

	var card_w  := 270
	var card_h  := 210
	var card_y  := 90
	var gap     := 20
	var total_w := UPG_NAMES.size() * card_w + (UPG_NAMES.size()-1) * gap
	var start_x := (W - total_w) / 2

	for i in range(UPG_NAMES.size()):
		var key: String = UPG_NAMES[i]
		var lbl: String = UPG_LABELS[i]
		var desc: String = UPG_DESCS[i]
		var lv: int = upgrade_manager.get_level(key)
		var max_lv: int = upgrade_manager.max_levels.get(key, 5)
		var cost: int = upgrade_manager.get_upgrade_cost(key)
		var sel  := i == upg_idx
		var cx   := start_x + i * (card_w + gap)
		var cr   := Rect2(cx, card_y, card_w, card_h)

		# Card background
		var bg_col := Color(0.12,0.14,0.22) if not sel else Color(0.20,0.18,0.08)
		_panel(cr, bg_col, Color(1,0.85,0.1) if sel else Color(0.3,0.3,0.4), 0)
		if sel:
			draw_rect(cr, Color(1,0.85,0.1,0.06))

		# Icon
		_label(UPG_ICONS[i], Vector2(cx+10, card_y+40), 36, Color.WHITE)

		# Title
		_label(lbl, Vector2(cx+10, card_y+78), 20, Color(1,0.92,0.5) if sel else Color.WHITE)

		# Description
		_label(desc, Vector2(cx+10, card_y+100), 13, Color(0.75,0.75,0.75), HORIZONTAL_ALIGNMENT_LEFT, card_w-20)

		# Level pip bar
		for p in range(max_lv):
			var px: float = cx + 10 + p * (int(card_w-20) / max_lv)
			var pip_col := Color(0.3,0.9,0.3) if p < lv else Color(0.2,0.2,0.2)
			_panel(Rect2(px, card_y+135, int(card_w-20)/max_lv - 4, 10), pip_col, Color(0.5,0.5,0.5))
		_label("Level " + str(lv) + " / " + str(max_lv), Vector2(cx+10, card_y+155), 14, Color(0.7,0.7,0.7))

		# Cost / Buy button
		if lv >= max_lv:
			_panel(Rect2(cx+10, card_y+170, card_w-20, 28), Color(0.1,0.3,0.1))
			_label("MAXED OUT", Vector2(cx+10, card_y+188), 16, Color(0.4,0.9,0.4), HORIZONTAL_ALIGNMENT_CENTER, card_w-20)
		else:
			var can_buy := coins >= cost
			var btn_col := Color(0.2,0.18,0.04) if can_buy else Color(0.15,0.1,0.1)
			_panel(Rect2(cx+10, card_y+170, card_w-20, 28), btn_col, Color(0.8,0.65,0.1) if can_buy else Color(0.35,0.2,0.2))
			var cost_str := "🪙 " + str(cost) + "  [ENTER]" if (sel and can_buy) else ("🪙 " + str(cost))
			var cost_col := Color(0.95,0.8,0.2) if can_buy else Color(0.55,0.35,0.35)
			_label(cost_str, Vector2(cx+10, card_y+188), 15, cost_col, HORIZONTAL_ALIGNMENT_CENTER, card_w-20)

	# Back option
	var back_sel := upg_idx >= UPG_NAMES.size()
	_panel(Rect2(W/2-100, card_y+card_h+20, 200, 36), Color(0.1,0.1,0.1) if not back_sel else Color(0.18,0.12,0.02), Color(0.4,0.4,0.4) if not back_sel else Color(1,0.85,0.1))
	_label("◀  BACK TO MENU", Vector2(W/2-100, card_y+card_h+42), 18, Color(0.9,0.9,0.9) if not back_sel else Color(1,0.92,0.3), HORIZONTAL_ALIGNMENT_CENTER, 200)

	_label("W/S • Select    Enter • Buy    ESC • Back", Vector2(0,H-12), 13, Color(0.4,0.4,0.4), HORIZONTAL_ALIGNMENT_CENTER, W)

# ── SETTINGS ─────────────────────────────────────────────────────────────────
func _draw_settings(from_pause: bool = false) -> void:
	if not from_pause:
		draw_rect(Rect2(0,0,W,H), Color(0.03,0.04,0.08))
	_panel(Rect2(W/2-240, 60, 480, 400), Color(0.06,0.07,0.12), Color(0.25,0.25,0.45))
	_label("OPTIONS", Vector2(W/2-240, 100), 32, Color(1,0.85,0.1), HORIZONTAL_ALIGNMENT_CENTER, 480)

	var vals := [
		str(master_vol) + "%",
		str(sfx_vol) + "%",
		"ON" if screen_shake else "OFF",
		"ON" if flash_effects else "OFF",
		"BACK"
	]
	for i in range(SETTINGS_OPTS.size()):
		var y := 150 + i * 52
		var sel := i == settings_idx
		if sel:
			_panel(Rect2(W/2-230, y-22, 460, 40), Color(1,0.85,0.1,0.15))
		var col := Color(1.0,0.92,0.3) if sel else Color(0.85,0.85,0.85)
		_label(SETTINGS_OPTS[i], Vector2(W/2-220, y), 20, col)
		if i < 4:
			_label("◀  " + vals[i] + "  ▶", Vector2(W/2+60, y), 20, col)

	_label("←/→ or Enter to adjust    ESC to go back", Vector2(0,H-12), 13, Color(0.4,0.4,0.4), HORIZONTAL_ALIGNMENT_CENTER, W)

# ── PAUSE MENU ────────────────────────────────────────────────────────────────
func _draw_pause_menu() -> void:
	# Keep gameplay visible behind the overlay
	_draw_playing_hud()
	draw_rect(Rect2(0,0,W,H), Color(0,0,0,0.6))

	var pw := 340
	var ph := 280
	var px := (W - pw) / 2
	var py := (H - ph) / 2

	_panel(Rect2(px, py, pw, ph), Color(0.06,0.07,0.12,0.97), Color(0.4,0.35,0.1))
	_label("PAUSED", Vector2(px, py+38), 34, Color(1,0.85,0.1), HORIZONTAL_ALIGNMENT_CENTER, pw)

	# Divider
	draw_line(Vector2(px+20, py+55), Vector2(px+pw-20, py+55), Color(0.3,0.28,0.1), 1.5)

	for i in range(PAUSE_OPTS.size()):
		var y := py + 85 + i * 46
		var sel := i == pause_idx
		if sel:
			_panel(Rect2(px+14, y-24, pw-28, 38), Color(1,0.85,0.1,0.18))
			draw_rect(Rect2(px+14, y-24, 4, 38), Color(1,0.85,0.1))
		var col := Color(1,0.92,0.3) if sel else Color(0.85,0.85,0.85)
		var prefix := "▶ " if sel else "   "
		_label(prefix + PAUSE_OPTS[i], Vector2(px+24, y), 22, col)

	_label("W/S • Navigate    Enter • Select    ESC • Resume", Vector2(px, py+ph-12), 12, Color(0.45,0.45,0.45), HORIZONTAL_ALIGNMENT_CENTER, pw)

func _draw_pause_options() -> void:
	_draw_playing_hud()
	draw_rect(Rect2(0,0,W,H), Color(0,0,0,0.6))
	_draw_settings(true)

# ── RECIPE BOOK ───────────────────────────────────────────────────────────────
func _draw_recipe_book() -> void:
	if state == GameState.PAUSE_RECIPE:
		_draw_playing_hud()
		draw_rect(Rect2(0,0,W,H), Color(0,0,0,0.65))

	# Book panel
	var bw := 700
	var bh := 420
	var bx := (W - bw) / 2
	var by := (H - bh) / 2

	# Wooden desk shadow
	_panel(Rect2(bx-6, by-6, bw+12, bh+12), Color(0.2,0.14,0.06))
	# Parchment
	_panel(Rect2(bx, by, bw, bh), Color(0.96,0.91,0.78))
	# Spine
	_panel(Rect2(bx+bw/2-5, by, 10, bh), Color(0.45,0.28,0.10))

	# Left page — recipe list / index
	_label("📖 RECIPE BOOK", Vector2(bx+16, by+32), 22, Color(0.35,0.22,0.08))
	_label("Page " + str(recipe_page+1) + " of " + str(RECIPES.size()), Vector2(bx+16, by+55), 13, Color(0.55,0.45,0.25))

	draw_line(Vector2(bx+16,by+62), Vector2(bx+bw/2-12,by+62), Color(0.7,0.6,0.4), 1.0)

	for i in range(RECIPES.size()):
		var ry := by + 80 + i * 28
		var sel := i == recipe_page
		if sel:
			draw_rect(Rect2(bx+10, ry-16, bw/2-22, 24), Color(0.8,0.6,0.2,0.25))
		var col := Color(0.35,0.22,0.08) if sel else Color(0.5,0.38,0.2)
		_label(("▶ " if sel else "  ") + RECIPES[i]["icon"] + " " + RECIPES[i]["name"], Vector2(bx+18, ry), 17, col)
		_label("🪙 " + str(RECIPES[i]["reward"]), Vector2(bx+bw/2-70, ry), 14, Color(0.7,0.55,0.1))

	draw_line(Vector2(bx+16,by+bh-32), Vector2(bx+bw/2-12,by+bh-32), Color(0.7,0.6,0.4), 1.0)
	_label("A/D or ←/→ to flip pages", Vector2(bx+16, by+bh-14), 12, Color(0.6,0.5,0.3))

	# Right page — selected recipe detail
	var rp: Dictionary = RECIPES[recipe_page]
	var rx := bx + bw/2 + 14

	_label(rp["icon"] + "  " + rp["name"], Vector2(rx, by+38), 22, Color(0.35,0.22,0.08))
	draw_line(Vector2(rx, by+48), Vector2(bx+bw-14, by+48), Color(0.7,0.6,0.4), 1.0)

	_label("INGREDIENTS:", Vector2(rx, by+72), 15, Color(0.5,0.35,0.12))
	var ings: Array = rp["ingredients"]
	for i in range(ings.size()):
		_label("• " + ings[i], Vector2(rx+8, by+92+i*20), 14, Color(0.4,0.28,0.1))

	var step_y := by + 92 + ings.size() * 20 + 14
	draw_line(Vector2(rx, step_y-4), Vector2(bx+bw-14, step_y-4), Color(0.7,0.6,0.4), 0.8)
	_label("HOW TO MAKE:", Vector2(rx, step_y+14), 15, Color(0.5,0.35,0.12))

	var steps: Array = rp["steps"]
	for i in range(steps.size()):
		_label(steps[i], Vector2(rx+6, step_y+32+i*24), 13, Color(0.38,0.26,0.1), HORIZONTAL_ALIGNMENT_LEFT, bw/2-24)

	_label("Reward: 🪙 " + str(rp["reward"]) + " coins", Vector2(rx, by+bh-22), 15, Color(0.6,0.42,0.08))

	_label("ESC • Close", Vector2(bx+bw-80, by+bh-16), 12, Color(0.55,0.45,0.25))

# ── IN-GAME HUD ───────────────────────────────────────────────────────────────
func _draw_playing_hud() -> void:
	_draw_hud_topbar()
	_draw_hud_orders()
	_draw_hud_chaos()
	_draw_hud_dash()
	_draw_hud_interact_hint()

func _draw_boss_hud() -> void:
	_draw_playing_hud()
	if is_instance_valid(current_boss):
		_draw_boss_bar()

func _draw_hud_topbar() -> void:
	# Background strip
	_panel(Rect2(0,0,W,56), Color(0,0,0,0.72))

	# Hearts (left)
	_label("HP", Vector2(10,20), 14, Color(0.6,0.6,0.6))
	if is_instance_valid(player):
		for i in range(player.max_health):
			var full := i < player.health
			var hc := Color(0.92,0.15,0.18) if full else Color(0.22,0.18,0.18)
			draw_circle(Vector2(38 + i * 28, 36), 11, hc)
			if full:
				draw_circle(Vector2(38 + i * 28, 36), 11, Color(1,0.5,0.5,0.35), false, 2.0)
			else:
				draw_circle(Vector2(38 + i * 28, 36), 11, Color(0.4,0.3,0.3,0.6), false, 1.0)

	# Round + timer (center)
	var r_str := "ROUND " + str(round_num) + " / " + str(max_rounds)
	_label(r_str, Vector2(0,24), 18, Color(0.9,0.9,0.9), HORIZONTAL_ALIGNMENT_CENTER, W)
	var tc := Color.YELLOW if round_timer < 15.0 else Color(0.8,0.9,0.8)
	_label(str(int(round_timer)) + "s", Vector2(0,46), 20, tc, HORIZONTAL_ALIGNMENT_CENTER, W)

	# Orders progress (center-right)
	var objective_text := "BOSS FIGHT" if state == GameState.BOSS_FIGHT else "Orders: " + str(completed_orders) + " / " + str(required_orders)
	var objective_color := Color(0.9,0.55,0.45) if state == GameState.BOSS_FIGHT else Color(0.75,0.9,0.75)
	_label(objective_text, Vector2(530,34), 15, objective_color)

	# Coins (right)
	_panel(Rect2(W-130,6,124,44), Color(0.12,0.10,0.02))
	_label("🪙 " + str(coins), Vector2(W-124,38), 20, Color(0.97,0.85,0.35))

func _draw_hud_orders() -> void:
	if state == GameState.BOSS_FIGHT:
		return
	var orders := order_manager.active_orders
	if orders.is_empty(): return

	var pw := 170
	var px := W - pw - 4
	var py := 62

	_panel(Rect2(px-4, py, pw+8, 22), Color(0,0,0,0.7))
	_label("ORDERS", Vector2(px, py+16), 14, Color(0.65,0.65,0.65))

	for i in range(orders.size()):
		var ord: Dictionary = orders[i]
		var oy   := py + 24 + i * 62
		var ratio: float = float(ord.get("time_left",0)) / float(ord.get("max_time",1))
		var ocol := Color(0.25,0.85,0.25) if ratio > 0.5 else (Color(0.9,0.75,0.1) if ratio > 0.25 else Color(0.9,0.2,0.15))

		_panel(Rect2(px-4, oy, pw+8, 56), Color(0.05,0.05,0.08,0.85), Color(0.2,0.2,0.25))
		_label(str(ord.get("recipe","?")), Vector2(px+2, oy+18), 15, Color.WHITE)
		_label("🪙 " + str(ord.get("reward",0)), Vector2(px+2, oy+35), 12, Color(0.8,0.75,0.3))
		_bar(Rect2(px+2, oy+42, pw-8, 8), ratio, ocol)

func _draw_hud_chaos() -> void:
	var bx := 4; var by := H - 36
	_label("CHAOS", Vector2(bx, by-2), 13, Color(0.75,0.35,0.35))
	var ratio := chaos_meter / max_chaos
	var cc := Color(0.15,0.85,0.15) if ratio < 0.5 else (Color(0.9,0.7,0.1) if ratio < 0.8 else Color(1.0,0.1,0.1))
	_bar(Rect2(bx, by+10, 200, 16), ratio, cc, Color(0.1,0.05,0.05), Color(0.5,0.25,0.25))
	_label(str(int(chaos_meter)) + "%", Vector2(bx+204, by+22), 14, cc)

func _draw_hud_dash() -> void:
	if not is_instance_valid(player): return
	var rdy := player.dash_cooldown_timer <= 0.0
	var dc  := Color(0.4,0.95,0.4) if rdy else Color(0.6,0.45,0.45)
	var ds  := "DASH  READY" if rdy else ("DASH  " + str(snappedf(player.dash_cooldown_timer,0.1)) + "s")
	_label(ds, Vector2(6, H-12), 15, dc)
	var knife_rdy := player.knife_cooldown_timer <= 0.0
	var knife_col := Color(0.75,0.9,1.0) if knife_rdy else Color(0.6,0.65,0.7)
	var knife_text := "KNIFE  READY" if knife_rdy else ("KNIFE  " + str(snappedf(player.knife_cooldown_timer,0.1)) + "s")
	_label("LMB  " + knife_text, Vector2(280, H-12), 15, knife_col)

func _draw_hud_interact_hint() -> void:
	if not is_instance_valid(player): return
	for s in stations:
		if is_instance_valid(s) and player.global_position.distance_to(s.global_position) < 55.0:
			var panel_width := 164.0
			var hx := clampf(player.global_position.x - panel_width / 2.0, 8.0, W - panel_width - 8.0)
			var hy := clampf(player.global_position.y - 56.0, 66.0, H - 36.0)
			_panel(Rect2(hx, hy, panel_width, 26), Color(0.025,0.035,0.045,0.9), Color(0.9,0.72,0.28,0.85))
			_label("E  " + s.interaction_hint(player), Vector2(hx+6, hy+17), 12, Color(1.0,0.91,0.67), HORIZONTAL_ALIGNMENT_CENTER, panel_width-12)
			break

func _draw_boss_bar() -> void:
	if not is_instance_valid(current_boss): return
	var ratio: float = float(current_boss.current_hp) / float(current_boss.max_hp)
	var bname := current_boss.boss_name.to_upper()
	_panel(Rect2(260,64,440,8), Color(0.08,0.04,0.08,0.95), Color(0.9,0.55,0.45))
	_panel(Rect2(262,66,int(436*ratio),4), Color(0.95,0.34,0.24))
	_label(bname + "  " + str(current_boss.current_hp) + " / " + str(current_boss.max_hp),
		Vector2(0,91), 14, Color(1.0,0.75,0.63), HORIZONTAL_ALIGNMENT_CENTER, W)

# ── ROUND COMPLETE ────────────────────────────────────────────────────────────
func _draw_round_complete() -> void:
	draw_rect(Rect2(0,0,W,H), Color(0,0,0,0.78))
	var prev := round_num - 1
	_label("ROUND " + str(prev) + " COMPLETE!", Vector2(0,170), 48, Color(1.0,0.88,0.1), HORIZONTAL_ALIGNMENT_CENTER, W)
	draw_line(Vector2(200,195), Vector2(760,195), Color(0.5,0.45,0.1), 2.0)
	if prev in [5, 10, 15]:
		_label("Boss Defeated!", Vector2(0,235), 26, Color(1.0,0.65,0.5), HORIZONTAL_ALIGNMENT_CENTER, W)
	else:
		_label("Orders Served: " + str(completed_orders) + " / " + str(required_orders), Vector2(0,235), 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	_label("Coins: 🪙 " + str(coins), Vector2(0,270), 26, Color(0.95,0.85,0.4), HORIZONTAL_ALIGNMENT_CENTER, W)
	_label("Chaos at end: " + str(int(chaos_meter)) + "%", Vector2(0,305), 22, Color(0.7,0.7,0.7), HORIZONTAL_ALIGNMENT_CENTER, W)
	_panel(Rect2(W/2-140,340,280,44), Color(0.12,0.18,0.08), Color(0.4,0.7,0.3))
	_label("▶  CONTINUE TO ROUND " + str(round_num), Vector2(W/2-140,368), 18, Color(0.6,0.95,0.5), HORIZONTAL_ALIGNMENT_CENTER, 280)
	_label("Press ENTER", Vector2(0,H-14), 14, Color(0.45,0.45,0.45), HORIZONTAL_ALIGNMENT_CENTER, W)

# ── GAME OVER ─────────────────────────────────────────────────────────────────
func _draw_game_over() -> void:
	draw_rect(Rect2(0,0,W,H), Color(0.08,0.01,0.01,0.92))
	_label("YOU'VE BEEN COOKED!", Vector2(0,150), 46, Color(1.0,0.18,0.18), HORIZONTAL_ALIGNMENT_CENTER, W)
	draw_line(Vector2(180,172), Vector2(780,172), Color(0.5,0.08,0.08), 1.5)
	_label(game_over_reason, Vector2(0,205), 22, Color(0.85,0.5,0.5), HORIZONTAL_ALIGNMENT_CENTER, W)
	_label("Round Reached:     " + str(round_num), Vector2(0,255), 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	_label("Orders Completed:  " + str(completed_orders), Vector2(0,288), 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	_label("Total Coins:       🪙 " + str(coins), Vector2(0,321), 24, Color(0.95,0.85,0.4), HORIZONTAL_ALIGNMENT_CENTER, W)
	_label("Best Round:        " + str(highest_round), Vector2(0,354), 24, Color(0.7,0.7,0.9), HORIZONTAL_ALIGNMENT_CENTER, W)
	_panel(Rect2(W/2-120,390,240,42), Color(0.18,0.04,0.04), Color(0.7,0.2,0.2))
	_label("BACK TO MENU", Vector2(W/2-120,414), 22, Color(0.9,0.5,0.5), HORIZONTAL_ALIGNMENT_CENTER, 240)
	_label("Press any key", Vector2(0,H-14), 14, Color(0.4,0.4,0.4), HORIZONTAL_ALIGNMENT_CENTER, W)

# ── VICTORY ───────────────────────────────────────────────────────────────────
func _draw_victory() -> void:
	draw_rect(Rect2(0,0,W,H), Color(0.01,0.06,0.01,0.92))
	_steam(0.5)
	_label("KITCHEN SURVIVED!", Vector2(0,130), 52, Color(1.0,0.92,0.2), HORIZONTAL_ALIGNMENT_CENTER, W)
	draw_line(Vector2(160,160), Vector2(800,160), Color(0.6,0.55,0.1), 2.0)
	_label("All 15 Rounds Complete!", Vector2(0,200), 28, Color(0.5,1.0,0.5), HORIZONTAL_ALIGNMENT_CENTER, W)
	_label("Bosses Defeated: 3 / 3 ⚔️",    Vector2(0,240), 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	_label("Orders Served: " + str(total_orders), Vector2(0,274), 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, W)
	_label("Final Coins: 🪙 " + str(coins), Vector2(0,308), 24, Color(0.95,0.85,0.4), HORIZONTAL_ALIGNMENT_CENTER, W)
	_panel(Rect2(W/2-140,355,280,44), Color(0.06,0.16,0.06), Color(0.3,0.7,0.3))
	_label("PLAY AGAIN", Vector2(W/2-140,379), 24, Color(0.5,0.95,0.5), HORIZONTAL_ALIGNMENT_CENTER, 280)
	_label("Press any key to continue", Vector2(0,H-14), 14, Color(0.4,0.4,0.4), HORIZONTAL_ALIGNMENT_CENTER, W)

# ── CREDITS ───────────────────────────────────────────────────────────────────
func _draw_credits() -> void:
	draw_rect(Rect2(0,0,W,H), Color(0.03,0.04,0.08))
	_panel(Rect2(W/2-280,60,560,380), Color(0.06,0.07,0.12,0.95), Color(0.25,0.25,0.45))
	_label("CREDITS", Vector2(W/2-280,100), 34, Color(1,0.85,0.1), HORIZONTAL_ALIGNMENT_CENTER, 560)
	draw_line(Vector2(W/2-260,115), Vector2(W/2+260,115), Color(0.35,0.3,0.1), 1.5)
	var lines := [
		["KITCHEN CHAOS", Color(1,0.85,0.1), 22],
		["A PhantomSix Games Original", Color(0.7,0.7,0.7), 16],
		["", Color.WHITE, 10],
		["Game Design & Development", Color(0.55,0.55,0.55), 14],
		["PhantomSix Games", Color.WHITE, 18],
		["", Color.WHITE, 10],
		["Art Direction & Characters", Color(0.55,0.55,0.55), 14],
		["Jeff  •  Xiangling  •  Rotoven", Color.WHITE, 18],
		["", Color.WHITE, 10],
		["Built with Godot Engine 4.7", Color(0.55,0.55,0.55), 14],
		["Thank you for playing!", Color(0.5,1.0,0.5), 20],
	]
	var cy := 136
	for ln in lines:
		_label(ln[0], Vector2(W/2-260, cy), ln[2], ln[1], HORIZONTAL_ALIGNMENT_CENTER, 520)
		cy += ln[2] + 8
	_label("Press any key to go back", Vector2(0,H-14), 13, Color(0.4,0.4,0.4), HORIZONTAL_ALIGNMENT_CENTER, W)
