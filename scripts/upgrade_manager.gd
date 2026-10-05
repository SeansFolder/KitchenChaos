extends Node
class_name UpgradeManager

var upgrades: Dictionary = {
	"speed_boots": 0,
	"chef_timer": 0,
	"extra_life": 0
}

var max_levels: Dictionary = {
	"speed_boots": 5,
	"chef_timer": 5,
	"extra_life": 3
}

var costs: Array = [100, 200, 350, 500, 750]

func get_level(upgrade: String) -> int:
	return upgrades.get(upgrade, 0)

func get_upgrade_cost(upgrade: String) -> int:
	var lv: int = get_level(upgrade)
	var max_lv: int = max_levels.get(upgrade, 5)
	if lv >= max_lv:
		return 0  # maxed
	return costs[min(lv, costs.size() - 1)]

func buy_upgrade(upgrade: String, player_coins: int) -> bool:
	var lv: int = get_level(upgrade)
	var max_lv: int = max_levels.get(upgrade, 5)
	if lv >= max_lv:
		return false
	var cost: int = get_upgrade_cost(upgrade)
	if player_coins < cost:
		return false
	upgrades[upgrade] = lv + 1
	save_data()
	return true

func apply_to_player(player: ChefPlayer) -> void:
	var speed_lv: int = get_level("speed_boots")
	player.move_speed = 160.0 + float(speed_lv) * 18.0
	var life_lv: int = get_level("extra_life")
	player.extra_lives = life_lv

func apply_to_station(station: KitchenStation) -> void:
	var timer_lv: int = get_level("chef_timer")
	station.task_speed_multiplier = 1.0 + float(timer_lv) * 0.15

func reset_for_new_game() -> void:
	# Upgrades persist across runs (roguelike permanent progression)
	pass

func save_data() -> void:
	SaveManager.save_upgrades(upgrades)

func load_data() -> void:
	for key in upgrades.keys():
		upgrades[key] = 0
	var d: Dictionary = SaveManager.load_upgrades()
	for k in d.keys():
		if upgrades.has(k):
			upgrades[k] = int(d[k])
